pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons
import "../modules"

Column {
    id: details
    required property var gpu
    readonly property var telemetry: gpu.root
    signal closeRequested()
    signal btopRequested()
    spacing: Tokens.s3

    CrateResourceHeader {
        width: parent.width
        title: "GPU"
        closeObjectName: "closeGpu"
        onCloseRequested: details.closeRequested()
    }
    CrateUsageSummary {
        objectName: "gpuSummary"
        width: parent.width
        percent: details.gpu.gpuUtil
        hasReading: details.telemetry.gpuAvailable
        caption: hasReading ? I18n.tr("In use") : I18n.tr("No data")
    }
    Sparkline {
        objectName: "gpuHistory"
        width: parent.width
        root: details.telemetry
        visible: root.gpuAvailable
        value: details.gpu.gpuUtil
        active: visible && details.gpu.visible && root.gpuVisible
        lineColor: Tokens.mark
        Accessible.role: Accessible.Graphic
        Accessible.name: I18n.tr("GPU usage")
    }

    component SecondaryMetrics: TextMetrics {
        font.family: Tokens.mono
        font.pixelSize: 11
        font.features: { "tnum": 1 }
    }
    SecondaryMetrics { id: vramWidth; text: vram.secondary }
    SecondaryMetrics { id: powerWidth; text: power.secondary }
    SecondaryMetrics { id: perfWidth; text: fan.secondary }

    component Stat: Kit.InfoRow {
        width: parent.width
        visible: valueText !== "" || secondary !== ""
        secondaryWidth: Math.max(vramWidth.advanceWidth, powerWidth.advanceWidth, perfWidth.advanceWidth)
    }

    Column {
        width: parent.width
        visible: details.telemetry.gpuAvailable
        Stat {
            label: I18n.tr("Model")
            labelWidth: labelImplicitWidth
            valueText: details.telemetry.gpuName || (details.telemetry.gpuBackend === "nvidia" ? "NVIDIA GPU" : "GPU")
        }
        Stat {
            label: I18n.tr("Temperature")
            valueText: details.gpu.gpuTemp > 0 ? details.gpu.gpuTemp + "°C" : ""
        }
        Stat {
            id: vram
            label: I18n.tr("VRAM")
            valueText: details.gpu.gpuMemTotal > 0 ? details.gpu.gib(details.gpu.gpuMemUsed) : ""
            secondary: details.gpu.gpuMemTotal > 0 ? "/ " + details.gpu.gib(details.gpu.gpuMemTotal) : ""
        }
        Stat {
            label: I18n.tr("Graphics clock")
            valueText: details.telemetry.gpuClockMHz > 0 ? details.telemetry.gpuClockMHz + " MHz" : ""
        }
        Stat {
            id: power
            label: I18n.tr("Power")
            valueText: details.telemetry.gpuPowerW > 0 ? details.telemetry.gpuPowerW.toFixed(0) + " W" : ""
            secondary: valueText && details.telemetry.gpuPowerLimitW > 0 ? "/ " + details.telemetry.gpuPowerLimitW.toFixed(0) + " W" : ""
        }
        Stat {
            id: fan
            label: I18n.tr("Fan · state")
            valueText: details.telemetry.gpuFanPercent > 0 ? details.telemetry.gpuFanPercent + "%" : ""
            secondary: details.telemetry.gpuPerformanceState
        }
        Stat {
            label: I18n.tr("Driver")
            valueText: details.telemetry.gpuDriverVersion
        }
    }
    Kit.Divider { width: parent.width; quiet: true }
    Kit.Btn {
        objectName: "openGpuMonitor"
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
