import QtQuick
import QtTest as Test
import Quickshell
import Ryoku.Ui.Singletons
import Ryoku.PluginKit
import Ryoku.PluginKit.Singletons as Kit

// The plugin kit on the shell kit, in the crate and the stock look: under crate
// its Theme takes the face, the mono, the hairline and the corner from Tokens,
// MicroLabel is the kit's accent tracked label without its dot, CornerTicks draw
// nothing and a Card takes the shared corner; WaveMeter stays in both looks.
// Beam, Chip, IconButton and TrackLabel are the shell kit's own controls,
// re-exported for plugins (R4), Beam reporting a drag while the pointer holds it.
ShellRoot {
    id: probe
    property int chipTaps: 0
    property int closes: 0
    property real seekTo: -1
    // crate from the start, so the controls' colour animations have settled by the checks
    Component.onCompleted: Tokens.controlsCrate = true

    FloatingWindow {
        implicitWidth: 640
        implicitHeight: 420
        Test.TestCase { id: input; when: false }

        Column {
            x: 40; y: 40
            spacing: 12
            MicroLabel { id: micro; label: "System" }
            Item {
                width: 120; height: 40
                CornerTicks { id: ticks; anchors.fill: parent }
            }
            Card { id: card; width: 240; eyebrow: "Disk"; Text { text: "42 %" } }
            WaveMeter { id: wave; width: 200; frac: 0.4 }
            Beam { id: beam; width: 240; value: 0.25; onCommitted: (v) => probe.seekTo = v }
            Row {
                spacing: 8
                Chip { id: chip; text: "Smart"; on: true; onClicked: probe.chipTaps++ }
                IconButton { id: close; glyph: "close"; glyphFont: "Material Symbols Rounded"; onClicked: probe.closes++ }
                TrackLabel { id: caption; text: "Equalizer"; tone: "accent" }
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
    function dotOf(row) {
        for (const child of row.children)
            if (child.width === 5 * row.s && child.height === 5 * row.s) return child;
        return null;
    }

    Timer {
        interval: 600
        running: true
        onTriggered: {
            check(Kit.Theme.crate, "the plugin Theme follows controls crate");
            check(Kit.Theme.radius === Tokens.radius && Kit.Theme.font === Tokens.ui && Kit.Theme.mono === Tokens.mono, "corner, face and mono from Tokens");
            check(Qt.colorEqual(Kit.Theme.border, Tokens.line), "the hairline from Tokens");
            const ml = find(micro, "microLabel");
            check(ml && ml.visible && ml.tone === "accent" && ml.text === "System", "MicroLabel is the accent tracked label");
            check(!dotOf(micro).visible, "no reg dot under crate");
            check(!ticks.visible, "corner ticks are marginalia");
            check(card.radius === Tokens.radius && find(card, "cardEyebrow").visible, "a card takes the shared corner and the kit eyebrow");
            check(wave.visible, "WaveMeter stays");

            check(beam.frac === 0.25 && !beam.dragging, "the re-exported Beam shows its value at rest");
            input.mousePress(beam, beam.width * 0.6, beam.height / 2);
            check(beam.dragging, "the Beam reports the drag");
            input.mouseRelease(beam, beam.width * 0.6, beam.height / 2);
            check(!beam.dragging && Math.abs(probe.seekTo - 0.6) < 0.02, "release commits where the pointer let go");

            check(chip.radius === Tokens.radius && chip.implicitHeight === 32 && Qt.colorEqual(chip.color, Tokens.mark), "the re-exported Chip is straight and filled with the mark");
            chip.clicked();
            check(probe.chipTaps === 1, "the chip taps");
            check(close.implicitWidth === 44, "the re-exported IconButton has the 44 px hit area");
            close.clicked();
            check(probe.closes === 1, "the icon button clicks");
            check(caption.font.family === Tokens.mono && caption.font.capitalization === Font.AllUppercase, "the re-exported label is mono, upper case");

            Tokens.controlsCrate = false;
            stock.start();
        }
    }
    Timer {
        id: stock
        interval: 400
        onTriggered: {
            check(!Kit.Theme.crate && Kit.Theme.radius === 0, "stock square corner");
            check(Kit.Theme.font === "Space Grotesk" && Kit.Theme.mono === "JetBrainsMono Nerd Font", "stock faces");
            check(!find(micro, "microLabel").visible && dotOf(micro).visible, "stock MicroLabel keeps its dot");
            check(ticks.visible, "stock corner ticks");
            check(card.radius === 0 && !find(card, "cardEyebrow").visible, "stock card");
            check(wave.visible, "WaveMeter in the stock look");
            check(chip.implicitHeight === 24 && close.implicitWidth === 26, "the re-exports follow the stock kit");
            console.log("PLUGINKIT-KIT-PROBE-PASS");
            Qt.quit();
        }
    }
}
