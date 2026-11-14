import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import "ryoshot" as Ryoshot

// Ryoshot's chrome over a dim capture: the region bar, the annotation toolbar
// with a tool picked, the settings popover and a column of Beautify sliders
// (a plain range and a bipolar adjustment).
ShellRoot {
    FloatingWindow {
        implicitWidth: 1100
        implicitHeight: 620
        color: "#3a4048"

        Rectangle {
            id: sheet
            width: 1100
            height: 620
            gradient: Gradient {
                GradientStop { position: 0; color: "#46505c" }
                GradientStop { position: 1; color: "#23282e" }
            }

            Ryoshot.RegionBar {
                x: 40; y: 30
                actions: [
                    { id: "shot", icon: "camera", label: "Shot" }, { id: "edit", icon: "pen", label: "Edit" },
                    { id: "ocr", icon: "ocr", label: "OCR" }, { id: "record", icon: "video", label: "Record" }
                ]
                activeAction: "edit"
                micOn: true
                delaySeconds: 3
            }
            Ryoshot.Toolbar {
                x: 40; y: 110
                tools: [
                    { id: "select", icon: "select", label: "Select", key: "v" }, { id: "rect", icon: "rect", label: "Rectangle", key: "r" },
                    { id: "ellipse", icon: "ellipse", label: "Ellipse", key: "o" }, { id: "arrow", icon: "arrow", label: "Arrow", key: "a" },
                    { id: "pen", icon: "pen", label: "Pen", key: "p" }, { id: "text", icon: "text", label: "Text", key: "t" },
                    { id: "blur", icon: "blur", label: "Blur", key: "b" }, { id: "magnify", icon: "magnify", label: "Zoom", key: "z" }
                ]
                activeTool: "arrow"
                canUndo: true
            }
            Ryoshot.SettingsPanel { x: 40; y: 190; defaultChord: "Print" }
            Rectangle {
                x: 620; y: 190
                width: 320; height: 260
                radius: Tokens.controlsCrate ? Tokens.radius : 12
                color: Tokens.controlsCrate ? Tokens.popover : Tokens.paperLift
                Column {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 14
                    Ryoshot.Slider { width: parent.width; label: "Padding"; from: 0; to: 240; value: 96 }
                    Ryoshot.Slider { width: parent.width; label: "Roundness"; from: 0; to: 80; value: 24 }
                    Ryoshot.Slider { width: parent.width; label: "Brightness"; bipolar: true; from: -100; to: 100; value: -35 }
                    Ryoshot.Slider { width: parent.width; label: "Saturation"; bipolar: true; from: -100; to: 100; value: 40; suffix: "%" }
                }
            }
        }

        Timer {
            interval: Number(Quickshell.env("BENCH_WAIT") || 2000)
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
