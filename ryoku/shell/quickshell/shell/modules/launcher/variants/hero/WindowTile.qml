import QtQuick
import Quickshell.Widgets
import Ryoku.Ui
import Ryoku.Ui.Singletons
import "../../shared/Singletons"
import shell.services as Svc

// One open window in the rail under the launcher card: the app's icon, the
// window title over its workspace. Under crate each tile is a small glass card
// (Tokens.glass in a hairline at Tokens.radius, frosted by the compositor's
// crate-glass rule on the rail's layer); the focused one takes the pick wash in
// the 1 px pickEdge. Stock keeps the raised drawer tile and the bone plate in a
// 2 px bright edge for the focused one.
Rectangle {
    id: tile

    property real s: 1
    property string title: ""
    property string cls: ""
    property string workspace: ""
    property bool picked: false

    readonly property bool crate: Tokens.controlsCrate

    width: 184 * s
    height: 64 * s
    radius: crate ? Tokens.radius : Math.max(2, 5 * s)
    color: crate ? Tokens.glass : picked ? Theme.leadContainer : Theme.drawerRaised
    border.width: crate ? Tokens.border : picked ? 2 : 1
    border.color: crate ? (picked ? Tokens.pickEdge : Tokens.line)
        : picked ? Theme.bright : Theme.hair

    Behavior on color {
        ColorAnimation { duration: Motion.selection; easing.type: Easing.OutCubic }
    }
    Behavior on border.color {
        ColorAnimation { duration: Motion.selection; easing.type: Easing.OutCubic }
    }

    Rectangle {
        objectName: "windowTileWash"
        visible: tile.crate && tile.picked
        anchors.fill: parent
        radius: tile.radius
        color: Tokens.pickFill
    }

    Rectangle {
        id: iconPlate
        objectName: "windowTileIcon"
        anchors.left: parent.left
        anchors.leftMargin: 7 * tile.s
        anchors.verticalCenter: parent.verticalCenter
        width: 32 * tile.s
        height: width
        radius: tile.crate ? Tokens.radius : Math.max(2, 4 * tile.s)
        color: tile.crate ? "transparent"
            : tile.picked ? Qt.rgba(0, 0, 0, 0.18) : Theme.drawerRaised

        IconImage {
            anchors.centerIn: parent
            implicitSize: 21 * tile.s
            source: tile.cls
                ? Svc.Icons.path(tile.cls, "application-x-executable") : ""
        }
    }

    Column {
        anchors.left: iconPlate.right
        anchors.leftMargin: 7 * tile.s
        anchors.right: parent.right
        anchors.rightMargin: 7 * tile.s
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2 * tile.s

        Text {
            width: parent.width
            text: tile.title
            color: tile.crate ? (tile.picked ? Tokens.pickInk : Tokens.ink)
                : tile.picked ? Theme.onLead : Theme.cream
            font.family: tile.crate ? Tokens.ui : Theme.font
            font.pixelSize: tile.crate ? Tokens.fSmall : 9.2 * tile.s
            font.weight: tile.picked ? Font.DemiBold : Font.Medium
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: I18n.tr("OPEN · %1").arg(String(tile.workspace).toUpperCase())
            color: tile.crate ? Tokens.inkSubtle : Theme.faint
            font.family: Theme.mono
            font.pixelSize: tile.crate ? Tokens.fTiny : 6.5 * tile.s
            font.letterSpacing: tile.crate ? Tokens.trackLabel : 0.5 * tile.s
            elide: Text.ElideRight
        }
    }
}
