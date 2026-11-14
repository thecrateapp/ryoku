import QtQuick
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons

// A row's reset: a quiet "Reset" link, or the kit chip under crate.
Item {
    id: chip

    signal triggered()

    implicitHeight: Theme.crate ? resetKit.implicitHeight : line.implicitHeight + 4 * Theme.scale
    implicitWidth: Theme.crate ? resetKit.implicitWidth : line.implicitWidth + 8 * Theme.scale

    Kit.Chip {
        id: resetKit
        objectName: "resetChip"
        visible: Theme.crate
        enabled: Theme.crate
        anchors.fill: parent
        text: I18n.tr("Reset")
        onClicked: chip.triggered()
    }

    readonly property bool hovered: area.containsMouse

    Row {
        id: line
        visible: !Theme.crate
        anchors.centerIn: parent
        spacing: 4 * Theme.scale

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "\u21ba"
            font.family: Theme.sans
            font.weight: Font.Medium
            font.pixelSize: Theme.fontFine
            color: Theme.withAlpha(Theme.surfaceText, chip.hovered ? 1 : 0.5)
            renderType: Text.NativeRendering
            Behavior on color { ColorAnimation { duration: Theme.fast } }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: I18n.tr("Reset")
            font.family: Theme.sans
            font.weight: Font.Medium
            font.pixelSize: Theme.fontFine
            color: Theme.withAlpha(Theme.surfaceText, chip.hovered ? 1 : 0.5)
            renderType: Text.NativeRendering
            Behavior on color { ColorAnimation { duration: Theme.fast } }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        enabled: !Theme.crate
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: chip.triggered()
    }
}
