import QtQuick
import QtQuick.Layouts
import stage.modules.common
import stage.modules.common.widgets
import Ryoku.Ui as Ui
import Ryoku.Ui.Singletons

/**
 * The heading over a run of rows on Edit Mode's panel. Under crate it is the
 * kit's TrackLabel in its accent tone: the mono caption at 0.14 em, regular
 * weight, in the theme's caption ink.
 */
StyledText {
    readonly property bool crate: Tokens.controlsCrate
    Layout.fillWidth: true
    Layout.leftMargin: Appearance.sizes.space2
    Layout.topMargin: Appearance.sizes.space4
    Layout.bottomMargin: Appearance.sizes.space1
    font.family: Appearance.font.family.monospace
    font.pixelSize: Appearance.font.pixelSize.smaller
    font.weight: crate ? Font.Normal : Font.Medium
    font.capitalization: Font.AllUppercase
    font.letterSpacing: Appearance.font.trackLabel
    color: crate ? (Tokens.labelAccent ? Tokens.caption : Tokens.inkSubtle) : Appearance.colors.colSubtext
}
