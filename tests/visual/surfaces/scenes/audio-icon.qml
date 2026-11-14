import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import "modules/bar/barstyles/qsbar/modules" as Modules
import "modules/bar/barstyles/qsbar/panels" as Panels

// The QS Bar's audio widget next to the volume panel's device rows, once per
// stand-in sink picked (laptop speaker, wired headphones, HDMI monitor,
// Bluetooth headphones): under crate the bar's glyph is the picked row's glyph.
// The stock panel draws its own tiles, so the stock look shows only the bar.
ShellRoot {
    component Sink: QtObject {
        property string name: ""
        property var properties: ({})
        property bool isSink: true
        property bool ready: true
        readonly property QtObject audio: QtObject {
            property real volume: 0.5
            property bool muted: false
        }
    }
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
        property string mono: Tokens.mono
        property color widgetIconColor: Tokens.ink
        property var tooltipOwner: null
        property string tooltipText: ""
        function widgetContentColor(gid, fallback) { return fallback }
        function iconOnly(gid) { return false }
        function showTooltip(text, x, top, bottom, owner) {}
        function hideTooltip(owner) {}
    }

    FloatingWindow {
        implicitWidth: 720
        implicitHeight: 600
        color: Tokens.popover

        Rectangle {
            id: sheet
            width: 720
            height: grid.implicitHeight + 40
            color: Tokens.popover

            Grid {
                id: grid
                x: 20
                y: 20
                columns: 2
                spacing: 20
                Repeater {
                    model: [laptopSpeaker, wiredHeadphones, hdmiMonitor, btHeadphones]
                    delegate: Column {
                        id: pane
                        required property var modelData
                        width: 330
                        spacing: 8
                        Rectangle {
                            width: 96
                            height: 32
                            radius: Tokens.radius
                            color: Tokens.glass
                            border.width: 1
                            border.color: Tokens.lineSoft
                            Modules.AudioWidget { anchors.centerIn: parent; root: theme; sink: pane.modelData }
                        }
                        Loader {
                            width: parent.width
                            active: Tokens.controlsCrate
                            sourceComponent: Panels.CrateOutputRows {
                                outputs: [laptopSpeaker, wiredHeadphones, hdmiMonitor, btHeadphones]
                                sink: pane.modelData
                            }
                        }
                    }
                }
            }
        }

        Timer {
            interval: Number(Quickshell.env("BENCH_WAIT") || 1500)
            running: true
            onTriggered: sheet.grabToImage(r => { r.saveToFile(Quickshell.env("BENCH_OUT")); Qt.quit(); })
        }

        Component.onCompleted: {
            const look = Quickshell.env("BENCH_CRATE");
            if (look === "1" || look === "0")
                Tokens.controlsCrate = look === "1";
        }
    }
}
