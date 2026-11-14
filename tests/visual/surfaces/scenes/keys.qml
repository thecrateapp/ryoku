import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import "keys" as Keys
import "keys-hint" as Hint

// Kit (Super+K) at its full card size three times over the dimmed desktop: the
// Keys tab (head, search, tabs, the rail with its live category, the legend),
// the typing test (the toolbar's chips, the test's progress) and the dev tools
// (a tool's choice chips); then the first-boot hint's two cards over a
// wallpaper-like backdrop, where the crate glass shows.
ShellRoot {
    id: scene

    readonly property var categories: [
        { name: "Windows", binds: [
            { keys: ["Super", "Q"], desc: "Close window", hint: "Closes the focused window" },
            { keys: ["Super", "F"], desc: "Toggle fullscreen", hint: "" },
            { keys: ["Super", "V"], desc: "Toggle floating", hint: "" },
            { keys: ["Super", "Shift", "Left"], desc: "Move window left", hint: "" }
        ] },
        { name: "Workspaces", binds: [
            { keys: ["Super", "1"], desc: "Go to workspace 1", hint: "" },
            { keys: ["Super", "Shift", "1"], desc: "Send window to workspace 1", hint: "" }
        ] },
        { name: "Apps", binds: [
            { keys: ["Super", "Return"], desc: "Open terminal", hint: "" },
            { keys: ["Super", "Space"], desc: "Open launcher", hint: "" }
        ] }
    ]

    FloatingWindow {
        implicitWidth: 1340
        implicitHeight: 2860
        color: Tokens.paper

        Item {
            id: sheet
            width: 1340
            height: 2860

            Repeater {
                model: ["keys", "typing", "devtools"]
                delegate: Item {
                    id: frame
                    required property string modelData
                    required property int index
                    y: index * 880
                    width: 1340
                    height: 860
                    // the overlay's scrim over the desktop, as shell.qml draws it
                    Rectangle { anchors.fill: parent; color: Tokens.paper; opacity: 0.42 }
                    Keys.Kit {
                        anchors.fill: parent
                        categories: scene.categories
                        loaded: true
                        requestedTab: frame.modelData
                    }
                }
            }

            Rectangle {
                y: 2640
                width: 1340
                height: 220
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "#3b4a5c" }
                    GradientStop { position: 0.5; color: "#7a5a48" }
                    GradientStop { position: 1; color: "#26303a" }
                }
                Hint.HintCards {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: Tokens.s5
                }
            }
        }

        Timer {
            interval: Number(Quickshell.env("BENCH_WAIT") || 3000)
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
