import QtQuick
import QtQuick.Effects
import Ryoku.Blobs
import shell.services
import "../../components"
import Ryoku.Ui
import Ryoku.Ui.Singletons

// What the camera bubble draws: a rounded backdrop and cue until the first
// frame arrives (the feed is transparent while the camera warms up), the live
// feed masked to the bubble's shape, and the rim tracing that shape. Pure
// drawing; CameraOverlay owns the drag, the handles and the input mask.
//
// Under controls "crate" the backdrop is the opaque popover, the cue the kit's
// Solar videocamera, and the rim a 1 px line in the mark, so the bubble's edge
// reads over any desktop.
Item {
    id: face

    readonly property bool crate: Tokens.controlsCrate

    // corner radius of the bubble shape, from Camera.roundness
    property real rad: 0
    // per-monitor UI scale, threaded from the overlay (1 = no-op)
    property real us: 1

    Rectangle {
        objectName: "cameraBackdrop"
        anchors.fill: parent
        radius: face.rad
        color: face.crate ? Tokens.popover : Theme.frameBg
    }
    GlyphIcon {
        objectName: "cameraCueStock"
        visible: !face.crate
        anchors.centerIn: parent
        width: 28 * face.us
        height: 28 * face.us
        name: "webcam"
        color: Theme.onSurfaceVariant
        stroke: 1.7
    }
    Glyph {
        objectName: "cameraCue"
        visible: face.crate
        anchors.centerIn: parent
        name: "videocamera"
        size: 28 * face.us
        color: Tokens.inkDim
    }

    // live feed, rendered as a scene-graph texture so the mask applies.
    CameraFeed {
        anchors.fill: parent
        active: Camera.active
        mirror: Camera.flipped
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: maskRect
        }
    }
    Rectangle {
        id: maskRect
        anchors.fill: parent
        radius: face.rad
        visible: false
        layer.enabled: true
    }

    // rim tracing the same shape.
    Rectangle {
        objectName: "cameraRim"
        anchors.fill: parent
        radius: face.rad
        color: "transparent"
        border.width: face.crate ? Tokens.border * face.us : 2 * face.us
        border.color: face.crate ? Tokens.mark : Theme.primary
    }
}
