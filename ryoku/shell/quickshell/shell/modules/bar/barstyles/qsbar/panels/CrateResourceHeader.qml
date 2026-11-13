import QtQuick
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons

Item {
    id: header

    required property string title
    required property string closeObjectName
    // trailing actions before the close button (a rescan IconButton, a radio Sw)
    default property alias actions: trailing.data
    signal closeRequested()

    width: parent.width
    implicitHeight: Math.max(closeButton.height, heading.implicitHeight)
    Kit.TrackLabel {
        id: heading
        anchors.left: parent.left
        anchors.right: trailing.left
        anchors.rightMargin: Tokens.s2
        anchors.verticalCenter: parent.verticalCenter
        text: header.title
        tone: "accent"
    }
    Row {
        id: trailing
        anchors.right: closeButton.left
        anchors.rightMargin: trailing.children.length > 0 ? Tokens.s1 : 0
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.s1
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
