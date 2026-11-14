import QtQuick
import stage.modules.common
import Ryoku.Ui.Singletons

/*
 * The halo a selected widget wears in Edit Mode (the canvas marquee's
 * feedback, distinct from the drag lift). Under crate it is the kit's
 * selection: the pick wash in a 1 px pickEdge at the shared corner.
 */
Rectangle {
    readonly property bool crate: Tokens.controlsCrate

    objectName: "widgetSelectionHalo"
    radius: crate ? Tokens.radius : Appearance.rounding.large
    color: crate ? Tokens.pickFill : Qt.alpha(Appearance.colors.colPrimary, 0.08)
    border.color: crate ? Tokens.pickEdge : Appearance.colors.colPrimary
    border.width: crate ? Tokens.border : 2
}
