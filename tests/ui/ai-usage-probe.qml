import QtQuick
import Quickshell
import Ryoku.Ui.Singletons

// Drives the QS Bar's crate AI usage body with a stand-in panel: a section per
// shown provider with its used share as a figure and a beam, the pace line, a
// seven-day chart scaled to its busiest day and the other limit windows; a
// provider behind pace turns to the alert; OpenCode's models list under it;
// refresh and close reach the panel; with no provider the panel says so.
ShellRoot {
    QtObject {
        id: theme
        property bool aiRefreshing: false
        property bool refreshed: false
        function aiBehindPace(pct, ts) { return ts > 0 && pct > 60 }
        function aiFmtReset(ts) { return "2d 4h" }
        function aiPaceText(pct, ts) { return ts > 0 ? (pct > 60 ? "8% behind pace" : "4% ahead of pace") : "" }
        function aiExpectedPct(ts) { return 55 }  // 45 % expected used today
        function aiDayTokens(d) { return Math.max(0, (d && d.tokens) || 0) }
        function aiRecentTotal(r) { let t = 0; for (const d of r) t += aiDayTokens(d); return t }
        function aiRecentPeak(r) { let p = 0; for (const d of r) p = Math.max(p, aiDayTokens(d)); return p }
        function aiTokenCount(n) { return Math.round(n / 1000) + "k" }
        function aiDayLabel(date) { return date.slice(-2) }
        function regenerateAiUsage() { refreshed = true }
    }
    QtObject {
        id: panel
        property var root: theme
        readonly property var week: [
            { date: "2026-11-07", tokens: 12000 }, { date: "2026-11-08", tokens: 40000 },
            { date: "2026-11-09", tokens: 0 }, { date: "2026-11-10", tokens: 80000 },
            { date: "2026-11-11", tokens: 20000 }, { date: "2026-11-12", tokens: 60000 },
            { date: "2026-11-13", tokens: 30000 }
        ]
        property var providers: [
            { id: "claude", name: "Claude", logo: "", tinted: false, markW: 18, markH: 18, has: true, fresh: true, plan: "",
              pct: 72, resetTs: 1, paceTs: 1, recent: week, extras: [{ label: "5h", pct: 34, resetTs: 1 }] },
            { id: "codex", name: "Codex", logo: "", tinted: true, markW: 18, markH: 18, has: true, fresh: false, plan: "Pro",
              pct: 18, resetTs: 1, paceTs: 1, recent: week, extras: [] },
            { id: "opencode", name: "OpenCode", logo: "", tinted: true, markW: 20, markH: 12, has: true, fresh: true, plan: "",
              pct: 40, resetTs: 0, paceTs: 0, recent: [], extras: [] }
        ]
        property var models: [
            { name: "claude-opus-5-5", totalLabel: "1.2M", inputLabel: "800k", outputLabel: "400k",
              reasoningLabel: "0", cacheReadLabel: "0", cacheWriteLabel: "0", todayLabel: "90k", pct: "64" }
        ]
    }

    Item {
        width: 288
        height: 900
        CrateAiUsageDetails {
            id: details
            width: 288
            height: 900
            panel: panel
            property bool closed: false
            onCloseRequested: closed = true
        }
    }

    function find(item, name) {
        if (!item) return null;
        if (item.objectName === name) return item;
        for (const child of item.children) {
            const hit = find(child, name);
            if (hit) return hit;
        }
        if (item.contentItem) return find(item.contentItem, name);
        return null;
    }

    Timer {
        interval: 150
        running: true
        onTriggered: {
            Tokens.controlsCrate = true;
            const claude = find(details, "ai-claude"), codex = find(details, "ai-codex");
            if (!claude || !codex || !find(details, "ai-opencode"))
                throw new Error("Every shown provider needs a section");
            if (find(claude, "aiPct").text !== "72%" || Math.abs(find(claude, "aiMeter").value - 0.72) > 0.001)
                throw new Error("The used share reads as a figure and a beam");
            if (Qt.colorEqual(find(claude, "aiPct").color, Tokens.alert) || Qt.colorEqual(find(codex, "aiPct").color, Tokens.alert))
                throw new Error("Nothing turns red: pace shows on the beam");
            const mark = find(claude, "aiPaceMark"), meter = find(claude, "aiMeter");
            if (!mark || !mark.visible || Math.abs(mark.x - meter.width * 0.45) > 1.5)
                throw new Error("The beam marks where use should be today, x " + (mark ? mark.x : "none"));
            if (!find(claude, "aiOverPace").visible || find(codex, "aiOverPace").visible)
                throw new Error("Only the share past today's mark shows, on a provider ahead of it");
            if (find(claude, "aiPace").text !== "8% behind pace")
                throw new Error("The pace line reads the panel");
            const curve = find(claude, "aiCurve");
            if (!curve || curve.points.length !== 7)
                throw new Error("The last seven days draw as a curve");
            const ys = curve.points.map(p => p[1]);
            if (Math.min(...ys) !== ys[3] || ys[2] !== curve.baseY)
                throw new Error("The busiest day peaks and an idle day sits on the baseline: " + ys);
            if (!find(claude, "aiWindow-5h"))
                throw new Error("The other limit windows list");
            if (find(codex, "aiStatus").text.indexOf("(stale)") < 0)
                throw new Error("A stale reading says so");
            if (!find(details, "aiModels").visible || !find(details, "aiModel-0"))
                throw new Error("OpenCode's models list");
            find(details, "aiRefresh").clicked();
            if (!theme.refreshed)
                throw new Error("Refresh regenerates the usage");
            panel.providers = [];
            panel.models = [];
            if (!find(details, "aiEmpty").visible || find(details, "ai-claude"))
                throw new Error("With no provider the panel says so");
            find(details, "closeAiUsage").clicked();
            if (!details.closed)
                throw new Error("Close must ask to close");
            console.log("AI-USAGE-PROBE-PASS");
            Qt.quit();
        }
    }
}
