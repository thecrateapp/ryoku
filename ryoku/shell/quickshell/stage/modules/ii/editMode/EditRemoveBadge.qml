import stage.modules.common
import stage.modules.common.widgets
import Ryoku.Ui as Ui
import Ryoku.Ui.Singletons
import QtQuick

/**
 * The small "take this off" badge Edit Mode pins to a bar widget or a dock
 * app: a click is the whole gesture, nothing to confirm - Ctrl+Z is the
 * confirmation.
 */
Rectangle {
    id: root

    signal clicked()

    // Under crate the badge takes the shared corner and its Solar glyph.
    readonly property bool crate: Tokens.controlsCrate

    objectName: "editBadge"
    width: 16
    height: 16
    radius: root.crate ? Tokens.radius : 8
    color: root.crate ? Tokens.alert : Appearance.m3colors.m3error

    Ui.Glyph {
        anchors.centerIn: parent
        visible: root.crate
        name: "close"
        size: 12
        color: Tokens.paper
    }
    MaterialSymbol {
        anchors.centerIn: parent
        visible: !root.crate
        text: "close"
        iconSize: 12
        color: Appearance.m3colors.m3onError
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
