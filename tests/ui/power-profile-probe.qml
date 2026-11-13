import QtQuick
import Quickshell
import Ryoku.Ui.Singletons

// Drives the QS Bar's crate power profile body with a stand-in panel: the
// profiles the daemon offers sit in one row of equal chips, the current one is
// on, a chip chooses its profile, the thermal row follows the sensor, and the
// close button asks to close.
ShellRoot {
    QtObject {
        id: panel
        property var profiles: [
            { key: "power-saver", label: "Power Saver" },
            { key: "balanced", label: "Balanced" },
            { key: "performance", label: "Performance" }
        ]
        property string current: "balanced"
        property bool thermalAvailable: false
        property int thermalC: 0
        property string chosen: ""
        function choose(key) { chosen = key }
    }

    Item {
        width: 296
        height: 400
        CratePowerProfileDetails {
            id: details
            width: 296
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

    Timer {
        interval: 100
        running: true
        onTriggered: {
            Tokens.controlsCrate = true;
            const saver = find(details, "profile-power-saver");
            const balanced = find(details, "profile-balanced");
            const perf = find(details, "profile-performance");
            if (!saver || !balanced || !perf)
                throw new Error("Every offered profile needs a chip");
            if (saver.y !== perf.y || Math.abs(saver.width - perf.width) > 1)
                throw new Error("The chips must share one row at one width");
            for (const chip of [saver, balanced, perf]) {
                // the chip's natural width is its text plus 28 px of padding
                if (chip.implicitWidth - 28 + 8 > chip.width)
                    throw new Error("\"" + chip.text + "\" overflows its " + chip.width + " px chip");
            }
            if (perf.x + perf.width > 296.5)
                throw new Error("The chips must fit the panel, right edge " + (perf.x + perf.width));
            if (!balanced.on || saver.on || perf.on)
                throw new Error("Only the current profile is on");
            perf.clicked();
            if (panel.chosen !== "performance")
                throw new Error("A chip must choose its profile, chose " + panel.chosen);
            const thermal = find(details, "powerThermal");
            if (!thermal || thermal.visible)
                throw new Error("No sensor, no thermal row");
            panel.thermalAvailable = true;
            panel.thermalC = 57;
            if (!thermal.visible || thermal.valueText !== "57 °C")
                throw new Error("The thermal row must read the sensor, got " + thermal.valueText);
            panel.profiles = [panel.profiles[1], panel.profiles[2]];
            if (find(details, "profile-power-saver"))
                throw new Error("A profile the daemon lacks must not be offered");
            find(details, "closePowerProfile").clicked();
            if (!details.closed)
                throw new Error("Close must ask to close");
            console.log("POWER-PROFILE-PROBE-PASS");
            Qt.quit();
        }
    }
}
