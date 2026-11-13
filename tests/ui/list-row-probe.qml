import QtQuick
import Quickshell
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons

// Loads the kit's list pieces (SignalBars, ListRow with trailing actions,
// SheetHeader) in the crate look and checks what each one shows.
ShellRoot {
    Item {
        width: 360
        height: 240

        Kit.SignalBars { id: bars; strength: 62; on: true }
        Kit.ListRow {
            id: row
            y: 20
            width: 360
            title: "Estudio"
            sub: "WPA3 · 71 %"
            on: true
            Kit.Btn { id: action; compact: true; outline: true; text: "Connect" }
        }
        Kit.SheetHeader {
            id: head
            y: 80
            width: 360
            title: "Wi-Fi"
            property int backs: 0
            onBackRequested: backs++
            Kit.Sw { id: radio; on: true }
        }
    }

    Timer {
        interval: 50
        running: true
        onTriggered: {
            Tokens.controlsCrate = true;
            if (bars.lit !== 3)
                throw new Error("62 % must light three bars, got " + bars.lit);
            if (action.parent === null || action.parent.parent !== row)
                throw new Error("ListRow must place its children in the trailing row");
            if (row.implicitHeight < 44)
                throw new Error("ListRow must be at least 44 px tall");
            if (radio.parent === null || radio.parent.parent !== head)
                throw new Error("SheetHeader must place its children in the trailing row");
            head.backRequested();
            if (head.backs !== 1)
                throw new Error("SheetHeader must signal back");
            if (action.implicitHeight !== 28)
                throw new Error("A compact crate Btn must be 28 px, got " + action.implicitHeight);
            console.log("LIST-ROW-PROBE-PASS");
            Qt.quit();
        }
    }
}
