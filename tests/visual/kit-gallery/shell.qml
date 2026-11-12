import QtQuick
import Quickshell
import Ryoku.Ui
import Ryoku.Ui.Singletons

ShellRoot {
    FloatingWindow {
        implicitWidth: 560
        implicitHeight: 600
        color: Tokens.paper
        Rectangle {
            id: sheet
            width: 560; height: 600
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
            }
        }
        Timer { interval: 1500; running: true; onTriggered: sheet.grabToImage(r => { r.saveToFile(Quickshell.env("KIT_OUT") || "/tmp/kit-gallery.png"); Qt.quit(); }) }
        Component.onCompleted: Tokens.controlsCrate = Quickshell.env("KIT_CRATE") === "1"
    }
}
