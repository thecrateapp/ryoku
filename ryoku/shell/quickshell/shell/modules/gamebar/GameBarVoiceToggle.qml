pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons as Ui
import "../../components"
import "look"

// One round voice control: a glyph on a filled circle that switches to the
// toggled tone while the mic or headphones are on.
// Under crate it is the kit's plateless IconButton in the alert ink while the
// mic is muted or the headphones deafened, the state a muted channel shows
// everywhere in the shell.
Item {
    id: toggle

    readonly property bool crate: Ui.Tokens.controlsCrate

    property real s: 1
    property string glyph: ""
    property bool on: false
    property real diameter: 34 * toggle.s

    signal clicked()

    width: toggle.diameter
    height: toggle.diameter

    Rectangle {
        visible: !toggle.crate
        anchors.fill: parent
        radius: height / 2
        color: toggle.on ? GameBarLook.toggled
            : (togglePointer.containsMouse ? GameBarLook.hover : GameBarLook.raised)

        Behavior on color {
            ColorAnimation { duration: 120 }
        }
    }

    GlyphIcon {
        visible: !toggle.crate
        anchors.centerIn: parent
        width: toggle.diameter * 0.5
        height: toggle.diameter * 0.5
        name: toggle.glyph
        color: toggle.on ? GameBarLook.toggledInk : GameBarLook.fg
        stroke: 1.8
    }

    Kit.IconButton {
        id: kit
        objectName: "gameBarVoiceButton"
        visible: toggle.crate
        enabled: toggle.crate
        anchors.fill: parent
        iconSize: Math.round(toggle.diameter * 0.5)
        alert: toggle.on
        glyph: GameBarLook.solar(toggle.glyph)
        path: kit.glyph.length > 0 ? "" : GameBarLook.linePath(toggle.glyph)
        onClicked: toggle.clicked()
    }

    MouseArea {
        id: togglePointer
        enabled: !toggle.crate
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: toggle.clicked()
    }
}
