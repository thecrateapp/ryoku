pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.Ui.Singletons as Ui
import "../../components"
import "look"

// A tile action in the capture grid: a 24px glyph over a 13px label on a raised
// 12px surface, the same fill the overlay's controls use.
// Under crate it takes the kit chip's grammar: no fill, a hairline edge that
// warms on hover, the 6 px corner, the Solar glyph where the catalogue has one
// and the label in mono.
Item {
    id: root

    readonly property bool crate: Ui.Tokens.controlsCrate
    readonly property bool hot: pointer.containsMouse && root.available

    property real s: 1
    property string icon: ""
    property string label: ""
    property bool available: true

    signal clicked()

    implicitWidth: 68 * root.s
    implicitHeight: 62 * root.s

    Rectangle {
        objectName: "gameBarActionTile"
        anchors.fill: parent
        radius: GameBarLook.radiusSmall * root.s
        color: root.crate ? "transparent"
            : pointer.containsMouse && root.available ? GameBarLook.raisedHover : GameBarLook.raised
        border.width: root.crate ? Ui.Tokens.border : 0
        border.color: root.hot ? Ui.Tokens.markHover : Ui.Tokens.line
        opacity: root.available ? 1 : (root.crate ? 0.5 : 0.4)

        Column {
            anchors.centerIn: parent
            spacing: 6 * root.s

            GameBarGlyph {
                anchors.horizontalCenter: parent.horizontalCenter
                width: (root.crate ? 20 : 24) * root.s
                height: (root.crate ? 20 : 24) * root.s
                glyph: root.icon
                color: root.crate && !root.hot ? GameBarLook.onLayer : GameBarLook.fg
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.label
                color: root.crate && root.hot ? GameBarLook.fg : GameBarLook.onLayer
                font.family: root.crate ? GameBarLook.numeric : GameBarLook.face
                font.pixelSize: GameBarLook.smallie * root.s
            }
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.available
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
