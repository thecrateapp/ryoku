import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import "ryopin" as Ryopin

// Two pinned screenshots over a wallpaper, as ryopin floats them over the
// desktop: one with its action strip shown (the pointer over it), one at rest.
// The strip is chrome and, under crate, the one glass over the desktop.
ShellRoot {
    FloatingWindow {
        implicitWidth: 1200
        implicitHeight: 640
        color: Tokens.paper

        Item {
            id: sheet
            width: 1200
            height: 640

            Image {
                anchors.fill: parent
                source: "file://" + Quickshell.env("PIN_BACKDROP")
                fillMode: Image.PreserveAspectCrop
            }

            Ryopin.PinCard {
                x: 90; y: 90
                width: 512; height: 332
                path: Quickshell.env("PIN_SHOT")
                showStrip: true
            }
            Ryopin.PinCard {
                x: 700; y: 250
                width: 400; height: 262
                path: Quickshell.env("PIN_SHOT")
            }
        }

        Timer {
            interval: Number(Quickshell.env("BENCH_WAIT") || 2500)
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
