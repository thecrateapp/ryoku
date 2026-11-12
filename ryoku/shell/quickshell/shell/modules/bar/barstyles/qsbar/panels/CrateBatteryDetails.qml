import QtQuick
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons

Column {
    id: details
    required property var battery
    signal closeRequested()
    signal btopRequested()

    readonly property bool low: battery.hasReading && battery.percent <= 20
        && !battery.charging && battery.status !== "fully-charged"
    spacing: Tokens.s2

    Item {
        width: parent.width
        height: closeButton.height
        Kit.TrackLabel {
            anchors.left: parent.left
            anchors.right: closeButton.left
            anchors.verticalCenter: parent.verticalCenter
            text: I18n.tr("Battery")
            tone: "accent"
        }
        Kit.IconButton {
            id: closeButton
            objectName: "closeBattery"
            anchors.right: parent.right
            width: 32
            height: 32
            glyph: "close"
            Accessible.role: Accessible.Button
            Accessible.name: I18n.tr("Close")
            Accessible.onPressAction: details.closeRequested()
            onClicked: details.closeRequested()
        }
    }

    Column {
        width: parent.width
        Item {
            width: parent.width
            height: Math.max(percentage.implicitHeight, state.implicitHeight)
            Text {
                id: percentage
                objectName: "batteryPercentage"
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: details.battery.hasReading ? details.battery.percent + "%" : "\u2014"
                color: details.low ? Tokens.alert : Tokens.ink
                font.family: Tokens.mono
                font.pixelSize: Tokens.px(28)
                font.features: { "tnum": 1 }
            }
            Text {
                id: state
                objectName: "batteryStatus"
                anchors.left: percentage.right
                anchors.leftMargin: Tokens.s3
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignRight
                text: details.battery.statusTitle(details.battery.status)
                color: details.battery.charging ? Tokens.mark : Tokens.inkSecondary
                font.family: Tokens.ui
                font.pixelSize: Tokens.px(13)
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }
        }
        Kit.Beam {
            objectName: "batteryBeam"
            width: parent.width
            visible: details.battery.hasReading
            value: details.battery.percent / 100
            interactive: false
            Accessible.ignored: true
        }
    }

    component DetailRow: Item {
        id: row
        required property string label
        required property string valueText
        width: parent.width
        height: Math.max(Tokens.px(22), caption.implicitHeight, amount.implicitHeight)
        visible: valueText.length > 0
        Kit.TrackLabel {
            id: caption
            anchors.left: parent.left
            anchors.right: amount.left
            anchors.rightMargin: Tokens.s2
            anchors.verticalCenter: parent.verticalCenter
            text: row.label
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        }
        Text {
            id: amount
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: row.valueText
            font.family: Tokens.mono
            font.pixelSize: Tokens.px(13)
            font.features: { "tnum": 1 }
            color: Tokens.ink
        }
    }
    Column {
        width: parent.width
        visible: details.battery.timeText !== "" || details.battery.healthText !== ""
            || details.battery.powerRate !== "" || details.battery.sizeText !== "" || details.battery.cycles > 0
        DetailRow {
            label: details.battery.charging ? I18n.tr("Time to full") : I18n.tr("Time left")
            valueText: details.battery.timeText
        }
        DetailRow {
            label: details.battery.healthLabel
            valueText: details.battery.healthText
        }
        DetailRow {
            label: details.battery.charging ? I18n.tr("Charge rate") : I18n.tr("Power draw")
            valueText: details.battery.powerRate ? details.battery.powerRate + " W" : ""
        }
        DetailRow {
            label: I18n.tr("Capacity")
            valueText: details.battery.sizeText
        }
        DetailRow {
            label: I18n.tr("Charge cycles")
            valueText: details.battery.cycles > 0 ? String(details.battery.cycles) : ""
        }
    }

    Kit.Divider { width: parent.width; quiet: true }
    Kit.Btn {
        objectName: "openBatteryMonitor"
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
