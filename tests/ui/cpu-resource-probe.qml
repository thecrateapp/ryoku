import QtQuick
import QtTest as Test
import Quickshell
import Ryoku.Ui.Singletons
import "bar/panels" as Panels

ShellRoot {
    id: fixture
    QtObject {
        id: theme
        property bool cpuVisible: true
        property bool systemCpuAvailable: true
        property bool systemLoadAvailable: true
        property int systemCpuPercent: 35
        property int systemCpuUserPercent: 19
        property int systemCpuSystemPercent: 16
        property int systemCpuIoWaitPercent: 2
        property string cpuModelName: "Ryzen test processor"
        property int cpuClockMHz: 2350
        property int cpuMaxClockMHz: 4300
        property int cpuThrottleCount: 5
        property string kernelRelease: "6.17-test"
        property var cpuTopProcesses: [
            { name: "musicPlayer", percent: 123.5 },
            { name: "Decoder", percent: 3.0 }
        ]
    }
    QtObject {
        id: panel
        readonly property var root: theme
        readonly property bool visible: theme.cpuVisible
        readonly property int cpuPct: theme.systemCpuPercent
        property string topologySummary: "8C / 16T"
        property string loadSummary: "0.42 · 0.34 · 0.23"
        property string powerMode: "balance performance"
    }

    FloatingWindow {
        implicitWidth: 340
        implicitHeight: 700
        Test.TestCase { id: input; when: false }
        Panels.CrateCpuDetails {
            id: details
            x: 16; y: 16
            width: 288
            cpu: panel
            availableHeight: 680
            property int launches: 0
            onCloseRequested: theme.cpuVisible = false
            onBtopRequested: launches++
        }
    }

    function check(ok, reason) {
        if (!ok) throw Error(reason)
    }
    function findRow(item, label) {
        if (!item.visible) return null
        if (item.label === label && item.valueText !== undefined) return item
        for (const child of item.children) {
            const match = findRow(child, label)
            if (match) return match
        }
        return null
    }
    function hasText(item, text) {
        return item.visible && (item.text === text || item.children.some(child => hasText(child, text)))
    }

    Timer {
        interval: 200
        running: true
        onTriggered: {
            try {
                Tokens.controlsCrate = true
                input.wait(80)
                const summary = input.findChild(details, "cpuSummary")
                const spark = input.findChild(details, "cpuHistory")
                const close = input.findChild(details, "closeCpu")
                const action = input.findChild(details, "openCpuMonitor")
                fixture.check(summary.hasReading && fixture.hasText(summary, "35%")
                    && summary.caption === theme.cpuModelName, "measured CPU usage and processor")
                fixture.check(spark.visible && spark.active && spark._buf.length, "history samples while open")
                for (const [label, value] of [
                    ["Cores", "8C / 16T"], ["Clock", "2.4 GHz"], ["Load 1 · 5 · 15", panel.loadSummary],
                    ["USER", "19%"], ["System", "16%"], ["I/O wait", "2%"], ["Kernel", "6.17-test"],
                    ["Power mode", panel.powerMode], ["Throttling", "5 events"], ["01", "musicPlayer"], ["02", "Decoder"]
                ]) {
                    const row = fixture.findRow(details, label)
                    fixture.check(row && row.height === 24 && row.valuePixelSize === 12 && row.valueText === value,
                        "readout " + label + ": " + value)
                }
                const clock = fixture.findRow(details, "Clock")
                const first = fixture.findRow(details, "01")
                const second = fixture.findRow(details, "02")
                fixture.check(clock.secondary === "4.3 GHz max", "maximum clock")
                fixture.check(first.secondary === "123.5%" && second.secondary === "3.0%"
                    && first.secondaryWidth > 0 && first.secondaryWidth === second.secondaryWidth,
                    "per-process readings aligned, including multicore percentages")
                const view = input.findChild(details, "cpuDetailsViewport")
                fixture.check(!view.interactive, "full-size display needs no scrolling")
                details.availableHeight = 380
                input.wait(40)
                fixture.check(details.height <= 380 && view.interactive
                    && close.mapToItem(details, 0, 0).y >= 0
                    && action.mapToItem(details, 0, action.height).y <= 380,
                    "short display keeps close and btop visible")
                view.forceActiveFocus()
                input.keyClick(Qt.Key_PageDown)
                fixture.check(view.contentY > 0, "keyboard reaches the last processes")
                input.keyClick(Qt.Key_PageUp)
                fixture.check(view.contentY === 0, "keyboard returns to summary")
                details.availableHeight = 680
                theme.cpuMaxClockMHz = 0
                fixture.check(clock.visible && clock.secondary === "", "current clock without a published maximum")
                theme.systemCpuPercent = 0
                fixture.check(summary.hasReading && fixture.hasText(summary, "0%") && spark.active, "measured idle")
                theme.systemCpuAvailable = false
                input.wait(30)
                fixture.check(fixture.hasText(summary, "No data") && fixture.hasText(summary, "\u2014")
                    && !fixture.findRow(details, "USER") && !spark.visible && !spark.active && !spark._buf.length,
                    "missing CPU interval hides usage, breakdown and history")
                fixture.check(fixture.findRow(details, "Load 1 · 5 · 15") !== null, "load remains independently available")
                theme.systemLoadAvailable = false
                theme.cpuClockMHz = 0
                theme.cpuThrottleCount = 0
                theme.kernelRelease = ""
                theme.cpuTopProcesses = []
                panel.powerMode = ""
                panel.topologySummary = ""
                theme.cpuModelName = ""
                input.wait(30)
                for (const label of ["Cores", "Clock", "Load 1 · 5 · 15", "Kernel", "Power mode", "Throttling", "01"])
                    fixture.check(!fixture.findRow(details, label), "no stale " + label)
                fixture.check(fixture.hasText(details, "Collecting…"), "empty process list")
                theme.systemCpuAvailable = true
                panel.loadSummary = "0.00 · 0.00 · 0.00"
                theme.systemLoadAvailable = true
                fixture.check(summary.hasReading && fixture.hasText(summary, "0%")
                    && fixture.findRow(details, "Load 1 · 5 · 15").valueText === panel.loadSummary, "sampling recovers at zero")
                fixture.check(action.outline, "outline monitor action")
                action.forceActiveFocus()
                input.keyClick(Qt.Key_Space)
                fixture.check(details.launches === 1, "btop keyboard action")
                fixture.check(close.width === 32 && close.height === 32, "32 px close action")
                input.mouseClick(close)
                fixture.check(!theme.cpuVisible && !spark.active, "close stops history")
                console.log("CPU-RESOURCE-PROBE-PASS")
            } catch (error) {
                console.error("CPU-RESOURCE-PROBE-FAIL", error)
            }
            Qt.quit()
        }
    }
}
