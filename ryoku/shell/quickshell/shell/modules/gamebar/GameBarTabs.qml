pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons as Ui
import "../../components"
import "look"

// A 42px row of icon and label tabs over a 1px bottom
// border, with a 3px primary indicator tucked under the active one.
// Under crate it is the kit's Tabs, selection drawn the way the theme draws it.
Item {
    id: root

    readonly property bool crate: Ui.Tokens.controlsCrate

    property real s: 1
    property var model: []
    property int currentIndex: 0

    signal picked(int index)

    implicitHeight: 42 * root.s

    Kit.Tabs {
        id: kitTabs
        objectName: "gameBarKitTabs"
        visible: root.crate
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        options: root.model.map((tab, i) => ({ key: String(i), label: tab.label }))
        current: String(root.currentIndex)
        onChose: key => root.picked(Number(key))
    }

    Row {
        id: tabs
        visible: !root.crate
        anchors.fill: parent
        anchors.bottomMargin: 1 * root.s

        Repeater {
            model: root.model

            delegate: Item {
                id: tab
                required property var modelData
                required property int index

                readonly property bool current: root.currentIndex === index
                readonly property real cellWidth: root.width / Math.max(1, root.model.length)

                width: cellWidth
                height: parent.height

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 3 * root.s
                    radius: GameBarLook.radiusNormal * root.s
                    color: pointer.containsMouse && !tab.current ? GameBarLook.hover : "transparent"
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 5 * root.s

                    GlyphIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 22 * root.s
                        height: 22 * root.s
                        name: tab.modelData.icon
                        color: tab.current ? GameBarLook.accent : GameBarLook.onLayer
                        stroke: 1.7
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: tab.modelData.label
                        color: tab.current ? GameBarLook.accent : GameBarLook.onLayer
                        font.family: GameBarLook.face
                        font.pixelSize: GameBarLook.small * root.s
                    }
                }

                MouseArea {
                    id: pointer
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(tab.index)
                }
            }
        }
    }

    Rectangle {
        visible: !root.crate
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: GameBarLook.border
    }

    Rectangle {
        visible: !root.crate
        readonly property real baseWidth: root.width / Math.max(1, root.model.length)
        readonly property real padding: 8 * root.s
        x: root.currentIndex * baseWidth + padding
        width: Math.max(0, baseWidth - padding * 2)
        anchors.bottom: parent.bottom
        height: 3 * root.s
        topLeftRadius: height
        topRightRadius: height
        color: GameBarLook.accent
    }
}
