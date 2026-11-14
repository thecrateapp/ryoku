import QtQuick
import "Singletons"

// A card you pick from a grid (a product, an operating system, a machine): a
// glyph over a title and a subtitle, and the picked state. It speaks PickRow's
// selection grammar: under controls "crate" the picked card takes the pick wash
// inside the 1 px pick edge with a dot and its halo in the corner, and hover
// warms the edge; otherwise it keeps the stock gallery tile (a tint wash, an ink
// edge, a corner dot). A card with richer content (cover art, a status flap)
// leaves the title empty and puts that content in the card; titleInk and subInk
// follow the picked state for it, and the corner mark stays above it. An owner
// that handles the pointer itself sets `interactive: false` and feeds its hover
// through `hotHint`.
Rectangle {
    id: card

    property string glyph: ""
    property string glyphFont: Tokens.ui
    property string title: ""
    property string subtitle: ""
    property bool picked: false
    property bool interactive: true
    property bool hotHint: false
    property bool focusVisible: false
    default property alias content: body.data
    signal clicked()

    readonly property bool crate: Tokens.controlsCrate
    readonly property bool hot: card.enabled && (card.hotHint || (card.interactive && hover.hovered))
    readonly property bool focusShown: card.focusVisible || card.activeFocus
    readonly property color titleInk: card.picked ? (card.crate ? Tokens.pickInk : Tokens.ink) : Tokens.ink
    readonly property color subInk: card.picked ? (card.crate ? Tokens.pickInkDim : Tokens.inkDim) : Tokens.inkDim

    implicitWidth: 160
    implicitHeight: Math.max(96, stack.implicitHeight + 32)
    radius: Tokens.radius
    opacity: card.enabled ? 1 : 0.5
    color: card.picked ? (card.crate ? Tokens.pickFill : Tokens.tint10)
        : card.hot ? Tokens.tint5 : "transparent"
    border.width: card.focusShown && !card.crate ? Tokens.border * 2 : Tokens.border
    border.color: card.focusShown ? Tokens.focus
        : card.picked ? (card.crate ? Tokens.pickEdge : Tokens.ink)
        : card.hot ? (card.crate ? Tokens.markHover : Tokens.lineStrong) : Tokens.line
    Behavior on color { ColorAnimation { duration: card.crate ? 150 : Tokens.snap } }
    Behavior on border.color { ColorAnimation { duration: card.crate ? 150 : Tokens.snap } }
    activeFocusOnTab: card.enabled && card.interactive
    Keys.onSpacePressed: card.clicked()
    Keys.onReturnPressed: card.clicked()

    // the default face: a glyph over the title and the subtitle
    Column {
        id: stack
        visible: body.children.length === 0 && (card.glyph.length > 0 || card.title.length > 0)
        anchors.centerIn: parent
        width: parent.width - 24
        spacing: 6

        Glyph {
            visible: card.glyph.length > 0
            anchors.horizontalCenter: parent.horizontalCenter
            name: card.glyph
            fallbackFont: card.glyphFont
            color: card.picked && card.crate ? Tokens.mark : card.titleInk
            size: 28
        }
        Text {
            width: parent.width
            visible: card.title.length > 0
            horizontalAlignment: Text.AlignHCenter
            text: card.title
            color: card.titleInk
            font.family: Tokens.ui
            font.pixelSize: card.crate ? 13 : Tokens.fRow
            font.weight: Font.Medium
            elide: Text.ElideRight
        }
        Text {
            width: parent.width
            visible: card.subtitle.length > 0
            horizontalAlignment: Text.AlignHCenter
            text: card.subtitle
            color: card.subInk
            font.family: card.crate ? Tokens.mono : Tokens.ui
            font.pixelSize: card.crate ? 11 : Tokens.fSmall
            elide: Text.ElideRight
        }
    }

    // caller content (cover art, a flap) fills the card under the corner mark
    Item {
        id: body
        anchors.fill: parent
    }

    // the picked mark in the corner: the dot with its halo under crate, the
    // stock gallery dot otherwise
    Item {
        objectName: "pickCardMark"
        z: 1
        visible: card.picked
        width: card.crate ? 12 : 5
        height: width
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: card.crate ? 8 : 7
        Rectangle { anchors.centerIn: parent; width: 12; height: 12; radius: 6; visible: card.crate; color: Qt.rgba(Tokens.sun.r, Tokens.sun.g, Tokens.sun.b, 0.22) }
        Rectangle {
            anchors.centerIn: parent
            width: card.crate ? 6 : 5
            height: width
            radius: width / 2
            color: card.crate ? Tokens.mark : Tokens.ink
        }
    }

    HoverHandler { id: hover; enabled: card.enabled && card.interactive; cursorShape: Qt.PointingHandCursor }
    TapHandler { enabled: card.enabled && card.interactive; onTapped: card.clicked() }
}
