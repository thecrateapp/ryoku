import QtQuick
import "Singletons"
import "lib/rows.js" as Rows

// A stream row, crate-mark's mixer line for one app or device: its name, an
// interactive Beam and a mute button, on the columns in lib/rows.js. The value
// is controlled: the row emits adjusted() and the owner sets `value`. `capture`
// shows a microphone instead of a speaker; `limit` lets it run past 100 %.
Item {
    id: row

    property real s: 1
    property string name: ""
    property real value: 0
    property bool muted: false
    property bool capture: false
    property bool available: true
    // a limit above 1 extends the beam past 100 % (volume boost), as on Beam
    property real limit: 0
    readonly property real upperLimit: row.limit > 1 ? row.limit : 1
    // a group of rows sets this to its longest name so the beams line up
    property real nameWidth: 0

    signal adjusted(real value)
    signal muteRequested()

    readonly property var cols: Rows.streamColumns(row.width, { s: row.s, nameWidth: row.nameWidth })

    implicitWidth: 320 * row.s
    implicitHeight: Rows.ROW.level * row.s
    opacity: row.available ? 1 : 0.48

    Text {
        x: row.cols.name.x
        width: row.cols.name.w
        anchors.verticalCenter: parent.verticalCenter
        text: row.name
        textFormat: Text.PlainText
        color: row.muted ? Tokens.inkFaint2 : Tokens.ink
        font.family: Tokens.mono
        font.pixelSize: 12 * row.s
        elide: Text.ElideRight
    }

    Beam {
        x: row.cols.beam.x
        width: row.cols.beam.w
        height: 24 * row.s
        anchors.verticalCenter: parent.verticalCenter
        from: 0
        to: 1
        limit: row.limit
        stepSize: 0.01
        value: Math.max(0, Math.min(row.upperLimit, row.value))
        interactive: row.available
        opacity: row.muted ? 0.4 : 1
        Accessible.name: I18n.tr("%1 volume").arg(row.name)
        onMoved: v => row.adjusted(v)

        WheelHandler {
            enabled: row.available
            onWheel: event => {
                row.adjusted(Math.max(0, Math.min(row.upperLimit, row.value + (event.angleDelta.y >= 0 ? 0.02 : -0.02))));
                event.accepted = true;
            }
        }
    }

    IconButton {
        x: row.cols.mute.x
        anchors.verticalCenter: parent.verticalCenter
        width: row.cols.mute.w
        height: width
        iconSize: 18 * row.s
        glyph: row.capture ? (row.muted ? "mic_off" : "mic") : (row.muted ? "volume_off" : "volume_up")
        alert: row.muted
        enabled: row.available
        Accessible.name: row.muted ? I18n.tr("Unmute %1").arg(row.name) : I18n.tr("Mute %1").arg(row.name)
        onClicked: row.muteRequested()
    }
}
