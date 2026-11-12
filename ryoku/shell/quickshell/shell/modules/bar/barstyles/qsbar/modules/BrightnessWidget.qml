pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.Ui.Singletons
import Ryoku.Ui as Kit

Item {
    id: rootMod
    required property var root
    required property var screen
    required property BrightnessOutput controller
    readonly property color contentColor: root.widgetContentColor("G13", root.ink)
    readonly property color levelColor: percent >= 100 && !root.widgetHasFill("G13") ? root.seal : contentColor

    readonly property int percent: controller.percent
    readonly property string tooltipText: I18n.tr("Brightness · %1%").arg(percent)

    readonly property bool shown: controller.available && root.modBrightness
    implicitWidth:  shown ? (row.implicitWidth + 18) : 0
    implicitHeight: 28
    visible: implicitWidth > 0.5
    opacity: shown ? 1 : 0

    Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

    function togglePanel() {
        tip.hide()
        if (!screen || !controller.available || screen.name !== controller.outputName) return
        if (root.brightnessVisible && root.brightnessTarget === controller) {
            root.brightnessVisible = false
            return
        }
        root.activatePopupScreen(screen)
        root.brightnessTarget = controller
        root.brightnessVisible = true
        controller.refresh()
    }

    Component {
        id: crateIcon

        Kit.Glyph {
            name: "sun"
            size: 18
            color: rootMod.levelColor
            opacity: 0.72 + 0.28 * rootMod.percent / 100
        }
    }

    Component {
        id: stockIcon

        Item {
            id: sun
            width: 13
            height: 13

            readonly property real ratio: Math.max(0, Math.min(1, rootMod.percent / 100))
            Rectangle {
                anchors.centerIn: parent
                width: 6.5
                height: 6.5
                radius: 3.25
                color: rootMod.levelColor
                Behavior on color { ColorAnimation { duration: 200 } }
            }

            Repeater {
                model: 8
                delegate: Item {
                    required property int index
                    anchors.fill: parent
                    rotation: index * 45
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 0.3
                        width: 1.5
                        height: 2 + 1.4 * sun.ratio
                        radius: 0.75
                        color: rootMod.levelColor
                        opacity: 0.35 + 0.65 * sun.ratio
                        Behavior on height  { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                        Behavior on color   { ColorAnimation  { duration: 200 } }
                    }
                }
            }
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Tokens.controlsCrate ? 6 : 4

        Loader {
            anchors.verticalCenter: parent.verticalCenter
            sourceComponent: Tokens.controlsCrate ? crateIcon : stockIcon
        }

        UiText {
            visible: !rootMod.root.iconOnly("G13")
            anchors.verticalCenter: parent.verticalCenter
            text: rootMod.percent + "%"
            color: rootMod.levelColor
            font.family: Tokens.controlsCrate ? Tokens.mono : rootMod.root.mono
            font.pixelSize: 12
            font.features: Tokens.controlsCrate ? { "tnum": 1 } : {}
            Behavior on color { ColorAnimation { duration: 200 } }
        }
    }

    TooltipMixin { id: tip; root: rootMod.root; owner: rootMod; text: rootMod.tooltipText }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
        onEntered: tip.show()
        onExited:  { tip.hide() }
        onClicked: rootMod.togglePanel()
        onWheel: e => {
            if (e.angleDelta.y !== 0) rootMod.controller.step(e.angleDelta.y > 0)
        }
    }
}
