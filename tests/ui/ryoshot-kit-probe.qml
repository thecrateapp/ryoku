import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import "ryoshot" as Ryoshot
import "ryoshot/Singletons" as RyoshotState

// Ryoshot on the kit, in both looks: a slider's track is the Beam under crate
// (filled from the middle for a bipolar value) and a press anywhere on the row
// still sets it; a toolbar action is the kit's plateless IconButton with the
// Solar glyph, or Ryoshot's own line path where Solar has none; corners are the
// shared 6 px under crate and keep their own size in stock.
ShellRoot {
    id: probe
    property string look: "crate"
    property real moved: -1
    property int clicks: 0

    FloatingWindow {
        implicitWidth: 700
        implicitHeight: 300
        Item {
            x: 60; y: 60
            width: 600; height: 200
            Ryoshot.Slider { id: plain; width: 300; from: 0; to: 100; value: 25; label: "Padding"; onMoved: v => probe.moved = v }
            Ryoshot.Slider { id: bipolar; y: 60; width: 300; from: -100; to: 100; value: -50; bipolar: true; label: "Brightness" }
            Ryoshot.IconButton { id: undo; x: 340; icon: "undo"; onClicked: probe.clicks++ }
            Ryoshot.IconButton { id: arrow; x: 380; icon: "arrow"; active: true }
            Ryoshot.IconButton { id: redo; x: 420; icon: "redo"; dim: true }
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
    function check(test, reason) { if (!test) throw new Error(probe.look + ": " + reason); }

    function verify(crate) {
        const beam = find(plain, "ryoshotSliderBeam");
        check(beam.visible === crate && beam.value === 25 && beam.to === 100, "the slider's track is a Beam under crate");
        const bb = find(bipolar, "ryoshotSliderBeam");
        check(bb.bipolar && bb.fillFrom === 0.25 && bb.fillTo === 0.5, "a bipolar slider fills from the middle");
        const kit = find(undo, "ryoshotKitButton");
        check(kit.visible === crate, "the toolbar action is the kit IconButton under crate");
        check(kit.glyph === "undo-left" && kit.path === "", "a Solar glyph where the catalogue has one");
        const own = find(arrow, "ryoshotKitButton");
        check(own.glyph === "" && own.path.length > 0 && own.on, "Ryoshot's own path where Solar has none, on when active");
        check(!find(redo, "ryoshotKitButton").enabled, "a dim action is disabled");
        check(!crate || Qt.colorEqual(undo.color, "transparent"), "no plate under crate");
        check(undo.radius === (crate ? Tokens.radius : 7), "an action's corner");
        check(RyoshotState.Theme.radius === (crate ? Tokens.radius : Tokens.radius * 2), "a panel's corner");
    }

    Timer {
        id: crateCheck
        interval: 500
        onTriggered: {
            probe.verify(true);
            probe.find(undo, "ryoshotKitButton").clicked();
            Tokens.controlsCrate = false;
            probe.look = "stock";
            stockCheck.start();
        }
    }
    Timer {
        id: stockCheck
        interval: 500
        onTriggered: {
            probe.verify(false);
            probe.check(probe.clicks === 1, "the kit button's click reaches the action");
            plain.setFromX(150);
            probe.check(Math.abs(probe.moved - 50) < 0.5, "a press at the middle moves to the middle, got " + probe.moved);
            console.log("RYOSHOT-KIT-PROBE-PASS");
            Qt.quit();
        }
    }
    Timer {
        interval: 200
        running: true
        onTriggered: {
            Tokens.controlsCrate = true;
            crateCheck.start();
        }
    }
}
