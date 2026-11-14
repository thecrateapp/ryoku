import QtQuick
import Ryoku.Ui
import Ryoku.Ui.Singletons

// A caption that is the kit's TrackLabel under crate (mono, tracked, uppercase,
// in its tone) and keeps the face it had in Kit in the stock look. Each caller
// names its stock face once, so the stock legend reads as it always did.
TrackLabel {
    id: cap

    property color stockColor: Tokens.inkFaint
    property string stockFamily: Tokens.mono
    property int stockSize: Tokens.fTiny
    property int stockWeight: Font.Normal
    property real stockSpacing: Tokens.trackLabel
    property int stockCaps: Font.MixedCase

    color: cap.crate ? cap.toneInk : cap.stockColor
    font.family: cap.crate ? Tokens.mono : cap.stockFamily
    font.pixelSize: cap.crate ? Tokens.fMicro : cap.stockSize
    font.weight: cap.crate ? Font.Normal : cap.stockWeight
    font.letterSpacing: cap.crate ? Tokens.trackLabel : cap.stockSpacing
    font.capitalization: cap.crate ? Font.AllUppercase : cap.stockCaps
    elide: cap.crate ? Text.ElideRight : Text.ElideNone
}
