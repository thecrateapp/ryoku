import QtQuick
import Quickshell
import Quickshell.Wayland
import Ryoku.Ui.Singletons
import "Singletons"
import "lib/pinlayout.js" as PinLayout

PanelWindow {
    id: pin

    property var entry: ({})
    signal closed(string path)
    signal painted()

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "ryopin"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    anchors { top: true; left: true }

    readonly property int screenW: screen ? screen.width : 0
    readonly property int screenH: screen ? screen.height : 0

    readonly property int natW: body.natW
    readonly property int natH: body.natH
    // Image.status reaches Ready a frame before sourceSize is populated, so the
    // dimensions themselves are the seeding trigger.
    readonly property bool measured: natW > 0 && natH > 0
    readonly property var fitted: PinLayout.fitSize(natW > 0 ? natW : 1, natH > 0 ? natH : 1, screenW, screenH)

    // fitted seeds the size; the wheel breaks these bindings to resize by hand.
    property int frameW: fitted.w
    property int frameH: fitted.h

    onMeasuredChanged: if (measured && !seeded) seedSlot()
    Component.onCompleted: if (measured && !seeded) seedSlot()

    // Transparent room around the card: the drop shadow spills into it in stock,
    // the action strip sits in it under crate.
    readonly property int gutter: Theme.gutter
    // a live theme switch changes the gutter: hold the card inside the new one
    onGutterChanged: if (seeded) reclamp()

    property int slotX: 0
    property int slotY: 0
    property bool seeded: false
    property bool notified: false

    implicitWidth: frameW + gutter * 2
    implicitHeight: frameH + gutter * 2

    margins.left: slotX - gutter
    margins.top: slotY - gutter

    /**
     * Places a fresh pin in its slot. The fit is recomputed here rather than
     * read off frameW, which still carries the placeholder size on the frame
     * where the image first reports its dimensions.
     */
    function seedSlot() {
        var f = PinLayout.fitSize(natW > 0 ? natW : 1, natH > 0 ? natH : 1, screenW, screenH);
        frameW = f.w;
        frameH = f.h;
        var p = PinLayout.slotPosition(entry.index || 0, f, screenW, screenH);
        var c = pin.onScreen(p.x, p.y);
        slotX = c.x;
        slotY = c.y;
        seeded = true;
    }

    // The surface carries a transparent gutter around the card, so the card is
    // held one gutter inside the output or the compositor clips the far edge.
    function onScreen(x, y) {
        return PinLayout.clamp({ x: x, y: y }, { w: pin.frameW, h: pin.frameH },
            pin.screenW, pin.screenH, pin.gutter);
    }

    function reclamp() {
        var c = pin.onScreen(slotX, slotY);
        slotX = c.x;
        slotY = c.y;
    }

    function editShot() {
        Spawn.run(["env", "RYOSHOT_OPEN=" + entry.path, "ryoku-cmd-ryoshot"]);
        pin.closeSelf();
    }
    function copyShot() { Quickshell.execDetached(["ryoku-shell", "clip-copy", "image/png", entry.path]); }
    function copyLink() {
        Quickshell.execDetached(["sh", "-c", "printf %s \"$1\" > \"$2\"; ryoku-shell clip-copy text/plain \"$2\"",
            "sh", entry.path, "/tmp/ryopin-path.txt"]);
    }
    function closeSelf() { pin.closed(entry.path); }

    FocusScope {
        id: content
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: pin.closeSelf()

        PinCard {
            id: body
            x: pin.gutter
            y: pin.gutter
            width: pin.frameW
            height: pin.frameH
            path: pin.entry.path || ""

            onGrabbed: pin.forceActiveFocus()
            onDragged: (dx, dy) => {
                var c = pin.onScreen(pin.slotX + dx, pin.slotY + dy);
                pin.slotX = c.x;
                pin.slotY = c.y;
            }
            onZoomed: (f) => {
                var s = PinLayout.fitSize(pin.frameW * f, pin.frameH * f, pin.screenW, pin.screenH);
                pin.frameW = s.w;
                pin.frameH = s.h;
                pin.reclamp();
            }
            onEditRequested: pin.editShot()
            onCopyRequested: pin.copyShot()
            onLinkRequested: pin.copyLink()
            onCloseRequested: pin.closeSelf()
        }

        FrameAnimation {
            running: pin.visible && !pin.notified
            onTriggered: { pin.notified = true; pin.painted(); }
        }
    }
}
