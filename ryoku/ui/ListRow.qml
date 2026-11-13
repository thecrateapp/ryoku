import QtQuick
import "Singletons"

// A row in a list of things you act on (networks, Bluetooth devices): a leading
// glyph or item, a title over a sub line, and trailing actions (Btns, IconButtons)
// placed as children. crate-mark's list line: a 1 px hairline at radius 6, the
// pick wash and pick edge when `on` (connected, active), and `quiet` drops the
// edge until hover, for the long tail of a list.
Rectangle {
    id: row

    property string title: ""
    property string sub: ""
    property string glyph: ""
    property string glyphFont: "Material Symbols Rounded"
    property Component leading: null
    property bool on: false
    property bool quiet: false
    property real s: 1
    default property alias actions: trailing.data

    readonly property bool hot: hover.hovered

    implicitWidth: 320 * row.s
    implicitHeight: Math.max(44 * row.s, texts.implicitHeight + 16 * row.s)
    radius: 6 * row.s
    color: row.on ? Tokens.pickFill : "transparent"
    border.width: 1
    border.color: row.on ? Tokens.pickEdge
        : row.quiet ? (row.hot ? Tokens.line : "transparent")
        : row.hot ? Tokens.markHover : Tokens.line
    Behavior on border.color { ColorAnimation { duration: 150 } }

    Item {
        id: lead
        anchors.left: parent.left
        anchors.leftMargin: 12 * row.s
        anchors.verticalCenter: parent.verticalCenter
        width: (row.glyph.length > 0 || row.leading) ? 18 * row.s : 0
        height: 18 * row.s

        Glyph {
            visible: row.glyph.length > 0 && !row.leading
            anchors.centerIn: parent
            name: row.glyph
            fallbackFont: row.glyphFont
            size: 18 * row.s
            color: row.on ? Tokens.mark : Tokens.inkSecondary
        }
        Loader {
            anchors.centerIn: parent
            active: row.leading !== null
            sourceComponent: row.leading
        }
    }

    Column {
        id: texts
        anchors.left: lead.right
        anchors.leftMargin: (lead.width > 0 ? 12 : 0) * row.s
        anchors.right: trailing.left
        anchors.rightMargin: 10 * row.s
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2 * row.s

        Text {
            width: parent.width
            text: row.title
            textFormat: Text.PlainText
            color: Tokens.ink
            font.family: Tokens.ui
            font.pixelSize: 13 * row.s
            elide: Text.ElideRight
        }
        Text {
            width: parent.width
            visible: row.sub.length > 0
            text: row.sub
            textFormat: Text.PlainText
            color: Tokens.inkMuted
            font.family: Tokens.ui
            font.pixelSize: 11 * row.s
            elide: Text.ElideRight
        }
    }

    Row {
        id: trailing
        anchors.right: parent.right
        anchors.rightMargin: 8 * row.s
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4 * row.s
    }

    HoverHandler { id: hover }
}
