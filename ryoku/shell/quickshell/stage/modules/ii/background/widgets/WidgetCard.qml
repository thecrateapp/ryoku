import QtQuick
import stage.modules.common
import Ryoku.Ui.Singletons

/*
 * The card a utility widget sits on (ExpressiveCardWidget's). Its fill and
 * corner are the caller's. Under crate the card is content on the desktop,
 * not a floating panel: it keeps the scheme's fill and adds a 1 px hairline
 * (the caller gives it the shared corner and drops the filled shadow).
 */
Rectangle {
    readonly property bool crate: Tokens.controlsCrate

    objectName: "widgetCard"
    border.width: crate ? Tokens.border : 0
    border.color: Tokens.line

    Behavior on color {
        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
    }
}
