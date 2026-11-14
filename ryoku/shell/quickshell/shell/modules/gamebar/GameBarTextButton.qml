pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons as Ui
import "look"

// A text button at overlay size: a 12px radius, 40px tall, one raised fill,
// a layer wash under the pointer. The primary and danger forms take the accent
// and error roles whole.
// Under crate it is the kit's Btn: a primary action (Record) is the confirm
// fill, a danger one (Stop a recording, a task's armed Stop) the kit's danger
// fill in the theme's error role, the rest keep the hairline.
Item {
    id: root

    readonly property bool crate: Ui.Tokens.controlsCrate

    property real s: 1
    property string label: ""
    property bool primary: false
    property bool danger: false
    property bool quiet: false
    property bool compact: false
    // a navigation action (open a folder): the kit's outline under crate
    property bool outline: false

    signal clicked()

    implicitWidth: root.crate ? kit.implicitWidth * root.s : text.implicitWidth + (root.compact ? 20 : 30) * root.s
    implicitHeight: root.crate ? kit.implicitHeight * root.s : (root.compact ? 32 : 40) * root.s

    Kit.Btn {
        id: kit
        objectName: "gameBarKitButton"
        visible: root.crate
        anchors.centerIn: parent
        width: root.width / root.s
        height: root.height / root.s
        scale: root.s
        text: root.label
        compact: root.compact
        primary: root.primary
        danger: root.danger
        outline: root.outline
        armed: root.crate && root.enabled
        onAct: root.clicked()
    }

    Rectangle {
        visible: !root.crate
        anchors.fill: parent
        radius: GameBarLook.radiusSmall * root.s
        color: {
            if (root.primary)
                return pointer.containsMouse ? Qt.lighter(GameBarLook.accent, 1.1) : GameBarLook.accent;
            if (root.danger)
                return pointer.containsMouse ? Qt.lighter(GameBarLook.danger, 1.1) : GameBarLook.danger;
            if (root.quiet)
                return pointer.containsMouse ? GameBarLook.hover : "transparent";
            return pointer.containsMouse ? GameBarLook.raisedHover : GameBarLook.raised;
        }

        Behavior on color {
            ColorAnimation { duration: 120 }
        }
    }

    Text {
        id: text
        visible: !root.crate
        anchors.centerIn: parent
        text: root.label
        color: root.primary ? GameBarLook.accentInk
            : root.danger ? GameBarLook.onDanger
            : GameBarLook.fg
        font.family: GameBarLook.face
        font.pixelSize: (root.compact ? GameBarLook.smallie : GameBarLook.small) * root.s
    }

    MouseArea {
        id: pointer
        enabled: !root.crate
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
