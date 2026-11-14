import QtQuick
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons
import "Singletons"

// One pin action. Stock draws a bare text glyph with a hover tint; under crate
// it is the kit's plateless IconButton with the Solar glyph named by `solar`.
Rectangle {
    id: btn
    property string glyph: ""
    property string solar: ""

    signal clicked()

    readonly property bool crate: Tokens.controlsCrate

    width: btn.crate ? Theme.actionSize : 26
    height: btn.crate ? Theme.actionSize : 26
    radius: btn.crate ? Tokens.radius : Theme.radius / 2
    color: !btn.crate && ma.containsMouse ? Theme.hover : "transparent"

    Text {
        objectName: "ryopinStockGlyph"
        visible: !btn.crate
        anchors.centerIn: parent
        text: btn.glyph
        font.family: Theme.ui
        font.pixelSize: 14
        color: ma.containsMouse ? Theme.ink : Theme.inkDim
    }

    Kit.IconButton {
        objectName: "ryopinKitButton"
        visible: btn.crate
        enabled: btn.crate
        anchors.fill: parent
        glyph: btn.solar
        onClicked: btn.clicked()
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        enabled: !btn.crate
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}
