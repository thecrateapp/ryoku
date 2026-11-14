import QtQuick
import "Singletons"
import Ryoku.Ui as Kit

// A plugin card: the palette's depth gradient in a hairline. Under crate it takes
// the shared corner and its eyebrow is the kit's tracked label.
Rectangle {
    id: card
    property real s: 1
    property string eyebrow: ""
    default property alias content: body.data

    radius: Theme.radius
    color: "transparent"
    border.width: 1
    border.color: Theme.border
    implicitHeight: body.implicitHeight + 26 * s
    gradient: Gradient {
        GradientStop { position: 0.0; color: Theme.panelTop }
        GradientStop { position: 1.0; color: Theme.panelBot }
    }
    Column {
        id: body
        anchors.fill: parent
        anchors.margins: 13 * card.s
        spacing: 11 * card.s
        Kit.TrackLabel {
            objectName: "cardEyebrow"
            visible: Theme.crate && card.eyebrow.length > 0
            text: card.eyebrow
        }
        Text {
            visible: !Theme.crate && card.eyebrow.length > 0
            text: card.eyebrow
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: 9.5 * card.s
            font.weight: Font.DemiBold
            font.capitalization: Font.AllUppercase
            font.letterSpacing: 1.4 * card.s
        }
    }
}
