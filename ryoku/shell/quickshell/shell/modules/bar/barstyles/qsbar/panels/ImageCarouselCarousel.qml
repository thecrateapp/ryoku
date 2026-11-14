import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "ImagePickerModel.js" as Model
import Ryoku.Ui.Singletons

// Carousel variant of the theme/wallpaper picker - skewed slices, one expands in
// the centre. Crisp Shape/CurveRenderer slices, red/accent via root.seal, shared
// thumbnail cache (no wallpaper stutter), and NO scrim (floats over the desktop).
// Active only while root.pickerStyle === "carousel".
PanelWindow {
    id: panel
    required property var root

    screen: root.activePopupScreen

    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "ryoku-image-carousel-cr"
    WlrLayershell.keyboardFocus: panel.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property bool active: root.pickerStyle === "carousel"
    readonly property bool isThemeMode: root.imagePickerMode === "theme"
    readonly property bool ready: root.imagePickerVisible && active && imagesLoaded && layoutSettled

    property bool imagesLoaded:  false
    property bool layoutSettled: false
    property bool scanDone:      false   // a scan finished (distinguishes "loading" from "nothing found")
    property var  imageArray:    []
    property int  selectedIndex: 0
    property string filterText:  ""
    property string currentImage: ""
    property string loadedMode:   ""
    property int thumbEpoch:      0
    property string readyThumbUrl: ""

    property var    wallpaperImageArray: []
    property int    wallpaperSelectedIndex: 0
    property string wallpaperCurrentImage: ""
    property string wallpaperLastScan: ""
    property bool   wallpaperImagesLoaded: false
    property bool   wallpaperScanDone: false

    property var    themeImageArray: []
    property int    themeSelectedIndex: 0
    property string themeCurrentImage: ""
    property string themeLastScan: ""
    property bool   themeImagesLoaded: false
    property bool   themeScanDone: false

    visible: root.imagePickerVisible && active

    // ── open / style gating ──
    function modeKey() { return root.imagePickerMode === "theme" ? "theme" : "wallpaper" }
    function scanCachePathFor(mode) {
        return Quickshell.env("HOME") + "/.cache/quickshell-scan-" + (mode === "theme" ? "theme" : "wallpaper")
    }
    function saveModeState() {
        if (panel.loadedMode === "theme") {
            panel.themeImageArray = panel.imageArray
            panel.themeSelectedIndex = panel.selectedIndex
            panel.themeCurrentImage = panel.currentImage
            panel.themeLastScan = panel._lastScan
            panel.themeImagesLoaded = panel.imagesLoaded
            panel.themeScanDone = panel.scanDone
        } else if (panel.loadedMode === "wallpaper") {
            panel.wallpaperImageArray = panel.imageArray
            panel.wallpaperSelectedIndex = panel.selectedIndex
            panel.wallpaperCurrentImage = panel.currentImage
            panel.wallpaperLastScan = panel._lastScan
            panel.wallpaperImagesLoaded = panel.imagesLoaded
            panel.wallpaperScanDone = panel.scanDone
        }
    }
    function restoreModeState(mode) {
        if (mode === "theme") {
            panel.imageArray = panel.themeImageArray || []
            panel.selectedIndex = Math.max(0, Math.min(panel.themeSelectedIndex, Math.max(0, panel.imageArray.length - 1)))
            panel.currentImage = panel.themeCurrentImage
            panel._lastScan = panel.themeLastScan
            panel.imagesLoaded = panel.themeImagesLoaded && panel.imageArray.length > 0
            panel.scanDone = panel.themeScanDone
        } else {
            panel.imageArray = panel.wallpaperImageArray || []
            panel.selectedIndex = Math.max(0, Math.min(panel.wallpaperSelectedIndex, Math.max(0, panel.imageArray.length - 1)))
            panel.currentImage = panel.wallpaperCurrentImage
            panel._lastScan = panel.wallpaperLastScan
            panel.imagesLoaded = panel.wallpaperImagesLoaded && panel.imageArray.length > 0
            panel.scanDone = panel.wallpaperScanDone
        }
        panel.loadedMode = mode
    }
    function startCurrentForMode(mode) {
        currentProc.requestMode = mode
        currentProc.running = false
        currentProc.running = true
    }
    function syncOpen() {
        var mode = panel.modeKey()
        if (root.imagePickerVisible && active) {
            if (panel.loadedMode !== mode) {
                panel.saveModeState()
                panel.restoreModeState(mode)
            }
            panel.layoutSettled = false
            panel.filterText    = ""
            if (!imagesLoaded) {
                panel.imageArray    = []
                panel.selectedIndex = 0
            } else if (panel.imageArray.length > 0) {
                Qt.callLater(function() {
                    if (root.imagePickerVisible && panel.active && panel.imagesLoaded) {
                        panel.layoutSettled = true
                        view.focusStage()
                    }
                })
            }
            panel.startCurrentForMode(mode)
        } else {
            panel.saveModeState()
            panel.scanDone = false
            panel.layoutSettled = false
        }
    }
    Connections {
        target: root
        function onImagePickerVisibleChanged() { panel.syncOpen() }
        function onImagePickerModeChanged()    { panel.syncOpen() }
        function onPickerStyleChanged()         { panel.syncOpen() }
    }
    Component.onCompleted: panel.syncOpen()

    // step 1: current image
    Process {
        id: currentProc
        property string requestMode: "wallpaper"
        command: requestMode === "theme"
            ? ["bash", "-c",
               "CACHE=$HOME/.cache/quickshell-theme-picker; " +
               "name=$(cat " + panel.shq(root.themeNamePath) + " 2>/dev/null || true); " +
               "for ext in png jpg jpeg webp; do f=\"$CACHE/$name.$ext\"; [ -L \"$f\" ] && echo \"$f\" && exit 0; done; echo ''"]
            : ["bash", "-c", "readlink -f " + panel.shq(root.currentBackgroundPath) + " 2>/dev/null || true"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var mode = currentProc.requestMode
                if (mode !== panel.modeKey() || !root.imagePickerVisible || !panel.active) return
                panel.currentImage = this.text.trim()
                // instant: paint from the cached scan while we refresh live
                cacheProc.requestMode = mode
                cacheProc.command = ["cat", panel.scanCachePathFor(mode)]
                cacheProc.running = false; cacheProc.running = true
                // live refresh - tee the output into the cache for next time
                var cmd = panel.buildScanCmd(mode)
                cmd[2] = cmd[2] + " | tee " + panel.shq(panel.scanCachePathFor(mode))
                scanProc.requestMode = mode
                scanProc.command = cmd
                scanProc.running = false; scanProc.running = true
            }
        }
    }

    // step 2: scan images (fast glob, same as the other pickers)
    Process {
        id: scanProc
        property string requestMode: "wallpaper"
        command: []
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: panel.applyScan(text, false, scanProc.requestMode)
        }
    }

    function buildScanCmd(mode) {
        if (mode === "theme") {
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
        if (!imagesLoaded || imageArray.length === 0) return
        var path = imageArray[selectedIndex].filePath; if (!path) return
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

    function selectAdjacent(dir) {
        var count = imageArray.length; if (count === 0) return
        var idx = selectedIndex
        for (var i = 0; i < count; i++) {
            idx = (idx + dir + count) % count
            if (Model.itemMatches(imageArray, idx, filterText)) { selectedIndex = idx; return }
        }
    }

    function currentLabel() {
        if (imageArray.length === 0 || !Model.itemMatches(imageArray, selectedIndex, filterText)) return filterText ? I18n.tr("No matches") : ""
        return Model.labelForPath(imageArray[selectedIndex].filePath)
    }

    function filteredPos(idx)  { return Model.filteredPosition(imageArray, idx, filterText) }
    function selectedFiltPos() { return Model.selectedFilteredPosition(imageArray, selectedIndex, filterText) }
    function itemMatches(idx)  { return Model.itemMatches(imageArray, idx, filterText) }

    // when typing a filter, jump the focused (main) card to the first match
    onFilterTextChanged: {
        var n = Model.nextSelectedIndexForFilter(imageArray, selectedIndex, filterText)
        if (n >= 0) selectedIndex = n
    }

    function shq(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'" }
    function wallpaperFindRoots() {
        var paths = root.wallpaperSourcePaths || []
        var args = []
        for (var i = 0; i < paths.length; i++)
            if (paths[i]) args.push(panel.shq(paths[i]))
        return args.join(" ")
    }

    // ── scan-result cache → instant (re)open: paint last result immediately,
    // refresh live in the background, only reassign if the list actually changed ──
    property string _lastScan: ""
    function thumbUrlFor(img) {
        if (!img || !img.thumbnailPath || img.thumbnailPath === img.filePath) return ""
        return "file://" + img.thumbnailPath
    }
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
    function applyScan(text, fromCache, mode) {
        mode = mode || panel.modeKey()
        if (mode !== panel.modeKey() || panel.loadedMode !== mode || !root.imagePickerVisible || !panel.active) return
        var t = String(text || "")
        if (fromCache && !t.trim()) return   // cache empty → wait for live scan; live empty → fall through to empty-state
        if (fromCache && panel.scanHasOriginalThumbs(t)) return
        if (fromCache && panel.imagesLoaded) return          // live scan already won
        if (!fromCache && t.trim() === panel._lastScan.trim() && panel.imagesLoaded) {
            panel.warmVisible()
            warmTimer.restart()
            return  // unchanged → no flicker
        }
        panel._lastScan = t
        var images = Model.loadRows(t)
        panel.imageArray    = images
        panel.selectedIndex = Model.indexForSelectedImage(images, panel.currentImage)
        panel.imagesLoaded  = images.length > 0; panel.scanDone = true
        panel.saveModeState()
        Qt.callLater(function() {
            if (root.imagePickerVisible && panel.active && panel.modeKey() === mode && panel.loadedMode === mode) {
                panel.layoutSettled = true
                if (panel.imageArray.length > 0) view.focusStage()   // keep Esc-catcher focused when empty
                if (!fromCache) { panel.warmVisible(); warmTimer.restart() }
            }
        })
    }
    Process {
        id: cacheProc
        property string requestMode: "wallpaper"
        command: []
        stdout: StdioCollector { onStreamFinished: panel.applyScan(this.text, true, cacheProc.requestMode) }
    }

    // ── pre-warm: visible entries first, the rest after the open settles ──
    Process {
        id: priorityWarmProc
        property string requestMode: "wallpaper"
        command: []
        stdout: SplitParser {
            onRead: function(line) { panel.applyThumbRows(line, priorityWarmProc.requestMode) }
        }
    }
    Process {
        id: warmProc
        property string requestMode: "wallpaper"
        command: []
        stdout: SplitParser {
            onRead: function(line) { panel.applyThumbRows(line, warmProc.requestMode) }
        }
    }
    Process {
        id: cacheWriteProc
        property string payload: ""
        command: []
        stdinEnabled: false
        onStarted: {
            write(payload)
            stdinEnabled = false
        }
    }
    Timer { id: warmTimer; interval: 450; onTriggered: panel.warmAll() }
    function visibleSourcePaths() {
        var srcs = [], seen = {}, candidates = []
        var selectedPos = panel.selectedFiltPos()
        for (var i = 0; i < imageArray.length; i++) {
            if (!panel.itemMatches(i)) continue
            var rel = panel.filteredPos(i) - selectedPos
            if (Math.abs(rel) > 14) continue
            var p = imageArray[i].filePath
            if (p && !seen[p]) { seen[p] = true; candidates.push({ path: p, rel: rel }) }
        }
        candidates.sort(function(a, b) {
            var distance = Math.abs(a.rel) - Math.abs(b.rel)
            return distance !== 0 ? distance : a.rel - b.rel
        })
        for (var j = 0; j < candidates.length; j++) srcs.push(candidates[j].path)
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
    function serializedRows() {
        var rows = []
        for (var i = 0; i < imageArray.length; i++) {
            var img = imageArray[i]
            if (!img || !img.filePath) continue
            var row = img.filePath + "\t" + (img.thumbnailPath || img.filePath)
            if (img.dir) row += "\t" + img.dir
            rows.push(row)
        }
        return rows.length > 0 ? rows.join("\n") + "\n" : ""
    }
    function persistScanCache(mode) {
        var payload = panel.serializedRows()
        if (!payload) return
        cacheWriteProc.running = false
        cacheWriteProc.payload = payload
        cacheWriteProc.command = ["bash", "-c",
            "p=$1; d=$(dirname \"$p\"); mkdir -p \"$d\"; tmp=$(mktemp \"$d/.${p##*/}.XXXXXX\") || exit 1; cat > \"$tmp\" && mv -f \"$tmp\" \"$p\"",
            "cache-write", panel.scanCachePathFor(mode)]
        cacheWriteProc.stdinEnabled = true
        cacheWriteProc.running = true
    }
    function applyThumbRows(text, mode) {
        mode = mode || panel.modeKey()
        if (mode !== panel.modeKey() || panel.loadedMode !== mode) return
        var t = String(text || "").trim()
        if (!t) return
        var rows = t.split("\n")
        var thumbs = {}
        var readyPath = ""
        for (var r = 0; r < rows.length; r++) {
            var cols = rows[r].split("\t")
            if (cols.length >= 2 && cols[0] && cols[1]) {
                thumbs[cols[0]] = cols[1]
                readyPath = cols[1]
            }
        }
        var hasGeneratedThumbs = false
        for (var key in thumbs) { hasGeneratedThumbs = true; break }
        var changed = false
        var next = []
        for (var i = 0; i < imageArray.length; i++) {
            var img = imageArray[i]
            var thumb = img && thumbs[img.filePath] ? thumbs[img.filePath] : ""
            if (thumb && thumb !== img.thumbnailPath) {
                next.push({
                    filePath: img.filePath,
                    fileName: img.fileName,
                    thumbnailPath: thumb,
                    dir: img.dir || ""
                })
                changed = true
            } else {
                next.push(img)
            }
        }
        if (changed) {
            panel.imageArray = next
            panel._lastScan = panel.serializedRows()
            panel.saveModeState()
            panel.persistScanCache(mode)
        }
        if (hasGeneratedThumbs) {
            panel.readyThumbUrl = "file://" + readyPath
            panel.thumbEpoch++
        }
    }
    function startWarm(proc, srcs, niceLevel) {
        if (srcs.length === 0) return
        var nice = niceLevel === 10 ? 10 : 19
        proc.requestMode = panel.modeKey()
        proc.command = ["bash", "-c",
            "D=$HOME/.cache/quickshell-img-thumbs; mkdir -p \"$D\"; " +
            "command -v magick >/dev/null 2>&1 || exit 0; " +
            "HASHCACHE=$HOME/.cache/quickshell-img-thumb-hashes.tsv; touch \"$HASHCACHE\"; " +
            "tmp=$(mktemp); trap 'rm -f \"$tmp\"' EXIT; " +
            "hash_for() { local s=\"$1\" r m key h t; r=$(readlink -f \"$s\" 2>/dev/null || printf '%s' \"$s\"); m=$(stat -Lc '%s:%Y:%Z' \"$s\" 2>/dev/null) || return 1; key=\"$r|$m\"; h=$(awk -F '\\t' -v k=\"$key\" '$1 == k { v=$2 } END { print v }' \"$HASHCACHE\" 2>/dev/null); if [ -z \"$h\" ]; then h=$(sha256sum \"$s\" 2>/dev/null | cut -d' ' -f1); [ -n \"$h\" ] || return 1; t=\"$HASHCACHE.$$\"; { awk -F '\\t' -v k=\"$key\" '$1 != k' \"$HASHCACHE\" 2>/dev/null; printf '%s\\t%s\\n' \"$key\" \"$h\"; } > \"$t\" && mv -f \"$t\" \"$HASHCACHE\"; fi; printf '%s' \"$h\"; }; " +
            "for s in \"$@\"; do k=$(hash_for \"$s\") || continue; o=\"$D/$k-512.jpg\"; [ -s \"$o\" ] || printf '%s\\n%s\\n' \"$s\" \"$o\" >> \"$tmp\"; done; " +
            "if [ -s \"$tmp\" ]; then nice -n " + nice + " xargs -d '\\n' -P 3 -n 2 sh -c 'magick -define jpeg:size=1024x1024 \"$0[0]\" -auto-orient -strip -thumbnail 512x512^ -quality 82 \"$1\" >/dev/null 2>&1 || true; [ -s \"$1\" ] && printf \"%s\\t%s\\n\" \"$0\" \"$1\"; exit 0' < \"$tmp\"; fi",
            "warm"].concat(srcs)
        proc.running = false; proc.running = true
    }
    function warmVisible() { panel.startWarm(priorityWarmProc, panel.visibleSourcePaths(), 10) }
    function warmAll() { panel.startWarm(warmProc, panel.backgroundSourcePaths(), 19) }

    // ── Carousel geometry ──
    readonly property int expandedW: 768
    readonly property int expandedH: 432
    readonly property int sliceW:    108
    readonly property int sliceH:    390
    readonly property int sliceGap:  -30
    readonly property int skew:       28

    // ── colors (red/accent via root.seal) ──
    readonly property color selBorder:   root.seal
    readonly property color unselBorder: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.22)
    readonly property color dimColor:    root.paper
    readonly property color footerText:  panel.readableAccent(root.seal)
    readonly property color footerDim:   Qt.rgba(footerText.r, footerText.g, footerText.b, 0.68)

    function luma(c) { return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b }
    function readableAccent(c) {
        var y = luma(c)
        if (y < 0.30) return Qt.lighter(c, 2.05)
        if (y < 0.42) return Qt.lighter(c, 1.55)
        if (y > 0.82) return Qt.darker(c, 1.45)
        return c
    }

    // the drawing, in an Item of its own so it loads offscreen
    ImageCarouselCarouselView {
        id: view
        anchors.fill: parent
        picker: panel
        root: panel.root
    }
}
