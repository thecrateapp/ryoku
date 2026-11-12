import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import shell.services
import "modules/sidebar"
import "modules/sidebar/cards"

// The Controls panel's Wi-Fi and Bluetooth pages with the live adapters, and
// the settings popup opened beside them.
ShellRoot {
    FloatingWindow {
        implicitWidth: 1720
        implicitHeight: 900
        color: Tokens.popover

        Rectangle {
            id: sheet
            width: 1720
            height: 900
            color: Tokens.popover

            SystemWifiPage { x: 16; y: 16; width: 560; height: 860; s: 1; active: true }
            SystemBluetoothPage { x: 592; y: 16; width: 560; height: 860; s: 1; active: true }

            Item {
                x: 1168
                y: 16
                width: 536
                height: 860
                ControlsSettingsPopup {
                    id: popup
                    s: 1
                    active: true
                    Component.onCompleted: popup.open()
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
