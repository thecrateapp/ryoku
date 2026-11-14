pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import shell.services
import Ryoku.Ui.Singletons

// One fullscreen selection overlay per output (contract 09 sec 1b/4a), raised on
// the Overlay layer with no exclusive zone so it floats over the bars and app
// windows and reserves nothing. It dims the output and lets the user pick a
// capture target for the frame's screenshot menu:
//
//   region  a single click-drag-release rubber band, each axis clamped to this
//           output, committing only when both width and height exceed 5px and
//           cancelled by Escape. Deliberately NO resize handles and NO snapping
//           (contract 09 confirms their absence); a too-small release just
//           resets and the overlay stays open to try again.
//   monitor click anywhere on an output to pick that whole output.
//   window  hit-test the hovered toplevel and pick its global rect.
//
// One overlay is mapped per output while Capture.selecting is set; a commit or
// Escape on any one clears Capture.selecting, which tears every sibling down at
// once. The clear cutout is drawn as four dim bands framing the selection, so
// the selected pixels carry no overlay tint and show the live screen through the
// transparent surface.
PanelWindow {
    id: win

    required property var modelData

    // Per-monitor UI scale (shell.json displays.ui_scale): scales this overlay's
    // own chrome (outline weight, dimension readout) without touching the
    // fullscreen bounds or the user-drawn selection. Default 1.0 is a no-op.
    readonly property real us: Tokens.uiScaleFor(modelData ? modelData.name : "")

    readonly property string sel: Capture.selecting

    // This surface's screen: layout position and logical size in the same
    // space the capture pipeline and Recorder expect, and a fallback for the
    // logical size before the surface maps. Never gate `visible` on
    // width/height: they are 0 until the surface maps, which would deadlock
    // (never sized -> never visible).
    readonly property real monX: modelData ? modelData.x : 0
    readonly property real monY: modelData ? modelData.y : 0
    readonly property real scrW: win.width > 0 ? win.width : (modelData ? modelData.width : 0)
    readonly property real scrH: win.height > 0 ? win.height : (modelData ? modelData.height : 0)

    screen: modelData
    visible: win.sel !== ""
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "ryoku-capture"

    anchors { top: true; bottom: true; left: true; right: true }

    // --- region drag (output-local logical px, clamped to this output) --------
    property bool dragging: false
    property real sx: 0
    property real sy: 0
    property real cx: 0
    property real cy: 0
    readonly property real rx: Math.min(win.sx, win.cx)
    readonly property real ry: Math.min(win.sy, win.cy)
    readonly property real rw: Math.abs(win.cx - win.sx)
    readonly property real rh: Math.abs(win.cy - win.sy)

    property bool hovering: false

    function clampX(x) { return Math.max(0, Math.min(win.scrW, x)); }
    function clampY(y) { return Math.max(0, Math.min(win.scrH, y)); }

    // A fresh open (or a family teardown) must never inherit a stale drag/hover.
    onSelChanged: {
        win.dragging = false;
        win.hovering = false;
        win.hoverWin = -1;
    }

    // --- window selector: this output's windows, snapshotted while open ------
    // Global logical rects, only when the compositor reports window geometry,
    // filtered to windows on this output's active workspace that intersect it
    // and converted to output-local for drawing and hit-testing. Snapshotted
    // reactively; overlays are transient so the next invocation re-queries
    // (hotplug mid-selection is out of scope).
    readonly property var wins: {
        if (win.sel !== "window" || !Wm.caps.windowGeometry)
            return [];
        var out = [];
        var output = Wm.outputByName(win.modelData ? win.modelData.name : "");
        var activeWs = output ? output.activeWorkspace : "";
        var all = Wm.windows;
        for (var i = 0; i < all.length; i++) {
            var w = all[i];
            if (!w || w.workspace !== activeWs || w.width <= 0 || w.height <= 0)
                continue;
            var lx = w.x - win.monX;
            var ly = w.y - win.monY;
            if (lx + w.width <= 0 || ly + w.height <= 0 || lx >= win.scrW || ly >= win.scrH)
                continue;
            out.push({ x: lx, y: ly, w: w.width, h: w.height });
        }
        return out;
    }
    property int hoverWin: -1
    function hitTest(x, y) {
        // Reverse order: the front-most window under the pointer wins.
        for (var i = win.wins.length - 1; i >= 0; i--) {
            var r = win.wins[i];
            if (x >= r.x && x < r.x + r.w && y >= r.y && y < r.y + r.h)
                return i;
        }
        return -1;
    }

    // The highlighted rect (output-local) driving the cutout + border.
    readonly property bool hasRect: win.sel === "region" ? (win.dragging && win.rw > 1 && win.rh > 1)
        : win.sel === "window" ? (win.hoverWin >= 0)
        : false
    readonly property real hlx: (win.sel === "window" && win.hoverWin >= 0) ? win.wins[win.hoverWin].x : win.rx
    readonly property real hly: (win.sel === "window" && win.hoverWin >= 0) ? win.wins[win.hoverWin].y : win.ry
    readonly property real hlw: (win.sel === "window" && win.hoverWin >= 0) ? win.wins[win.hoverWin].w : win.rw
    readonly property real hlh: (win.sel === "window" && win.hoverWin >= 0) ? win.wins[win.hoverWin].h : win.rh

    // The scrim, the cutout, the outline and the readout (CaptureFrame).
    CaptureFrame {
        anchors.fill: parent
        sel: win.sel
        hasRect: win.hasRect
        hovering: win.hovering
        hlx: win.hlx
        hly: win.hly
        hlw: win.hlw
        hlh: win.hlh
        scrW: win.scrW
        scrH: win.scrH
        us: win.us
    }

    // --- input ----------------------------------------------------------------
    MouseArea {
        anchors.fill: parent
        enabled: win.sel !== ""
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: win.sel === "region" ? Qt.CrossCursor : Qt.PointingHandCursor

        onEntered: win.hovering = true
        onExited: {
            win.hovering = false;
            if (win.sel === "window")
                win.hoverWin = -1;
        }
        onPositionChanged: mouse => {
            win.hovering = true;
            if (win.sel === "window")
                win.hoverWin = win.hitTest(mouse.x, mouse.y);
            else if (win.sel === "region" && win.dragging) {
                win.cx = win.clampX(mouse.x);
                win.cy = win.clampY(mouse.y);
            }
        }
        onPressed: mouse => {
            if (win.sel === "region") {
                win.sx = win.cx = win.clampX(mouse.x);
                win.sy = win.cy = win.clampY(mouse.y);
                win.dragging = true;
            }
        }
        onReleased: mouse => {
            if (win.sel === "region") {
                if (!win.dragging)
                    return;
                win.dragging = false;
                if (win.rw > 5 && win.rh > 5)
                    Capture.commit({ mode: "region", output: win.modelData.name, monX: win.monX, monY: win.monY, x: win.rx, y: win.ry, w: win.rw, h: win.rh });
                // else too small: reset above, stay open to try again.
            } else if (win.sel === "monitor") {
                Capture.commit({ mode: "monitor", output: win.modelData.name, monX: win.monX, monY: win.monY, x: 0, y: 0, w: win.scrW, h: win.scrH });
            } else if (win.sel === "window") {
                var i = win.hitTest(mouse.x, mouse.y);
                if (i >= 0) {
                    var r = win.wins[i];
                    Capture.commit({ mode: "window", output: win.modelData.name, monX: win.monX, monY: win.monY, x: r.x, y: r.y, w: r.w, h: r.h });
                }
            }
        }
    }

    // Escape cancels the whole family. Keyboard mode is OnDemand (contract 09),
    // so focus is opportunistic; the press that starts a drag grants it.
    Item {
        anchors.fill: parent
        focus: win.sel !== ""
        Keys.onEscapePressed: Capture.cancel()
    }
}
