import QtQuick
import QtQuick.Effects
import "Singletons"
import "lib/beam.js" as BeamMath

// The crate-mark Beam: a slider or a progress track drawn as a 1 px hairline with
// a gradient fill, a soft trail, a dot head in a halo, and a thumb that shows only
// on hover or drag. `to` is the 100 % mark; a `limit` above it extends the track
// (volume boost) and paints the part past the mark as an over segment. Set
// `interactive: false` for a meter, `indeterminate` for work of unknown length.
// The value is controlled: the Beam emits moved() while dragging and committed()
// on release; the owner sets `value`.
Item {
    id: beam

    property real value: 0
    property real from: 0
    property real to: 1
    property real limit: 0
    property real stepSize: 0
    property bool interactive: true
    property bool indeterminate: false
    // show the thumb while an owner that handles input itself (a QQC.Slider
    // drawing through a Beam) is hovered, pressed or focused
    property bool hotHint: false

    signal moved(real v)
    signal committed(real v)

    readonly property var range: ({ from: beam.from, to: beam.to, limit: beam.limit, step: beam.stepSize })
    readonly property real frac: BeamMath.fraction(beam.range, beam.value)
    readonly property real mainFrac: BeamMath.mainFraction(beam.range, beam.value)
    readonly property real overFrac: BeamMath.overFraction(beam.range, beam.value)
    readonly property real markFrac: BeamMath.markFraction(beam.range)
    readonly property bool extended: beam.limit > beam.to
    readonly property real cy: Math.round(height / 2)
    readonly property real headX: Math.round(width * beam.frac)
    readonly property bool hot: beam.hotHint || (beam.interactive && (area.containsMouse || area.pressed || beam.activeFocus))

    implicitHeight: 24
    implicitWidth: 160
    activeFocusOnTab: beam.interactive

    function nudge(sign) {
        var step = beam.stepSize > 0 ? beam.stepSize : BeamMath.span(beam.range) / 50;
        var top = beam.extended ? beam.limit : beam.to;
        var v = Math.max(beam.from, Math.min(top, beam.value + sign * step));
        beam.moved(v);
        beam.committed(v);
    }
    Keys.onLeftPressed: beam.nudge(-1)
    Keys.onDownPressed: beam.nudge(-1)
    Keys.onRightPressed: beam.nudge(1)
    Keys.onUpPressed: beam.nudge(1)

    // track
    Rectangle { y: beam.cy; width: beam.width; height: 1; color: Tokens.line }

    // Soft trail behind the one-pixel fill.
    Rectangle {
        visible: !beam.indeterminate && beam.mainFrac > 0
        x: 0
        y: beam.cy + 0.5 - height / 2
        width: Math.round(beam.width * beam.mainFrac)
        height: 6
        radius: height / 2
        opacity: 0.65
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.44; color: Qt.rgba(Tokens.sun.r, Tokens.sun.g, Tokens.sun.b, 0.08) }
            GradientStop { position: 0.82; color: Qt.rgba(Tokens.sun.r, Tokens.sun.g, Tokens.sun.b, 0.28) }
            GradientStop { position: 1.0; color: Qt.rgba((Tokens.beamTail.r + Tokens.thumb.r) / 2,
                                                         (Tokens.beamTail.g + Tokens.thumb.g) / 2,
                                                         (Tokens.beamTail.b + Tokens.thumb.b) / 2, 1) }
        }
        layer.enabled: visible
        layer.effect: MultiEffect {
            blurEnabled: true
            blurMax: 8
            blur: 0.5
            autoPaddingEnabled: true
        }
    }

    // fill up to the 100 % mark
    Rectangle {
        visible: !beam.indeterminate
        y: beam.cy
        width: Math.round(beam.width * beam.mainFrac)
        height: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Qt.rgba(Tokens.sun.r, Tokens.sun.g, Tokens.sun.b, 0.14) }
            GradientStop { position: 0.5; color: Qt.rgba(Tokens.sun.r, Tokens.sun.g, Tokens.sun.b, 0.56) }
            GradientStop { position: 1.0; color: Tokens.beamTail }
        }
        Behavior on width {
            enabled: !area.pressed && !Tokens.reduceMotion
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }
    }

    // past the mark: the over segment and the mark itself
    Rectangle {
        visible: beam.extended && !beam.indeterminate && beam.overFrac > 0
        x: Math.round(beam.width * beam.markFrac)
        y: beam.cy
        width: Math.round(beam.width * beam.overFrac)
        height: 1
        color: Tokens.alert
    }
    Rectangle {
        visible: beam.extended
        x: Math.round(beam.width * beam.markFrac)
        y: beam.cy + 0.5 - height / 2
        width: 1
        height: 7
        color: Tokens.inkFaint2
    }

    // Head and halo share the center of the fill.
    Rectangle {
        visible: !beam.indeterminate && beam.frac > 0
        x: beam.headX - width / 2
        y: beam.cy + 0.5 - height / 2
        width: 6
        height: width
        radius: width / 2
        color: Qt.rgba(Tokens.sun.r, Tokens.sun.g, Tokens.sun.b, 0.22)
    }
    Rectangle {
        visible: !beam.indeterminate && beam.frac > 0
        x: beam.headX - width / 2
        y: beam.cy + 0.5 - height / 2
        width: 2
        height: width
        radius: width / 2
        color: Tokens.thumb
        opacity: 0.62
    }

    // thumb: only while the pointer is over the track, dragging, or focused
    Rectangle {
        visible: !beam.indeterminate
        x: beam.headX - width / 2
        y: beam.cy + 0.5 - height / 2
        width: 8
        height: width
        radius: width / 2
        color: Qt.rgba(Tokens.sun.r, Tokens.sun.g, Tokens.sun.b, 0.14)
        opacity: beam.hot ? 1 : 0
        Behavior on opacity {
            enabled: !Tokens.reduceMotion
            NumberAnimation { duration: 150 }
        }
        Rectangle {
            anchors.centerIn: parent
            width: 4
            height: width
            radius: width / 2
            color: Tokens.thumb
            border.width: 1
            border.color: Qt.rgba(Tokens.sun.r, Tokens.sun.g, Tokens.sun.b, 0.8)
        }
    }

    // indeterminate: a short segment sweeping across; held still under reduced motion
    Rectangle {
        id: sweep
        visible: beam.indeterminate
        y: beam.cy
        width: Math.max(24, beam.width * 0.22)
        height: 1
        x: Tokens.reduceMotion ? (beam.width - width) / 2 : -width
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.7; color: Tokens.beamTail }
            GradientStop { position: 1.0; color: Tokens.thumb }
        }
        NumberAnimation on x {
            running: beam.indeterminate && beam.visible && !Tokens.reduceMotion
            loops: Animation.Infinite
            from: -sweep.width
            to: beam.width
            duration: 1100
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        enabled: beam.interactive && !beam.indeterminate
        hoverEnabled: true
        cursorShape: beam.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        onPressed: (m) => {
            beam.forceActiveFocus();
            beam.moved(BeamMath.valueAt(beam.range, m.x, beam.width));
        }
        onPositionChanged: (m) => {
            if (pressed)
                beam.moved(BeamMath.valueAt(beam.range, m.x, beam.width));
        }
        onReleased: (m) => beam.committed(BeamMath.valueAt(beam.range, m.x, beam.width))
    }
}
