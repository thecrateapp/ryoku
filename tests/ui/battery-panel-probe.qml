import QtQuick
import QtTest as Test
import Quickshell
import Quickshell.Io
import Ryoku.Ui.Singletons
import "bar/panels" as Panels
ShellRoot {
    id: fixture

    QtObject {
        id: theme
        property var activePopupScreen: Quickshell.screens[0]
        property bool batteryVisible: true
        property int batteryBarX: 180
        property int v2BarHeight: 28
        property int panelRadius: 6
        property int panelButtonRadius: 4
        property string mono: "monospace"
        property color panelBorder: "gray"
        property color panelOuterBorderColor: panelBorder
        property int panelOuterBorderW: 1
        property color bg: "black"
        property color ink: "white"
        property color sumi: "gray"
        property color sumiHi: "gray"
        property color paper: "black"
        property color sep: "gray"
        property color fillActive: "gray"
        property color fillPrimaryHover: "gray"
        property color indigo: "blue"
        property color seal: "cyan"
        property color pillShadow: "transparent"
        property bool barShadowEnabled: false
        property string barPosition: "top"
        function setPanelInsetX(x) {}
    }
    Panels.BatteryPanel { id: panel; root: theme }
    FloatingWindow {
        implicitWidth: 500
        implicitHeight: 420
        Test.TestCase { id: input; when: false }
        Item { id: stage; anchors.fill: parent }
    }
    FileView {
        id: reading
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/reading"
        blockWrites: true
    }

    function expect(predicate, reason) {
        const deadline = Date.now() + 1500;
        while (!predicate() && Date.now() < deadline) input.wait(15);
        if (!predicate()) throw Error(reason);
    }

    function read(record, status, expectedText) {
        reading.setText(record);
        panel.refreshBatteryData();
        expect(() => panel.status === status && named("batteryPercentage").text === expectedText,
               "reading " + status + " at " + expectedText);
    }

    function named(name) {
        return input.findChild(stage, name);
    }

    function texts(item, result) {
        if (!item.visible) return;
        if (typeof item.text === "string") result.push(item.text);
        for (const child of item.children) texts(child, result);
    }

    function labels(required, absent) {
        const rendered = [];
        texts(stage, rendered);
        for (const label of required) {
            if (!rendered.includes(label)) throw Error("missing " + label + " in " + rendered.join(" / "));
        }
        for (const label of absent) {
            if (rendered.includes(label)) throw Error("unexpected " + label + " in " + rendered.join(" / "));
        }
    }

    function meter(value) {
        const beam = named("batteryBeam");
        if (beam.interactive || !beam.visible || Math.abs(beam.value - value) > 0.001)
            throw Error("expected a read-only meter showing " + value);
    }

    Timer {
        running: true
        interval: 100
        onTriggered: {
            try {
                Tokens.controlsCrate = true;
                fixture.expect(() => panel.hasReading && panel.percent === 67, "opening reads the device");
                // Weston has no layer-shell protocol. Keep the actual card and controller
                // together, giving the card a mapped surface for Qt pointer and keyboard events.
                let card = input.findChild(panel.contentItem, "batteryPercentage");
                if (!card) throw Error("Crate panel did not load");
                while (card.parent !== panel.contentItem) card = card.parent;
                card.parent = stage;
                input.wait(30);

                fixture.labels(["67%", "Discharging", "Time left", "2h 30m", "Health (BAT0)",
                                "90%", "Power draw", "9.3 W", "Capacity", "49 Wh", "Charge cycles", "175"], ["Charge rate"]);
                fixture.meter(0.67);
                const expanded = card.height;

                fixture.read("BAT0|8|discharging|Time left|||||0", "discharging", "8%");
                fixture.expect(() => card.height < expanded, "sparse telemetry must collapse its rows");
                fixture.meter(0.08);
                if (!Qt.colorEqual(fixture.named("batteryPercentage").color, Tokens.alert))
                    throw Error("low discharge should use the alert color");
                fixture.labels(["8%", "Discharging"], ["Time left", "Health (BAT0)", "Power draw", "Capacity", "Charge cycles"]);
                fixture.read("BAT0|8|charging|Time to full|55m|27|49 Wh|90%|175", "charging", "8%");
                fixture.labels(["Charging", "Time to full", "55m", "Charge rate", "27 W"], ["Discharging", "Time left", "Power draw"]);
                I18n.configLang = "es";
                fixture.expect(() => I18n.tr("Time to full") === "Hasta la carga completa",
                               "Spanish charging-time translation should load");
                fixture.labels(["Hasta la carga completa", "55m", I18n.tr("Charge rate")], ["Time to full"]);
                I18n.configLang = "en";
                fixture.expect(() => I18n.tr("Charge rate") === "Charge rate", "restore English");
                if (Qt.colorEqual(fixture.named("batteryPercentage").color, Tokens.alert))
                    throw Error("charging should clear the low-discharge warning");

                fixture.read("BAT0|100|fully-charged||||||0", "fully-charged", "100%");
                fixture.labels(["100%", "Full"], ["Charge rate", "Charge cycles"]);
                fixture.meter(1);
                fixture.read("BAT0|0|empty||||||0", "empty", "0%");
                fixture.meter(0);
                fixture.read("", "unknown", "\u2014");
                fixture.labels(["Unknown"], ["0%", "Full", "Charge rate", "49 Wh"]);
                if (fixture.named("batteryBeam").visible) throw Error("missing reading should hide the meter");

                Tokens.controlsCrate = false;
                fixture.expect(() => !fixture.named("batteryBeam"), "stock style should remove the Crate meter");
                fixture.labels(["Status", "Unknown", "Open btop"], []);
                Tokens.controlsCrate = true;
                fixture.expect(() => !!fixture.named("closeBattery"), "switch back to Crate controls");

                const close = fixture.named("closeBattery");
                const launch = fixture.named("openBatteryMonitor");
                close.forceActiveFocus();
                input.keyClick(Qt.Key_Escape);
                if (theme.batteryVisible) throw Error("Escape should dismiss from the focused button");
                theme.batteryVisible = true;
                input.wait(200);
                input.mouseClick(close, close.width / 2, close.height / 2);
                if (theme.batteryVisible) throw Error("clicking close should dismiss the popup");
                theme.batteryVisible = true;
                input.wait(200);
                close.forceActiveFocus();
                input.keyClick(Qt.Key_Tab);
                if (!launch.activeFocus) throw Error("Tab should move from close to Open btop");
                input.keyClick(Qt.Key_Return);
                if (theme.batteryVisible) throw Error("Open btop should close the popup");
                console.log("BATTERY-PANEL-PROBE-PASS");
            } catch (error) {
                console.error("BATTERY-PANEL-PROBE-FAIL", error);
            }
            Qt.quit();
        }
    }
}
