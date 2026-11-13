pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons

Column {
    id: details
    required property var storage
    required property real availableHeight
    signal closeRequested()

    spacing: Tokens.s3

    component Metric: Column {
        id: metric
        required property string label
        required property string valueText
        spacing: Tokens.s1

        Kit.TrackLabel {
            width: parent.width
            text: metric.label
        }
        Text {
            width: parent.width
            text: metric.valueText
            color: Tokens.ink
            font.family: Tokens.mono
            font.pixelSize: Tokens.px(12)
            font.features: { "tnum": 1 }
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        }
    }
    component CapacityMetrics: Row {
        id: metrics
        required property string used
        required property string free
        required property string total
        readonly property real cellWidth: (width - 2 * spacing) / 3
        spacing: Tokens.s2

        Metric { width: metrics.cellWidth; label: I18n.tr("Used"); valueText: metrics.used }
        Metric { width: metrics.cellWidth; label: I18n.tr("Free"); valueText: metrics.free }
        Metric { width: metrics.cellWidth; label: I18n.tr("Total"); valueText: metrics.total }
    }

    CrateResourceHeader {
        id: header
        width: parent.width
        title: I18n.tr("STORAGE")
        closeObjectName: "closeStorage"
        onCloseRequested: details.closeRequested()
    }

    Flickable {
        id: viewport
        objectName: "storageDetailsViewport"
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
            spacing: Tokens.s2

            CrateUsageSummary {
                objectName: "storageRootUsage"
                width: parent.width
                caption: I18n.tr("Root filesystem")
                percent: details.storage.pct
                hasReading: details.storage.root.storageAvailable
            }
            CapacityMetrics {
                width: parent.width
                visible: details.storage.root.storageAvailable
                used: details.storage.usedGiB.toFixed(1) + " GiB"
                free: details.storage.freeGiB.toFixed(1) + " GiB"
                total: details.storage.totalGiB.toFixed(1) + " GiB"
            }
            Kit.Divider { width: parent.width; quiet: true }
            Kit.TrackLabel {
                width: parent.width
                text: I18n.tr("Drives · %1").arg(details.storage.root.storageDrives.length)
                tone: "accent"
            }

            Repeater {
                model: details.storage.root.storageDrives
                delegate: Column {
                    id: disk
                    required property var modelData
                    required property int index
                    readonly property bool hasUsage: modelData.totalBytes > 0 && modelData.state !== "/boot"
                    readonly property bool hasPercent: modelData.percent >= 0
                    width: body.width
                    spacing: Tokens.s1

                    Item {
                        width: parent.width
                        height: Math.max(glyph.height, modelName.implicitHeight, capacity.implicitHeight)
                        Kit.Glyph {
                            id: glyph
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            name: disk.modelData.driveType === "hdd" ? "ssd-round" : "ssd-square"
                            size: 16
                            color: Tokens.inkSecondary
                            Accessible.ignored: true
                        }
                        Text {
                            id: modelName
                            anchors.left: glyph.right
                            anchors.leftMargin: Tokens.s2
                            anchors.right: capacity.left
                            anchors.rightMargin: Tokens.s2
                            anchors.verticalCenter: parent.verticalCenter
                            text: disk.modelData.model
                            textFormat: Text.PlainText
                            color: Tokens.ink
                            font.family: Tokens.ui
                            font.pixelSize: Tokens.px(13)
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        }
                        Text {
                            id: capacity
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: details.storage.formatCapacity(disk.modelData.size)
                            color: Tokens.ink
                            font.family: Tokens.mono
                            font.pixelSize: Tokens.px(13)
                            font.features: { "tnum": 1 }
                        }
                    }

                    Text {
                        width: parent.width
                        text: [disk.modelData.media, disk.modelData.fileSystems, disk.modelData.state,
                            !disk.hasUsage && disk.hasPercent ? disk.modelData.percent + "%" : "",
                            !disk.hasUsage && disk.modelData.freeBytes >= 0 ? details.storage.formatFree(disk.modelData.freeBytes) : ""]
                            .filter(field => field).join(" · ")
                        textFormat: Text.PlainText
                        color: Tokens.inkSecondary
                        font.family: Tokens.ui
                        font.pixelSize: Tokens.px(12)
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    }

                    Kit.MeterRow {
                        width: parent.width
                        visible: disk.hasUsage && disk.hasPercent
                        label: I18n.tr("USAGE")
                        fraction: disk.modelData.percent / 100
                        valueText: disk.modelData.percent + "%"
                    }
                    CapacityMetrics {
                        width: parent.width
                        visible: disk.hasUsage
                        used: details.storage.formatGiB(disk.modelData.usedBytes)
                        free: details.storage.formatGiB(disk.modelData.freeBytes)
                        total: details.storage.formatGiB(disk.modelData.totalBytes)
                    }
                    Kit.Divider {
                        width: parent.width
                        visible: disk.index + 1 < details.storage.root.storageDrives.length
                        quiet: true
                    }
                }
            }
            Text {
                width: parent.width
                visible: details.storage.root.storageDrives.length === 0
                text: details.storage.root.storageInventoryAvailable
                    ? I18n.tr("No physical drives found") : I18n.tr("Reading drive information…")
                color: Tokens.inkSecondary
                font.family: Tokens.ui
                font.pixelSize: Tokens.px(13)
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }
        }
    }
}
