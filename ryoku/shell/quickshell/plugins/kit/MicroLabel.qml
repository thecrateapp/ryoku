import QtQuick
import "Singletons"
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons

// section eyebrow, dossier idiom: vermilion reg dot then a mono uppercase
// letterspaced label. scales with `s`. Under crate it is the kit's tracked label
// in the accent tone, with no reg dot (Ryoku marginalia).
Row {
    id: ml

    property string label: ""
    property real s: 1

    spacing: 8 * s

    Kit.TrackLabel {
        objectName: "microLabel"
        visible: Theme.crate
        anchors.verticalCenter: parent.verticalCenter
        text: I18n.tr(ml.label)
        tone: "accent"
    }

    Rectangle {
        visible: !Theme.crate
        width: 5 * ml.s
        height: 5 * ml.s
        radius: 1 * ml.s
        color: Theme.brand
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        visible: !Theme.crate
        anchors.verticalCenter: parent.verticalCenter
        text: I18n.tr(ml.label)
        color: Theme.faint
        font.family: Theme.mono
        font.pixelSize: 10 * ml.s
        font.weight: Font.DemiBold
        font.letterSpacing: 2.4 * ml.s
        font.capitalization: Font.AllUppercase
    }
}
