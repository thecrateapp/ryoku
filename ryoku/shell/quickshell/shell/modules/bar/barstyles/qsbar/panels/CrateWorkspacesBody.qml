pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons

// The QS Bar workspace list under the crate look: a kit ListRow per workspace
// with its window count, the active one taking the pick and the one the arrow
// keys reached showing its edge; a whole row goes to its workspace. It reads
// and drives only the panel: workspaces [{id, name, windows}], activeId,
// navIndex, goTo(id) and close().
Column {
    id: body
    required property var panel
    spacing: Tokens.s3

    CrateResourceHeader {
        width: parent.width
        title: I18n.tr("Workspaces")
        closeObjectName: "closeWorkspaces"
        onCloseRequested: body.panel.close()
    }

    Column {
        width: parent.width
        spacing: Tokens.s1

        Repeater {
            model: body.panel.workspaces || []

            Item {
                id: slot
                required property var modelData
                required property int index
                function activate() { body.panel.goTo(slot.modelData.id) }
                objectName: "wsGo-" + modelData.id
                width: body.width
                height: row.implicitHeight
                Accessible.role: Accessible.Button
                Accessible.name: row.title
                Accessible.onPressAction: slot.activate()

                Kit.ListRow {
                    id: row
                    objectName: "ws-" + slot.modelData.id
                    anchors.fill: parent
                    glyph: "desktop_windows"
                    title: I18n.tr("Workspace %1").arg(slot.modelData.name)
                    sub: slot.modelData.windows === 0 ? I18n.tr("No windows")
                        : slot.modelData.windows === 1 ? I18n.tr("1 window")
                        : I18n.tr("%1 windows").arg(slot.modelData.windows)
                    on: slot.modelData.id === body.panel.activeId
                    quiet: !row.on && slot.index !== body.panel.navIndex
                }
                TapHandler {
                    cursorShape: Qt.PointingHandCursor
                    onTapped: slot.activate()
                }
            }
        }
    }
}
