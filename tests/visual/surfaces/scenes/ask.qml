import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import shell.services
import "modules/ask"
import "services" as Services

// The Ask bar (Rashin's question bar) and its pinned bubble. AskBar and
// AskBubble map layer-shell windows, so the scene lays out what they hold: the
// bar with an answer and its actions, the bar working with the route drawer
// open, the Tools mode with a download running, the file picker, and the
// bubble's chat card, disc and remove target. A colour band behind the left
// column shows the glass through which the compositor's frost would read.
ShellRoot {
    id: scene

    readonly property bool crate: Quickshell.env("BENCH_CRATE") === "1"
    // scenes/ask.bin leads PATH; its sibling ask.files is what the picker lists
    readonly property string files: String(Quickshell.env("PATH") || "").split(":")[0].replace(/\.bin$/, ".files")

    Services.AskSession { id: answered }
    Services.AskSession { id: working }
    Services.AskSession { id: toolsSession }

    function convoRow(fields) {
        const row = {
            kind: "msg", key: String(Needle.convo.count), role: "", body: "", thought: "", open: false, live: false,
            cont: false, failed: false, imagesJson: "[]", toolId: "", title: "", tkind: "", status: "", input: "",
            output: "", diffsJson: "[]", auto: false, permJson: "", askId: "", question: "", answer: ""
        };
        for (const key in fields)
            row[key] = fields[key];
        Needle.convo.append(row);
    }

    FloatingWindow {
        implicitWidth: 1840
        implicitHeight: 1160
        color: Tokens.paper

        Rectangle {
            id: sheet
            width: 1840
            height: 1160
            color: Tokens.paper

            Rectangle {
                x: 0
                y: 120
                width: 1840
                height: 90
                opacity: 0.55
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Tokens.sun }
                    GradientStop { position: 1; color: Tokens.sunHi }
                }
            }

            AskSurface {
                id: askBar
                x: 20
                y: 20
                width: 640
                s: 1
                screen: Quickshell.screens[0]
                session: answered
                active: true
                query: "What is the Crate accent?"
                maximumHeight: 420
            }

            AskSurface {
                id: workingBar
                x: 700
                y: 20
                width: 640
                s: 1
                screen: Quickshell.screens[0]
                session: working
                active: true
                query: "Summarise my week"
                maximumHeight: 380
            }

            AskSurface {
                id: toolsBar
                x: 20
                y: 440
                width: 640
                s: 1
                screen: Quickshell.screens[0]
                session: toolsSession
                active: true
                mode: "tools"
                maximumHeight: 700
            }

            AskFilePicker {
                id: picker
                x: 700
                y: 440
                width: 640
                s: 1
            }

            AskBubbleCard {
                x: 1380
                y: 20
                width: 440
                height: 560
                s: 1
                AskChat {
                    anchors.fill: parent
                    anchors.margins: Tokens.s4
                    s: 1
                    active: true
                    maximumHeight: 528
                }
            }

            AskHandoffCard {
                x: 1380
                y: 600
                width: 440
                s: 1
                question: "Which kernel am I on?"
                answer: "7.3.4-1-cachyos, built with the BORE scheduler."
            }

            AskBubbleDisc {
                x: 1380
                y: 720
                width: 56
                height: 56
                s: 1
                shown: true
                unread: true
            }

            AskDismissTarget { x: 1460; y: 721; s: 1; armed: true; overDismiss: false }
            AskDismissTarget { x: 1620; y: 721; s: 1; armed: true; overDismiss: true }
        }

        // The chat re-projects an empty transcript as it opens, so the rows land
        // after it; the drawer opens once the stub's routes have arrived.
        Timer {
            interval: 300
            running: true
            onTriggered: {
                scene.convoRow({ role: "user", body: "Which kernel am I on?" });
                scene.convoRow({ kind: "tool", toolId: "t1", title: "uname -r", tkind: "execute", status: "running" });
                scene.convoRow({ role: "agent", body: "You are on **7.3.4-1-cachyos**, with the BORE scheduler." });
                scene.convoRow({ kind: "tool", toolId: "t2", title: "Read /etc/os-release", tkind: "read", status: "completed" });
                picker.open = true;
                workingBar.toggleModel();
            }
        }
        Timer {
            interval: 700
            running: true
            onTriggered: {
                picker.folder = "file://" + scene.files;
                picker.toggle(scene.files + "/clip.mp4");
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
            if (look === "1") {
                // the Crate theme's style flags (crate-for-ryoku theme/crate)
                Tokens.accentMarks = true;
                Tokens.labelAccent = true;
                Tokens.focusAccent = true;
                Tokens.selectFill = false;
                Tokens.lineAlpha = 0.1;
            }
            answered.phase = "done";
            answered.askedQuestion = "What is the Crate accent?";
            answered.answerText = "The Crate accent is cyan, #06b6d4, with a brighter tone for marks.";
            answered.answerActions = [{ kind: "color", value: "#06b6d4", label: "#06b6d4" }];
            working.phase = "working";
            working.working = "Thinking";
            Stash.queueModel.append({ kind: "download", arg: "https://example.org/v", mode: "auto", name: "ambient-set.webm",
                title: "", state: "running", pct: 42, msg: "", saved: false, fmt: "", key: "" });
            Stash.queueModel.append({ kind: "download", arg: "https://example.org/w", mode: "audio", name: "live-at-the-roundhouse.opus",
                title: "", state: "error", pct: 0, msg: "Unsupported URL", saved: false, fmt: "", key: "" });
        }
    }
}
