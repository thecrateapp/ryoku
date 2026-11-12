import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import shell.services
import "modules/bar"

// The administrator (polkit) and keyring prompts as their islands draw them,
// with the services idle, so the default copy shows.
ShellRoot {
    FloatingWindow {
        implicitWidth: 800
        implicitHeight: 340
        color: Tokens.paper

        Rectangle {
            id: sheet
            width: 800
            height: 340
            color: Tokens.paper

            // a PillSurface fills its host and lays out at its open size
            Rectangle {
                x: 20; y: 20; width: 370; height: 300
                radius: 10
                color: Tokens.popover
                PolkitSurface { open: true; shown: true; openProgress: 1; openW: 370; openH: 300 }
            }
            Rectangle {
                x: 410; y: 20; width: 370; height: 300
                radius: 10
                color: Tokens.popover
                KeyringSurface { open: true; shown: true; openProgress: 1; openW: 370; openH: 300 }
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
