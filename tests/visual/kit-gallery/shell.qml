import QtQuick
import Quickshell
import Ryoku.Ui
import Ryoku.Ui.Singletons

ShellRoot {
    FloatingWindow {
        implicitWidth: 560
        implicitHeight: 1060
        color: Tokens.paper
        Rectangle {
            id: sheet
            width: 560; height: 1060
            color: Tokens.popover
            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12
                Section { width: parent.width; title: "Seg / Chips / Multi" }
                Seg { options: ["top", "bottom", "left"]; current: "top" }
                Chips { width: parent.width; options: ["Islands", "Full", "Fit", "Dock"]; current: "Full" }
                Multi { width: parent.width; options: ["CPU", "Memory", "Battery"]; chosen: ["CPU"] }
                Section { width: parent.width; title: "Sw / Step / IconBtn" }
                Row { spacing: 12
                    Sw { on: true } Sw { on: false }
                    Step { value: 4; from: 0; to: 10 }
                    IconBtn { glyph: "✕" } IconBtn { glyph: "↺" }
                }
                Section { width: parent.width; title: "Slid" }
                Slid { width: 300; value: 64; from: 0; to: 100 }
                Section { width: parent.width; title: "Btn" }
                Row { spacing: 8
                    Btn { text: "Apply"; primary: true } Btn { text: "Open"; outline: true } Btn { text: "Cancel" }
                }
                Section { width: parent.width; title: "Tabs" }
                Tabs { options: ["Shortcuts", "Apps", "Custom"]; current: "Shortcuts" }
                Section { width: parent.width; title: "MeterRow" }
                Column { width: parent.width
                    MeterRow { width: parent.width; label: "Memory"; valueText: "13.0 / 30.8 GiB"; fraction: 0.42 }
                    MeterRow { width: parent.width; label: "GPU"; valueText: "0% · 49 °C"; fraction: 0.02 }
                    MeterRow { width: parent.width; label: "Network"; valueText: "↓ 5.4 MB/s · ↑ 1.8 MB/s"; showMeter: false }
                    MeterRow { width: parent.width; label: "Battery"; valueText: "89% · on battery"; fraction: 0.89 }
                }
                Section { width: parent.width; title: "LevelRow" }
                Column { id: levels; width: parent.width; spacing: 6
                    property real capW: Math.max(lv1.labelImplicitWidth, lv2.labelImplicitWidth, lv3.labelImplicitWidth)
                    LevelRow { id: lv1; width: parent.width; labelWidth: levels.capW; label: "Volume"; glyph: "volume_up"; value: 0.77; muteEnabled: true }
                    LevelRow { id: lv2; width: parent.width; labelWidth: levels.capW; label: "Brightness"; glyph: "brightness_high"; value: 1 }
                    LevelRow { id: lv3; width: parent.width; labelWidth: levels.capW; label: "Mic"; glyph: "mic_off"; value: 0.4; muted: true; muteEnabled: true; expandable: false }
                }
                Section { width: parent.width; title: "SheetHeader / ListRow / SignalBars" }
                SheetHeader { width: parent.width; title: "Wi-Fi"; Sw { on: true } }
                Column { width: parent.width; spacing: 6
                    ListRow { width: parent.width; title: "Casa-5G"; sub: "Connected · 82 % · WPA2"; on: true
                        leading: Component { SignalBars { strength: 82; on: true } }
                        Btn { compact: true; text: "Disconnect" } }
                    ListRow { width: parent.width; title: "Estudio"; sub: "WPA3 · 71 %"
                        leading: Component { SignalBars { strength: 71 } }
                        Btn { compact: true; outline: true; text: "Connect" } }
                    ListRow { width: parent.width; title: "Jabra Evolve"; sub: "Paired · trusted"; glyph: "headphones"; quiet: true
                        IconButton { width: 28; height: 28; iconSize: 16; glyph: "delete" }
                        Btn { compact: true; outline: true; text: "Connect" } }
                }
            }
        }
        Timer { interval: 1500; running: true; onTriggered: sheet.grabToImage(r => { r.saveToFile(Quickshell.env("KIT_OUT") || "/tmp/kit-gallery.png"); Qt.quit(); }) }
        Component.onCompleted: Tokens.controlsCrate = Quickshell.env("KIT_CRATE") === "1"
    }
}
