import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import "modules/bar/barstyles/qsbar/panels"

// The QS Bar dashboard body in a card at the panel's 720 px width with the 16 px
// inset, fed a November day with weather, next to the same panel offline.
ShellRoot {
    component Day: QtObject {
        property string weekdayLong: "Friday"
        property string dateLong: "November 13"
        property string timeMain: "14:05"
        property string timeSecs: "09"
        property string ampm: ""
        property string monthTitle: "November 2026"
        property int monthOffset: 0
        property var weekdays: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
        property var cells: {
            const out = [];
            for (let i = 0; i < 6; i++) out.push({ day: 0, today: false });
            for (let d = 1; d <= 30; d++) out.push({ day: d, today: d === 13 });
            return out;
        }
        property int selectedDay: 20
        function selectDay(day) { selectedDay = day }
        function shiftMonth(delta) {}
        function resetMonth() {}
        property bool wxReady: true
        property bool wxLoading: false
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
    Day { id: sunny }
    Day { id: offline; wxReady: false; monthOffset: 1; monthTitle: "December 2026" }

    component Card: Rectangle {
        default property alias body: inner.data
        property real cardWidth: 720
        width: cardWidth
        height: inner.childrenRect.height + 32
        radius: 6
        color: Tokens.popover
        border.width: 1
        border.color: Tokens.line
        Item { id: inner; x: 16; y: 16; width: parent.width - 32 }
    }

    FloatingWindow {
        implicitWidth: 1488
        implicitHeight: 520
        color: Tokens.paper

        Rectangle {
            id: sheet
            width: 1488
            height: 520
            color: Tokens.paper
            Row {
                x: 16; y: 16
                spacing: 16
                Card { CrateDashboardDetails { width: parent.width; panel: sunny } }
                Card { CrateDashboardDetails { width: parent.width; panel: offline } }
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
        }
    }
}
