import QtQuick
import Ryoku.Ui as Kit

// A rice's tag. Under crate it is a static kit chip, filled with the mark when strong
// (the live, active and compatibility marks).
Rectangle {
    id: chip

    property string label: ""
    property color tint: Theme.withAlpha(Theme.surfaceText, 0.7)
    property bool strong: false

    implicitWidth: Theme.crate ? riceKit.implicitWidth : chipText.implicitWidth + 16 * Theme.scale
    height: Theme.crate ? riceKit.implicitHeight : 20 * Theme.scale
    color: Theme.crate ? "transparent" : chip.strong ? Theme.withAlpha(chip.tint, 0.16) : "transparent"
    border.width: Theme.crate ? 0 : 1
    border.color: Theme.withAlpha(chip.tint, chip.strong ? 0.55 : 0.3)

    Kit.Chip {
        id: riceKit
        objectName: "riceChip"
        visible: Theme.crate
        anchors.fill: parent
        interactive: false
        text: chip.label
        on: chip.strong
    }

    Text {
        id: chipText
        visible: !Theme.crate
        anchors.centerIn: parent
        text: chip.label
        font.family: Theme.sans
        font.weight: Font.Medium
        font.pixelSize: Theme.fontFine
        font.letterSpacing: 0.8
        color: chip.strong ? chip.tint : Theme.withAlpha(Theme.surfaceText, 0.7)
        renderType: Text.NativeRendering
    }
}
