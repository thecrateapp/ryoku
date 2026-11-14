import QtQuick
import Ryoku.Ui
import Ryoku.Ui.Singletons

// A caption that is the kit's TrackLabel under crate (mono, tracked, uppercase,
// in its tone) and keeps the face it had here in the stock look. The pages'
// field labels, sheet labels and detail heads name their stock face once.
TrackLabel {
    id: cap

    property color stockColor: Tokens.inkMuted
    property string stockFamily: Tokens.ui
    property int stockSize: 10
    property int stockWeight: Font.Medium
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
