import QtQuick
import Quickshell
import Ryoku.Ui as Kit

ShellRoot {
    Kit.StreamRow {
        id: row

        property real lastAdjusted: -1

        width: 320
        onAdjusted: (value) => {
            return lastAdjusted = value;
        }
    }

    Timer {
        interval: 50
        running: true
        onTriggered: {
            let beam = null;
            for (const child of row.children) {
                if (typeof child.nudge === "function") {
                    beam = child;
                    break;
                }
            }
            if (!beam)
                throw new Error("StreamRow Beam not found");

            row.value = 2;
            if (row.upperLimit !== 1 || beam.value !== 1)
                throw new Error("Normal volume must clamp at 1");

            row.value = -1;
            if (beam.value !== 0)
                throw new Error("Volume must clamp at 0");

            row.limit = 1.5;
            row.value = 2;
            if (row.upperLimit !== 1.5 || beam.value !== 1.5)
                throw new Error("Boosted volume must clamp at 1.5");

            row.value = 1.2;
            beam.nudge(1);
            if (Math.abs(row.lastAdjusted - 1.21) > 1e-06)
                throw new Error("Beam movement must emit adjusted with the new value");

            console.log("STREAM-ROW-PROBE-PASS");
            Qt.quit();
        }
    }

}
