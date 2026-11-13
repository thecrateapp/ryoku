pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons
import "../modules"

Column {
    id: details
    required property var memory
    readonly property bool hasReading: memory.memTotal > 0
    signal closeRequested()
    signal btopRequested()
    spacing: Tokens.s3

    CrateResourceHeader {
        width: parent.width
        title: I18n.tr("Memory")
        closeObjectName: "closeMemory"
        onCloseRequested: details.closeRequested()
    }
    CrateUsageSummary {
        objectName: "memorySummary"
        width: parent.width
        percent: details.memory.pct
        hasReading: details.hasReading
        caption: details.hasReading ? I18n.tr("In use") : I18n.tr("No data")
    }
    Sparkline {
        objectName: "memoryHistory"
        width: parent.width
        root: details.memory.root
        visible: details.hasReading
        value: details.memory.pct
        active: details.hasReading && details.memory.visible && root.memVisible
        lineColor: Tokens.mark
        Accessible.role: Accessible.Graphic
        Accessible.name: I18n.tr("Memory usage")
    }

    // a readout line: the kit's InfoRow, its MiB column aligned across rows
    component Stat: Kit.InfoRow {
        width: parent ? parent.width : 0
        secondaryWidth: mibWidth.advanceWidth
    }
    TextMetrics {
        id: mibWidth
        text: details.memory.memTotal + " MiB"
        font.family: Tokens.mono
        font.pixelSize: Tokens.px(11)
        font.features: { "tnum": 1 }
    }
    component Capacity: Stat {
        required property int mib
        visible: details.hasReading
        valueText: (mib / 1024).toFixed(1) + " GiB"
        secondary: mib + " MiB"
    }

    Column {
        width: parent.width
        visible: details.hasReading || details.memory.root.memorySpeedMTs > 0
        Capacity { label: I18n.tr("Used"); mib: details.memory.memUsed }
        Capacity { label: I18n.tr("Available"); mib: details.memory.memAvail }
        Capacity { label: I18n.tr("Total"); mib: details.memory.memTotal }
        Stat {
            label: I18n.tr("Speed")
            visible: details.memory.root.memorySpeedMTs > 0
            valueText: details.memory.root.memorySpeedMTs + " MT/s"
            secondary: details.memory.root.memoryType
        }
    }
    Kit.Divider { width: parent.width; quiet: true }
    Kit.Btn {
        objectName: "openMemoryMonitor"
        width: parent.width
        text: I18n.tr("Open btop")
        outline: true
        activeFocusOnTab: true
        Accessible.role: Accessible.Button
        Accessible.name: text
        Accessible.onPressAction: details.btopRequested()
        onAct: details.btopRequested()
    }
}
