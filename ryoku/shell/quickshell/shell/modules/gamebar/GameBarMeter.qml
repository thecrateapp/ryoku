pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons as Ui
import "look"

// A label and a value over a 4px track, in the overlay's layer colours.
// Under crate it is the kit's MeterRow: a tracked caption, a read-only Beam and
// the value in mono, as crate-mark's vitals list.
Item {
    id: root

    property real s: 1
    property string label: ""
    property string value: ""
    property real fraction: 0
    property color tint: GameBarLook.accent

    readonly property bool crate: Ui.Tokens.controlsCrate

    implicitHeight: root.crate ? kit.implicitHeight : 30 * root.s

    readonly property real amount: Math.max(0, Math.min(1, root.fraction))

    Kit.MeterRow {
        id: kit
        objectName: "gameBarMeterRow"
        visible: root.crate
        width: root.width
        s: root.s
        label: root.label
        valueText: root.value
        fraction: root.amount
    }

    Item {
        visible: !root.crate
        anchors.fill: parent

        Text {
            anchors.left: parent.left
            anchors.top: parent.top
            text: root.label
            color: GameBarLook.subtext
            font.family: GameBarLook.face
            font.pixelSize: GameBarLook.smallie * root.s
        }

        Text {
            anchors.right: parent.right
            anchors.top: parent.top
            text: root.value
            color: GameBarLook.fg
            font.family: GameBarLook.face
            font.pixelSize: GameBarLook.small * root.s
        }

        Rectangle {
            id: track
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 4 * root.s
            radius: height / 2
            color: GameBarLook.raised

            Rectangle {
                width: track.width * root.amount
                height: parent.height
                radius: parent.radius
                color: root.tint
            }
        }
    }
}
