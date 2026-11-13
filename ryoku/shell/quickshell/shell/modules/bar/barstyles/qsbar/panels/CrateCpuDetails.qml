pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons
import "../modules"

Column {
    id: details
    required property var cpu
    required property real availableHeight
    readonly property var telemetry: cpu.root
    signal closeRequested()
    signal btopRequested()
    spacing: Tokens.s3

    CrateResourceHeader {
        id: header
        width: parent.width
        title: "CPU"
        closeObjectName: "closeCpu"
        onCloseRequested: details.closeRequested()
    }
    component Stat: Kit.InfoRow {
        width: parent ? parent.width : 0
        visible: valueText.length > 0
    }

    Flickable {
        id: viewport
        objectName: "cpuDetailsViewport"
        width: parent.width
        height: Math.min(contentHeight, Math.max(0, details.availableHeight
            - header.height - footerRule.height - monitor.height - 3 * details.spacing))
        contentHeight: readings.implicitHeight
        contentWidth: width
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height
        activeFocusOnTab: interactive
        function scrollBy(amount) {
            contentY = Math.max(0, Math.min(contentHeight - height, contentY + amount))
        }
        Keys.onDownPressed: scrollBy(Tokens.s5)
        Keys.onUpPressed: scrollBy(-Tokens.s5)
        Keys.onPressed: event => {
            if (event.key === Qt.Key_PageDown || event.key === Qt.Key_PageUp) {
                scrollBy(event.key === Qt.Key_PageDown ? height : -height)
                event.accepted = true
            }
        }
        QQC.ScrollBar.vertical: Kit.ScrollRail {
            policy: viewport.interactive ? QQC.ScrollBar.AlwaysOn : QQC.ScrollBar.AlwaysOff
        }
        Kit.WheelScroll { enabled: viewport.interactive }

        Column {
            id: readings
            width: viewport.width - (viewport.interactive ? Tokens.s3 : 0)
            spacing: details.spacing
            CrateUsageSummary {
                objectName: "cpuSummary"
                width: parent.width
                percent: details.cpu.cpuPct
                hasReading: details.telemetry.systemCpuAvailable
                caption: hasReading ? (details.telemetry.cpuModelName || I18n.tr("In use"))
                    : I18n.tr("No data")
            }
            Sparkline {
                objectName: "cpuHistory"
                width: parent.width
                root: details.telemetry
                value: details.cpu.cpuPct
                visible: details.telemetry.systemCpuAvailable
                active: visible && details.cpu.visible && root.cpuVisible
                lineColor: Tokens.mark
                Accessible.role: Accessible.Graphic
                Accessible.name: I18n.tr("CPU usage")
            }

            Column {
                width: parent.width
                Stat { label: I18n.tr("Cores"); valueText: details.cpu.topologySummary }
                Stat {
                    label: I18n.tr("Clock")
                    valueText: details.telemetry.cpuClockMHz > 0
                        ? I18n.tr("%1 GHz").arg((details.telemetry.cpuClockMHz / 1000).toFixed(1)) : ""
                    secondary: details.telemetry.cpuMaxClockMHz > 0
                        ? I18n.tr("%1 GHz max").arg((details.telemetry.cpuMaxClockMHz / 1000).toFixed(1)) : ""
                }
                Stat {
                    label: I18n.tr("Load 1 · 5 · 15")
                    valueText: details.telemetry.systemLoadAvailable ? details.cpu.loadSummary : ""
                }
                Stat {
                    label: I18n.tr("USER")
                    valueText: details.telemetry.systemCpuAvailable ? details.telemetry.systemCpuUserPercent + "%" : ""
                }
                Stat {
                    label: I18n.tr("System")
                    valueText: details.telemetry.systemCpuAvailable ? details.telemetry.systemCpuSystemPercent + "%" : ""
                }
                Stat {
                    label: I18n.tr("I/O wait")
                    valueText: details.telemetry.systemCpuAvailable ? details.telemetry.systemCpuIoWaitPercent + "%" : ""
                }
                Stat { label: I18n.tr("Power mode"); valueText: details.cpu.powerMode }
                Stat {
                    label: I18n.tr("Throttling")
                    valueText: details.telemetry.cpuThrottleCount > 0
                        ? I18n.tr("%1 events").arg(details.telemetry.cpuThrottleCount) : ""
                }
                Stat { label: I18n.tr("Kernel"); valueText: details.telemetry.kernelRelease }
            }
            Kit.Divider { width: parent.width; quiet: true }
            Column {
                width: parent.width
                Kit.TrackLabel { text: I18n.tr("TOP PROCESSES") }
                TextMetrics {
                    id: processWidth
                    text: Math.max(0, ...details.telemetry.cpuTopProcesses.map(p => p.percent)).toFixed(1) + "%"
                    font.family: Tokens.mono
                    font.pixelSize: 11
                    font.features: { "tnum": 1 }
                }
                Repeater {
                    model: details.telemetry.cpuTopProcesses
                    delegate: Stat {
                        required property int index
                        required property var modelData
                        label: String(index + 1).padStart(2, "0")
                        labelWidth: labelImplicitWidth
                        valueText: modelData.name
                        secondary: Number(modelData.percent).toFixed(1) + "%"
                        secondaryWidth: processWidth.advanceWidth
                    }
                }
                Stat {
                    visible: details.telemetry.cpuTopProcesses.length === 0
                    valueText: I18n.tr("Collecting…")
                }
            }
        }
    }
    Kit.Divider { id: footerRule; width: parent.width; quiet: true }
    Kit.Btn {
        id: monitor
        objectName: "openCpuMonitor"
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
