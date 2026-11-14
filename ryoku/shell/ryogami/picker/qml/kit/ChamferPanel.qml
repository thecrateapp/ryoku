import QtQuick
import Ryoku.Ui.Singletons

// A floating dialog plate: flat paper, a hairline, a hair of rounding. It floats, so it
// keeps a soft shadow; there is no colour on it, only the words it holds.
Rectangle {
    id: panel

    property real reveal: 1

    radius: Theme.radius
    color: Theme.withAlpha(Theme.surface, (Theme.crate ? 1 : 0.99) * panel.reveal)
    border.width: 1
    border.color: Theme.crate ? Theme.withAlpha(Tokens.line, Tokens.line.a * panel.reveal)
        : Theme.withAlpha(Theme.outline, 0.55 * panel.reveal)
}
