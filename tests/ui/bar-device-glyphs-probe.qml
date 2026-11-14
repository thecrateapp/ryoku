import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import Ryoku.Ui as Kit
import "modules/bar/barstyles/qsbar" as QsBar
import "modules/bar/barstyles/qsbar/modules" as Modules

// Under crate the bar's audio widget draws a kit glyph for the device the
// default sink plays through (AudioOutput.js picks it; with no sink in this
// isolated session it is the plain speaker), and the Bluetooth widget draws the
// squared rune (struck through while the radio is off). Both glyphs must exist
// in the kit catalogue, so they draw instead of falling back to Material.
ShellRoot {
    QsBar.Theme { id: theme }
    Item {
        Modules.AudioWidget { id: audioWidget; root: theme }
        Modules.BluetoothWidget { id: btWidget; root: theme }
        Repeater {
            id: names
            model: ["headphones-round-sound", "speaker-minimalistic", "laptop", "monitor", "headphones-round", "bluetooth-square", "bluetooth-square-off"]
            Kit.Glyph { required property string modelData; name: modelData }
        }
    }

    function part(item, name) {
        if (item.objectName === name) return item;
        for (const c of item.children) { const f = part(c, name); if (f) return f; }
        return null;
    }

    Timer {
        interval: 900
        running: true
        onTriggered: {
            let err = "";
            const oldKit = Quickshell.env("PROBE_KIT") === "old";
            const a = part(audioWidget, "audioGlyph");
            const b = part(btWidget, "bluetoothGlyph");
            if (!Tokens.controlsCrate) err = "crate style not read";
            else if (!a || !a.visible || !a.drawn) err = "audio glyph not drawn: " + (a && a.name);
            else if (["speaker", "laptop", "monitor", "headphones-round", "headphones-round-sound", "speaker-minimalistic"].indexOf(a.name) < 0)
                err = "audio glyph " + a.name;
            else if (!b || !b.drawn)
                err = "bluetooth glyph not drawn: " + (b && b.name);
            else if (!oldKit && ["bluetooth-square", "bluetooth-square-off"].indexOf(b.name) < 0)
                err = "bluetooth glyph " + b.name;
            for (let i = 0; i < names.count && !err && !oldKit; i++)
                if (!names.itemAt(i).drawn) err = "kit lacks " + names.itemAt(i).name;
            console.log(err ? "BAR-DEVICE-GLYPHS-PROBE-FAIL " + err : "BAR-DEVICE-GLYPHS-PROBE-PASS");
            Qt.quit();
        }
    }
}
