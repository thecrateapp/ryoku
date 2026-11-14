import QtQuick
import Ryoku.Ui.Singletons

// The card the pinned bubble opens: the chat's frame. Stock is paper with a
// strong edge; under controls "crate" it is the one glass with a hairline.
Rectangle {
    id: root

    required property real s
    readonly property bool crate: Tokens.controlsCrate

    radius: Tokens.radius * s
    color: crate ? Tokens.glass : Tokens.paper
    border.width: Tokens.border
    border.color: crate ? Tokens.line : Tokens.lineStrong
}
