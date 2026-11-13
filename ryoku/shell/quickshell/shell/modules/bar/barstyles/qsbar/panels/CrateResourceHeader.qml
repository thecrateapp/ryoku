import QtQuick
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons

Item {
    id: header

    required property string title
    required property string closeObjectName
    signal closeRequested()

    width: parent.width
    implicitHeight: Math.max(closeButton.height, heading.implicitHeight)
    Kit.TrackLabel {
        id: heading
        anchors.left: parent.left
        anchors.right: closeButton.left
        anchors.verticalCenter: parent.verticalCenter
        text: header.title
        tone: "accent"
    }
    Kit.IconButton {
        id: closeButton
        objectName: header.closeObjectName
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 32
        height: 32
        glyph: "close"
        Accessible.role: Accessible.Button
        Accessible.name: I18n.tr("Close")
        Accessible.onPressAction: header.closeRequested()
        onClicked: header.closeRequested()
    }
}
