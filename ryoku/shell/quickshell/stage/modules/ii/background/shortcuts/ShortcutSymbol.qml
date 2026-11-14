import QtQuick
import stage.modules.common.widgets
import Ryoku.Ui as Ui
import Ryoku.Ui.Singletons

/*
 * An icon in the desktop shortcuts' menus and dialogs: the kit's Solar glyph
 * under crate (the font's where the catalogue has none), the Material Symbols
 * glyph in stock, sized and coloured the same way.
 */
Item {
    id: symbol

    property string text: ""
    property real iconSize: 18
    property color color: Tokens.ink
    readonly property bool crate: Tokens.controlsCrate

    implicitWidth: symbol.crate ? symbol.iconSize : stock.implicitWidth
    implicitHeight: symbol.crate ? symbol.iconSize : stock.implicitHeight

    Ui.Glyph {
        objectName: "shortcutGlyph"
        anchors.centerIn: parent
        visible: symbol.crate
        name: symbol.text
        size: symbol.iconSize
        color: symbol.color
    }
    MaterialSymbol {
        id: stock
        anchors.centerIn: parent
        visible: !symbol.crate
        text: symbol.text
        iconSize: symbol.iconSize
        color: symbol.color
    }
}
