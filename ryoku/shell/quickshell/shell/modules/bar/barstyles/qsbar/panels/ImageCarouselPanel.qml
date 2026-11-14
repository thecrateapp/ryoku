import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "ImagePickerModel.js" as Model
import Ryoku.Ui.Singletons

// Tanzaku filmstrip picker for theme & wallpaper.
// sumi-e language: lots of empty space (ma), the focused image centred & full,
// the rest as thin desaturated paper strips (tanzaku), and ONE seal brush-stroke
// gliding under the focus as the single confident accent line.
PanelWindow {
    id: panel
    required property var root

    screen: root.activePopupScreen

    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "ryoku-image-carousel"
    WlrLayershell.keyboardFocus: panel.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property bool active: root.pickerStyle === "tanzaku" || root.pickerStyle === ""   // default
    readonly property bool isThemeMode: root.imagePickerMode === "theme"
    readonly property bool ready: root.imagePickerVisible && active && imagesLoaded && layoutSettled

    property bool imagesLoaded:  false
    property bool layoutSettled: false
    property bool scanDone:      false   // a scan finished (distinguishes "loading" from "nothing found")
    property var  imageArray:    []
    property int  selFilt:       0
    property string filterText:  ""
    property string currentImage: ""
    property int thumbEpoch:      0
    property string readyThumbUrl: ""

    visible: root.imagePickerVisible && active

    // ── reveal (fade + subtle rise) ──
    property real reveal: 0
    Behavior on reveal { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    onReadyChanged: reveal = ready ? 1 : 0

    // ── filtered list (each entry keeps its original index) ──
    readonly property var filtered: {
        var out = []
        for (var i = 0; i < imageArray.length; i++) {
            if (!Model.itemMatches(imageArray, i, filterText)) continue
            out.push({
                idx:      i,
                filePath: imageArray[i].filePath,
                thumb:    panel.thumbUrlFor(imageArray[i]),
                label:    Model.labelForPath(imageArray[i].filePath),
                dir:      imageArray[i].dir || "",
                current:  imageArray[i].filePath === panel.currentImage
            })
        }
        return out
    }
    onFilteredChanged: if (selFilt >= filtered.length) selFilt = Math.max(0, filtered.length - 1)

    readonly property string currentLabel:
        (filtered.length > 0 && selFilt >= 0 && selFilt < filtered.length)
            ? I18n.tr(filtered[selFilt].label)
            : (filterText ? I18n.tr("No matches") : "")
    function thumbUrlFor(img) {
        if (!img || !img.thumbnailPath || img.thumbnailPath === img.filePath) return ""
        return "file://" + img.thumbnailPath
    }

    // ── open / style gating ──
    function syncOpen() {
        if (root.imagePickerVisible && active) {
            if (!imagesLoaded) {
                panel.layoutSettled = false
                panel.filterText    = ""
                panel.imageArray    = []
                panel.selFilt       = 0
                panel.reveal        = 0
                currentProc.running = false; currentProc.running = true
            }
        } else {
            panel.imagesLoaded  = false; panel.scanDone = false
            panel.layoutSettled = false
            panel.reveal        = 0
        }
    }
    Connections {
        target: root
        function onImagePickerVisibleChanged() { panel.syncOpen() }
        function onPickerStyleChanged()         { panel.syncOpen() }
    }
    Component.onCompleted: panel.syncOpen()

    // step 1: current image
    Process {
        id: currentProc
        command: panel.isThemeMode
            ? ["bash", "-c",
               "CACHE=$HOME/.cache/quickshell-theme-picker; " +
               "name=$(cat " + panel.shq(root.themeNamePath) + " 2>/dev/null || true); " +
               "for ext in png jpg jpeg webp; do f=\"$CACHE/$name.$ext\"; [ -L \"$f\" ] && echo \"$f\" && exit 0; done; echo ''"]
            : ["bash", "-c", "readlink -f " + panel.shq(root.currentBackgroundPath) + " 2>/dev/null || true"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                panel.currentImage = this.text.trim()
                cacheProc.running = false; cacheProc.running = true   // instant from cache
                var cmd = panel.buildScanCmd()
                cmd[2] = cmd[2] + " | tee " + panel.shq(panel.scanCachePath)
                scanProc.command = cmd
                scanProc.running = false; scanProc.running = true
            }
        }
    }

    // step 2: scan images (live refresh; writes the cache via tee)
    Process {
        id: scanProc
        command: []
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: panel.applyScan(text, false)
        }
    }

    // scan-result cache → instant (re)open
    readonly property string scanCachePath: Quickshell.env("HOME") + "/.cache/quickshell-scan-" + (isThemeMode ? "theme" : "wallpaper")
    property string _lastScan: ""
    function scanHasOriginalThumbs(text) {
        var rows = String(text || "").split("\n")
        for (var i = 0; i < rows.length; i++) {
            var row = rows[i]
            if (!row) continue
            var cols = row.split("\t")
            if (cols.length < 2 || !cols[1] || cols[0] === cols[1]) return true
        }
        return false
    }
    Process {
        id: cacheProc
        command: ["cat", panel.scanCachePath]
        stdout: StdioCollector { onStreamFinished: panel.applyScan(this.text, true) }
    }
    function applyScan(text, fromCache) {
        var t = String(text || "")
        if (fromCache && !t.trim()) return   // cache empty → wait for live scan; live empty → fall through to empty-state
        if (fromCache && scanHasOriginalThumbs(t)) return
        if (fromCache && imagesLoaded) return
        if (!fromCache && t.trim() === _lastScan.trim() && imagesLoaded) { panel.warmVisible(); warmTimer.restart(); return }
        _lastScan = t
        var images = Model.loadRows(t)
        panel.imageArray   = images
        panel.selFilt      = Model.indexForSelectedImage(images, panel.currentImage)
        panel.imagesLoaded = images.length > 0; panel.scanDone = true
        Qt.callLater(function() {
            if (root.imagePickerVisible && panel.active) {
                panel.layoutSettled = true
                if (panel.imageArray.length > 0) view.focusStage()   // keep Esc-catcher focused when empty
                panel.fetchMeta()
                if (!fromCache) { panel.warmMeta(); panel.warmVisible(); warmTimer.restart() }
            }
        })
    }

    function buildScanCmd() {
        if (isThemeMode) {
            return ["bash", "-c", [
                "shopt -s nullglob nocaseglob;",
                "CACHE=$HOME/.cache/quickshell-theme-picker; mkdir -p \"$CACHE\";",
                "D=$HOME/.cache/quickshell-img-thumbs; mkdir -p \"$D\";",
                "HASHCACHE=$HOME/.cache/quickshell-img-thumb-hashes.tsv; touch \"$HASHCACHE\";",
                "hash_for() { local s=\"$1\" r m key h tmp; r=$(readlink -f \"$s\" 2>/dev/null || printf '%s' \"$s\"); m=$(stat -Lc '%s:%Y:%Z' \"$s\" 2>/dev/null) || return 1; key=\"$r|$m\"; h=$(awk -F '\\t' -v k=\"$key\" '$1 == k { v=$2 } END { print v }' \"$HASHCACHE\" 2>/dev/null); if [ -z \"$h\" ]; then h=$(sha256sum \"$s\" 2>/dev/null | cut -d' ' -f1); [ -n \"$h\" ] || return 1; tmp=\"$HASHCACHE.$$\"; { awk -F '\\t' -v k=\"$key\" '$1 != k' \"$HASHCACHE\" 2>/dev/null; printf '%s\\t%s\\n' \"$key\" \"$h\"; } > \"$tmp\" && mv -f \"$tmp\" \"$HASHCACHE\"; fi; printf '%s' \"$h\"; };",
                "thumb_for() { local s=\"$1\" k; k=$(hash_for \"$s\") || return 1; printf '%s/%s-512.jpg' \"$D\" \"$k\"; };",
                "for d in ~/.local/share/ryoku/themes/* ~/.config/ryoku/themes/*; do",
                "  [ -d \"$d\" ] || continue;",
                "  name=$(basename \"$d\");",
                "  prev=\"\";",
                "  for c in \"$d\"/preview.png \"$d\"/preview.jpg \"$d\"/preview.jpeg; do [ -f \"$c\" ] && { prev=\"$c\"; break; }; done;",
                "  if [ -z \"$prev\" ]; then bgs=(\"$d\"/backgrounds/*.jpg \"$d\"/backgrounds/*.jpeg \"$d\"/backgrounds/*.png \"$d\"/backgrounds/*.webp); prev=\"${bgs[0]}\"; fi;",
                "  [ -z \"$prev\" ] && continue;",
                "  ext=\"${prev##*.}\"; link=\"$CACHE/$name.$ext\";",
                "  [ -L \"$link\" ] || ln -sf \"$prev\" \"$link\";",
                "  thumb=$(thumb_for \"$link\") || continue;",
                "  printf '%s\\t%s\\t%s\\n' \"$link\" \"$thumb\" \"$d\";",
                "done | sort -u"
            ].join(" ")]
        } else {
            return ["bash", "-c", [
                "D=$HOME/.cache/quickshell-img-thumbs; mkdir -p \"$D\";",
                "HASHCACHE=$HOME/.cache/quickshell-img-thumb-hashes.tsv; touch \"$HASHCACHE\";",
                "hash_for() { local s=\"$1\" r m key h tmp; r=$(readlink -f \"$s\" 2>/dev/null || printf '%s' \"$s\"); m=$(stat -Lc '%s:%Y:%Z' \"$s\" 2>/dev/null) || return 1; key=\"$r|$m\"; h=$(awk -F '\\t' -v k=\"$key\" '$1 == k { v=$2 } END { print v }' \"$HASHCACHE\" 2>/dev/null); if [ -z \"$h\" ]; then h=$(sha256sum \"$s\" 2>/dev/null | cut -d' ' -f1); [ -n \"$h\" ] || return 1; tmp=\"$HASHCACHE.$$\"; { awk -F '\\t' -v k=\"$key\" '$1 != k' \"$HASHCACHE\" 2>/dev/null; printf '%s\\t%s\\n' \"$key\" \"$h\"; } > \"$tmp\" && mv -f \"$tmp\" \"$HASHCACHE\"; fi; printf '%s' \"$h\"; };",
                "thumb_for() { local s=\"$1\" k; k=$(hash_for \"$s\") || return 1; printf '%s/%s-512.jpg' \"$D\" \"$k\"; };",
                "find -L " + wallpaperFindRoots() + " -maxdepth 1 -type f " +
                "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp' -o -iname '*.gif' \\) " +
                "2>/dev/null | sort | while IFS= read -r f; do thumb=$(thumb_for \"$f\") || continue; printf '%s\\t%s\\n' \"$f\" \"$thumb\"; done"
            ].join(" ")]
        }
    }

    Process { id: applyThemeProc; command: [] }
    Process { id: applyBgProc;    command: [] }

    function applySelected() {
        if (!imagesLoaded || filtered.length === 0) return
        if (selFilt < 0 || selFilt >= filtered.length) return
        var path = filtered[selFilt].filePath; if (!path) return
        if (isThemeMode) {
            var name = Model.nameForPath(path)
            applyThemeProc.command = ["env", "RYOKU_PATH=" + root.omarchyInstallRoot, "true", name]
            applyThemeProc.running = false; applyThemeProc.running = true
        } else {
            applyBgProc.command = ["ryogami", "wallpaper", "set", path]
            applyBgProc.running = false; applyBgProc.running = true
        }
        root.imagePickerVisible = false
    }

    function moveSel(delta) {
        if (filtered.length === 0) return
        selFilt = Math.max(0, Math.min(filtered.length - 1, selFilt + delta))
    }

    // the currently focused entry (or null)
    readonly property var sel: (filtered.length > 0 && selFilt >= 0 && selFilt < filtered.length)
                               ? filtered[selFilt] : null

    function shq(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'" }
    function wallpaperFindRoots() {
        var paths = root.wallpaperSourcePaths || []
        var args = []
        for (var i = 0; i < paths.length; i++)
            if (paths[i]) args.push(panel.shq(paths[i]))
        return args.join(" ")
    }
    function paletteReadCmd(pathExpr) {
        return "awk -F'\"' 'function valid(v){ return v ~ /^#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$/ } { k=$1; gsub(/[[:space:]=]/,\"\",k); if (valid($2)) c[k]=$2 } END { split(\"color1 red color2 green color3 yellow color4 blue color5 magenta color6 cyan\", a, \" \"); for (i=1; i<=6; i++) { p=a[i*2-1]; q=a[i*2]; v=c[p]; if (v == \"\") v=c[q]; if (v != \"\") { if (out != \"\") out=out \",\"; out=out v } } print out }' " + pathExpr + " 2>/dev/null"
    }

    // ── pre-warm: visible entries first, the rest after the open settles. All
    // image pickers share the 512px cache family; Tanzaku lets sourceSize decode
    // the shared thumbnails down to its strip dimensions.
    Process {
        id: priorityWarmProc
        command: []
        stdout: SplitParser {
            onRead: function(line) { panel.noteThumbReady(line) }
        }
    }
    Process {
        id: warmProc
        command: []
        stdout: SplitParser {
            onRead: function(line) { panel.noteThumbReady(line) }
        }
    }
    Timer { id: warmTimer; interval: 450; onTriggered: panel.warmAll() }
    function noteThumbReady(line) {
        var path = String(line || "").trim()
        if (!path) return
        panel.readyThumbUrl = "file://" + path
        panel.thumbEpoch++
    }
    function warmCommand(srcs, niceLevel) {
        var nice = niceLevel === 10 ? 10 : 19
        return ["bash", "-c",
            "D=$HOME/.cache/quickshell-img-thumbs; mkdir -p \"$D\"; command -v magick >/dev/null 2>&1 || exit 0; " +
            "HASHCACHE=$HOME/.cache/quickshell-img-thumb-hashes.tsv; touch \"$HASHCACHE\"; " +
            "tmp=$(mktemp); trap 'rm -f \"$tmp\"' EXIT; " +
            "hash_for() { local s=\"$1\" r m key h t; r=$(readlink -f \"$s\" 2>/dev/null || printf '%s' \"$s\"); m=$(stat -Lc '%s:%Y:%Z' \"$s\" 2>/dev/null) || return 1; key=\"$r|$m\"; h=$(awk -F '\\t' -v k=\"$key\" '$1 == k { v=$2 } END { print v }' \"$HASHCACHE\" 2>/dev/null); if [ -z \"$h\" ]; then h=$(sha256sum \"$s\" 2>/dev/null | cut -d' ' -f1); [ -n \"$h\" ] || return 1; t=\"$HASHCACHE.$$\"; { awk -F '\\t' -v k=\"$key\" '$1 != k' \"$HASHCACHE\" 2>/dev/null; printf '%s\\t%s\\n' \"$key\" \"$h\"; } > \"$t\" && mv -f \"$t\" \"$HASHCACHE\"; fi; printf '%s' \"$h\"; }; " +
            "for s in \"$@\"; do k=$(hash_for \"$s\") || continue; " +
            "o=\"$D/$k-512.jpg\"; [ -s \"$o\" ] && continue; printf '%s\\n%s\\n' \"$s\" \"$o\" >> \"$tmp\"; done; " +
            "if [ -s \"$tmp\" ]; then nice -n " + nice + " xargs -d '\\n' -P 3 -n 2 sh -c 'magick -define jpeg:size=1024x1024 \"$0[0]\" -auto-orient -strip -thumbnail 512x512^ -quality 82 \"$1\" >/dev/null 2>&1 || true; [ -s \"$1\" ] && printf \"%s\\n\" \"$1\"; exit 0' < \"$tmp\"; fi",
            "warm"].concat(srcs)
    }
    function startWarm(proc, srcs, niceLevel) {
        if (srcs.length === 0) return
        proc.command = panel.warmCommand(srcs, niceLevel)
        proc.running = false; proc.running = true
    }
    function visibleSourcePaths() {
        var srcs = [], seen = {}
        for (var distance = 0; distance <= maxVisible; distance++) {
            var indices = distance === 0 ? [selFilt] : [selFilt - distance, selFilt + distance]
            for (var j = 0; j < indices.length; j++) {
                var i = indices[j]
                if (i < 0 || i >= filtered.length) continue
                var p = filtered[i].filePath
                if (p && !seen[p]) { seen[p] = true; srcs.push(p) }
            }
        }
        return srcs
    }
    function backgroundSourcePaths() {
        var visible = {}, priority = visibleSourcePaths(), srcs = [], seen = {}
        for (var i = 0; i < priority.length; i++) visible[priority[i]] = true
        for (var j = 0; j < imageArray.length; j++) {
            var p = imageArray[j].filePath
            if (p && !visible[p] && !seen[p]) { seen[p] = true; srcs.push(p) }
        }
        return srcs
    }
    function warmVisible() { panel.startWarm(priorityWarmProc, panel.visibleSourcePaths(), 10) }
    function warmAll() { panel.startWarm(warmProc, panel.backgroundSourcePaths(), 19) }

    // ── lazy meta (author/repo/palette) for the FOCUSED theme only, cached by
    // dir - keeps the scan instant; enrichment lands ~110ms after the focus settles
    property var metaCache: ({})
    property string _metaDir: ""
    readonly property var selMeta: (sel && sel.dir && metaCache[sel.dir]) ? metaCache[sel.dir] : null

    Timer { id: metaTimer; interval: 60; onTriggered: panel.fetchMeta() }
    onSelChanged: if (isThemeMode && sel && sel.dir && !metaCache[sel.dir]) metaTimer.restart()

    function fetchMeta() {
        if (!isThemeMode || !sel || !sel.dir || metaCache[sel.dir]) return
        panel._metaDir = sel.dir
        metaProc.command = ["bash", "-c",
            "d=" + shq(sel.dir) + "; repo=''; author='';" +
            "if [ -f \"$d/.git/config\" ]; then " +
            "  repo=$(sed -nE 's#^[[:space:]]*url = (.*)$#\\1#p' \"$d/.git/config\" | head -1);" +
            "  author=$(printf '%s' \"$repo\" | sed -nE 's#.*github\\.com[:/]+([^/]+)/.*#\\1#p');" +
            "fi;" +
            "pal=$(" + paletteReadCmd("\"$d/colors.toml\"") + ");" +
            "printf '%s\\t%s\\t%s\\n' \"$author\" \"$repo\" \"$pal\""]
        metaProc.running = false; metaProc.running = true
    }
    Process {
        id: metaProc
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = String(this.text || "").replace(/\n+$/, "").split("\t")
                var m = panel.metaCache
                m[panel._metaDir] = { author: parts[0] || "", repo: parts[1] || "", palette: parts[2] || "" }
                panel.metaCache = m   // reassign → bindings refresh
            }
        }
    }

    function openRepo() {
        if (!selMeta || !selMeta.repo) return
        var url = String(selMeta.repo)
            .replace(/^git@github\.com:/, "https://github.com/")
            .replace(/\.git$/, "")
        Spawn.runApp(["xdg-open", url], { label: "theme-source" })
    }

    // ── bulk meta pre-warm: author/repo/palette for ALL themes in one background
    // pass → info is instant for every theme (no lazy timing fragility) ──
    Process {
        id: metaWarmProc
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = String(this.text || "").split("\n")
                var m = panel.metaCache
                for (var i = 0; i < lines.length; i++) {
                    if (!lines[i]) continue
                    var p = lines[i].split("\t")
                    if (p[0] && !m[p[0]]) m[p[0]] = { author: p[1] || "", repo: p[2] || "", palette: p[3] || "" }
                }
                panel.metaCache = m
            }
        }
    }
    function warmMeta() {
        if (!isThemeMode) return
        var dirs = []
        for (var i = 0; i < imageArray.length; i++)
            if (imageArray[i].dir) dirs.push(imageArray[i].dir)
        if (dirs.length === 0) return
        metaWarmProc.command = ["bash", "-c",
            "for d in \"$@\"; do repo=''; author='';" +
            "if [ -f \"$d/.git/config\" ]; then repo=$(sed -nE 's#^[[:space:]]*url = (.*)$#\\1#p' \"$d/.git/config\" | head -1);" +
            "author=$(printf '%s' \"$repo\" | sed -nE 's#.*github\\.com[:/]+([^/]+)/.*#\\1#p'); fi;" +
            "pal=$(" + paletteReadCmd("\"$d/colors.toml\"") + ");" +
            "printf '%s\\t%s\\t%s\\t%s\\n' \"$d\" \"$author\" \"$repo\" \"$pal\"; done",
            "warm"].concat(dirs)
        metaWarmProc.running = false; metaWarmProc.running = true
    }

    // ── geometry ──
    readonly property int  focusedW:   460
    readonly property int  focusedH:   259      // 16:9
    readonly property int  peekW:      104      // ONLY the immediate neighbour - preview peek
    readonly property int  stripW:     24       // every other strip - thin tanzaku (unchanged)
    readonly property int  gap:        8
    readonly property int  maxVisible: 5

    // only the first neighbour on each side widens for a preview; the rest stay thin
    function stripWidthFor(d) {
        if (d <= 0) return focusedW
        if (d === 1) return peekW
        return stripW
    }

    // ── colors (bar materials) ──
    readonly property color scrim:   Qt.rgba(root.paper.r, root.paper.g, root.paper.b, 0.8)
    readonly property color frameBg: root.frameWeak
    readonly property color uiDim:   Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.45)

    // the drawing, in an Item of its own so it loads offscreen
    ImageCarouselPanelView {
        id: view
        anchors.fill: parent
        picker: panel
        root: panel.root
    }
}
