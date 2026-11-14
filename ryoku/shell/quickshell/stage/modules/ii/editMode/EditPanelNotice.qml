import QtQuick
import QtQuick.Layouts
import stage.modules.common
import stage.modules.common.widgets
import Ryoku.Ui as Ui
import Ryoku.Ui.Singletons

/**
 * The panel's way of saying why a control is not answering: Settings' NoticeBox
 * cut down to a 380px column - one line of icon, one paragraph, no card inside
 * a card.
 */
Rectangle {
    id: root

    property string text: ""
    property string symbol: "lock"

    // Under crate: a quiet wash in a hairline, the reason in secondary ink
    // beside a Solar glyph, rather than a filled plate on the glass.
    readonly property bool crate: Tokens.controlsCrate

    Layout.fillWidth: true
    implicitHeight: noticeRow.implicitHeight + 20
    radius: crate ? Tokens.radius : Appearance.rounding.small
    color: crate ? Tokens.tint5 : Appearance.colors.colSecondaryContainer
    border.width: crate ? Tokens.border : 0
    border.color: Tokens.line

    RowLayout {
        id: noticeRow
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        Ui.Glyph {
            Layout.alignment: Qt.AlignTop
            visible: root.crate
            name: root.symbol
            color: Tokens.inkSecondary
        }
        MaterialSymbol {
            Layout.alignment: Qt.AlignTop
            visible: !root.crate
            text: root.symbol
            iconSize: 18
            color: Appearance.colors.colOnSecondaryContainer
        }
        StyledText {
            Layout.fillWidth: true
            text: root.text
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: root.crate ? Tokens.inkSecondary : Appearance.colors.colOnSecondaryContainer
            wrapMode: Text.Wrap
        }
    }
}
