import QtQuick
import Quickshell
import Ryoku.Ui
import Ryoku.Ui.Singletons
import "modules/launcher/shared/lib/results.js" as Results
import "modules/launcher/variants/hero" as Hero

// The hero launcher (Super+Space) over a busy desktop: at rest (the hero art,
// the search, the modes), and open on a query with the lead result, the action
// shelf (Ctrl+K), the ledger with its picked row, and the window rail under the
// card with its focused tile. Each is the Item its layer window hosts, since a
// layer window needs a compositor; the glass shows the desktop unfrosted here.
ShellRoot {
    FloatingWindow {
        implicitWidth: 1560
        implicitHeight: 860
        color: Tokens.paper

        Item {
            id: sheet
            width: 1560
            height: 860

            // the results arrive after the drawer opens, as a query's do
            property bool arrived: false
            Timer { interval: 200; running: true; onTriggered: sheet.arrived = true }

            readonly property var actions: [
                { id: "new-window", name: "New Window", enabled: true },
                { id: "private", name: "New Private Window", enabled: true },
                { id: "profile", name: "Profile Manager", enabled: true }
            ]
            readonly property var rows: [
                { resultKey: "apps:firefox", providerId: "apps", type: "App", title: "Firefox", icon: "",
                  subtitle: "Web browser", primaryAction: { id: "open", name: "Open" },
                  secondaryActions: sheet.actions },
                { resultKey: "apps:files", providerId: "apps", type: "App", title: "Files", icon: "",
                  subtitle: "File manager", primaryAction: { id: "open", name: "Open" }, secondaryActions: [] },
                { resultKey: "find:fire", providerId: "find", type: "File", title: "fire-drill.md", icon: "",
                  subtitle: "~/notes/fire-drill.md", primaryAction: { id: "open", name: "Open" }, secondaryActions: [] },
                { resultKey: "recent:fireworks", providerId: "recent", type: "Image", title: "fireworks.jpg", icon: "",
                  subtitle: "~/Pictures", primaryAction: { id: "open", name: "Open" }, secondaryActions: [] },
                { resultKey: "web:fire", providerId: "web", type: "Web", title: "Search the web for fire", icon: "",
                  subtitle: "duckduckgo.com", primaryAction: { id: "open", name: "Open" }, secondaryActions: [] },
                { resultKey: "apps:firewall", providerId: "apps", type: "App", title: "Firewall", icon: "",
                  subtitle: "Network rules", primaryAction: { id: "open", name: "Open" }, secondaryActions: [] }
            ]

            // the desktop behind the cards
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "#1b2333" }
                    GradientStop { position: 0.55; color: "#5d7f9c" }
                    GradientStop { position: 1; color: "#efe9df" }
                }
            }
            Rectangle {
                x: 980; y: 60; width: 520; height: 520
                color: "#fbfaf7"
                Column {
                    x: 20; y: 20; spacing: 12
                    Repeater {
                        model: 24
                        Rectangle { required property int index; width: 200 + (index * 53) % 260; height: 8; color: "#c9c4ba" }
                    }
                }
            }

            // at rest
            Hero.LauncherCard {
                x: 40
                y: 40
                width: 720
                height: 250
                s: 1
                longRadius: 16
                shortRadius: 3

                Hero.HeroShutter {
                    width: 720
                    height: 250
                    s: 1
                    shown: false
                }
            }

            // open on "fire": the lead, the shelf, the ledger
            Hero.LauncherCard {
                id: openCard
                x: 800
                y: 40
                width: 720
                height: 126 + drawer.height
                s: 1
                longRadius: 16
                shortRadius: 3

                Hero.HeroShutter {
                    id: hero
                    width: 720
                    height: 126
                    s: 1
                    compressed: true
                    activeMode: "all"
                    shown: false
                    Component.onCompleted: query = "fire"
                }
                Hero.ResultDrawer {
                    id: drawer
                    y: 126
                    width: 720
                    s: 1
                    open: true
                    animationsEnabled: false
                    maxHeight: 520
                    results: sheet.arrived ? sheet.rows : []
                    selectedResult: sheet.arrived ? sheet.rows[0] : null
                    selectedResultKey: sheet.rows[0].resultKey
                    shelfOpen: true
                    secondaryActions: sheet.actions
                    packedLayout: Results.packActions(sheet.actions)
                    focusedActionId: "private"
                    windowCount: 2
                    windowFocusActive: true
                }
            }

            // the window rail under the open card
            Row {
                x: 816
                y: openCard.y + openCard.height + 22
                spacing: 7
                Hero.WindowTile { s: 1; title: "Firefox - Release notes"; cls: "firefox"; workspace: "2"; picked: true }
                Hero.WindowTile { s: 1; title: "Firefox - Mail"; cls: "firefox"; workspace: "3" }
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
            // the Crate theme's switches (hub-fixture/crate.json), so the crate
            // look shows its mark, its hairline and its mono face
            if (look === "1") {
                Tokens.accentMarks = true;
                Tokens.selectFill = false;
                Tokens.labelAccent = true;
                Tokens.compact = true;
                Tokens.lineAlpha = 0.1;
                Tokens.mono = "JetBrainsMono Nerd Font";
            }
        }
    }
}
