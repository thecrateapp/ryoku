pragma ComponentBehavior: Bound

import QtQuick
import shell.services
import "../../components"
import Ryoku.Ui
import Ryoku.Ui.Singletons

// Visual edit-handle indicators for the camera bubble. The drag logic lives in
// CameraOverlay's single DragHandler, which moves / resizes / rounds by press
// zone -- so these are pure visuals (no competing handlers) plus one flip tap.
// A roundness dot (top-left, at `rad` along the diagonal), a resize grip
// (bottom-right, kept inside the input mask), a flip toggle (top-right), and
// readouts driven by the current drag `mode`. Revealed on hover, hidden while
// recording so they are never in the shot.
//
// Under controls "crate" the dot and the grip are popover knobs edged in the
// mark, the readouts opaque popover tags with mono values, and the flip the
// kit's IconButton (Solar flip-horizontal) on a popover tile: each keeps its
// own ground, so it reads over whatever the camera sees.
Item {
    id: handles

    readonly property bool crate: Tokens.controlsCrate

    // "" | "move" | "resize" | "round" -- set by the overlay, drives the readouts.
    property string mode: ""

    // Per-monitor UI scale, threaded from the CameraOverlay (default 1 = no-op).
    property real us: 1

    readonly property real maxRad: Math.min(width, height) / 2
    readonly property real rad: Camera.roundness * handles.maxRad

    // roundness dot (top-left, sits `rad` in along the diagonal)
    Rectangle {
        objectName: "cameraRoundDot"
        width: 14 * handles.us
        height: 14 * handles.us
        radius: width / 2
        x: handles.rad - width / 2
        y: handles.rad - height / 2
        color: handles.crate ? Tokens.popover : Theme.onSurface
        border.width: handles.crate ? Tokens.border * handles.us : 2 * handles.us
        border.color: handles.crate ? Tokens.mark : Theme.primary
        HoverHandler { cursorShape: Qt.SizeFDiagCursor }
    }
    Rectangle { // "Radius N" readout
        objectName: "cameraRadiusTag"
        visible: handles.mode === "round"
        x: handles.rad + 12 * handles.us
        y: handles.rad - height / 2
        width: rL.implicitWidth + (handles.crate ? 2 * Tokens.s2 : 12) * handles.us
        height: rL.implicitHeight + 8 * handles.us
        radius: (handles.crate ? Tokens.radius : 5) * handles.us
        color: handles.crate ? Tokens.popover : Qt.rgba(0, 0, 0, 0.72)
        border.width: handles.crate ? Tokens.border * handles.us : 0
        border.color: Tokens.line
        Text {
            id: rL
            objectName: "cameraRadiusText"
            anchors.centerIn: parent
            text: I18n.tr("Radius %1").arg(Math.round(handles.rad))
            color: handles.crate ? Tokens.ink : Theme.onSurface
            font.family: handles.crate ? Tokens.mono : Theme.mono
            font.pixelSize: (handles.crate ? Tokens.fSmall : 11) * handles.us
            font.weight: handles.crate ? Font.Normal : Font.DemiBold
        }
    }

    // resize grip (bottom-right, inset so it stays inside the bubble input mask)
    Rectangle {
        objectName: "cameraGrip"
        width: 16 * handles.us
        height: 16 * handles.us
        radius: (handles.crate ? Tokens.radius : 3) * handles.us
        x: handles.width - width - 5 * handles.us
        y: handles.height - height - 5 * handles.us
        color: handles.crate ? Tokens.popover : Theme.onSurface
        border.width: handles.crate ? Tokens.border * handles.us : 2 * handles.us
        border.color: handles.crate ? Tokens.mark : Theme.primary
        HoverHandler { cursorShape: Qt.SizeFDiagCursor }
    }
    Rectangle { // "W x H" readout
        objectName: "cameraSizeTag"
        visible: handles.mode === "resize"
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 28 * handles.us
        anchors.bottomMargin: 6 * handles.us
        width: sL.implicitWidth + (handles.crate ? 2 * Tokens.s2 : 12) * handles.us
        height: sL.implicitHeight + 8 * handles.us
        radius: (handles.crate ? Tokens.radius : 5) * handles.us
        color: handles.crate ? Tokens.popover : Qt.rgba(0, 0, 0, 0.72)
        border.width: handles.crate ? Tokens.border * handles.us : 0
        border.color: Tokens.line
        Text {
            id: sL
            objectName: "cameraSizeText"
            anchors.centerIn: parent
            text: Math.round(Camera.bw) + (handles.crate ? "\u00d7" : " x ") + Math.round(Camera.bh)
            color: handles.crate ? Tokens.ink : Theme.onSurface
            font.family: handles.crate ? Tokens.mono : Theme.mono
            font.pixelSize: (handles.crate ? Tokens.fSmall : 11) * handles.us
            font.weight: handles.crate ? Font.Normal : Font.DemiBold
        }
    }

    // flip toggle (top-right) -- a tap target; taps do not compete with the drag.
    Rectangle {
        id: flipBtn
        objectName: "cameraFlipStock"
        visible: !handles.crate
        width: 26 * handles.us
        height: 26 * handles.us
        radius: width / 2
        x: handles.width - width - 6 * handles.us
        y: 6 * handles.us
        color: Qt.rgba(0, 0, 0, flipHov.hovered ? 0.72 : 0.5)
        border.width: 1 * handles.us
        border.color: Qt.rgba(1, 1, 1, 0.12)
        GlyphIcon {
            anchors.centerIn: parent
            width: 15 * handles.us
            height: 15 * handles.us
            name: "flip"
            color: Camera.flipped ? Theme.primary : Theme.onSurface
            stroke: 1.7
        }
        HoverHandler { id: flipHov; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: Camera.flipped = !Camera.flipped }
    }

    // the crate flip: the kit IconButton, on while mirrored, on a popover tile
    Rectangle {
        objectName: "cameraFlip"
        visible: handles.crate
        width: 28 * handles.us
        height: 28 * handles.us
        radius: Tokens.radius * handles.us
        x: handles.width - width - 6 * handles.us
        y: 6 * handles.us
        color: Tokens.popover
        border.width: Tokens.border * handles.us
        border.color: Tokens.line
        IconButton {
            objectName: "cameraFlipButton"
            anchors.fill: parent
            glyph: "flip-horizontal"
            iconSize: Math.round(16 * handles.us)
            on: Camera.flipped
            onClicked: Camera.flipped = !Camera.flipped
        }
    }
}
