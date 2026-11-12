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
    radius: Tokens.radius
    // off sits on a faint tint with a dim knob, on brightens the track and fills
    // the knob: two signals for one state, so it reads at a glance. A theme with
    // accent marks fills the live track with the accent instead.
    readonly property bool accentOn: sw.on && Tokens.accentMarks
    color: Tokens.controlsCrate ? "transparent" : sw.accentOn ? Tokens.sun : (tap.pressed || sw.on ? Tokens.tint16 : Tokens.tint5)
    border.width: Tokens.controlsCrate ? 0 : Tokens.border
    border.color: activeFocus ? (Tokens.focusAccent ? Tokens.sunHi : Tokens.bone)
        : (sw.accentOn ? Tokens.sun : (hh.hovered ? Tokens.lineStrong : Tokens.line))
    antialiasing: false
    Behavior on border.color { ColorAnimation { duration: Tokens.snap } }
    Behavior on color { ColorAnimation { duration: Tokens.snap } }

    Rectangle {
        visible: !Tokens.controlsCrate
        width: 25
        height: 17
        y: 3
        x: sw.on ? parent.width - width - 3 : 3
        radius: Tokens.radius
        antialiasing: false
        // off is a dim knob on a hairline track, not an empty outline: the state
        // has to be readable at a glance, which an outlined box is not.
        color: sw.accentOn ? Tokens.inkOnBone : (sw.on ? Tokens.ink : Tokens.inkDim)
        border.width: 0
        Behavior on x { NumberAnimation { duration: Tokens.snap; easing.type: Tokens.easeSnap } }
    }
    // crate-mark: a slim 34x18 pill drawn at its own size, right-aligned, so a
    // caller that stretches the switch to its control slot cannot distort it
    Rectangle {
        visible: Tokens.controlsCrate
        width: 34
        height: 18
        radius: 9
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        antialiasing: true
        color: sw.on ? Qt.rgba(Tokens.mark.r, Tokens.mark.g, Tokens.mark.b, 0.12) : "transparent"
        border.width: 1
        border.color: sw.activeFocus ? Tokens.focus : sw.on ? Tokens.mark : (hh.hovered ? Tokens.markHover : Tokens.line)
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }
        Rectangle {
            width: 10
            height: 10
            radius: 5
            y: 4
            x: sw.on ? parent.width - width - 4 : 4
            antialiasing: true
            color: sw.on ? Tokens.mark : Tokens.inkDim
            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        }
    }
    HoverHandler { id: hh; cursorShape: Qt.PointingHandCursor }
    TapHandler { id: tap; onTapped: sw.toggled(!sw.on) }
}
