import QtQuick
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons

// kind: "plain", "order" or "swatch". Under crate a plain or order chip is the kit
// chip, filled with the mark when active; a swatch is colour data and keeps its square.
Item {
    id: chip

    property string kind: "plain"
    property string label: ""
    property bool active: false
    // Swatch index (0-12); used only when kind === "swatch".
    property int swatchIndex: 0
    property color swatchInner: "gray"
    property color swatchInnerActive: "white"

    signal clicked()

    readonly property bool _swatch: chip.kind === "swatch"
    readonly property bool _order: chip.kind === "order"
    readonly property bool hovered: hoverArea.containsMouse

    readonly property bool _kit: Theme.crate && !chip._swatch

    implicitHeight: chip._kit ? browserKit.implicitHeight
        : _swatch ? 18 * Theme.scale : (_order ? 20 * Theme.scale : 22 * Theme.scale)
    implicitWidth: chip._kit ? browserKit.implicitWidth
        : _swatch
        ? 18 * Theme.scale
        : labelText.implicitWidth + (_order ? 20 : 16) * Theme.scale

    Kit.Chip {
        id: browserKit
        objectName: "browserChip"
        visible: chip._kit
        enabled: chip._kit
        anchors.fill: parent
        text: chip.label
        on: chip.active
        onClicked: chip.clicked()
    }

    Rectangle {
        anchors.fill: parent
        visible: !chip._swatch && !chip._kit
        radius: Theme.radius
        color: chip.active
            ? (chip._order ? "transparent" : Theme.withAlpha(Theme.surfaceText, 0.06))
            : chip.hovered
                ? Theme.withAlpha(Theme.surfaceText, chip._order ? 0.07 : 0.09)
                : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.fast } }

        // A bone underline marks the chosen plain chip.
        Rectangle {
            visible: !chip._order
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: chip.active ? 2 * Theme.scale : 1
            color: chip.active
                ? Theme.surfaceText
                : Theme.withAlpha(Theme.outline, 0.22)
            Behavior on height { NumberAnimation { duration: Theme.fast; easing.type: Theme.revealEasing } }
        }
        // A bone marker runs down the chosen order chip.
        Rectangle {
            visible: chip._order && chip.active
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 2 * Theme.scale
            color: Theme.surfaceText
        }
    }

    Text {
        id: labelText
        visible: !chip._swatch && !chip._kit
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: (chip._order ? 8 : 7) * Theme.scale
        text: chip.label
        font.family: Theme.sans
        font.weight: chip.active ? Font.DemiBold : Font.Medium
        font.pixelSize: Theme.fontBase
        color: chip.active
            ? Theme.surfaceText
            : chip.hovered
                ? Theme.withAlpha(Theme.surfaceText, chip._order ? 0.88 : 0.90)
                : Theme.withAlpha(Theme.surfaceText, chip._order ? 0.54 : 0.64)
        renderType: Text.NativeRendering
        Behavior on color { ColorAnimation { duration: Theme.fast } }
    }

    Item {
        anchors.fill: parent
        visible: chip._swatch
        scale: chip.active ? 1.15 : 1.0
        Behavior on scale { NumberAnimation { duration: Theme.fast; easing.type: Theme.revealEasing } }

        Rectangle {
            anchors.fill: parent
            color: Theme.withAlpha(Theme.background, 0.9)
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: 2 * Theme.scale
            color: chip.active
                ? chip.swatchInnerActive
                : chip.hovered ? Qt.lighter(chip.swatchInner, 1.2) : chip.swatchInner
            border.width: chip.active ? 1.5 : 0
            border.color: Theme.surfaceText
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        enabled: !chip._kit
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: chip.clicked()
    }
}
