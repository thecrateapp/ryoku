import QtQuick
import Ryoku.Ui
import Ryoku.Ui.Singletons
import "look"

// A Game Bar caption (a card's head, a column head, a field's name). Under crate
// it is the kit's TrackLabel at the bar's scale: mono, tracked, uppercase, in its
// tone. In the stock look it keeps the plain face it always had.
TrackLabel {
    id: cap

    property real s: 1
    property color stockColor: GameBarLook.subtext
    property int stockSize: GameBarLook.smallie

    color: cap.crate ? cap.toneInk : cap.stockColor
    font.family: cap.crate ? Tokens.mono : GameBarLook.face
    font.pixelSize: (cap.crate ? GameBarLook.smallest : cap.stockSize) * cap.s
    font.weight: Font.Normal
    font.letterSpacing: cap.crate ? Tokens.trackLabel * cap.s : 0
    font.capitalization: cap.crate ? Font.AllUppercase : Font.MixedCase
}
