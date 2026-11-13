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
    spacing: Tokens.s3

    CrateResourceHeader {
        width: parent.width
        title: I18n.tr("Battery")
        closeObjectName: "closeBattery"
        onCloseRequested: details.closeRequested()
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

    // a readout line: the kit's InfoRow, hidden when there is no reading
    component DetailRow: Kit.InfoRow {
        width: parent ? parent.width : 0
        visible: valueText.length > 0
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
