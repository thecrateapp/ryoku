import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import shell.services
import "modules/sidebar"

// The Controls volume drawer (outputs, playing apps, recording, microphones)
// with the live audio graph, at the panel's 656 px content width.
ShellRoot {
    FloatingWindow {
        implicitWidth: 688
        implicitHeight: 520
        color: Tokens.popover

        Rectangle {
            id: sheet
            width: 688
            height: Math.max(120, drawer.implicitHeight + 32)
            color: Tokens.popover

            MixerDrawer {
                id: drawer
                x: 16
                y: 16
                width: 656
                s: 1
                active: true
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
