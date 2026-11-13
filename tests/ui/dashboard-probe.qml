import QtQuick
import Quickshell
import Ryoku.Ui.Singletons

// Drives the QS Bar's crate dashboard body with a stand-in panel: the month grid
// with today filled and a picked day edged, month navigation, the weather in its
// loading, offline and ready states, the hourly curve with its head on now, and
// the close button.
ShellRoot {
    QtObject {
        id: panel
        property string weekdayLong: "Friday"
        property string dateLong: "November 13"
        property string timeMain: "14:05"
        property string timeSecs: "09"
        property string ampm: ""
        property string monthTitle: "November 2026"
        property int monthOffset: 0
        property var weekdays: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
        // November 2026 starts on a Sunday: six leading blanks
        property var cells: {
            const out = [];
            for (let i = 0; i < 6; i++) out.push({ day: 0, today: false });
            for (let d = 1; d <= 30; d++) out.push({ day: d, today: d === 13 });
            return out;
        }
        property int selectedDay: 0
        property int shifted: 0
        property bool reset: false
        function selectDay(day) { selectedDay = day }
        function shiftMonth(delta) { shifted += delta }
        function resetMonth() { reset = true }
        property bool wxReady: false
        property bool wxLoading: true
        property string temperature: "17°"
        property string condition: "Partly cloudy"
        property string area: "Gipuzkoa, Spain"
        property string symbol: "partly_cloudy_day"
        property var readouts: [
            { label: "Wind", value: "12 km/h NE" }, { label: "Humidity", value: "71%" },
            { label: "Rain", value: "20%" }, { label: "Feels", value: "16°" }
        ]
        property var hourly: [
            { time: "14:00", temp: 17, symbol: "partly_cloudy_day" }, { time: "15:00", temp: 18, symbol: "clear_day" },
            { time: "16:00", temp: 18, symbol: "clear_day" }, { time: "17:00", temp: 16, symbol: "cloud" },
            { time: "18:00", temp: 14, symbol: "rainy" }, { time: "19:00", temp: 13, symbol: "rainy" },
            { time: "20:00", temp: 12, symbol: "clear_night" }, { time: "21:00", temp: 11, symbol: "clear_night" }
        ]
    }

    Item {
        width: 688
        height: 600
        CrateDashboardDetails {
            id: details
            width: 688
            panel: panel
            onCloseRequested: closed = true
            property bool closed: false
        }
    }

    function find(item, name) {
        if (!item) return null;
        if (item.objectName === name) return item;
        for (const child of item.children) {
            const hit = find(child, name);
            if (hit) return hit;
        }
        return null;
    }
    function texts(item, out) {
        if (item.text !== undefined && item.visible) out.push(String(item.text));
        for (const child of item.children) texts(child, out);
        return out;
    }
    function fill(cell) {
        for (const child of cell.children)
            if (child.radius !== undefined && child.border) return child;
        return null;
    }

    Timer {
        interval: 150
        running: true
        onTriggered: {
            Tokens.controlsCrate = true;
            const all = texts(details, []);
            if (all.indexOf("Friday · November 13") < 0)
                throw new Error("The header must name the day, got " + all.slice(0, 4));
            for (const d of ["Mo", "Su"])
                if (all.indexOf(d) < 0) throw new Error("Weekday " + d + " is missing");

            // today is filled with the mark; picking another day edges it
            const today = find(details, "day-13");
            if (!today || !today.today) throw new Error("Day 13 must be today");
            if (!Qt.colorEqual(fill(today).color, Tokens.mark))
                throw new Error("Today must be filled with the mark");
            const day20 = find(details, "day-20");
            if (!day20 || day20.picked) throw new Error("No day is picked yet");
            panel.selectDay(20);
            if (!day20.picked || fill(day20).border.width !== 1 || !Qt.colorEqual(fill(day20).border.color, Tokens.pickEdge))
                throw new Error("A picked day takes the pick edge");
            if (find(details, "day-31")) throw new Error("November has 30 days");

            // month navigation
            find(details, "monthPrev").clicked();
            find(details, "monthNext").clicked();
            find(details, "monthNext").clicked();
            if (panel.shifted !== 1) throw new Error("The arrows must shift the month, net " + panel.shifted);
            const title = find(details, "monthTitle");
            if (title.tone !== "accent") throw new Error("The current month reads in the accent tone");
            panel.monthOffset = 1;
            if (title.tone !== "active") throw new Error("Away from today the month title is live");
            if (day20.picked) throw new Error("A picked day only shows in the current month");
            panel.monthOffset = 0;

            // weather: loading, then offline, then ready
            const cond = find(details, "dashboardCondition");
            if (cond.text !== "Loading…") throw new Error("Loading must say so, got " + cond.text);
            if (find(details, "dashboardReadouts").visible || find(details, "hourCurve").visible)
                throw new Error("No readouts or curve before the weather arrives");
            panel.wxLoading = false;
            if (cond.text !== "Weather offline") throw new Error("Offline must say so, got " + cond.text);
            panel.wxReady = true;
            if (cond.text !== "Partly cloudy") throw new Error("The condition must show, got " + cond.text);
            const readouts = find(details, "dashboardReadouts");
            if (!readouts.visible) throw new Error("The readouts show with the weather");
            const shown = texts(readouts, []);
            for (const v of ["12 km/h NE", "71%", "20%", "16°"])
                if (shown.indexOf(v) < 0) throw new Error("Readout " + v + " is missing from " + shown);

            // the hourly curve: drawn, its head on the first (current) hour
            const curve = find(details, "hourCurve");
            if (!curve.visible || curve.points.length !== 8)
                throw new Error("The curve draws every hour, got " + curve.points.length);
            const head = find(details, "hourHead");
            if (Math.abs(head.x + 4 - curve.points[0][0]) > 0.5)
                throw new Error("The head dot sits on the current hour");
            const warmest = curve.points[1][1], coldest = curve.points[7][1];
            if (!(warmest < coldest)) throw new Error("A warmer hour draws higher");
            for (const p of curve.points)
                if (p[0] < 0 || p[0] > curve.width || p[1] < 0 || p[1] > curve.height)
                    throw new Error("A point leaves the curve box: " + p);
            panel.hourly = panel.hourly.slice(0, 1);
            if (curve.visible) throw new Error("One hour is not a curve");
            panel.hourly = [];

            // the two columns fit the panel
            const month = find(details, "dashboardMonth");
            if (month.width + 1 > details.width / 2)
                throw new Error("The month must leave room for the weather");

            find(details, "closeDashboard").clicked();
            if (!details.closed) throw new Error("The close button must ask to close");
            console.log("DASHBOARD-PROBE-PASS");
            Qt.quit();
        }
    }
}
