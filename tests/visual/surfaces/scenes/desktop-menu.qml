import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import "modules/desktop"

// The desktop and dock menus' primitives: a section, sliders and a chip row,
// at a menu's width.
ShellRoot {
    FloatingWindow {
        implicitWidth: 360
        implicitHeight: 260
        color: Tokens.popover

        Rectangle {
            id: sheet
            width: 360
            height: 260
            color: Tokens.popover

            Column {
                x: 12
                y: 12
                width: 336
                spacing: 6

                MenuSection { label: "Widget" }
                MenuSlider { label: "Opacity"; value: 0.72; decimals: 2 }
                MenuSlider { label: "Scale"; from: 0.5; to: 2; value: 1.25; decimals: 2 }
                MenuSection { label: "Placement" }
                Flow {
                    width: parent.width
                    spacing: 6
                    MenuChip { label: "Free"; selected: true }
                    MenuChip { label: "Grid" }
                    MenuChip { label: "Edge" }
                    MenuChip { label: "Center" }
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
