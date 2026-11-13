pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons
import "../modules"

Column {
    id: details
    required property var thermals
    required property real availableHeight
    readonly property var theme: thermals.root
    readonly property var sensors: [cpu, core, gpu, nvme, ram]
    readonly property var selectedSensor: sensors.find(sensor => sensor.sourceId === theme.barTemperatureSource)
    readonly property bool hasSensors: sensors.some(sensor => sensor.reading > 0)
    readonly property real limitWidth: Math.max(...sensors.map(sensor => sensor.reading > 0 ? sensor.limitTextWidth : 0))
    signal closeRequested()
    signal sourceRequested(string source)
    spacing: Tokens.s3

    CrateResourceHeader {
        id: header
        width: parent.width
        title: I18n.tr("Temperature")
        closeObjectName: "closeThermals"
        onCloseRequested: details.closeRequested()
    }

    component Sensor: Column {
        id: sensor
        required property string sourceId
        required property string shortLabel
        required property string label
        required property int reading
        property int maximum: 0
        property int critical: 0
        readonly property int scaleMax: critical > 0 ? critical : maximum > 0 ? maximum : 100
        readonly property string limitText: critical > 0 || maximum > 0
            ? I18n.tr("%1° limit").arg(scaleMax) : I18n.tr("%1° scale").arg(scaleMax)
        readonly property real limitTextWidth: limitMetrics.advanceWidth

        objectName: "thermalRow-" + sourceId
        width: parent.width
        visible: reading > 0
        Accessible.role: Accessible.StaticText
        Accessible.name: label + " · " + readout.valueText + " · " + readout.label + " · " + limitText

        Kit.TrackLabel {
            objectName: "thermalName-" + sensor.sourceId
            width: parent.width
            text: sensor.label
            textFormat: Text.PlainText
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            elide: Text.ElideNone
        }
        Kit.InfoRow {
            id: readout
            objectName: "thermalReadout-" + sensor.sourceId
            width: parent.width
            label: details.thermals.status(sensor.reading, sensor.maximum, sensor.critical)
            valueText: sensor.reading + "°C"
            secondary: sensor.limitText
            secondaryWidth: details.limitWidth
        }
        Kit.Beam {
            objectName: "thermalBeam-" + sensor.sourceId
            width: parent.width
            height: Tokens.s3
            interactive: false
            value: sensor.reading
            to: sensor.scaleMax
            Accessible.ignored: true
        }
        TextMetrics {
            id: limitMetrics
            text: sensor.limitText
            font.family: Tokens.mono
            font.pixelSize: 11
            font.features: { "tnum": 1 }
        }
    }

    Flickable {
        id: viewport
        objectName: "thermalSensorsViewport"
        width: parent.width
        height: Math.min(contentHeight, Math.max(0, details.availableHeight - header.height - details.spacing))
        contentWidth: width
        contentHeight: body.implicitHeight
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
            id: body
            width: viewport.width - (viewport.interactive ? Tokens.s3 : 0)
            spacing: details.spacing
            CrateUsageSummary {
                objectName: "thermalsSummary"
                width: parent.width
                visible: details.hasSensors
                hasReading: !!details.selectedSensor && details.selectedSensor.reading > 0
                percent: hasReading ? Math.min(100, Math.round(100 * details.selectedSensor.reading / details.selectedSensor.scaleMax)) : 0
                valueText: hasReading ? details.selectedSensor.reading + "°C" : ""
                caption: details.theme.barTemperatureSourceLabel(details.theme.barTemperatureSource)
                    + " · " + (hasReading ? details.selectedSensor.limitText : I18n.tr("No data"))
            }
            // Replacing the delegate on selection starts a fresh history for that sensor.
            Repeater {
                model: details.selectedSensor ? [details.selectedSensor] : []
                Sparkline {
                    required property var modelData
                    objectName: "thermalsHistory"
                    width: body.width
                    root: details.theme
                    value: modelData.reading
                    max: modelData.scaleMax
                    visible: modelData.reading > 0
                    active: visible && details.thermals.visible && root.thermalVisible
                    lineColor: Tokens.mark
                    Accessible.role: Accessible.Graphic
                    Accessible.name: details.theme.barTemperatureSourceLabel(modelData.sourceId)
                }
            }
            Column {
                width: parent.width
                spacing: Tokens.s1
                Kit.TrackLabel {
                    width: parent.width
                    text: I18n.tr("BAR SENSOR")
                }
                Flow {
                    id: picker
                    width: parent.width
                    spacing: Tokens.s1
                    Repeater {
                        model: details.sensors
                        Kit.Chip {
                            id: choice
                            required property var modelData
                            objectName: "thermalSource-" + modelData.sourceId
                            width: Math.max((picker.width - 4 * picker.spacing) / 5, implicitWidth - 20)
                            text: modelData.shortLabel
                            on: modelData === details.selectedSensor
                            enabled: modelData.reading > 0
                            activeFocusOnTab: enabled
                            Accessible.role: Accessible.RadioButton
                            Accessible.name: details.theme.barTemperatureSourceLabel(modelData.sourceId)
                            Accessible.checked: on
                            Accessible.onPressAction: if (enabled) clicked()
                            Keys.onSpacePressed: clicked()
                            Keys.onReturnPressed: clicked()
                            Keys.onEnterPressed: clicked()
                            onClicked: details.sourceRequested(modelData.sourceId)

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 2
                                visible: choice.activeFocus
                                color: "transparent"
                                border.color: choice.on ? Tokens.paper : Tokens.focus
                                radius: Tokens.radius
                            }
                        }
                    }
                }
            }
            Kit.Divider { width: parent.width; quiet: true }

            Column {
                width: parent.width
                visible: details.hasSensors
                spacing: Tokens.s2
                Sensor {
                    id: cpu
                    sourceId: "cpu"
                    shortLabel: "CPU"
                    label: I18n.tr("CPU package")
                    reading: details.theme.cpuTemperatureC
                    maximum: details.theme.cpuTemperatureMaxC
                    critical: details.theme.cpuTemperatureCriticalC
                }
                Sensor {
                    id: core
                    sourceId: "core"
                    shortLabel: I18n.tr("CORE")
                    label: I18n.tr("Hottest CPU core")
                    reading: details.theme.cpuCoreMaxTemperatureC
                    maximum: details.theme.cpuTemperatureMaxC
                    critical: details.theme.cpuTemperatureCriticalC
                }
                Sensor {
                    id: gpu
                    sourceId: "gpu"
                    shortLabel: "GPU"
                    label: details.theme.gpuName ? "GPU · " + details.theme.gpuName : "GPU"
                    reading: details.theme.gpuTemperatureC
                }
                Sensor {
                    id: nvme
                    sourceId: "nvme"
                    shortLabel: "NVMe"
                    label: I18n.tr("NVMe composite")
                    reading: details.theme.nvmeTemperatureC
                    maximum: details.theme.nvmeTemperatureMaxC
                    critical: details.theme.nvmeTemperatureCriticalC
                }
                Sensor {
                    id: ram
                    sourceId: "memory"
                    shortLabel: "RAM"
                    label: I18n.tr("Memory sensor")
                    reading: details.theme.memoryTemperatureC
                }
            }
            Text {
                objectName: "thermalsEmpty"
                width: parent.width
                visible: !details.hasSensors
                text: I18n.tr("No temperature sensors available")
                color: Tokens.inkSecondary
                font.family: Tokens.ui
                font.pixelSize: Tokens.px(13)
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
            }
        }
    }
}
