import QtQuick
import "Singletons"

// boolean. two named modes are a Seg, not a switch.
Rectangle {
    id: sw
    property bool on: false
    signal toggled(bool v)

    activeFocusOnTab: true
    function activate() { toggled(!on) }
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            activate();
            event.accepted = true;
        }
    }

    implicitWidth: Tokens.controlsCrate ? 34 : 54
    implicitHeight: Tokens.controlsCrate ? 18 : 24
    radius: Tokens.controlsCrate ? height / 2 : Tokens.radius
    // off sits on a faint tint with a dim knob, on brightens the track and fills
    // the knob: two signals for one state, so it reads at a glance. A theme with
    // accent marks fills the live track with the accent instead.
    readonly property bool accentOn: sw.on && Tokens.accentMarks
    color: Tokens.controlsCrate ? (sw.on ? Qt.rgba(Tokens.mark.r, Tokens.mark.g, Tokens.mark.b, 0.12) : "transparent")
        : sw.accentOn ? Tokens.sun : (tap.pressed || sw.on ? Tokens.tint16 : Tokens.tint5)
    border.width: Tokens.border
    border.color: activeFocus ? (Tokens.focusAccent ? Tokens.sunHi : Tokens.bone)
        : Tokens.controlsCrate ? (sw.on ? Tokens.mark : (hh.hovered ? Tokens.markHover : Tokens.line))
        : (sw.accentOn ? Tokens.sun : (hh.hovered ? Tokens.lineStrong : Tokens.line))
    antialiasing: Tokens.controlsCrate
    Behavior on border.color { ColorAnimation { duration: Tokens.snap } }
    Behavior on color { ColorAnimation { duration: Tokens.snap } }

    Rectangle {
        width: Tokens.controlsCrate ? 10 : 25
        height: Tokens.controlsCrate ? 10 : 17
        y: Tokens.controlsCrate ? 4 : 3
        x: sw.on ? parent.width - width - (Tokens.controlsCrate ? 4 : 3) : (Tokens.controlsCrate ? 4 : 3)
        radius: Tokens.controlsCrate ? 5 : Tokens.radius
        antialiasing: Tokens.controlsCrate
        // off is a dim knob on a hairline track, not an empty outline: the state
        // has to be readable at a glance, which an outlined box is not.
        color: Tokens.controlsCrate ? (sw.on ? Tokens.mark : Tokens.inkDim) : sw.accentOn ? Tokens.inkOnBone : (sw.on ? Tokens.ink : Tokens.inkDim)
        border.width: 0
        Behavior on x { NumberAnimation { duration: Tokens.snap; easing.type: Tokens.easeSnap } }
    }
    HoverHandler { id: hh; cursorShape: Qt.PointingHandCursor }
    TapHandler { id: tap; onTapped: sw.toggled(!sw.on) }
}
