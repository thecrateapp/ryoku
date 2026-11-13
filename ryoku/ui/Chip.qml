import QtQuick
import "Singletons"

// One selectable chip. Under a theme style's controls "crate" it is the crate-mark
// chip: 32 px, straight (Tokens.radius), transparent with a hairline edge, the edge
// warming on hover, and filled with the mark when on. Otherwise it keeps the kit's
// stock chip (24 px, bone when on). Chips, Seg and Multi draw through this.
Rectangle {
    id: chip

    property string text: ""
    property bool on: false
    property bool interactive: true
    property color labelInk: chip.tone
    signal clicked()

    readonly property bool crate: Tokens.controlsCrate
    readonly property bool hot: hover.hovered && chip.enabled
    readonly property color tone: chip.on ? (chip.crate ? Tokens.paper : Tokens.inkOnBone)
        : chip.crate ? (chip.hot ? Tokens.ink : Tokens.inkSecondary)
        : (chip.hot && Tokens.accentMarks ? Tokens.hoverInk : Tokens.inkDim)

    implicitWidth: label.implicitWidth + (chip.crate ? 28 : 18)
    implicitHeight: chip.crate ? 32 : 24
    radius: Tokens.radius
    opacity: chip.enabled ? 1 : 0.5
    color: chip.on ? (chip.crate ? Tokens.mark : Tokens.bone)
        : chip.crate ? "transparent"
        : tap.pressed ? Tokens.tint16 : chip.hot ? Tokens.tint10 : "transparent"
    border.width: Tokens.border
    border.color: chip.on ? (chip.crate ? Tokens.mark : Tokens.line)
        : chip.hot ? (chip.crate || Tokens.accentMarks ? Tokens.markHover : Tokens.lineStrong)
        : Tokens.line
    Behavior on color { ColorAnimation { duration: chip.crate ? 150 : Tokens.snap } }
    Behavior on border.color { ColorAnimation { duration: chip.crate ? 150 : Tokens.snap } }

    Text {
        id: label
        anchors.centerIn: parent
        text: chip.text
        color: chip.labelInk
        font.family: chip.crate ? Tokens.mono : Tokens.ui
        font.pixelSize: chip.crate ? 12 : 10
        font.weight: chip.crate ? Font.Normal : Font.Medium
        font.letterSpacing: chip.crate ? 12 * 0.04 : 0
    }

    HoverHandler { id: hover; enabled: chip.enabled && chip.interactive; cursorShape: Qt.PointingHandCursor }
    TapHandler { id: tap; enabled: chip.enabled && chip.interactive; onTapped: chip.clicked() }
}
