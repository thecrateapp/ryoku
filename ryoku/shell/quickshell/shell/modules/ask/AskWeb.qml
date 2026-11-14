pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.Ui
import Ryoku.Ui.Singletons
import shell.services
import "../launcher/shared/providers/web" as WebProvider

Item {
    id: root

    required property real s
    property bool active: false
    property string query: ""
    property int selectedIndex: 0
    property var rows: []
    readonly property bool motionAllowed: active && !Tokens.reduceMotion && !Motion.reduce
    // Under controls "crate" the instant answer is a hairline card on the glass
    // and each result a kit pick row, the selected one picked.
    readonly property bool crate: Tokens.controlsCrate

    implicitHeight: content.implicitHeight

    function refresh() {
        rows = query.trim().length > 0 ? provider.query(query.trim(), "?") : [];
        selectedIndex = rows.length > 0 ? 0 : -1;
    }

    function move(delta) {
        selectedIndex = Math.max(0, Math.min(rows.length - 1, selectedIndex + delta));
    }

    function activate() {
        const row = rows[selectedIndex];
        if (row && row.actions && row.actions.length > 0)
            row.actions[0].execute();
    }

    onQueryChanged: if (active) refresh()
    onActiveChanged: {
        if (active) refresh();
        else rows = [];
    }

    WebProvider.Web { id: provider }

    Column {
        id: content
        width: parent.width
        spacing: Tokens.s3 * root.s

        Rectangle {
            width: parent.width
            visible: provider.answer.available === true
            implicitHeight: answerColumn.implicitHeight + Tokens.s4 * root.s * 2
            radius: Tokens.radius * root.s
            color: root.crate ? "transparent" : Tokens.paperLift
            border.width: Tokens.border
            border.color: root.crate ? Tokens.line : Tokens.lineStrong
            Column {
                id: answerColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Tokens.s4 * root.s
                spacing: Tokens.s2 * root.s
                Text {
                    width: parent.width
                    text: provider.answer.heading || I18n.tr("Instant answer")
                    color: Tokens.ink
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fRow * root.s
                    font.weight: Font.DemiBold
                    wrapMode: Text.WordWrap
                }
                TextEdit {
                    width: parent.width
                    text: provider.answer.text || ""
                    color: Tokens.inkDim
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fSmall * root.s
                    wrapMode: TextEdit.Wrap
                    readOnly: true
                    selectByMouse: true
                }
                Text {
                    visible: String(provider.answer.source || "").length > 0
                    text: provider.answer.source
                    color: Tokens.inkMuted
                    font.family: Tokens.mono
                    font.pixelSize: Tokens.fTiny * root.s
                }
            }
            HoverHandler { enabled: String(provider.answer.url || "").length > 0; cursorShape: Qt.PointingHandCursor }
            TapHandler { enabled: String(provider.answer.url || "").length > 0; onTapped: Spawn.runApp(["xdg-open", provider.answer.url], { label: "browser" }) }
        }

        Text {
            width: parent.width
            visible: root.query.trim().length === 0
            text: I18n.tr("Try a question or a bang like !yt ambient music")
            color: Tokens.inkMuted
            font.family: Tokens.ui
            font.pixelSize: Tokens.fSmall * root.s
            wrapMode: Text.WordWrap
        }

        Repeater {
            model: root.rows
            delegate: Rectangle {
                id: webRow
                required property var modelData
                required property int index
                width: parent.width
                height: 52 * root.s
                radius: Tokens.radius * root.s
                readonly property bool current: index === root.selectedIndex
                color: root.crate ? "transparent"
                    : current ? Tokens.bone
                    : webTap.pressed ? Tokens.tint16
                    : webHover.hovered ? Tokens.tint10 : "transparent"
                border.width: root.crate ? 0 : Tokens.border
                border.color: current ? Tokens.bone : Tokens.lineSoft
                PickRow {
                    objectName: "askWebRow"
                    visible: root.crate
                    anchors.fill: parent
                    glyph: "public"
                    title: webRow.modelData.title || ""
                    sub: webRow.modelData.subtitle || ""
                    picked: webRow.current
                    onClicked: {
                        root.selectedIndex = webRow.index;
                        root.activate();
                    }
                }
                Text {
                    visible: !root.crate
                    anchors.left: parent.left
                    anchors.leftMargin: Tokens.s3 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    text: "public"
                    color: webRow.current ? Tokens.inkOnBone : Tokens.inkMuted
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: Tokens.fValue * root.s
                }
                Column {
                    visible: !root.crate
                    anchors.left: parent.left
                    anchors.right: keycap.left
                    anchors.leftMargin: 46 * root.s
                    anchors.rightMargin: Tokens.s3 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        width: parent.width
                        text: webRow.modelData.title
                        color: webRow.current ? Tokens.inkOnBone : Tokens.ink
                        font.family: Tokens.ui
                        font.pixelSize: Tokens.fSmall * root.s
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        text: webRow.modelData.subtitle
                        color: webRow.current ? Tokens.inkOnBone : Tokens.inkMuted
                        font.family: Tokens.ui
                        font.pixelSize: Tokens.fTiny * root.s
                        elide: Text.ElideRight
                    }
                }
                Text {
                    id: keycap
                    visible: !root.crate
                    anchors.right: parent.right
                    anchors.rightMargin: Tokens.s3 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    text: webRow.current ? I18n.tr("Enter") : ""
                    color: webRow.current ? Tokens.inkOnBone : Tokens.inkMuted
                    font.family: Tokens.mono
                    font.pixelSize: Tokens.fTiny * root.s
                }
                HoverHandler { id: webHover; cursorShape: Qt.PointingHandCursor; onHoveredChanged: if (hovered) root.selectedIndex = webRow.index }
                TapHandler {
                    id: webTap
                    enabled: !root.crate
                    onTapped: {
                        root.selectedIndex = webRow.index;
                        root.activate();
                    }
                }
            }
        }
    }
}
