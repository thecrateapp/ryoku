pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons

// A tray item's dbusmenu under the crate look, as the approved desktop menu
// draws it: the app's icon and name as the head, 32 px rows that warm on
// hover, a hairline per separator, the pick mark on a checked entry and a
// chevron that turns down when a submenu discloses. It reads and drives only
// the menu: title, icon, rows [{node, depth, sep, hasKids}], isExpanded(id),
// toggleExpand(id), activate(id), cleanLabel(s), iconPath(name), close().
Column {
    id: body
    required property var panel
    spacing: 2

    Item {
        width: parent.width
        height: 32
        Image {
            id: appIcon
            anchors.left: parent.left
            anchors.leftMargin: Tokens.s2
            anchors.verticalCenter: parent.verticalCenter
            visible: body.panel.icon !== ""
            source: body.panel.icon
            sourceSize: Qt.size(16, 16)
            width: visible ? 16 : 0
            height: 16
            fillMode: Image.PreserveAspectFit
            smooth: true
        }
        Kit.TrackLabel {
            objectName: "trayTitle"
            anchors.left: appIcon.right
            anchors.leftMargin: Tokens.s2
            anchors.right: closeButton.left
            anchors.rightMargin: Tokens.s2
            anchors.verticalCenter: parent.verticalCenter
            text: body.panel.title
            tone: "accent"
        }
        Kit.IconButton {
            id: closeButton
            objectName: "closeTrayMenu"
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 28
            height: 28
            iconSize: 16
            glyph: "close"
            Accessible.role: Accessible.Button
            Accessible.name: I18n.tr("Close")
            onClicked: body.panel.close()
        }
    }

    Kit.Divider { width: parent.width; quiet: true }

    Repeater {
        model: body.panel.rows || []

        Item {
            id: entry
            required property var modelData
            readonly property var node: modelData.node
            readonly property bool sep: modelData.sep
            readonly property bool hasKids: modelData.hasKids
            readonly property bool rowEnabled: entry.node.enabled !== false
            readonly property bool toggled: (entry.node.toggleType || "").length > 0 && (entry.node.toggleState || 0) === 1
            readonly property bool open: entry.hasKids && body.panel.isExpanded(entry.node.id)
            readonly property real indent: Tokens.s2 + modelData.depth * 14
            readonly property bool hot: hover.hovered && entry.rowEnabled && !entry.sep
            function act() {
                if (entry.sep || !entry.rowEnabled) return;
                if (entry.hasKids) body.panel.toggleExpand(entry.node.id);
                else body.panel.activate(entry.node.id);
            }

            objectName: (entry.sep ? "traySep-" : "trayRow-") + entry.node.id
            width: body.width
            height: entry.sep ? 9 : 32
            activeFocusOnTab: !entry.sep && entry.rowEnabled
            Accessible.role: entry.sep ? Accessible.Separator : Accessible.MenuItem
            Accessible.name: label.text
            Accessible.checked: entry.toggled
            Accessible.onPressAction: entry.act()
            Keys.onReturnPressed: entry.act()
            Keys.onSpacePressed: entry.act()

            Rectangle {
                visible: entry.sep
                anchors.verticalCenter: parent.verticalCenter
                x: entry.indent
                width: parent.width - entry.indent - Tokens.s2
                height: 1
                color: Tokens.lineSoft
            }

            Rectangle {
                visible: !entry.sep
                anchors.fill: parent
                radius: Tokens.radius
                color: entry.hot || entry.activeFocus ? Qt.rgba(Tokens.ink.r, Tokens.ink.g, Tokens.ink.b, 0.05) : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }

                Item {
                    id: checkSlot
                    x: entry.indent
                    width: 10
                    height: parent.height
                    Rectangle {
                        objectName: "trayCheck"
                        anchors.centerIn: parent
                        visible: entry.toggled
                        width: 6
                        height: 6
                        radius: 3
                        color: Tokens.mark
                    }
                }
                Image {
                    id: entryIcon
                    anchors.left: checkSlot.right
                    anchors.leftMargin: Tokens.s1
                    anchors.verticalCenter: parent.verticalCenter
                    readonly property string path: body.panel.iconPath(entry.node.iconName || "")
                    visible: path !== ""
                    source: path
                    sourceSize: Qt.size(16, 16)
                    width: visible ? 16 : 0
                    height: 16
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    opacity: entry.rowEnabled ? 1 : 0.4
                }
                Text {
                    id: label
                    objectName: "trayLabel"
                    anchors.left: entryIcon.right
                    anchors.leftMargin: entryIcon.visible ? Tokens.s2 : Tokens.s1
                    anchors.right: chevron.left
                    anchors.rightMargin: Tokens.s1
                    anchors.verticalCenter: parent.verticalCenter
                    text: I18n.tr(body.panel.cleanLabel(entry.node.label))
                    color: !entry.rowEnabled ? Tokens.inkFaint : entry.hot ? Tokens.ink : Tokens.inkSecondary
                    font.family: Tokens.mono
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
                Kit.Glyph {
                    id: chevron
                    anchors.right: parent.right
                    anchors.rightMargin: Tokens.s2
                    anchors.verticalCenter: parent.verticalCenter
                    visible: entry.hasKids
                    width: visible ? 14 : 0
                    name: "chevron_right"
                    size: 14
                    color: entry.open ? Tokens.mark : Tokens.inkSubtle
                    rotation: entry.open ? 90 : 0
                    Behavior on rotation { NumberAnimation { duration: 120 } }
                }
            }

            HoverHandler {
                id: hover
                enabled: !entry.sep
                cursorShape: entry.rowEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            }
            TapHandler {
                enabled: !entry.sep
                onTapped: entry.act()
            }
        }
    }
}
