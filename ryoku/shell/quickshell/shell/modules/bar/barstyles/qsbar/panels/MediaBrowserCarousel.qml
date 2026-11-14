import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "ImagePickerModel.js" as Model
import Ryoku.Ui.Singletons

// Carousel variant of the screenshot/video browser - skewed slices, one expands
// in the centre (16:9, perfect for landscape media). Crisp Shape slices, shared
// thumbnail + scan cache, delete/copy, no scrim.
// Active only while root.pickerStyle === "carousel".
PanelWindow {
    id: panel
    required property var root

    screen: root.activePopupScreen

    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "ryoku-media-carousel"
    WlrLayershell.keyboardFocus: panel.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property bool active: root.pickerStyle === "carousel"
    readonly property bool isVideos: root.mediaBrowserMode === "videos"
    readonly property bool ready: root.mediaBrowserVisible && active && loaded && layoutSettled

    property bool loaded:        false
    property bool layoutSettled: false
    property bool closing:       false
    property int  thumbEpoch:    0
    property var  imageArray:    []
    property int  selectedIndex: 0
    property string filterText:  ""

    visible: root.mediaBrowserVisible && active

    // ── open / style gating ──
    function releaseClosedState() {
        panel.closing = true
        cacheProc.running = false
        scanProc.running = false
        warmTimer.stop()
        warmProc.running = false
        panel.loaded        = false
        panel.layoutSettled = false
        panel.filterText    = ""
        panel.imageArray    = []
        panel.selectedIndex = 0
        panel.confirmDelete = false
    }
    function syncOpen() {
        if (root.mediaBrowserVisible && active) {
            panel.closing = false
            if (!loaded) {
                panel.layoutSettled = false
                panel.filterText    = ""
                panel.imageArray    = []
                panel.selectedIndex = 0
                panel.runScan()
            }
        } else {
            panel.releaseClosedState()
        }
    }
    Connections {
        target: root
        function onMediaBrowserVisibleChanged() { panel.syncOpen() }
        function onPickerStyleChanged()          { panel.syncOpen() }
    }
    Component.onCompleted: panel.syncOpen()

    function buildScanCmd() {
        if (isVideos) {
            return ["bash", "-c",
                "D=\"${RYOKU_SCREENRECORD_DIR:-${XDG_VIDEOS_DIR:-$HOME/Videos}/Recordings}\"; " +
                "find \"$D\" -maxdepth 1 -type f " +
                "\\( -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.webm' -o -iname '*.mov' -o -iname '*.avi' -o -iname '*.m4v' \\) " +
                "-printf '%T@\\t%p\\n' 2>/dev/null | sort -rn | head -100 | cut -f2- | " +
                "while IFS= read -r f; do b=$(basename \"$f\"); printf '%s\\t%s/%s-512.jpg\\n' \"$f\" \"$HOME/.cache/quickshell-media-thumbs\" \"${b%.*}\"; done"]
        } else {
            return ["bash", "-c",
                "D=\"${RYOKU_SCREENSHOT_DIR:-${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots}\"; " +
                "find \"$D\" -maxdepth 1 -type f -iname '*.png' " +
                "-printf '%T@\\t%p\\n' 2>/dev/null | sort -rn | head -100 | cut -f2- | " +
                "while IFS= read -r f; do k=$(printf '%s' \"$f\" | md5sum | cut -d' ' -f1); m=$(stat -c %Y \"$f\" 2>/dev/null); printf '%s\\t%s/%s-%s-512.jpg\\n' \"$f\" \"$HOME/.cache/quickshell-img-thumbs\" \"$k\" \"$m\"; done"]
        }
    }

    function shq(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'" }
    function cancellableCommand(body, argv0, args) {
        return ["bash", "-c",
            "body=$1; shift; setsid bash -c \"$body\" worker \"$@\" & worker=$!; " +
            "cleanup() { pkill -TERM -s \"$worker\" 2>/dev/null || true; sleep 0.2; pkill -KILL -s \"$worker\" 2>/dev/null || true; }; " +
            "trap 'cleanup; exit 143' TERM INT; wait \"$worker\"",
            argv0 || "manager", body].concat(args || [])
    }

    // ── scan-result cache → instant (re)open (shared with the other media browsers) ──
    readonly property string scanCachePath: Quickshell.env("HOME") + "/.cache/quickshell-scan-" + (isVideos ? "videos" : "screenshots")
    property string _lastScan: ""
    function liveScanCmd() { var c = panel.buildScanCmd(); c[2] = c[2] + " | tee " + panel.shq(panel.scanCachePath); return c }
    function runScan() {
        cacheProc.running = false; cacheProc.running = true
        scanProc.command = panel.liveScanCmd(); scanProc.running = false; scanProc.running = true
    }
    Process {
        id: cacheProc
        command: ["cat", panel.scanCachePath]
        stdout: StdioCollector { onStreamFinished: panel.applyScan(this.text, true) }
    }
    function applyScan(text, fromCache) {
        if (!root.mediaBrowserVisible || !panel.active) return
        var t = String(text || "")
        if (fromCache && (!t.trim() || loaded)) return
        if (!fromCache && t.trim() === _lastScan.trim() && loaded) {
            warmTimer.restart()
            return
        }
        _lastScan = t
        var rows = Model.loadRows(t)
        panel.imageArray    = rows
        panel.selectedIndex = 0
        panel.loaded        = rows.length > 0
        Qt.callLater(function() {
            if (root.mediaBrowserVisible && panel.active) {
                panel.layoutSettled = true
                if (panel.imageArray.length > 0) view.focusStage()   // keep Esc-catcher focused when empty
                if (!fromCache) warmTimer.restart()
            }
        })
    }
    Process {
        id: scanProc
        command: []
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: panel.applyScan(text, false)
        }
    }

    // ── background pre-warm (nice; after open settles) ──
    Process {
        id: warmProc
        command: []
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: if (this.text.trim() && root.mediaBrowserVisible && panel.active)
                panel.thumbEpoch++
        }
    }
    Timer { id: warmTimer; interval: 450; onTriggered: panel.warmAll() }
    function warmAll() {
        var srcs = []
        for (var i = 0; i < imageArray.length; i++)
            if (imageArray[i].filePath) srcs.push(imageArray[i].filePath)
        if (srcs.length === 0) return
        if (panel.isVideos) {
            warmProc.command = panel.cancellableCommand(
                "d=$HOME/.cache/quickshell-media-thumbs; mkdir -p \"$d\"; command -v ffmpegthumbnailer >/dev/null 2>&1 || exit 0; " +
                "tmp=$(mktemp); trap 'rm -f \"$tmp\"' EXIT; " +
                "for s in \"$@\"; do b=$(basename \"$s\"); o=\"$d/${b%.*}-512.jpg\"; [ -s \"$o\" ] && continue; printf '%s\\n%s\\n' \"$s\" \"$o\" >> \"$tmp\"; done; " +
                "if [ -s \"$tmp\" ]; then nice -n 19 xargs -r -d '\\n' -P 2 -n 2 sh -c 'ffmpegthumbnailer -i \"$0\" -o \"$1\" -s 910 -q 6 >/dev/null 2>&1 || true' < \"$tmp\"; made=0; while IFS= read -r _src && IFS= read -r out; do [ -s \"$out\" ] && { made=1; break; }; done < \"$tmp\"; [ \"$made\" -eq 1 ] && echo changed; fi",
                "warm", srcs)
        } else {
            warmProc.command = panel.cancellableCommand(
                "D=$HOME/.cache/quickshell-img-thumbs; mkdir -p \"$D\"; command -v magick >/dev/null 2>&1 || exit 0; " +
                "tmp=$(mktemp); trap 'rm -f \"$tmp\"' EXIT; " +
                "for s in \"$@\"; do k=$(printf '%s' \"$s\" | md5sum | cut -d' ' -f1); m=$(stat -c %Y \"$s\" 2>/dev/null); " +
                "o=\"$D/$k-$m-512.jpg\"; [ -s \"$o\" ] && continue; printf '%s\\n%s\\n' \"$s\" \"$o\" >> \"$tmp\"; done; " +
                "if [ -s \"$tmp\" ]; then nice -n 19 xargs -r -d '\\n' -P 3 -n 2 sh -c 'magick \"$0\" -auto-orient -strip -thumbnail 512x512^ -quality 82 \"$1\" >/dev/null 2>&1' < \"$tmp\"; made=0; while IFS= read -r _src && IFS= read -r out; do [ -s \"$out\" ] && { made=1; break; }; done < \"$tmp\"; [ \"$made\" -eq 1 ] && echo changed; fi",
                "warm", srcs)
        }
        warmProc.running = false; warmProc.running = true
    }

    function openSelected() {
        if (!loaded || imageArray.length === 0) return
        var path = imageArray[selectedIndex] ? imageArray[selectedIndex].filePath : ""; if (!path) return
        Spawn.runApp(["xdg-open", path], { label: "media" })
        root.mediaBrowserVisible = false
    }

    function selectAdjacent(dir) {
        var count = imageArray.length; if (count === 0) return
        var idx = selectedIndex
        for (var i = 0; i < count; i++) {
            idx = (idx + dir + count) % count
            if (Model.itemMatches(imageArray, idx, filterText)) { selectedIndex = idx; return }
        }
    }

    function mediaLabel(path) {
        var n = String(path || "").split("/").pop().replace(/\.[^.]+$/, "")
        var m = n.match(/(\d{4})-(\d{2})-(\d{2})[_-](\d{2})-(\d{2})-(\d{2})/)
        return m ? (m[1] + "-" + m[2] + "-" + m[3] + "  " + m[4] + ":" + m[5]) : n
    }
    function currentLabel() {
        if (imageArray.length === 0 || !Model.itemMatches(imageArray, selectedIndex, filterText)) return filterText ? I18n.tr("No matches") : ""
        return mediaLabel(imageArray[selectedIndex].filePath)
    }

    function filteredPos(idx)  { return Model.filteredPosition(imageArray, idx, filterText) }
    function selectedFiltPos() { return Model.selectedFilteredPosition(imageArray, selectedIndex, filterText) }
    function itemMatches(idx)  { return Model.itemMatches(imageArray, idx, filterText) }

    // when typing a filter, jump the focused (main) slice to the first match
    onFilterTextChanged: {
        var n = Model.nextSelectedIndexForFilter(imageArray, selectedIndex, filterText)
        if (n >= 0) selectedIndex = n
    }

    // ── delete (two-step confirm) + copy ──
    property bool confirmDelete: false
    onSelectedIndexChanged: confirmDelete = false
    readonly property var sel: imageArray[selectedIndex] || null

    Process {
        id: deleteProc
        command: []
        onExited: function(code) {       // rescan only on success; on trash failure keep the file + warn (no silent rm)
            if (code !== 0) { console.warn("MediaBrowser: trash failed (gio/trash-put unavailable) - file KEPT, not deleted"); return }
            scanProc.command = panel.liveScanCmd()
            scanProc.running = false; scanProc.running = true
        }
    }
    function deleteFocused() {
        if (!sel || !sel.filePath) return
        deleteProc.command = ["bash", "-c", "f=" + shq(sel.filePath) + "; gio trash -- \"$f\" 2>/dev/null || trash-put -- \"$f\" 2>/dev/null"]
        deleteProc.running = false; deleteProc.running = true
        confirmDelete = false
    }
    Process { id: copyProc; command: [] }
    function copyFocused() {
        if (!sel || !sel.filePath) return
        copyProc.command = panel.isVideos
            ? ["bash", "-c", "printf '%s' " + shq(sel.filePath) + " | wl-copy"]
            : ["bash", "-c", "wl-copy --type image/png < " + shq(sel.filePath)]
        copyProc.running = false; copyProc.running = true
    }

    // ── Carousel geometry ──
    readonly property int expandedW: 768
    readonly property int expandedH: 432
    readonly property int sliceW:    108
    readonly property int sliceH:    390
    readonly property int sliceGap:  -30
    readonly property int skew:       28

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
    MediaBrowserCarouselView {
        id: view
        anchors.fill: parent
        picker: panel
        root: panel.root
    }
}
