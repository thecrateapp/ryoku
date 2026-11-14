pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons as Ui
import "look"

// A label and value pair: a subtext label on the left, the value in the body
// size on the right. Under crate it is the kit's InfoRow: a tracked caption and
// the value in mono.
Item {
    id: root

    property real s: 1
    property string label: ""
    property string value: ""

    readonly property bool crate: Ui.Tokens.controlsCrate

    implicitHeight: 24 * root.s

    Kit.InfoRow {
        objectName: "gameBarInfoRow"
        visible: root.crate
        anchors.fill: parent
        s: root.s
        label: root.label
        valueText: root.value
    }

    Text {
        visible: !root.crate
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: GameBarLook.subtext
        font.family: GameBarLook.face
        font.pixelSize: GameBarLook.smallie * root.s
        elide: Text.ElideRight
        width: Math.min(implicitWidth, root.width * 0.45)
    }

    Text {
        visible: !root.crate
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.value
        color: GameBarLook.fg
        font.family: GameBarLook.face
        font.pixelSize: GameBarLook.small * root.s
        elide: Text.ElideRight
        width: Math.min(implicitWidth, root.width * 0.55)
        horizontalAlignment: Text.AlignRight
    }
}
