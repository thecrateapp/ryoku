import QtQuick
import "Singletons"

// The head of a sheet inside a panel (the Controls panel's Wi-Fi and Bluetooth
// pages): a back button, the title in the display face, and trailing actions
// (IconButtons, a Sw) placed as children. crate-mark's page head from the
// mock-up; `showBack: false` drops the back button for a top-level sheet.
Item {
    id: head

    property string title: ""
    property bool showBack: true
    property real s: 1
    default property alias actions: trailing.data

    signal backRequested()

    implicitWidth: 320 * head.s
    implicitHeight: 36 * head.s

    IconButton {
        id: back
        visible: head.showBack
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: head.showBack ? 32 * head.s : 0
        height: 32 * head.s
        iconSize: 18 * head.s
        glyph: "arrow_back"
        Accessible.name: I18n.tr("Back")
        onClicked: head.backRequested()
    }

    Text {
        anchors.left: back.right
        anchors.leftMargin: (head.showBack ? 4 : 0) * head.s
        anchors.right: trailing.left
        anchors.rightMargin: 8 * head.s
        anchors.verticalCenter: parent.verticalCenter
        text: head.title
        textFormat: Text.PlainText
        color: Tokens.ink
        font.family: Tokens.display
        font.weight: Tokens.displayWeightSet ? Tokens.displayWeight : Font.Bold
        font.pixelSize: 20 * head.s
        elide: Text.ElideRight
    }

    Row {
        id: trailing
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4 * head.s
    }
}
