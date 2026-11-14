import QtQuick
import Quickshell
import Ryoku.Ui
import Ryoku.Ui.Singletons

// PickCard in both looks: the default face (glyph, title, subtitle), the crate
// pick grammar (pick wash inside the 1 px pick edge, the corner dot with its
// halo, a warm edge on hover) and the stock gallery tile (tint wash, ink edge,
// the 5 px corner dot); a click, keyboard activation, caller content that
// replaces the default face, and an owner-driven card that ignores the pointer.
ShellRoot {
    id: probe
    property int clicks: 0

    FloatingWindow {
        implicitWidth: 560
        implicitHeight: 240
        // offset from the window's origin, where the offscreen pointer rests
        Row {
            x: 60; y: 60
            spacing: 12
            PickCard { id: idle; width: 150; height: 110; glyph: "monitor"; title: "Arch"; subtitle: "rolling"; onClicked: probe.clicks++ }
            PickCard { id: picked; width: 150; height: 110; glyph: "monitor"; title: "Fedora"; subtitle: "41"; picked: true }
            PickCard {
                id: custom
                width: 150; height: 110
                interactive: false
                hotHint: true
                Text { objectName: "customFace"; anchors.centerIn: parent; text: "cover" }
            }
        }
    }

    function find(item, name) {
        if (!item) return null;
        if (item.objectName === name) return item;
        for (const child of item.children) {
            const hit = find(child, name);
            if (hit) return hit;
        }
        return null;
    }
    function check(test, reason) { if (!test) throw new Error(reason); }
    function faceVisible(card) {
        for (const child of card.children)
            if (child instanceof Column) return child.visible;
        return false;
    }

    Timer {
        id: crateCheck
        interval: 500
        onTriggered: {
            check(idle.radius === Tokens.radius && picked.radius === Tokens.radius, "6 px corners");
            check(Qt.colorEqual(idle.border.color, Tokens.line) && idle.border.width === 1, "idle hairline edge");
            check(Qt.colorEqual(idle.color, "transparent"), "idle card has no fill");
            check(Qt.colorEqual(picked.color, Tokens.pickFill), "picked card takes the pick wash");
            check(Qt.colorEqual(picked.border.color, Tokens.pickEdge) && picked.border.width === 1, "picked card 1 px pick edge");
            const mark = find(picked, "pickCardMark");
            check(mark.visible && mark.width === 12, "picked dot with its halo");
            check(!find(idle, "pickCardMark").visible, "an idle card has no dot");
            check(faceVisible(idle), "default face shows glyph, title and subtitle");
            check(!faceVisible(custom) && find(custom, "customFace").visible, "caller content replaces the default face");
            check(Qt.colorEqual(custom.border.color, Tokens.markHover), "hotHint warms the edge");
            check(!custom.activeFocusOnTab, "an owner-driven card leaves focus to its owner");
            idle.clicked();
            idle.forceActiveFocus();
            check(idle.activeFocus && idle.focusShown, "a card takes keyboard focus");
            Tokens.controlsCrate = false;
            stockCheck.start();
        }
    }
    Timer {
        id: stockCheck
        interval: 500
        onTriggered: {
            check(Qt.colorEqual(idle.border.color, Tokens.focus) && idle.border.width === 2, "stock focus edge");
            idle.focus = false;
            check(Qt.colorEqual(picked.color, Tokens.tint10), "stock picked tile tint");
            check(Qt.colorEqual(picked.border.color, Tokens.ink), "stock picked tile ink edge");
            const mark = find(picked, "pickCardMark");
            check(mark.visible && mark.width === 5, "stock corner dot");
            check(Qt.colorEqual(custom.border.color, Tokens.lineStrong), "stock hover edge");
            check(probe.clicks === 1, "clicked fired once, got " + probe.clicks);
            console.log("PICK-CARD-PROBE-PASS");
            Qt.quit();
        }
    }
    Timer {
        interval: 150
        running: true
        onTriggered: {
            Tokens.controlsCrate = true;
            crateCheck.start();
        }
    }
}
