import QtQuick
import QtTest as Test
import Quickshell
import Ryoku.Ui.Singletons
import "bar/panels" as Panels

ShellRoot {
    id: fixture

    QtObject {
        id: theme
        property bool gpuVisible: true
        property string gpuBackend: "nvidia"
        readonly property bool gpuAvailable: gpuBackend !== ""
        property string gpuName: "NVIDIA GeForce RTX 4070"
        property int gpuClockMHz: 1500
        property real gpuPowerW: 63.2
        property real gpuPowerLimitW: 185
        property int gpuFanPercent: 26
        property string gpuPerformanceState: "P2"
        property string gpuDriverVersion: "580.82.09"
    }
    QtObject {
        id: panel
        readonly property var root: theme
        readonly property bool visible: theme.gpuVisible
        property int gpuUtil: 41
        property int gpuTemp: 47
        property int gpuMemUsed: 2560
        property int gpuMemTotal: 12288
        function gib(mib) { return (Math.max(0, mib) / 1024).toFixed(1) + " GiB" }
    }
    FloatingWindow {
        implicitWidth: 320
        implicitHeight: 480
        Test.TestCase { id: input; when: false }
        Panels.CrateGpuDetails {
            id: details
            x: 16
            y: 16
            width: 288
            gpu: panel
            property int launches: 0
            onCloseRequested: theme.gpuVisible = false
            onBtopRequested: launches++
        }
    }

    function check(ok, reason) {
        if (!ok) throw Error(reason);
    }
    function findRow(item, label) {
        if (item.label === label && item.valueText !== undefined) return item;
        for (const child of item.children) {
            const match = findRow(child, label);
            if (match) return match;
        }
        return null;
    }
    function checkRow(label, amount, extra) {
        const row = findRow(details, label);
        check(row && row.visible && row.valueText === amount && row.secondary === extra, label + " row");
        check(row.height === 24 && row.valuePixelSize === 12, label + " dimensions");
        return row;
    }

    Timer {
        interval: 200
        running: true
        onTriggered: {
            try {
                Tokens.controlsCrate = true;
                input.wait(70);
                const summary = input.findChild(details, "gpuSummary");
                const reading = input.findChild(summary, "usagePercentage");
                const beam = input.findChild(summary, "usageBeam");
                const spark = input.findChild(details, "gpuHistory");
                fixture.check(summary.hasReading && reading.text === "41%" && beam.value === 0.41, "dedicated GPU utilization");
                fixture.check(spark.active && spark.value === 41 && spark._buf.length > 0, "open GPU samples history");
                fixture.checkRow("Model", theme.gpuName, "");
                fixture.checkRow("Temperature", "47°C", "");
                const vram = fixture.checkRow("VRAM", "2.5 GiB", "/ 12.0 GiB");
                fixture.checkRow("Graphics clock", "1500 MHz", "");
                const power = fixture.checkRow("Power", "63 W", "/ 185 W");
                const fan = fixture.checkRow("Fan · state", "26%", "P2");
                fixture.checkRow("Driver", theme.gpuDriverVersion, "");
                fixture.check(vram.secondaryWidth > 0 && vram.secondaryWidth === power.secondaryWidth && power.secondaryWidth === fan.secondaryWidth, "aligned secondary readings");

                const close = input.findChild(details, "closeGpu");
                fixture.check(close.width === 32 && close.height === 32 && close.glyph === "close", "shared close control");
                close.forceActiveFocus();
                input.keyClick(Qt.Key_Return);
                fixture.check(!theme.gpuVisible && !spark.active && spark._buf.length === 0, "close releases sampler");
                theme.gpuVisible = true;
                input.wait(20);
                fixture.check(spark.active, "reopen restarts sampler");

                theme.gpuBackend = "sysfs";
                theme.gpuName = "Intel Graphics";
                panel.gpuUtil = 0;
                panel.gpuTemp = 0;
                panel.gpuMemTotal = 0;
                theme.gpuClockMHz = 0;
                theme.gpuPowerW = 0;
                theme.gpuFanPercent = 0;
                theme.gpuPerformanceState = "";
                theme.gpuDriverVersion = "";
                fixture.check(summary.hasReading && reading.text === "0%" && beam.visible && spark.visible, "integrated GPU legitimately idle");
                fixture.checkRow("Model", theme.gpuName, "");
                for (const field of ["Temperature", "VRAM", "Graphics clock", "Power", "Fan · state", "Driver"])
                    fixture.check(!fixture.findRow(details, field).visible, "hide unsupported " + field);

                theme.gpuBackend = "";
                fixture.check(!summary.hasReading && summary.caption === "No data" && reading.text === "\u2014", "unavailable GPU");
                fixture.check(!beam.visible && !spark.visible && !spark.active && !fixture.findRow(details, "Model").visible, "no stale readings");

                const action = input.findChild(details, "openGpuMonitor");
                fixture.check(action.visible && action.outline && action.text === "Open btop", "monitor remains available");
                action.forceActiveFocus();
                input.keyClick(Qt.Key_Space);
                fixture.check(details.launches === 1, "activate btop with keyboard");
                console.log("GPU-RESOURCE-PROBE-PASS");
            } catch (error) {
                console.error("GPU-RESOURCE-PROBE-FAIL", error);
            }
            Qt.quit();
        }
    }
}
