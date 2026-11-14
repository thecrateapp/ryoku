import QtQuick
import Ryoku.Ui as Kit

// moved fires while dragging; released fires once on let-go.
// A hairline track fills bone to a round knob; the knob springs a touch under the pointer.
// Under crate the slider draws the kit Beam over the same track; it keeps its own
// input, so snapping, dragging and released() behave the same in both looks.
Item {
    id: slider

    property real from: 0
    property real to: 1
    property real value: 0
    // Snap increment; 0 leaves the value continuous.
    property real step: 0

    readonly property bool dragging: drag.pressed
    property bool focused: false

    signal moved(real value)
    signal released(real value)

    implicitHeight: 26 * Theme.scale
    implicitWidth: 160 * Theme.scale

    readonly property real _knob: 12 * Theme.scale
    readonly property real _inset: slider._knob * 0.5
    readonly property real _trackW: Math.max(1, width - slider._inset * 2)
    readonly property real _span: (slider.to - slider.from) || 1
    readonly property real _t: Math.max(0, Math.min(1, (slider.value - slider.from) / slider._span))
    readonly property real _knobX: slider._inset + slider._t * slider._trackW

    function _snap(v) {
        var c = Math.max(slider.from, Math.min(slider.to, v))
        if (slider.step > 0)
            c = slider.from + Math.round((c - slider.from) / slider.step) * slider.step
        return c
    }
    function _fromX(x) {
        var t = (x - slider._inset) / slider._trackW
        return slider._snap(slider.from + t * slider._span)
    }

    Rectangle {
        visible: !Theme.crate
        height: 2
        radius: height
        width: slider._trackW
        x: slider._inset
        y: (slider.height - height) / 2
        color: Theme.withAlpha(Theme.surfaceText, slider.enabled ? 0.18 : 0.1)
    }

    Rectangle {
        visible: !Theme.crate
        height: 2
        radius: height
        width: Math.max(0, slider._knobX - slider._inset)
        x: slider._inset
        y: (slider.height - height) / 2
        color: Theme.withAlpha(Theme.surfaceText, slider.enabled ? 0.9 : 0.35)
    }

    Rectangle {
        visible: !Theme.crate
        width: slider._knob
        height: slider._knob
        radius: slider._knob / 2
        x: slider._knobX - width / 2
        y: (slider.height - height) / 2
        antialiasing: true
        color: slider.enabled ? Theme.surfaceText : Theme.withAlpha(Theme.surfaceText, 0.4)
        scale: slider.dragging ? 1.25 : slider.focused ? 1.15 : 1
        Behavior on scale { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutBack; easing.overshoot: 2.4 } }
    }

    Kit.Beam {
        objectName: "folioBeam"
        visible: Theme.crate
        x: slider._inset
        width: slider._trackW
        height: slider.height
        from: slider.from
        to: slider.to
        value: slider.value
        stepSize: slider.step
        interactive: false
        hotHint: drag.containsMouse || drag.pressed || slider.focused
        opacity: slider.enabled ? 1 : 0.5
    }

    MouseArea {
        id: drag
        anchors.fill: parent
        enabled: slider.enabled
        hoverEnabled: Theme.crate
        preventStealing: true
        cursorShape: Qt.PointingHandCursor
        onPressed: (m) => { var v = slider._fromX(m.x); if (v !== slider.value) { slider.value = v; slider.moved(v) } }
        onPositionChanged: (m) => { if (pressed) { var v = slider._fromX(m.x); if (v !== slider.value) { slider.value = v; slider.moved(v) } } }
        onReleased: slider.released(slider.value)
    }
}
