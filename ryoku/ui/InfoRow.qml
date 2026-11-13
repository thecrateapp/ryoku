import QtQuick
import "Singletons"

// A key/value line, crate-mark's readout row: a tracked caption on the left, the
// value in mono 12 on the right, and an optional faint secondary after it (a unit
// or a second reading). 24 px tall, as the mock-up's key/value rows. A group of
// rows passes `labelWidth` (its widest caption) and `secondaryWidth` so values and
// secondaries line up.
Item {
    id: row

    property string label: ""
    property string valueText: ""
    property string secondary: ""
    property real labelWidth: 0
    property real secondaryWidth: 0
    property real s: 1
    readonly property real labelImplicitWidth: caption.implicitWidth
    readonly property int valuePixelSize: amount.font.pixelSize

    implicitWidth: 280 * row.s
    implicitHeight: 24 * row.s

    TrackLabel {
        id: caption
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: row.labelWidth > 0 ? Math.min(row.labelWidth, row.width * 0.5)
            : Math.max(0, amount.x - 8 * row.s)
        text: row.label
        font.pixelSize: Tokens.fMicro * row.s
        font.letterSpacing: Tokens.trackLabel * row.s
    }

    Text {
        id: amount
        anchors.right: extra.visible ? extra.left : parent.right
        anchors.rightMargin: extra.visible ? 8 * row.s : 0
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, Math.max(0, (extra.visible ? extra.x - 8 * row.s : row.width) - caption.x - (row.labelWidth > 0 ? caption.width + 8 * row.s : 0)))
        text: row.valueText
        textFormat: Text.PlainText
        color: Tokens.ink
        font.family: Tokens.mono
        font.pixelSize: 12 * row.s
        font.features: { "tnum": 1 }
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideLeft
    }

    Text {
        id: extra
        visible: row.secondary.length > 0
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(row.secondaryWidth, implicitWidth)
        text: row.secondary
        textFormat: Text.PlainText
        color: Tokens.inkSecondary
        font.family: Tokens.mono
        font.pixelSize: 11 * row.s
        font.features: { "tnum": 1 }
        horizontalAlignment: Text.AlignRight
    }
}
