import QtQuick
import shell.services
import Ryoku.Ui
import Ryoku.Ui.Singletons

// The placement chrome around the keypress stack: an edge around the keys and a
// "DRAG TO PLACE" tag under it, shown while the stack is hovered or dragged and
// never while a recording runs. Pure drawing; KeypressOverlay owns the drag.
//
// Under controls "crate" the edge is a 1 px line in the mark at the shared
// corner, and the tag an opaque popover with the kit's tracked caption; the
// keycaps themselves keep their fixed media stock in both looks.
Item {
    id: place

    // the keycaps' theme: "dark" caps get the light chrome and vice versa
    property bool dark: true
    // hovered or dragged, and no recording running
    property bool shown: false
    // per-monitor UI scale, threaded from the overlay (1 = no-op)
    property real us: 1

    readonly property bool crate: Tokens.controlsCrate

    visible: opacity > 0.01
    opacity: place.shown ? 1 : 0

    Behavior on opacity {
        NumberAnimation { duration: Motion.dur(150); easing.type: Easing.OutCubic }
    }

    Rectangle {
        objectName: "placeEdge"
        anchors.fill: parent
        color: "transparent"
        radius: (place.crate ? Tokens.radius : Tokens.radius + 6) * place.us
        border.width: Tokens.border * place.us
        border.color: place.crate ? Tokens.mark : place.dark ? Tokens.keycapOnDark : Tokens.keycapOnLight
    }

    Rectangle {
        objectName: "placeTag"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.bottom
        anchors.topMargin: Tokens.s1 * place.us
        width: dragLabel.implicitWidth + (place.crate ? 2 * Tokens.s3 : 18) * place.us
        height: 24 * place.us
        radius: place.crate ? Tokens.radius * place.us : height / 2
        color: place.crate ? Tokens.popover : place.dark ? Tokens.keycapLight : Tokens.keycapDark
        border.width: place.crate ? Tokens.border * place.us : 0
        border.color: Tokens.line

        TrackLabel {
            id: dragLabel
            objectName: "placeLabel"
            anchors.centerIn: parent
            text: I18n.tr("DRAG TO PLACE")
            // the stock tag keeps its own face; crate is the kit caption as is
            color: place.crate ? dragLabel.toneInk : place.dark ? Tokens.keycapOnLight : Tokens.keycapOnDark
            font.family: place.crate ? Tokens.mono : Tokens.ui
            font.pixelSize: (place.crate ? Tokens.fMicro : 9) * place.us
            font.weight: place.crate ? Font.Normal : Font.DemiBold
            font.letterSpacing: Tokens.trackLabel * place.us
            font.capitalization: place.crate ? Font.AllUppercase : Font.MixedCase
        }
    }
}
