import QtQuick
import Quickshell
import Ryoku.Ui

// An indeterminate Beam with bounce scans like KITT: the segment runs to the
// right end, turns and runs back, never leaving the track, its bright head
// always leading (the gradient mirrors on the way back). Without bounce it
// keeps running out on the right and coming in from the left.
ShellRoot {
    id: probe
    property real minX: 1e9
    property real maxX: -1e9
    property bool sawBack: false
    property bool sawForth: false
    property bool headLeads: true
    property real runMinX: 1e9
    property bool runBack: false

    FloatingWindow {
        implicitWidth: 300
        implicitHeight: 60
        Column {
            Beam { id: kitt; width: 200; height: 12; interactive: false; indeterminate: true; bounce: true }
            Beam { id: run; width: 200; height: 12; interactive: false; indeterminate: true }
        }
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
            if ((s.back ? -1 : 1) !== s.headDirection) probe.headLeads = false;
            const r = part(run, "beamSweep");
            probe.runMinX = Math.min(probe.runMinX, r.x);
            if (r.back) probe.runBack = true;
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
            else if (!probe.headLeads)
                err = "the head trails on the way back";
            else if (probe.runBack || probe.runMinX > -1)
                err = "the plain sweep changed (back " + probe.runBack + ", min x " + probe.runMinX + ")";
            console.log(err ? "BEAM-BOUNCE-PROBE-FAIL " + err : "BEAM-BOUNCE-PROBE-PASS");
            Qt.quit();
        }
    }
}
