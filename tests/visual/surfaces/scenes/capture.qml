import QtQuick
import Quickshell
import Ryoku.Ui
import Ryoku.Ui.Singletons
import shell.services
import "modules/capture"

// The capture overlays over a busy desktop (a dark and a light window on a
// gradient, so every tag is seen over both): a region being dragged with its
// size readout, a hovered window, the camera bubble with its handles (the
// radius and the size readouts), and a region recording's dim around the
// keypress stack with its placement chrome. Each is the Item its layer window
// hosts, since a layer window needs a compositor.
ShellRoot {
    FloatingWindow {
        implicitWidth: 1280
        implicitHeight: 760
        color: Tokens.paper

        Item {
            id: sheet
            width: 1280
            height: 760

            component Desk: Item {
                clip: true
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: "#1b2333" }
                        GradientStop { position: 0.55; color: "#5d7f9c" }
                        GradientStop { position: 1; color: "#efe9df" }
                    }
                }
                Rectangle {
                    x: 30; y: 40; width: 300; height: 240
                    color: "#16171c"
                    Column {
                        x: 16; y: 16; spacing: 10
                        Repeater {
                            model: 9
                            Rectangle { required property int index; width: 140 + (index * 37) % 120; height: 8; color: "#3d4250" }
                        }
                    }
                }
                Rectangle {
                    x: 340; y: 120; width: 280; height: 230
                    color: "#fbfaf7"
                    Column {
                        x: 16; y: 16; spacing: 10
                        Repeater {
                            model: 9
                            Rectangle { required property int index; width: 120 + (index * 53) % 130; height: 8; color: "#c9c4ba" }
                        }
                    }
                }
            }

            // a region being dragged across both windows
            Desk {
                x: 0; y: 0; width: 640; height: 380
                CaptureFrame {
                    anchors.fill: parent
                    sel: "region"
                    hasRect: true
                    hlx: 150; hly: 70; hlw: 330; hlh: 190
                }
            }
            // a hovered window, picked whole
            Desk {
                x: 640; y: 0; width: 640; height: 380
                CaptureFrame {
                    anchors.fill: parent
                    sel: "window"
                    hasRect: true
                    hlx: 340; hly: 120; hlw: 280; hlh: 230
                }
            }
            // the camera bubble, hovered: the radius readout on one, the size on the other
            Desk {
                x: 0; y: 380; width: 640; height: 380
                Repeater {
                    model: [
                        { x: 60, y: 70, w: 220, h: 220, round: 0.28, mode: "round" },
                        { x: 360, y: 80, w: 240, h: 200, round: 1, mode: "resize" }
                    ]
                    Item {
                        id: bub
                        required property var modelData
                        x: modelData.x; y: modelData.y
                        width: modelData.w; height: modelData.h
                        readonly property real rad: modelData.round * Math.min(width, height) / 2
                        CameraFace { anchors.fill: parent; rad: bub.rad }
                        CameraHandles { anchors.fill: parent; mode: bub.modelData.mode }
                    }
                }
            }
            // a region recording: the dim around the box, the keypress stack inside it
            Desk {
                x: 640; y: 380; width: 640; height: 380
                RegionDim {
                    anchors.fill: parent
                    bx: 70; by: 50; bw: 500; bh: 280
                }
                KeypressStack {
                    id: keys
                    x: 320 - implicitWidth / 2
                    y: 250 - implicitHeight / 2
                    width: implicitWidth
                    height: implicitHeight
                    preview: true
                    motionEnabled: false
                }
                KeypressPlacement {
                    anchors.fill: keys
                    anchors.margins: -10
                    shown: true
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
            // the Crate theme's switches (hub-fixture/crate.json), so the crate
            // look shows its mark, its hairline and its mono face
            if (look === "1") {
                Tokens.accentMarks = true;
                Tokens.selectFill = false;
                Tokens.labelAccent = true;
                Tokens.compact = true;
                Tokens.lineAlpha = 0.1;
                Tokens.mono = "JetBrainsMono Nerd Font";
            }
        }
    }
}
