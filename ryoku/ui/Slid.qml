import QtQuick
import "Singletons"

// ratio. for quantities where the felt effect outranks the number. the track
// is 42% of the cell; the cell's numeral is the readout, so this stays mute.
Item {
    id: slid
    property real value: 0
    property real from: 0
    property real to: 100
    signal modified(real v)

    readonly property real frac: to > from ? (value - from) / (to - from) : 0
    implicitHeight: 24

    Rectangle {
        visible: !Tokens.controlsCrate
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 4
        color: "transparent"
        border.width: Tokens.border
        border.color: hh.hovered ? Tokens.lineStrong : Tokens.line
        antialiasing: false
    }
    Rectangle {
        visible: !Tokens.controlsCrate
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width * slid.frac
        height: 4
        color: Tokens.mark
        antialiasing: false
    }
    Rectangle {
        visible: !Tokens.controlsCrate
        x: Math.min(parent.width - 6, Math.max(0, parent.width * slid.frac - 3))
        anchors.verticalCenter: parent.verticalCenter
        width: 6
        height: 17
        color: Tokens.mark
        antialiasing: false
    }
    HoverHandler { id: hh; enabled: !Tokens.controlsCrate; cursorShape: Qt.PointingHandCursor }
    TapHandler { enabled: !Tokens.controlsCrate; onTapped: (p) => slid.seat(p.position.x) }
    DragHandler {
        enabled: !Tokens.controlsCrate
        target: null
        onCentroidChanged: if (active) slid.seat(centroid.position.x)
    }
    // the crate-mark look: the same value and signal, drawn as a Beam
    Beam {
        visible: Tokens.controlsCrate
        enabled: Tokens.controlsCrate
        anchors.fill: parent
        value: slid.value
        from: slid.from
        to: slid.to
        onMoved: (v) => slid.modified(Math.round(v * 100) / 100)
    }
    function seat(x) {
        var f = Math.max(0, Math.min(1, x / width));
        modified(Math.round((from + f * (to - from)) * 100) / 100);
    }
}
