import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import "welcome" as Welcome

// The Welcome at its full window size twice: the bar step (the step rail with
// its progress, the page head, the bar cards) and the make-it-yours step.
ShellRoot {
    FloatingWindow {
        implicitWidth: 1180
        implicitHeight: 1544
        color: Tokens.controlsCrate ? Tokens.popover : Tokens.paper

        Item {
            id: sheet
            width: 1180
            height: 1544
            Welcome.Welcome { id: bars; width: 1180; height: 760; step: 1 }
            Welcome.Welcome { id: make; y: 784; width: 1180; height: 760; step: 2 }
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
