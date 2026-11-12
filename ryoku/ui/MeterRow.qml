import QtQuick
import "Singletons"
import "lib/rows.js" as Rows

// A meter row, crate-mark's vitals list: a tracked caption, a read-only Beam and a
// mono value, on the columns in lib/rows.js. `fraction` is 0..1. `showMeter: false`
// leaves the middle empty (a rate with no scale); `meter` replaces the Beam with
// other content, such as a sparkline. `s` scales the row for surfaces that carry
// their own UI scale.
Item {
    id: row

    property real s: 1
    // a group of rows sets this to the widest caption so the beams line up
    property real labelWidth: 0
    readonly property real labelImplicitWidth: caption.implicitWidth
    property string label: ""
    property string valueText: ""
    property real fraction: 0
    property bool showMeter: true
    property Component meter: null

    readonly property var cols: Rows.meterColumns(row.width, valueText.implicitWidth, { s: row.s, labelWidth: row.labelWidth })

    implicitWidth: 320 * row.s
    implicitHeight: Rows.ROW.meter * row.s

    TrackLabel {
        id: caption
        x: row.cols.label.x
        width: row.cols.label.w
        anchors.verticalCenter: parent.verticalCenter
        text: row.label
        font.pixelSize: Tokens.fMicro * row.s
        font.letterSpacing: Tokens.trackLabel * row.s
    }

    Item {
        x: row.cols.beam.x
        width: row.cols.beam.w
        height: 24 * row.s
        anchors.verticalCenter: parent.verticalCenter

        Beam {
            visible: row.showMeter && row.meter === null
            anchors.fill: parent
            interactive: false
            value: Math.max(0, Math.min(1, isFinite(row.fraction) ? row.fraction : 0))
        }

        Loader {
            anchors.fill: parent
            active: row.visible && row.meter !== null
            sourceComponent: row.meter
        }
    }

    Text {
        id: valueText
        x: row.cols.value.x
        width: row.cols.value.w
        anchors.verticalCenter: parent.verticalCenter
        text: row.valueText
        textFormat: Text.PlainText
        color: Tokens.ink
        font.family: Tokens.mono
        font.pixelSize: 12 * row.s
        font.features: { "tnum": 1 }
        elide: Text.ElideLeft
        horizontalAlignment: Text.AlignRight
    }
}
