import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import shell.services
import "modules/osd"

// The volume OSD as OsdWindow frames it: at 77 %, boosted to 120 % of a 150 %
// range, and muted.
ShellRoot {
    FloatingWindow {
        implicitWidth: 400
        implicitHeight: 260
        color: Tokens.paper

        Rectangle {
            id: sheet
            width: 400
            height: 260
            color: Tokens.paper

            Column {
                anchors.centerIn: parent
                spacing: 16

                Repeater {
                    model: [
                        { value: 0.77, max: 1, muted: false, icon: "audio-volume-high" },
                        { value: 1.2, max: 1.5, muted: false, icon: "audio-volume-high" },
                        { value: 0.4, max: 1, muted: true, icon: "audio-volume-muted" }
                    ]

                    delegate: Rectangle {
                        id: box
                        required property var modelData
                        readonly property real padY: Tokens.controlsCrate ? 14 : 16
                        width: osd.implicitWidth + 32
                        height: osd.implicitHeight + padY * 2
                        radius: Tokens.controlsCrate ? 10 : Theme.radiusWindow
                        color: Tokens.controlsCrate ? Tokens.popover : Theme.surface
                        border.width: Theme.borderWidth
                        border.color: Theme.frameLine

                        Osd {
                            id: osd
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            anchors.topMargin: box.padY
                            anchors.bottomMargin: box.padY
                            value: box.modelData.value
                            maxValue: box.modelData.max
                            muted: box.modelData.muted
                            iconName: box.modelData.icon
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
