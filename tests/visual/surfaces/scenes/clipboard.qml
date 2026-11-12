import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import shell.services
import "modules/clipboard"

// Clipboard cards: a plain entry, a starred one, a selected one, and one
// hovered-looking selection with its corner controls.
ShellRoot {
    FloatingWindow {
        implicitWidth: 700
        implicitHeight: 300
        color: Tokens.popover

        Rectangle {
            id: sheet
            width: 700
            height: 300
            color: Tokens.popover

            Grid {
                x: 20
                y: 20
                columns: 2
                spacing: 16

                Repeater {
                    model: [
                        { id: 1, kind: "text", mime: "text/plain", size: 48, starred: false, selected: false,
                          preview: "git commit -m \"[ryoku] shell: crate clipboard\"" },
                        { id: 2, kind: "text", mime: "text/plain", size: 2048, starred: true, selected: false,
                          preview: "https://cratemusic.app/listen/album/repion-pronto" },
                        { id: 3, kind: "text", mime: "text/html", size: 512, starred: false, selected: true,
                          preview: "Copied from the Crate admin: 10,900 albums, 138K tracks" },
                        { id: 4, kind: "text", mime: "text/plain", size: 12, starred: true, selected: true,
                          preview: "innsmouth" }
                    ]

                    delegate: ClipboardCard {
                        required property var modelData
                        width: 322
                        entry: modelData
                        selected: modelData.selected
                    }
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
