import QtQuick
import "Singletons"

Rectangle {
    id: btn

    property alias text: lab.text
    property bool primary: false
    // a navigation action (Open, Browse): no fill, the mark on the edge and the
    // label; it wins over primary when both are set
    property bool outline: false
    property bool armed: true
    property bool compact: false
    property bool motionEnabled: !Tokens.reduceMotion
    // A TapHandler is passive: it never takes focus from a TextInput, so a
    // field's editingFinished (and its commit into the draft) does not fire
    // when the user types and then clicks the button directly. The commit-on-
    // save loss it causes (#294) is invisible and silent, so buttons that act
    // on the whole page opt in to stealing focus on press, the way a real
    // toolkit button does. Off by default: a button inside a list row would
    // have the commit's rebuild destroy its own delegate mid-tap.
    property bool stealFocus: false
    signal act()
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            if (btn.armed && !event.isAutoRepeat)
                btn.act();
            event.accepted = true;
        }
    }

    implicitWidth: lab.implicitWidth + (compact ? 20 : 30)
    implicitHeight: compact ? 24 : (Tokens.controlsCrate ? 34 : 32)
    radius: Tokens.radius
    // 0.5, not 0.3: a control that cannot act must still be legible as itself
    // (the reader needs to see what is there and why it is inert), while the
    // dimming keeps it from reading as available.
    opacity: armed ? 1 : 0.5
    // crate-mark (D4): a confirm action fills with the accent, a navigation
    // action is an accent outline washing on hover, a plain one keeps a hairline
    color: Tokens.controlsCrate ? (primary && armed ? (bh.hovered ? Tokens.beamTail : Tokens.sun)
            : outline ? (bh.hovered && armed ? Qt.rgba(Tokens.sun.r, Tokens.sun.g, Tokens.sun.b, 0.10) : "transparent")
            : (bh.hovered && armed ? Tokens.tint5 : "transparent"))
        : outline ? (bh.hovered && armed ? Tokens.rowWash : "transparent")
        : (primary && armed ? Tokens.bone : (tap.pressed && armed ? Tokens.tint16 : (bh.hovered && armed ? Tokens.tint10 : "transparent")))
    border.width: Tokens.border
    border.color: activeFocus ? (Tokens.focusAccent ? Tokens.focus : Tokens.bone)
        : Tokens.controlsCrate ? (primary || outline ? Tokens.sun : (bh.hovered && armed ? Tokens.markHover : Tokens.line))
        : (outline ? Tokens.mark : (primary && armed ? Tokens.bone : (bh.hovered && armed ? Tokens.lineStrong : Tokens.line)))
    Behavior on color { enabled: btn.motionEnabled; ColorAnimation { duration: Tokens.snap } }
    Behavior on opacity { enabled: btn.motionEnabled; NumberAnimation { duration: Tokens.snap } }

    Text {
        id: lab
        anchors.centerIn: parent
        color: Tokens.controlsCrate ? (btn.primary && btn.armed ? Tokens.paper : Tokens.ink)
            : btn.outline ? Tokens.mark : (btn.primary && btn.armed ? Tokens.inkOnBone : Tokens.ink)
        font.family: Tokens.controlsCrate ? Tokens.mono : Tokens.ui
        font.pixelSize: btn.compact ? 10 : (Tokens.controlsCrate ? 12 : 11)
        font.weight: Tokens.controlsCrate ? Font.Normal : Font.Medium
        font.letterSpacing: Tokens.controlsCrate ? 12 * 0.04 : Tokens.trackLabel
        // Longer translations (Portuguese, German) must not be clipped when a
        // caller fixes the button narrower than the label wants: the text
        // elides instead. Unconstrained buttons still size to their text.
        width: Math.max(0, parent.width - (btn.compact ? 20 : 30))
        // a button stretched past its text (half of a dialog's row) keeps it centred
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
    }
    HoverHandler { id: bh; enabled: btn.armed; cursorShape: Qt.PointingHandCursor }
    TapHandler { id: tap; enabled: btn.armed
        onPressedChanged: if (tap.pressed && btn.stealFocus) btn.forceActiveFocus()
        onTapped: btn.act() }
}
