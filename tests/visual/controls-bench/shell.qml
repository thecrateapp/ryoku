import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import shell.modules.sidebar

// The Controls panel's board, loaded from the checkout, on the panel's surface.
// render.sh drives it; BENCH_OUT is the PNG, BENCH_WAIT the ms to let the live
// readings and the graph fill, BENCH_CRATE "1"/"0" forces a look.
ShellRoot {
    FloatingWindow {
        implicitWidth: 688
        implicitHeight: Math.max(200, sheet.height)
        color: Tokens.popover

        Rectangle {
            id: sheet
            width: 688
            height: board.implicitHeight + 32
            color: Tokens.popover

            ControlsBoard {
                id: board
                x: 16
                y: 16
                width: 656
                s: 1
                screen: Quickshell.screens[0]
                active: true
            }
        }

        Timer {
            interval: Number(Quickshell.env("BENCH_WAIT") || 4000)
            running: true
            onTriggered: sheet.grabToImage(r => {
                r.saveToFile(Quickshell.env("BENCH_OUT") || "/tmp/controls-bench.png");
                Qt.quit();
            })
        }

        Component.onCompleted: {
            const look = Quickshell.env("BENCH_CRATE");
            if (look === "1" || look === "0")
                Tokens.controlsCrate = look === "1";
        }
    }
}
