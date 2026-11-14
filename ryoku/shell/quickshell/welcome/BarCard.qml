import QtQuick
import Ryoku.Ui
import Ryoku.Ui.Singletons
import "Singletons"

// One bar style to pick. Stock fills the picked card with bone and a lead bar;
// under crate the kit's PickCard draws it: the pick edge and its dot.
Rectangle {
    id: root

    property string styleId: ""
    property string name: ""
    property string description: ""
    property bool selected: false
    property bool recommended: false
    signal chosen(string styleId)

    readonly property bool crate: Tokens.controlsCrate

    height: 116
    radius: Tokens.radius
    color: root.crate ? "transparent" : selected ? Tokens.bone
        : (tap.pressed ? Tokens.tint16 : (hover.hovered ? Tokens.tint5 : "transparent"))
    border.width: root.crate ? 0 : Tokens.border
    border.color: selected ? Tokens.bone
        : (hover.hovered ? Tokens.lineStrong : Tokens.line)
    scale: selected && !root.crate ? 1.018 : 1

    Behavior on color { ColorAnimation { duration: Motion.snap } }
    Behavior on border.color { ColorAnimation { duration: Motion.snap } }
    Behavior on scale {
        NumberAnimation { duration: Motion.move; easing.type: Tokens.ease }
    }

    PickCard {
        id: plate
        objectName: "welcomeBarPick"
        anchors.fill: parent
        visible: root.crate
        interactive: false
        hotHint: hover.hovered
        picked: root.selected
    }

    Rectangle {
        visible: !root.crate
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.selected ? 4 : 0
        color: root.selected ? Tokens.inkOnBone : Tokens.ink
        radius: Tokens.radius
        Behavior on width {
            NumberAnimation { duration: Motion.move; easing.type: Tokens.ease }
        }
    }

    // the text sits in the pick card under crate, below its corner mark
    Column {
        parent: root.crate ? plate : root
        anchors.fill: parent
        anchors.margins: Tokens.s3
        spacing: Tokens.s1

        Text {
            width: parent.width
            text: root.name
            color: root.crate ? plate.titleInk : root.selected ? Tokens.inkOnBone : Tokens.ink
            font.family: Tokens.ui
            font.pixelSize: Tokens.fRow
            font.weight: Font.DemiBold
            wrapMode: Text.WordWrap
        }

        Text {
            width: parent.width
            text: root.description
            color: root.crate ? plate.subInk : root.selected ? Tokens.inkOnBoneDim : Tokens.inkMuted
            font.family: Tokens.ui
            font.pixelSize: Tokens.fSmall
            wrapMode: Text.WordWrap
            lineHeight: 1.15
        }

        Text {
            visible: root.recommended
            width: parent.width
            text: I18n.tr("RYOKU DEFAULT")
            color: root.crate ? Tokens.inkSubtle : root.selected ? Tokens.inkOnBoneDim : Tokens.inkFaint
            font.family: Tokens.mono
            font.pixelSize: Tokens.fTiny
            font.letterSpacing: Tokens.trackLabel
            wrapMode: Text.WordWrap
        }
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { id: tap; onTapped: root.chosen(root.styleId) }
}
