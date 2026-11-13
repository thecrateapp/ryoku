import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import shell.services
import shell.modules.sidebar as Sidebar
import "shell/modules/bar/barstyles/qsbar/panels" as Panels

// Render the actual AI panel selector and the actual Controls overview. Both
// read identical sample data in each look. The graph and clock are disabled
// using the overview's regular visibility settings.
ShellRoot {
    id: scene
    readonly property string look: Quickshell.env("BENCH_LOOK")
    readonly property var week: [12, 40, 0, 80, 20, 60, 30].map((n, i) => ({
        date: "2026-11-" + ("0" + (7 + i)).slice(-2), tokens: n * 1000
    }))
    readonly property var sample: ({
        v2BarHeight: 8, aiBarX: 208, barPosition: "top", aiUsageReveal: 1, aiUsageVisible: true, aiRefreshing: false,
        panelRadius: 6, panelBorder: Tokens.line, panelOuterBorderColor: Tokens.line, panelOuterBorderW: 1,
        bg: Tokens.popover, ink: Tokens.ink, sumi: Tokens.inkDim, sumiHi: Tokens.inkMuted, sep: Tokens.line,
        green: "#8a9a73", seal: Tokens.sun, sealRaw: Tokens.alert, sectionInk: Tokens.caption, mono: Tokens.mono,
        pillShadow: "transparent", barShadowEnabled: false,
        aiClHas: true, aiClFresh: true, aiClPct5h: 34, aiClPct7d: 72,
        aiClReset5hTs: 1, aiClReset7dTs: 2, aiClRecent: week,
        aiCxHas: true, aiCxFresh: true, aiCxPct7d: 18, aiCxReset7dTs: 2, aiCxPrimaryPct: 9,
        aiCxPrimaryResetTs: 1, aiCxPlan: "Pro", aiCxWindows: [{label: "5h", minutes: 300, pct: 9, resetTs: 1}],
        aiCxRecent: week.slice().reverse().map((d, i) => ({date: week[i].date, tokens: d.tokens})),
        aiCxLimitStatus: "", aiCxLimitReachedType: "",
        aiOcHas: false, aiOcFresh: false, aiOcPct5h: 0, aiOcPct7d: 0, aiOcModel: "", aiOcPlan: "", aiOcModels: [], aiOcRecent: [],
        aiToolShown: id => id === "claude" || id === "codex",
        aiBehindPace: (pct, ts) => ts > 0 && pct > 45,
        aiExpectedPct: () => 55,
        aiFmtReset: t => t === 1 ? "2h 10m" : "2d 4h",
        aiPaceText: pct => pct > 45 ? (pct - 45) + "% behind pace" : (45 - pct) + "% ahead of pace",
        aiDayTokens: day => day.tokens, aiRecentTotal: days => days.reduce((total, d) => total + d.tokens, 0),
        aiRecentPeak: days => Math.max(...days.map(d => d.tokens)),
        aiTokenCount: count => Math.round(count / 1000) + "k", aiDayLabel: date => date.slice(-2),
        regenerateAiUsage: () => {}, setPanelInsetX: x => {}
    })

    Window {
        visible: true
        width: 752
        height: 640
        Rectangle {
            id: usage
            x: 0; y: 0; width: 416; height: 625
            color: Tokens.paper
            Panels.AiUsagePanel { id: panel; anchors.fill: parent; root: scene.sample }
        }
        Rectangle {
            id: controls
            x: 0; y: 0; width: 752; height: board.item ? board.item.implicitHeight + 40 : 0
            color: Tokens.popover
            visible: false
            Loader {
                id: board
                x: 20; y: 20; width: parent.width - 40
                active: false
                sourceComponent: Sidebar.ControlsBoard {
                    screen: null
                    active: true
                    s: 1
                }
            }
        }
    }
    function find(item, predicate) {
        if (predicate(item)) return item;
        for (const child of item.children || []) {
            const match = find(child, predicate);
            if (match) return match;
        }
        return null;
    }
    Timer {
        interval: 450
        running: true
        onTriggered: {
            if (Tokens.controlsCrate !== (scene.look === "crate") || panel.providers.length !== 2) {
                console.error("SHELL-STATES-FAIL theme or providers");
                Qt.quit();
                return;
            }
            const branch = scene.find(panel, item => scene.look === "crate" ? item.objectName === "aiCurve"
                : item.text === "Claude");
            if (!branch || !branch.visible) {
                console.error("SHELL-STATES-FAIL AI body", scene.look);
                Qt.quit();
                return;
            }
            usage.grabToImage(img => {
                if (!img.saveToFile("/output/shell-" + scene.look + "-ai-usage.png")) { Qt.quit(); return; }
                usage.visible = false;
                Config.controls = {sections: SidebarState.defaultSections.map(s => ({id: s.id, visible: s.id === "vitals"})),
                    hidden: ["identity", "liveGraph", "network"]};
                controls.visible = true;
                board.active = true;
                captureBoard.start();
            });
        }
    }
    Timer {
        id: captureBoard
        interval: 350
        onTriggered: {
            const memory = scene.find(board, item => item.label === "Memory" && item.visible);
            if (!memory || memory.progressValue !== 6.5 || controls.height < 70) {
                console.error("SHELL-STATES-FAIL Controls vitals");
                Qt.quit();
                return;
            }
            controls.grabToImage(img => {
                if (img.saveToFile("/output/shell-" + scene.look + "-controls-vitals.png"))
                    console.log("SHELL-STATES-DONE", scene.look);
                Qt.quit();
            });
        }
    }
}
