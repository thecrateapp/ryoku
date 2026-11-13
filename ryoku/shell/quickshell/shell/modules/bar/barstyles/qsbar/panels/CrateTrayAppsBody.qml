pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons

// The QS Bar tray overflow under the crate look: the apps the bar hides, each
// a kit ListRow with its icon, name and status, and three IconButtons (open,
// pin to the bar, its menu). An app that needs attention takes the pick and
// says why. It scrolls inside the panel's cap and reads only the panel:
// hiddenItems [{service, name, description, attention, icon, hasMenu,
// itemIsMenu}], attentionCount, activateItem(entry, anchor), pinItem(entry),
// openMenu(entry, anchor) and close().
Column {
    id: body
    required property var panel
    readonly property var items: body.panel.hiddenItems || []
    property int listCap: 320
    spacing: Tokens.s3

    CrateResourceHeader {
        objectName: "trayAppsTitle"
        width: parent.width
        title: body.panel.attentionCount > 0
            ? I18n.tr("Tray Apps") + " · " + body.items.length + " · " + I18n.tr("%1 ATTENTION").arg(body.panel.attentionCount)
            : I18n.tr("Tray Apps") + " · " + body.items.length
        closeObjectName: "closeTrayApps"
        onCloseRequested: body.panel.close()
    }

    Flickable {
        width: parent.width
        height: Math.min(rows.implicitHeight, body.listCap)
        contentHeight: rows.implicitHeight
        clip: true
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: rows
            width: parent.width
            spacing: Tokens.s1

            Repeater {
                model: body.items

                Kit.ListRow {
                    id: row
                    required property var modelData
                    readonly property var e: modelData
                    objectName: "trayApp-" + e.service
                    width: rows.width
                    title: e.name
                    sub: e.attention
                        ? (e.description !== "" ? e.description : I18n.tr("Needs attention"))
                        : e.description
                    on: e.attention
                    leading: Component {
                        Image {
                            source: row.e.icon
                            sourceSize: Qt.size(18, 18)
                            width: 18
                            height: 18
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                        }
                    }

                    Kit.IconButton {
                        objectName: "trayOpen"
                        width: 28
                        height: 28
                        iconSize: 16
                        glyph: "open_in_new"
                        Accessible.role: Accessible.Button
                        Accessible.name: I18n.tr("Open %1").arg(row.e.name)
                        onClicked: body.panel.activateItem(row.e, this)
                    }
                    Kit.IconButton {
                        objectName: "trayPin"
                        width: 28
                        height: 28
                        iconSize: 16
                        glyph: "pin"
                        Accessible.role: Accessible.Button
                        Accessible.name: I18n.tr("Pin")
                        onClicked: body.panel.pinItem(row.e)
                    }
                    Kit.IconButton {
                        objectName: "trayMenu"
                        width: 28
                        height: 28
                        iconSize: 16
                        glyph: "expand_more"
                        enabled: row.e.hasMenu
                        opacity: enabled ? 1 : 0.35
                        Accessible.role: Accessible.Button
                        Accessible.name: row.e.hasMenu ? I18n.tr("AppMenu") : I18n.tr("No Menu")
                        onClicked: body.panel.openMenu(row.e, this)
                    }
                }
            }
        }
    }
}
