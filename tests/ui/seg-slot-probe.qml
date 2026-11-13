import QtQuick
import Quickshell
import Ryoku.Ui
import Ryoku.Ui.Singletons

// A SettingRow's inline Seg, the way the QS Bar control center lays out Edge and
// Workspaces: a slot sized to the Seg's own one-row width keeps every segment on
// one line in the crate look, where a fixed slot sized for the stock chips
// (Edge's old 130) wrapped them onto a second line.
ShellRoot {
    // a window, so the Flows are polished and really lay out (offscreen)
    FloatingWindow {
        implicitWidth: 560
        implicitHeight: 400
        Column {
            width: 560
            SettingRow {
                id: edgeRow
                width: parent.width
                label: "Edge"
                controlWidth: edgeSeg.implicitWidth
                Seg { id: edgeSeg; anchors.right: parent.right; options: ["top", "bottom"]; current: "top" }
            }
            SettingRow {
                width: parent.width
                label: "Workspaces"
                controlWidth: workspaceSeg.implicitWidth
                Seg { id: workspaceSeg; anchors.right: parent.right; options: ["Active", "1-5", "1-10"]; current: "Active" }
            }
            SettingRow {
                width: parent.width
                label: "Edge (fixed slot)"
                controlWidth: 130
                Seg { id: fixedSeg; anchors.right: parent.right; options: ["top", "bottom"]; current: "top" }
            }
        }
    }

    function check(label) {
        for (const s of [edgeSeg, workspaceSeg])
            if (s.height !== s.segH)
                throw new Error(label + ": " + s.options + " wrapped to " + s.height + " px; one row is " + s.segH);
    }

    // a look switch relays the Flows on the next polish, so each check waits a frame
    Timer {
        id: stockCheck
        interval: 100
        onTriggered: {
            check("stock");
            console.log("SEG-SLOT-PROBE-PASS");
            Qt.quit();
        }
    }
    Timer {
        id: crateCheck
        interval: 100
        onTriggered: {
            check("crate");
            if (fixedSeg.height === fixedSeg.segH)
                throw new Error("The fixed 130 slot should reproduce the wrap under crate");
            Tokens.controlsCrate = false;
            stockCheck.start();
        }
    }
    Timer {
        interval: 150
        running: true
        onTriggered: {
            Tokens.controlsCrate = true;
            crateCheck.start();
        }
    }
}
