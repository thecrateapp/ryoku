import QtQuick
import QtTest as Test
import Quickshell
import Ryoku.Ui.Singletons
import "bar/panels" as Panels

ShellRoot {
    id: fixture

    QtObject {
        id: theme
        property bool thermalVisible: true
        property string barTemperatureSource: "cpu"
        property int cpuTemperatureC: 56
        property int cpuCoreMaxTemperatureC: 94
        property int cpuTemperatureMaxC: 80
        property int cpuTemperatureCriticalC: 96
        property int gpuTemperatureC: 36
        property string gpuName: "Mock GPU"
        property int nvmeTemperatureC: 60
        property int nvmeTemperatureMaxC: 70
        property int nvmeTemperatureCriticalC: 0
        property int memoryTemperatureC: 38
        function barTemperatureSourceLabel(source) {
            return {cpu: "CPU package", core: "Hottest CPU core", gpu: "GPU", nvme: "NVMe", memory: "Memory"}[source];
        }
    }
    QtObject {
        id: panel
        readonly property var root: theme
        readonly property bool visible: theme.thermalVisible
        function status(value, maximum, critical) {
            if (critical > 0 && value >= critical * 0.9) return I18n.tr("HOT");
            if (maximum > 0 && value >= maximum * 0.8) return I18n.tr("WARM");
            return maximum > 0 || critical > 0 ? I18n.tr("NORMAL") : I18n.tr("LIVE");
        }
    }
    FloatingWindow {
        implicitWidth: 340
        implicitHeight: 450
        Test.TestCase { id: input; when: false }
        Panels.CrateThermalsDetails {
            id: details
            width: 288
            thermals: panel
            onCloseRequested: theme.thermalVisible = false
            onSourceRequested: source => theme.barTemperatureSource = source
        }
    }

    function check(ok, reason) {
        if (!ok) throw Error(reason);
    }
    function child(name) {
        const item = input.findChild(details, name);
        check(item, "missing " + name);
        return item;
    }
    function checkRow(source, label, value, secondary) {
        const row = child("thermalRow-" + source);
        check(row.visible && row.label === label && row.valueText === value && row.secondary === secondary,
              "row for " + source);
        check(row.height === 24 && row.valuePixelSize === 12 && row.secondaryWidth >= row.limitTextWidth,
              "aligned readout for " + source);
    }

    Timer {
        interval: 200
        running: true
        onTriggered: {
            try {
                Tokens.controlsCrate = true;
                input.wait(50);
                fixture.checkRow("cpu", "CPU package", "56°C · NORMAL", "96° limit");
                fixture.checkRow("core", "Hottest CPU core", "94°C · HOT", "96° limit");
                fixture.checkRow("gpu", "GPU · Mock GPU", "36°C · LIVE", "100° scale");
                fixture.checkRow("nvme", "NVMe composite", "60°C · WARM", "70° limit");
                fixture.checkRow("memory", "Memory sensor", "38°C · LIVE", "100° scale");

                const summary = fixture.child("thermalsSummary");
                const hero = fixture.child("usagePercentage");
                const beam = fixture.child("usageBeam");
                const empty = fixture.child("thermalsEmpty");
                const gpuChoice = fixture.child("thermalSource-gpu");
                const coreChoice = fixture.child("thermalSource-core");
                fixture.check(summary.hasReading && hero.text === "56°C" && beam.value === 0.58
                              && summary.caption === "CPU package · 96° limit", "selected sensor and limit");
                fixture.check(!empty.visible && fixture.child("thermalsHistory").active, "active CPU history");

                gpuChoice.forceActiveFocus();
                input.keyClick(Qt.Key_Space);
                input.wait(40);
                let spark = fixture.child("thermalsHistory");
                fixture.check(theme.barTemperatureSource === "gpu" && gpuChoice.on && hero.text === "36°C"
                              && summary.caption === "GPU · 100° scale", "select an unbounded sensor by keyboard");
                fixture.check(spark.active && spark.max === 100 && spark._buf.length
                              && spark._buf.every(v => v === 36), "GPU history contains only GPU samples");
                I18n.configLang = "es";
                input.wait(80);
                fixture.check(summary.caption === "GPU · Escala de 100°" && coreChoice.text === "NÚCLEO"
                              && coreChoice.children[0].implicitWidth <= coreChoice.width, "Spanish scale and selector");
                fixture.checkRow("gpu", "GPU · Mock GPU", "36°C · EN VIVO", "Escala de 100°");
                I18n.configLang = "en";
                input.wait(80);
                theme.gpuTemperatureC = 0;
                input.wait(30);
                fixture.check(!summary.hasReading && !spark.active && !spark._buf.length && !gpuChoice.enabled
                              && !beam.visible && !fixture.child("thermalRow-gpu").visible && !empty.visible,
                              "selected sensor removed, other sensors remain");
                theme.cpuTemperatureC = theme.nvmeTemperatureC = theme.memoryTemperatureC = 0;
                coreChoice.Accessible.pressAction();
                input.wait(30);
                fixture.check(coreChoice.on && !empty.visible && summary.hasReading && hero.text === "94°C",
                              "a lone core sensor is available");

                theme.cpuCoreMaxTemperatureC = 0;
                input.wait(30);
                fixture.check(empty.visible && empty.text === "No temperature sensors available"
                              && !summary.visible && !coreChoice.enabled, "empty message and disabled choices");
                gpuChoice.Accessible.pressAction();
                fixture.check(theme.barTemperatureSource === "core", "disabled sensor cannot become selected");
                theme.cpuCoreMaxTemperatureC = 45;
                input.wait(30);
                spark = fixture.child("thermalsHistory");
                fixture.check(!empty.visible && spark.active && spark.value === 45, "readings resume");
                const close = fixture.child("closeThermals");
                fixture.check(close.width === 32 && close.height === 32, "32 px close action");
                close.forceActiveFocus();
                input.keyClick(Qt.Key_Return);
                fixture.check(!theme.thermalVisible && !spark.active && !spark._buf.length, "closing stops sampling");
                console.log("THERMALS-RESOURCE-PROBE-PASS");
            } catch (error) {
                console.error("THERMALS-RESOURCE-PROBE-FAIL", error);
            }
            Qt.quit();
        }
    }
}
