import QtQuick
import stage.modules.common
import Ryoku.Ui.Singletons

/**
 * The catalogue panel's plate: a flat sheet with a hairline edge, and the
 * remove tint lit while a desktop widget is carried over the panel.
 *
 * Under crate it is the one glass, Tokens.glass in a 1 px Tokens.line at
 * Tokens.radius. Its own Item, so a probe can load it without the panel's
 * services.
 */
Rectangle {
    id: plate

    property bool dropWouldRemove: false
    readonly property bool crate: Tokens.controlsCrate

    objectName: "editDrawerPanel"
    color: plate.crate ? Tokens.glass : Appearance.colors.colLayer0
    radius: plate.crate ? Tokens.radius : Appearance.rounding.small
    border.width: 1
    border.color: plate.crate ? Tokens.line : Appearance.colors.colOutline
    clip: true

    // The remove tint: lit while a desktop widget is carried over the panel.
    Rectangle {
        anchors.fill: parent
        radius: plate.radius
        color: plate.dropWouldRemove ? Appearance.colors.colLayer1Active : "transparent"
        Behavior on color {
            enabled: !Appearance.reducedMotion
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }
}
