pragma ComponentBehavior: Bound
import QtQuick
import "Singletons"
import Ryoku.Ui.Singletons
import Ryoku.Ui.Singletons as Ui

// A choice keeps the ryogami inversion language while allowing its label to
// yield inside wrapped Stage rows instead of widening through a neighbour.
Item {
    id: chip

    property string label: ""
    property bool selected: false
    property real minWidth: 0

    signal clicked()

    readonly property bool hovered: ma.containsMouse
    // crate-mark: the kit Chip's look (mark fill when picked, a hairline that
    // warms on hover, mono label) at the menu's 26 px
    readonly property bool crate: Ui.Tokens.controlsCrate
    readonly property color contentColor: chip.crate
        ? (chip.selected ? Ui.Tokens.paper : ma.containsMouse ? Ui.Tokens.ink : Ui.Tokens.inkSecondary)
        : chip.selected ? Theme.inkOnBone
        : (ma.containsMouse ? Theme.ink : Theme.inkDim)

    default property alias content: hold.data

    implicitWidth: Math.max(chip.minWidth, lbl.implicitWidth + 20)
    implicitHeight: 26

    scale: ma.pressed ? 0.94 : 1
    Behavior on scale {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutBack
            easing.overshoot: 2.2
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: chip.crate ? (chip.selected ? Ui.Tokens.mark : "transparent")
            : chip.selected ? Theme.bone
            : ma.pressed ? Theme.tilePress
            : ma.containsMouse ? Theme.tileHover : "transparent"
        border.width: 1
        border.color: chip.crate
            ? (chip.selected ? Ui.Tokens.mark : ma.containsMouse ? Ui.Tokens.markHover : Ui.Tokens.line)
            : chip.selected ? Theme.bone
            : ma.containsMouse ? Theme.lineStrong : Theme.line
        Behavior on color { ColorAnimation { duration: 180 } }
        Behavior on border.color { ColorAnimation { duration: 180 } }
    }

    Text {
        id: lbl
        visible: chip.label.length > 0
        anchors {
            fill: parent
            leftMargin: 9
            rightMargin: 9
        }
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        text: I18n.tr(chip.label)
        color: chip.contentColor
        elide: Text.ElideRight
        maximumLineCount: 1
        font.family: chip.crate ? Ui.Tokens.mono : Theme.font
        font.pixelSize: chip.crate ? 11 : 9
        font.weight: chip.crate ? Font.Normal : Font.DemiBold
        font.letterSpacing: chip.crate ? 11 * 0.04 : 0.6
        Behavior on color { ColorAnimation { duration: 180 } }
    }

    Item { id: hold; anchors.fill: parent }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: chip.clicked()
    }
}
