import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import shell.services
import "modules/notifications"

// Two notification cards as the mock-up shows them: a normal one with two
// actions and a critical one with one. The notifications are plain objects
// with the fields NotificationCard reads.
ShellRoot {
    FloatingWindow {
        implicitWidth: 820
        implicitHeight: 260
        color: Tokens.paper

        Rectangle {
            id: sheet
            width: 820
            height: 260
            color: Tokens.paper

            Row {
                x: 20
                y: 20
                spacing: 20

                Repeater {
                    model: [
                        { appName: "Crate", summary: "Download complete", urgency: 1,
                          body: "Repion · Pronto is available offline.",
                          actions: [{ text: "Play", identifier: "play" }, { text: "Open in Crate", identifier: "open" }] },
                        { appName: "Battery", summary: "Battery at 5 %", urgency: 2,
                          body: "Plug in the charger; the computer suspends in 3 minutes.",
                          actions: [{ text: "Power saver", identifier: "save" }] }
                    ]

                    delegate: NotificationCard {
                        required property var modelData
                        width: 370
                        notif: ({
                            id: 0, appName: modelData.appName, summary: modelData.summary,
                            body: modelData.body, urgency: modelData.urgency, image: "", appIcon: "",
                            actions: modelData.actions.map(a => ({ text: a.text, identifier: a.identifier, invoke: () => {} }))
                        })
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
