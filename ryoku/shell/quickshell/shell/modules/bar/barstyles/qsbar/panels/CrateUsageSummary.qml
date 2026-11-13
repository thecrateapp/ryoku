import QtQuick
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons

Column {
    id: summary

    required property int percent
    required property bool hasReading
    required property string caption

    width: parent.width
    Item {
        width: parent.width
        height: Math.max(reading.implicitHeight, label.implicitHeight)
        Text {
            id: reading
            objectName: "usagePercentage"
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: summary.hasReading ? summary.percent + "%" : "\u2014"
            color: Tokens.ink
            font.family: Tokens.mono
            font.pixelSize: Tokens.px(28)
            font.features: { "tnum": 1 }
        }
        Text {
            id: label
            anchors.left: reading.right
            anchors.leftMargin: Tokens.s3
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignRight
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            text: summary.caption
            color: Tokens.inkSecondary
            font.family: Tokens.ui
            font.pixelSize: Tokens.px(13)
        }
    }
    Kit.Beam {
        objectName: "usageBeam"
        width: parent.width
        visible: summary.hasReading
        interactive: false
        value: summary.percent / 100
        Accessible.ignored: true
    }
}
