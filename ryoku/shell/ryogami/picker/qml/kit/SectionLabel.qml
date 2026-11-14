import QtQuick
import Ryoku.Ui as Kit

// A section heading: accent tick, spaced caps, and a hairline running to the edge.
// Under crate it is the kit's tracked label in the accent tone over the kit hairline,
// with no tick: a lead bar is Ryoku marginalia.
Item {
    id: label

    property string text: ""

    implicitHeight: Theme.crate ? crateCaption.implicitHeight
        : Math.max(caption.implicitHeight, 14 * Theme.scale)

    Rectangle {
        id: tick
        visible: !Theme.crate
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 2 * Theme.scale
        height: caption.implicitHeight
        color: Theme.withAlpha(Theme.surfaceText, 0.85)
    }
    Text {
        id: caption
        visible: !Theme.crate
        anchors.left: tick.right
        anchors.leftMargin: 8 * Theme.scale
        anchors.verticalCenter: parent.verticalCenter
        text: label.text.toUpperCase()
        font.family: Theme.sans
        font.weight: Font.DemiBold
        font.pixelSize: Theme.fontFine
        font.letterSpacing: 1.6
        color: Theme.withAlpha(Theme.surfaceText, 0.78)
        renderType: Text.NativeRendering
    }
    FolioRule {
        visible: !Theme.crate
        anchors.left: caption.right
        anchors.leftMargin: 12 * Theme.scale
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        alpha: 0.4
    }

    Kit.TrackLabel {
        id: crateCaption
        objectName: "sectionLabel"
        visible: Theme.crate
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: label.text
        tone: "accent"
    }
    Kit.Divider {
        visible: Theme.crate
        anchors.left: crateCaption.right
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
    }
}
