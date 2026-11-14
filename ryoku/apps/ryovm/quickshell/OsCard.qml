import QtQuick
import Ryoku.Ui
import Ryoku.Ui.Singletons
import "Singletons"

// One operating system in the catalogue: the project's own brand logo (colour:
// it is the catalogue's data), the name beneath. The kit's PickCard draws the
// plate: hover lifts the border; the picked tile wears the gallery grammar (ink
// border, tint10 fill, corner dot), or the pick edge and its dot under crate.
PickCard {
    id: cell

    property var entry
    property bool active: false
    signal chosen()

    picked: cell.active
    clip: true
    antialiasing: Tokens.controlsCrate
    onClicked: cell.chosen()

    Column {
        anchors.centerIn: parent
        spacing: 9
        width: parent.width - 20

        OsIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 52; height: 52; size: 52
            slug: cell.entry ? cell.entry.os : ""
            label: cell.entry ? cell.entry.name : ""
        }
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            maximumLineCount: 1
            text: cell.entry ? cell.entry.name : ""
            color: cell.active ? cell.titleInk : Tokens.inkDim
            font.family: Tokens.ui
            font.pixelSize: 12
            font.weight: cell.active ? Font.DemiBold : Font.Medium
        }
    }
}
