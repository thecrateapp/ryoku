import QtQuick
import QtQuick.Layouts
import stage.modules.common
import stage.modules.common.widgets
import Ryoku.Ui as Ui
import Ryoku.Ui.Singletons

/**
 * One row of an edit-mode menu card: a symbol, a label, a ripple. Shared by
 * the widget menu and the desktop menu so the two cannot drift apart.
 */
RippleButton {
    id: row
    property string symbol: ""
    property string label: ""
    property color colText: Appearance.m3colors.m3onSurface
    // The card's inner padding, so the hover shape follows the card's corner.
    property real cardPadding: 6
    // Under crate the row's glyph is Solar's and its hover the faint ink wash.
    readonly property bool crate: Tokens.controlsCrate

    Layout.fillWidth: true
    implicitHeight: 34
    buttonRadius: Math.max(0, Appearance.rounding.windowRounding - row.cardPadding)
    colBackground: "transparent"
    colBackgroundHover: crate ? Tokens.tint5 : Appearance.colors.colLayer1Hover
    colRipple: crate ? Tokens.tint10 : Appearance.colors.colLayer1Active

    contentItem: RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 8

        Ui.Glyph {
            visible: row.crate
            name: row.symbol
            color: row.enabled ? row.colText : Tokens.inkFaint
        }
        MaterialSymbol {
            visible: !row.crate
            text: row.symbol
            iconSize: Appearance.font.pixelSize.larger
            color: row.enabled ? row.colText : Appearance.m3colors.m3outline
        }
        StyledText {
            Layout.fillWidth: true
            text: row.label
            font.pixelSize: Appearance.font.pixelSize.small
            color: row.enabled ? row.colText : Appearance.m3colors.m3outline
            elide: Text.ElideRight
        }
    }
}
