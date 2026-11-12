import QtQuick
import "Singletons"

// A full-width row in a list you pick one from (audio devices, networks): an
// icon, a title over a sub line, and the picked state. Under controls "crate" the
// picked row takes the pick wash inside a mark edge and a dot with a halo;
// otherwise it fills with bone like the stock tiles.
Rectangle {
    id: row

    property string title: ""
    property string sub: ""
    property string glyph: ""
    property string glyphFont: Tokens.ui
    property bool picked: false
    signal clicked()

    readonly property bool crate: Tokens.controlsCrate
    readonly property bool hot: hover.hovered && row.enabled

    implicitWidth: 240
    implicitHeight: Math.max(40, texts.implicitHeight + 20)
    radius: Tokens.radius
    opacity: row.enabled ? 1 : 0.5
    color: row.picked ? (row.crate ? Tokens.pickFill : Tokens.bone)
        : row.hot ? Tokens.tint5 : "transparent"
    border.width: Tokens.border
    border.color: row.picked ? (row.crate ? Tokens.pickEdge : Tokens.bone)
        : row.hot ? (row.crate ? Tokens.markHover : Tokens.lineStrong) : Tokens.line
    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }
    activeFocusOnTab: row.enabled
    Keys.onSpacePressed: row.clicked()
    Keys.onReturnPressed: row.clicked()

    readonly property color titleInk: row.picked ? (row.crate ? Tokens.pickInk : Tokens.inkOnBone) : Tokens.ink
    readonly property color subInk: row.picked ? (row.crate ? Tokens.pickInkDim : Tokens.inkOnBoneDim) : Tokens.inkDim

    // the catalogue's Solar glyph under crate, the font glyph otherwise
    Glyph {
        id: icon
        visible: row.glyph.length > 0
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        name: row.glyph
        color: row.picked && row.crate ? Tokens.mark : row.titleInk
        fallbackFont: row.glyphFont
        size: 18
    }
    Column {
        id: texts
        anchors.left: icon.visible ? icon.right : parent.left
        anchors.leftMargin: 12
        anchors.right: mark.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        Text {
            width: parent.width
            text: row.title
            color: row.titleInk
            font.family: Tokens.ui
            font.pixelSize: row.crate ? 13 : Tokens.fRow
            elide: Text.ElideRight
        }
        Text {
            width: parent.width
            visible: row.sub.length > 0
            text: row.sub
            color: row.subInk
            font.family: Tokens.ui
            font.pixelSize: row.crate ? 11 : Tokens.fSmall
            elide: Text.ElideRight
        }
    }
    // the picked dot with its halo
    Item {
        id: mark
        width: 12
        height: 12
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        visible: row.crate
        Rectangle { anchors.centerIn: parent; width: 12; height: 12; radius: 6; visible: row.picked; color: Qt.rgba(Tokens.sun.r, Tokens.sun.g, Tokens.sun.b, 0.22) }
        Rectangle { anchors.centerIn: parent; width: 6; height: 6; radius: 3; visible: row.picked; color: Tokens.mark }
    }
    HoverHandler { id: hover; enabled: row.enabled; cursorShape: Qt.PointingHandCursor }
    TapHandler { enabled: row.enabled; onTapped: row.clicked() }
}
