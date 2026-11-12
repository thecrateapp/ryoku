pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.Ui.Singletons

Rectangle {
    id: root
    property real s: 1
    radius: Tokens.radius * s * (Tokens.controlsCrate ? 10 / 6 : 2.5)
    color: Tokens.controlsCrate ? Tokens.popover : Tokens.paper
    border.width: Tokens.border
    border.color: Tokens.line
    Rectangle {
        visible: !Tokens.controlsCrate
        anchors.fill: parent
        anchors.margins: Tokens.border
        radius: Math.max(0, root.radius - Tokens.border)
        color: "transparent"
        border.width: Tokens.border
        border.color: Qt.alpha(Tokens.ink, Tokens.light ? 0.02 : 0.035)
    }
}
