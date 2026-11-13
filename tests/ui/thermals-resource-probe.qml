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
        implicitWidth: 320
        implicitHeight: 760
        Test.TestCase { id: input; when: false }
        Panels.CrateThermalsDetails {
            id: details
            x: 16
            width: parent.width - 2 * x
            availableHeight: 760
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
    function checkRow(source, label, value, status, secondary, fraction) {
        const row = child("thermalRow-" + source);
        const name = child("thermalName-" + source);
        const readout = child("thermalReadout-" + source);
        const meter = child("thermalBeam-" + source);
        check(row.visible && name.visible && name.text === label && !name.truncated
              && name.contentWidth <= name.width + 1 && name.contentHeight <= name.height + 1,
              "complete sensor name: " + label);
        check(readout.label === status && readout.valueText === value && readout.secondary === secondary
              && readout.valuePixelSize === 12 && readout.height === 24
              && readout.secondaryWidth > 0 && readout.secondaryWidth === child("thermalReadout-cpu").secondaryWidth,
              "aligned temperature, status and limit for " + source);
        check(meter.visible && !meter.interactive && meter.width > 0 && meter.height > 0
              && Math.abs(meter.frac - fraction) < 0.006, "read-only meter for " + source);
    }

    Timer {
        interval: 200
        running: true
        onTriggered: {
            try {
                Tokens.controlsCrate = true;
                input.wait(50);
                fixture.check(details.width === 288, "320 px card with 16 px insets");
                fixture.checkRow("cpu", "CPU package", "56°C", "NORMAL", "96° limit", 56 / 96);
                fixture.checkRow("core", "Hottest CPU core", "94°C", "HOT", "96° limit", 94 / 96);
                fixture.checkRow("gpu", "GPU · Mock GPU", "36°C", "LIVE", "100° scale", 0.36);
                fixture.checkRow("nvme", "NVMe composite", "60°C", "WARM", "70° limit", 60 / 70);
                fixture.checkRow("memory", "Memory sensor", "38°C", "LIVE", "100° scale", 0.38);

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
                theme.gpuName = "NVIDIA GeForce RTX 4090 Laptop GPU";
                input.wait(80);
                fixture.check(summary.caption === "GPU · Escala de 100°" && coreChoice.text === "NÚCLEO"
                              && coreChoice.children[0].implicitWidth <= coreChoice.width, "Spanish scale and selector");
                fixture.checkRow("cpu", "Paquete de CPU", "56°C", "NORMAL", "límite de 96°", 56 / 96);
                fixture.checkRow("core", "Núcleo de CPU más caliente", "94°C", "CALIENTE", "límite de 96°", 94 / 96);
                fixture.checkRow("gpu", "GPU · " + theme.gpuName, "36°C", "EN VIVO", "Escala de 100°", 0.36);
                fixture.checkRow("nvme", "NVMe compuesto", "60°C", "CÁLIDO", "límite de 70°", 60 / 70);
                fixture.checkRow("memory", "Sensor de memoria", "38°C", "EN VIVO", "Escala de 100°", 0.38);
                fixture.check(fixture.child("thermalName-gpu").lineCount > 1, "long GPU name wraps in Spanish");
                theme.nvmeTemperatureC = 74;
                fixture.checkRow("nvme", "NVMe compuesto", "74°C", "CÁLIDO", "límite de 70°", 1);
                const viewport = fixture.child("thermalSensorsViewport");
                const close = fixture.child("closeThermals");
                fixture.check(!viewport.interactive, "full-height panel fits all sensors");
                details.availableHeight = 420;
                input.wait(30);
                const closeY = close.mapToItem(details, 0, 0).y;
                fixture.check(viewport.interactive && viewport.height > 0 && details.height <= 420, "short panel scrolls");
                viewport.forceActiveFocus();
                for (let i = 0; i < Math.ceil(viewport.contentHeight / viewport.height); i++)
                    input.keyClick(Qt.Key_PageDown);
                const last = fixture.child("thermalBeam-memory");
                const lastY = last.mapToItem(viewport, 0, last.height).y;
                fixture.check(viewport.contentY > 0 && lastY > 0 && lastY <= viewport.height + 1
                              && close.mapToItem(details, 0, 0).y === closeY, "last meter reachable with fixed header");
                details.availableHeight = 760;
                I18n.configLang = "en";
                input.wait(80);
                theme.gpuTemperatureC = 0;
                input.wait(30);
                fixture.check(!summary.hasReading && !spark.active && !spark._buf.length && !gpuChoice.enabled
                              && !beam.visible && !fixture.child("thermalBeam-gpu").visible
                              && !fixture.child("thermalRow-gpu").visible && fixture.child("thermalBeam-nvme").visible && !empty.visible,
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
                for (const source of ["cpu", "core", "gpu", "nvme", "memory"])
                    fixture.check(!fixture.child("thermalBeam-" + source).visible, "no lingering meter for " + source);
                gpuChoice.Accessible.pressAction();
                fixture.check(theme.barTemperatureSource === "core", "disabled sensor cannot become selected");
                theme.cpuCoreMaxTemperatureC = 45;
                input.wait(30);
                spark = fixture.child("thermalsHistory");
                fixture.check(!empty.visible && spark.active && spark.value === 45, "readings resume");
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
