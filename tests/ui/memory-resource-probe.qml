import QtQuick
import QtTest as Test
import Quickshell
import Ryoku.Ui.Singletons
import "bar/modules" as Modules
import "bar/panels" as Panels

ShellRoot {
    id: fixture

    QtObject {
        id: theme
        property bool modMemory: true
        property bool memVisible: true
        property int systemMemTotalMiB: 32768
        property int systemMemAvailMiB: 19456
        readonly property int systemMemUsedMiB: systemMemTotalMiB - systemMemAvailMiB
        readonly property int systemMemPercent: systemMemTotalMiB ? Math.round(systemMemUsedMiB / systemMemTotalMiB * 100) : 0
        readonly property real systemMemUsedGiB: systemMemUsedMiB / 1024
        readonly property real systemMemTotalGiB: systemMemTotalMiB / 1024
        property int memorySpeedMTs: 5600
        property string memoryType: "DDR5"
        property bool iconMode: false
        property color widgetIconColor: "#33dddd"
        property string mono: "monospace"
        property var tooltipOwner: null
        property string tooltipText: ""
        function widgetContentColor(gid, fallback) { return widgetIconColor }
        function iconOnly(gid) { return iconMode }
        function showTooltip(text, x, top, bottom, owner) { tooltipOwner = owner; tooltipText = text }
        function hideTooltip(owner) { tooltipOwner = null }
    }

    QtObject {
        id: panel
        readonly property var root: theme
        readonly property bool visible: theme.memVisible
        readonly property int pct: theme.systemMemPercent
        readonly property int memTotal: theme.systemMemTotalMiB
        readonly property int memUsed: theme.systemMemUsedMiB
        readonly property int memAvail: theme.systemMemAvailMiB
    }

    FloatingWindow {
        implicitWidth: 380
        implicitHeight: 510
        Test.TestCase { id: input; when: false }
        Modules.MemoryWidget { id: widget; root: theme; x: 12; y: 8 }
        Panels.CrateMemoryDetails {
            id: details
            x: 12; y: 65
            width: 288
            property int launches: 0
            memory: panel
            onCloseRequested: theme.memVisible = false
            onBtopRequested: launches++
        }
    }

    function check(ok, reason) {
        if (!ok) throw Error(reason);
    }
    function hasText(item, value) {
        if (!item.visible) return false;
        if (item.text === value) return true;
        return item.children.some(child => hasText(child, value));
    }

    Timer {
        interval: 200
        running: true
        onTriggered: {
            try {
                Tokens.controlsCrate = true;
                input.wait(70);
                const glyph = input.findChild(widget, "memoryGlyph");
                const label = input.findChild(widget, "memoryLabel");
                const track = input.findChild(widget, "memoryIconTrack");
                const spark = input.findChild(details, "memoryHistory");
                const summary = input.findChild(details, "memorySummary");
                fixture.check(glyph && glyph.drawn && Qt.colorEqual(glyph.color, theme.widgetIconColor), "RAM glyph and configured foreground");
                fixture.check(label.text === "13G" && label.font.features.tnum === 1, "used GiB in the bar");
                input.mouseMove(widget, widget.width / 2, widget.height / 2);
                input.wait(370);
                fixture.check(theme.tooltipOwner === widget && theme.tooltipText === "13.0/32G", "usage tooltip");
                fixture.check(summary.hasReading && summary.percent === 41 && fixture.hasText(details, "41%"), "panel percentage");
                for (const t of ["13.0 GiB", "13312 MiB", "19.0 GiB", "19456 MiB", "32.0 GiB", "32768 MiB", "5600 MT/s", "DDR5"])
                    fixture.check(fixture.hasText(details, t), "missing value " + t);
                fixture.check(spark.active && spark._buf.length > 0, "live history when open");
                theme.iconMode = true;
                input.wait(40);
                fixture.check(!label.visible && track.visible && track.children[0].width === 7, "icon-only leaves a live usage meter");
                theme.systemMemAvailMiB = 0;
                fixture.check(summary.percent === 100 && track.children[0].width === track.width && theme.tooltipText === "32.0/32G", "full updates panel, meter and tooltip");
                input.mouseClick(widget, widget.width / 2, widget.height / 2);
                fixture.check(!theme.memVisible && !spark.active && spark._buf.length === 0 && !theme.tooltipOwner, "closing releases history and tooltip");
                widget.Accessible.pressAction();
                fixture.check(theme.memVisible && spark.active, "accessible action opens memory");
                theme.systemMemAvailMiB = 32768;
                fixture.check(summary.hasReading && summary.percent === 0 && fixture.hasText(details, "0%"), "zero usage is a measured level");
                theme.systemMemAvailMiB = 0;
                theme.systemMemTotalMiB = 0;
                theme.memorySpeedMTs = 0;
                theme.iconMode = false;
                input.wait(20);
                fixture.check(!summary.hasReading && label.text === "\u2014" && !spark.visible && !spark.active, "unavailable telemetry");
                fixture.check(!fixture.hasText(details, "0 MiB") && !fixture.hasText(details, "DDR5"), "hide unavailable statistics");
                const close = input.findChild(details, "closeMemory");
                close.forceActiveFocus();
                input.keyClick(Qt.Key_Return);
                fixture.check(!theme.memVisible, "close via keyboard");
                input.keyClick(Qt.Key_Tab);
                input.keyClick(Qt.Key_Space);
                fixture.check(details.launches === 1, "keyboard access to btop");
                Tokens.controlsCrate = false;
                theme.iconMode = true;
                input.wait(40);
                fixture.check(!input.findChild(widget, "memoryGlyph") && widget.implicitWidth === 34, "classic 16px ring");
                theme.modMemory = false;
                fixture.check(!widget.visible && widget.implicitWidth === 0, "respect disabled module");
                console.log("MEMORY-RESOURCE-PROBE-PASS");
            } catch (error) {
                console.error("MEMORY-RESOURCE-PROBE-FAIL", error);
            }
            Qt.quit();
        }
    }
}
