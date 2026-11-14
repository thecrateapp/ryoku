import QtQuick
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons
import "Singletons"

// A toolbar action. Stock draws Ryoshot's own plate (the accent fill when
// active) with its line icon; under crate it is the kit's plateless IconButton:
// the Solar glyph where the catalogue has one, else Ryoshot's own line path,
// the mark ink when active or hovered.
Rectangle {
    id: btn
    property string icon: ""
    property bool active: false
    property bool dim: false
    property string tooltip: ""
    property real iconSize: 18

    signal clicked()

    readonly property bool crate: Tokens.controlsCrate
    readonly property bool hovered: btn.crate ? kit.hot : ma.containsMouse
    // Ryoshot's names that the kit's Solar catalogue draws
    readonly property var solar: ({
        "select": "cursor", "pen": "pen", "undo": "undo-left", "redo": "undo-right",
        "copy": "copy", "save": "diskette", "upload": "upload", "pin": "pin",
        "gear": "settings", "phone": "smartphone", "sound": "volume-loud",
        "mic": "microphone-2", "keyboard": "keyboard", "webcam": "videocamera",
        "timer": "stopwatch", "eyedropper": "pipette", "fullscreen": "maximize-square",
        "folder": "folder", "magnify": "magnifier", "cancel": "close"
    })

    width: 32
    height: 32
    radius: Theme.corner(7)
    color: btn.crate ? "transparent" : active ? Theme.accent : (hovered && !dim ? Theme.hover : "transparent")

    Icon {
        id: glyph
        visible: !btn.crate
        anchors.centerIn: parent
        name: btn.icon
        size: btn.iconSize
        tint: btn.active ? Theme.accentInk : (btn.dim ? Theme.inkFaint : Theme.inkDim)
    }

    Kit.IconButton {
        id: kit
        objectName: "ryoshotKitButton"
        visible: btn.crate
        anchors.fill: parent
        enabled: btn.crate && !btn.dim
        on: btn.active
        iconSize: btn.iconSize
        glyph: btn.solar[btn.icon] || ""
        path: btn.solar[btn.icon] ? "" : (glyph.defs[btn.icon] || "")
        onClicked: btn.clicked()
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        enabled: !btn.crate
        hoverEnabled: true
        onClicked: if (!btn.dim) btn.clicked()
    }

    Timer {
        id: tipDelay
        interval: 450
        onTriggered: tip.opacity = 1
    }

    onHoveredChanged: {
        if (hovered && tooltip.length > 0)
            tipDelay.restart()
        else {
            tipDelay.stop()
            tip.opacity = 0
        }
    }

    Rectangle {
        id: tip
        enabled: false
        visible: btn.tooltip.length > 0
        opacity: 0
        z: 100
        anchors.top: parent.bottom
        anchors.topMargin: 6
        anchors.horizontalCenter: parent.horizontalCenter
        width: tipText.implicitWidth + 14
        height: tipText.implicitHeight + 8
        radius: Theme.corner(5)
        color: Theme.panelSolid
        border.color: Theme.hair
        border.width: 1

        Behavior on opacity {
            NumberAnimation { duration: Theme.snap }
        }

        Text {
            id: tipText
            anchors.centerIn: parent
            text: btn.tooltip
            font.family: Theme.ui
            font.pixelSize: 11
            color: Theme.ink
        }
    }
}
