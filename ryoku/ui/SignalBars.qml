import QtQuick
import "Singletons"
import "lib/signal.js" as SignalMath

// Four rising bars for a radio's signal, crate-mark's network glyph: lit bars in
// secondary ink, or the mark when `on` (the connected network), unlit ones faint.
// `strength` is 0..100.
Row {
    id: sig

    property real strength: 0
    property bool on: false
    property real s: 1

    readonly property int lit: SignalMath.bars(sig.strength)

    spacing: 2 * sig.s
    height: 12 * sig.s
    Accessible.role: Accessible.Indicator
    Accessible.name: I18n.tr("Signal %1 of 4").arg(sig.lit)

    Repeater {
        model: 4
        delegate: Rectangle {
            required property int index
            anchors.bottom: parent.bottom
            width: 3 * sig.s
            height: (4 + index * 2.75) * sig.s
            radius: 1 * sig.s
            color: index < sig.lit ? (sig.on ? Tokens.mark : Tokens.inkSecondary) : Tokens.inkFaint2
        }
    }
}
