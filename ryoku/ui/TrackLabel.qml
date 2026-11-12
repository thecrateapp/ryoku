import QtQuick
import "Singletons"

// A tracked caption. Under controls "crate" it is crate-mark's mono label: 11 px,
// 0.14 em, uppercase; tone "subtle" by default, "accent" for a section head (the
// theme's caption ink under labelAccent), "active" for something that is live.
// Otherwise it keeps the kit's stock micro label.
Text {
    id: lbl

    property string tone: "subtle"

    readonly property bool crate: Tokens.controlsCrate

    color: lbl.tone === "active" ? Tokens.mark
        : lbl.tone === "accent" && Tokens.labelAccent ? Tokens.caption
        : lbl.crate ? Tokens.inkSubtle : Tokens.inkFaint
    font.family: lbl.crate ? Tokens.mono : Tokens.ui
    font.pixelSize: Tokens.fMicro
    font.weight: lbl.crate ? Font.Normal : Font.Medium
    font.letterSpacing: Tokens.trackLabel
    font.capitalization: Font.AllUppercase
    elide: Text.ElideRight
}
