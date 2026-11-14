import stage.modules.common
import stage.modules.common.widgets
import Ryoku.Ui as Ui
import Ryoku.Ui.Singletons
import QtQuick

/**
 * The counterpart to EditRemoveBadge: the "put this one on" badge Edit Mode
 * pins to a dock app that is only open, not kept. A click is the whole
 * gesture, and Ctrl+Z is the confirmation.
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
    color: root.crate ? Tokens.mark : Appearance.colors.colPrimary

    Ui.Glyph {
        anchors.centerIn: parent
        visible: root.crate
        name: "add"
        size: 12
        color: Tokens.paper
    }
    MaterialSymbol {
        anchors.centerIn: parent
        visible: !root.crate
        text: "add"
        iconSize: 12
        color: Appearance.colors.colOnPrimary
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
