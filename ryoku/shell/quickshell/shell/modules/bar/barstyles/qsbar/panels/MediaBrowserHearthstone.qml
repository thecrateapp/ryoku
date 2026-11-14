import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "ImagePickerModel.js" as Model
import Ryoku.Ui.Singletons

// Hearthstone (card-deck) variant of the screenshot/video browser. Original felt
// look + fanned cards on the same fast data layer as the Tanzaku media browser
// (cached thumbnails, niced pre-warm, delete/copy). Active only while
// pickerStyle == "hearthstone".
PanelWindow {
    id: panel
    required property var root

    screen: root.activePopupScreen

    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "ryoku-media-browser-hs"
    WlrLayershell.keyboardFocus: panel.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property bool active: root.pickerStyle === "hearthstone"
    readonly property bool isVideos: root.mediaBrowserMode === "videos"
    readonly property bool ready: root.mediaBrowserVisible && active && loaded && layoutSettled

    property bool loaded:        false
    property bool layoutSettled: false
    property bool closing:       false
    property int  thumbEpoch:    0
    property var  imageArray:    []
    property int  selFilt:       0
    property string filterText:  ""

    visible: root.mediaBrowserVisible && active

    // ── reveal + deal ──
    property real reveal: 0
    Behavior on reveal { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    property real dealT: 0
    Behavior on dealT { NumberAnimation { duration: 360; easing.type: Easing.OutCubic } }
    onReadyChanged: { reveal = ready ? 1 : 0; if (ready) dealT = 1 }

    // ── filtered list ──
    readonly property var filtered: {
        var out = []
        for (var i = 0; i < imageArray.length; i++) {
            if (!Model.itemMatches(imageArray, i, filterText)) continue
            out.push({
                idx:      i,
                filePath: imageArray[i].filePath,
                thumbnailPath: imageArray[i].thumbnailPath,
                label:    panel.mediaLabel(imageArray[i].filePath),
                isVideo:  panel.isVideos
            })
        }
        return out
    }
    onFilteredChanged: if (selFilt >= filtered.length) selFilt = Math.max(0, filtered.length - 1)

    readonly property string currentLabel:
        (filtered.length > 0 && selFilt >= 0 && selFilt < filtered.length)
            ? I18n.tr(filtered[selFilt].label)
            : (filterText ? I18n.tr("No matches") : "")

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
        panel.selFilt       = 0
        panel.reveal        = 0
        panel.dealT         = 0
    }
    function syncOpen() {
        if (root.mediaBrowserVisible && active) {
            panel.closing = false
            if (!loaded) {
                panel.layoutSettled = false
                panel.filterText    = ""
                panel.imageArray    = []
                panel.selFilt       = 0
                panel.reveal        = 0
                panel.dealT         = 0
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

    // scan-result cache → instant (re)open (shared with the Tanzaku media browser)
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
        panel.imageArray = rows
        panel.selFilt    = 0
        panel.loaded     = rows.length > 0
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

    function shq(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'" }
    function cancellableCommand(body, argv0, args) {
        return ["bash", "-c",
            "body=$1; shift; setsid bash -c \"$body\" worker \"$@\" & worker=$!; " +
            "cleanup() { pkill -TERM -s \"$worker\" 2>/dev/null || true; sleep 0.2; pkill -KILL -s \"$worker\" 2>/dev/null || true; }; " +
            "trap 'cleanup; exit 143' TERM INT; wait \"$worker\"",
            argv0 || "manager", body].concat(args || [])
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
        if (!loaded || filtered.length === 0) return
        if (selFilt < 0 || selFilt >= filtered.length) return
        var path = filtered[selFilt].filePath; if (!path) return
        Spawn.runApp(["xdg-open", path], { label: "media" })
        root.mediaBrowserVisible = false
    }

    function moveSel(delta) {
        if (filtered.length === 0) return
        selFilt = Math.max(0, Math.min(filtered.length - 1, selFilt + delta))
    }

    readonly property var sel: (filtered.length > 0 && selFilt >= 0 && selFilt < filtered.length)
                               ? filtered[selFilt] : null

    // ── delete (two-step confirm) + copy ──
    property bool confirmDelete: false
    onSelFiltChanged: confirmDelete = false

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

    function mediaLabel(path) {
        var n = String(path || "").split("/").pop().replace(/\.[^.]+$/, "")
        var m = n.match(/(\d{4})-(\d{2})-(\d{2})[_-](\d{2})-(\d{2})-(\d{2})/)
        return m ? (m[1] + "-" + m[2] + "-" + m[3] + "  " + m[4] + ":" + m[5]) : n
    }

    // ── card-hand geometry ──
    readonly property int  cardW:      232
    readonly property int  cardH:      330
    readonly property real focusScale: 1.24
    readonly property real spreadDeg:  6.0
    readonly property real stepX:      128
    readonly property real focusLift:  54
    readonly property int  maxVisible: 5

    // ── felt look ──
    readonly property color feltColor: Qt.rgba(0.035, 0.035, 0.05, 0.975)
    readonly property color frameDark: "#16161c"
    readonly property color textLight: "#ECECEE"
    readonly property color textDim:   Qt.rgba(0.92, 0.92, 0.94, 0.55)

    // the drawing, in an Item of its own so it loads offscreen
    MediaBrowserHearthstoneView {
        id: view
        anchors.fill: parent
        picker: panel
        root: panel.root
    }
}
