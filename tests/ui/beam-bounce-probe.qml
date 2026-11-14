import QtQuick
import Quickshell
import Ryoku.Ui

// Every indeterminate Beam scans like KITT: the segment runs to the right end,
// turns and runs back, never leaving the track (a panel's Beam must not paint
// outside its container). Like the web's Beam it is one continuous motion: a
// symmetric segment (dark, bright middle, dark) that never flips, and no frame
// jumps. The narrow Beam checks the 24 px minimum segment.
ShellRoot {
    id: probe
    property real minX: 1e9
    property real maxX: -1e9
    property bool sawBack: false
    property bool sawForth: false
    property bool neverFlips: true
    property real lastX: -1
    property real maxStep: 0
    property real runMinX: 1e9
    property real runMaxX: -1e9

    FloatingWindow {
        implicitWidth: 300
        implicitHeight: 60
        Column {
            Beam { id: kitt; width: 200; height: 12; interactive: false; indeterminate: true }
            Beam { id: run; width: 60; height: 12; interactive: false; indeterminate: true }
        }
    }

    function symmetric(stops) {
        return stops.length >= 3 && Qt.colorEqual(stops[0].color, stops[stops.length - 1].color);
    }

    function part(item, name) {
        if (item.objectName === name) return item;
        for (const c of item.children) { const f = part(c, name); if (f) return f; }
        return null;
    }

    Timer {
        interval: 16
        repeat: true
        running: true
        onTriggered: {
            const s = part(kitt, "beamSweep");
            probe.minX = Math.min(probe.minX, s.x);
            probe.maxX = Math.max(probe.maxX, s.x);
            if (s.back) probe.sawBack = true; else probe.sawForth = true;
            for (const t of s.transform)
                if (t.xScale !== undefined && t.xScale < 0) probe.neverFlips = false;
            if (probe.lastX >= 0) probe.maxStep = Math.max(probe.maxStep, Math.abs(s.x - probe.lastX));
            probe.lastX = s.x;
            const r = part(run, "beamSweep");
            probe.runMinX = Math.min(probe.runMinX, r.x);
            probe.runMaxX = Math.max(probe.runMaxX, r.x + r.width);
        }
    }

    Timer {
        interval: 3200
        running: true
        onTriggered: {
            const s = part(kitt, "beamSweep");
            let err = "";
            if (probe.minX < -0.5 || probe.maxX > kitt.width - s.width + 0.5)
                err = "bounce left the track: " + probe.minX + ".." + probe.maxX;
            else if (probe.minX > 2 || probe.maxX < kitt.width - s.width - 2)
                err = "bounce did not reach both ends: " + probe.minX + ".." + probe.maxX;
            else if (!probe.sawBack || !probe.sawForth)
                err = "bounce never turned (back " + probe.sawBack + ", forth " + probe.sawForth + ")";
            else if (!probe.neverFlips)
                err = "the segment flips at the ends";
            else if (!probe.symmetric(part(kitt, "beamSweepLine").gradient.stops))
                err = "the segment is not symmetric";
            else if (probe.maxStep > 12)
                err = "the scan jumped " + probe.maxStep + " px in one frame";
            else if (probe.runMinX < -0.5 || probe.runMaxX > run.width + 0.5)
                err = "the narrow Beam left its track: " + probe.runMinX + ".." + probe.runMaxX;
            console.log(err ? "BEAM-BOUNCE-PROBE-FAIL " + err : "BEAM-BOUNCE-PROBE-PASS");
            Qt.quit();
        }
    }
}
