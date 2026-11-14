import QtQuick
import stage.modules.common
import stage.modules.common.widgets
import Ryoku.Ui.Singletons

/*
 * The percentage a widget shows over itself while its grip resizes it.
 * Under crate it is a mono tag on the popover ground in a hairline, opaque so
 * it reads over any face (the widget layers are not frosted).
 */
Rectangle {
    id: readout

    property string text: ""
    readonly property bool crate: Tokens.controlsCrate

    objectName: "widgetResizeReadout"
    implicitWidth: (crate ? kitText.implicitWidth : readoutText.implicitWidth) + 18
    implicitHeight: (crate ? kitText.implicitHeight : readoutText.implicitHeight) + 8
    radius: crate ? Tokens.radius : Appearance.rounding.full
    color: crate ? Tokens.popover : Appearance.colors.colPrimary
    border.width: crate ? Tokens.border : 0
    border.color: Tokens.line

    StyledText {
        id: readoutText
        anchors.centerIn: parent
        visible: !readout.crate
        text: readout.text
        font.pixelSize: Appearance.font.pixelSize.smaller
        color: Appearance.colors.colOnPrimary
    }
    Text {
        id: kitText
        anchors.centerIn: parent
        visible: readout.crate
        text: readout.text
        color: Tokens.ink
        font.family: Tokens.mono
        font.pixelSize: Tokens.fMicro
        font.features: ({ "tnum": 1 })
    }
}
