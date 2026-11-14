import QtQuick
import QtTest
import Quickshell
import shell.services
import Ryoku.Ui.Singletons
import Ryoku.Ui as Kit
import "modules" as Modules
import "panels" as Panels

// Under crate the bar's audio widget must draw the glyph of the device the
// volume panel shows picked, for each kind of sink; the stock look keeps the
// Material graphic_eq and the panel's crate rows stay out of it.
ShellRoot {
    id: probe

    component Sink: QtObject {
        property string name: ""
        property var properties: ({})
        property bool isSink: true
        property bool isStream: false
        property bool ready: true
        readonly property QtObject audio: QtObject {
            property real volume: 0.5
            property bool muted: false
        }
    }

    // PipeWire properties as this laptop (SoundWire speakers, a headphone jack,
    // DisplayPort monitors) and WirePlumber's Bluetooth sinks publish them
    Sink {
        id: laptopSpeaker
        name: "alsa_output.pci-0000_00_1f.3-platform-sof_sdw.HiFi__Speaker__sink"
        properties: ({ "node.name": name, "node.description": "Meteor Lake-P HD Audio Controller Speaker",
            "device.bus": "pci", "device.icon-name": "audio-card-analog", "device.api": "alsa" })
    }
    Sink {
        id: wiredHeadphones
        name: "alsa_output.pci-0000_00_1f.3-platform-sof_sdw.HiFi__Headphones__sink"
        properties: ({ "node.name": name, "node.description": "Meteor Lake-P HD Audio Controller Headphones",
            "device.bus": "pci", "device.icon-name": "audio-card-analog", "device.api": "alsa" })
    }
    Sink {
        id: hdmiMonitor
        name: "alsa_output.pci-0000_01_00.1.hdmi-stereo"
        properties: ({ "node.name": name, "node.description": "GA104 High Definition Audio Controller Digital Stereo (HDMI)",
            "device.bus": "pci", "device.api": "alsa" })
    }
    Sink {
        id: btHeadphones
        name: "bluez_output.AC_80_0A_11_22_33.1"
        properties: ({ "node.name": name, "node.description": "ULT WEAR", "device.bus": "bluetooth",
            "device.form-factor": "headphone", "device.api": "bluez5" })
    }

    QtObject {
        id: theme
        property bool modVolume: true
        property bool audioBoost: false
        property bool volVisible: false
        property string mono: "monospace"
        property color widgetIconColor: "#eeeeee"
        property var tooltipOwner: null
        property string tooltipText: ""
        function widgetContentColor(gid, fallback) { return fallback }
        function iconOnly(gid) { return false }
        function showTooltip(text, x, top, bottom, owner) {}
        function hideTooltip(owner) {}
    }

    FloatingWindow {
        implicitWidth: 360
        implicitHeight: 360
        TestCase { id: input; when: false }
        Modules.AudioWidget { id: widget; x: 10; y: 10; root: theme }
        Panels.CrateOutputRows { id: rows; x: 10; y: 60; width: 320 }
    }

    function check(ok, message) {
        if (!ok) throw new Error(message);
    }
    function find(item, test) {
        if (test(item)) return item;
        for (const c of item.children) {
            const f = find(c, test);
            if (f) return f;
        }
        return null;
    }
    function pickedRow() {
        const picked = [];
        for (const c of rows.children)
            if (c.objectName === "outputRow" && c.picked) picked.push(c);
        return picked;
    }

    Timer {
        interval: 200
        running: true
        onTriggered: {
            const kit = Quickshell.env("PROBE_KIT");
            const old = kit === "old";
            try {
                const glyph = input.findChild(widget, "audioGlyph");
                check(glyph, "the bar's audio glyph is missing");
                Audio.outputs = [laptopSpeaker, wiredHeadphones, hdmiMonitor, btHeadphones];

                // stock: graphic_eq in Material, no kit glyph
                Tokens.controlsCrate = false;
                Audio.sink = laptopSpeaker;
                const stockIcon = probe.find(widget, i => i.text === "graphic_eq");
                check(stockIcon && stockIcon.visible && !glyph.visible, "stock lost graphic_eq");

                Tokens.controlsCrate = true;
                const cases = [
                    [laptopSpeaker, old ? "speaker" : "laptop"],
                    [wiredHeadphones, "headphones-round"],
                    [hdmiMonitor, "monitor"],
                    [btHeadphones, old ? "speaker" : "headphones-round-sound"],
                ];
                for (const [sink, want] of cases) {
                    Audio.sink = sink;
                    const picked = probe.pickedRow();
                    check(picked.length === 1, sink.name + ": " + picked.length + " picked rows");
                    const rowGlyph = probe.find(picked[0], i => i !== picked[0] && i.drawn !== undefined && i.fallbackFont !== undefined);
                    check(rowGlyph && rowGlyph.drawn && glyph.visible && glyph.drawn,
                        sink.name + ": a glyph is not drawn from the kit");
                    const bar = Kit.GlyphCatalog.resolve(glyph.name);
                    const row = Kit.GlyphCatalog.resolve(rowGlyph.name);
                    check(bar === row, sink.name + ": bar draws " + bar + ", the picked row " + row);
                    check(bar === want, sink.name + ": draws " + bar + ", want " + want);
                }

                // stock again: the widget is back on graphic_eq
                Tokens.controlsCrate = false;
                check(stockIcon.visible && !glyph.visible, "stock did not come back");
                console.log("AUDIO-OUTPUT-GLYPH-PROBE-PASS " + kit);
            } catch (error) {
                console.log("AUDIO-OUTPUT-GLYPH-PROBE-FAIL " + kit + " " + error.message);
            }
            Qt.quit();
        }
    }
}
