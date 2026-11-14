pragma Singleton

import QtQuick
import Quickshell
import Ryoku.Ui.Singletons

// ryopin is a separate Quickshell config and cannot import ryoshot's Singletons,
// so this is a second copy of the same Tokens derivation, trimmed to the roles a
// pin uses.
Singleton {
    readonly property color panel: Qt.rgba(Tokens.paper.r, Tokens.paper.g, Tokens.paper.b, 0.92)
    readonly property color panelSolid: Tokens.paperLift
    readonly property color hair: Tokens.lineSoft
    readonly property color shadow: Qt.rgba(0, 0, 0, 0.5)

    readonly property color ink: Tokens.ink
    readonly property color inkDim: Tokens.inkDim

    readonly property color accent: Tokens.sun
    readonly property color accentInk: Tokens.paper

    readonly property color hover: Tokens.tint10

    readonly property string ui: Tokens.ui
    readonly property string mono: Tokens.mono

    // a card's corner: twice the token in stock, the shared 6 px under crate
    readonly property int radius: Tokens.controlsCrate ? Tokens.radius : Tokens.radius * 2
    readonly property int snap: Tokens.snap

    // Under crate the action strip is a glass plate in the gutter above the card:
    // its buttons, the plate's padding and the gap down to the card.
    readonly property int actionSize: Tokens.s6
    readonly property int stripPad: 2
    readonly property int stripGap: Tokens.s1
    // the transparent room around the card: the drop shadow's spill in stock,
    // the strip plus a gap from the output's edge under crate
    readonly property int gutter: Tokens.controlsCrate ? actionSize + stripPad * 2 + stripGap * 2 : 28
}
