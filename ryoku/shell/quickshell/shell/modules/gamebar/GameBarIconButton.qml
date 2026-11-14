pragma ComponentBehavior: Bound

import QtQuick
import shell.services
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons as Ui
import "../../components"
import "look"

// A 30px circle holding a 20px glyph, filled with the
// secondary container while its state is on, a layer wash under the pointer.
// No red hover: the overlay's close button is an ordinary button.
// Under crate it is the kit's plateless IconButton: the Solar glyph where the
// catalogue has one, else the Game Bar's own line icon or Material symbol, the
// mark ink while its state is on.
Item {
    id: root

    property real s: 1
    property real size: 30
    property string glyph: ""
    property string symbol: ""
    property bool toggled: false

    signal clicked()

    readonly property bool crate: Ui.Tokens.controlsCrate

    implicitWidth: root.size * root.s
    implicitHeight: root.size * root.s
    scale: !root.crate && pointer.pressed ? 0.92 : 1

    readonly property real iconSize: root.size * 0.7 * root.s

    Behavior on scale {
        NumberAnimation { duration: Motion.dur(110); easing.type: Easing.OutCubic }
    }

    Rectangle {
        visible: !root.crate
        anchors.fill: parent
        radius: height / 2
        color: root.toggled ? GameBarLook.toggled
            : (pointer.containsMouse ? GameBarLook.hover : "transparent")

        Behavior on color {
            ColorAnimation { duration: Motion.dur(120) }
        }
    }

    MaterialIcon {
        anchors.centerIn: parent
        width: root.iconSize
        height: root.iconSize
        visible: !root.crate && root.symbol.length > 0
        text: root.symbol
        color: root.toggled ? GameBarLook.toggledInk : GameBarLook.fg
        fill: root.toggled ? 1 : 0
        font.pixelSize: root.iconSize

        Behavior on color {
            ColorAnimation { duration: Motion.dur(120) }
        }
    }

    GlyphIcon {
        anchors.centerIn: parent
        width: root.size * 2 / 3 * root.s
        height: root.size * 2 / 3 * root.s
        visible: !root.crate && root.symbol.length === 0
        name: root.glyph
        color: root.toggled ? GameBarLook.toggledInk : GameBarLook.fg
        stroke: 1.7
    }

    Kit.IconButton {
        id: kit
        objectName: "gameBarKitButton"
        visible: root.crate
        enabled: root.crate && root.enabled
        anchors.centerIn: parent
        width: root.width
        height: root.height
        iconSize: Math.round(18 * root.s)
        on: root.toggled
        readonly property string wanted: root.symbol.length > 0 ? root.symbol : root.glyph
        glyph: GameBarLook.solar(kit.wanted) || (root.symbol.length > 0 ? root.symbol : "")
        glyphFont: "Material Symbols Rounded"
        path: kit.glyph.length > 0 ? "" : GameBarLook.linePath(root.glyph)
        onClicked: root.clicked()

        GlyphIcon {
            visible: kit.glyph.length === 0 && GameBarLook.lineFilled(root.glyph)
            anchors.centerIn: parent
            width: kit.iconSize
            height: kit.iconSize
            name: root.glyph
            color: kit.ink
        }
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
