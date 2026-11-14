import QtQuick
import stage.modules.common
import stage.modules.common.widgets
import Ryoku.Ui as Ui
import Ryoku.Ui.Singletons

/*
 * One of the two knobs a widget carries through Edit Mode: the resize grip
 * and the menu grip. `hot` while the pointer is on it or it is being dragged.
 * Under crate the knob is the popover ground in a hairline at the shared
 * corner, with the kit's Solar glyph in secondary ink, both warming to the
 * mark when hot. Opaque, not glass: the widget layers are not frosted.
 */
Rectangle {
    id: knob

    property string symbol: ""
    property real symbolSize: 13
    property bool hot: false
    readonly property bool crate: Tokens.controlsCrate

    width: 22
    height: 22
    radius: crate ? Tokens.radius : 7
    color: crate ? Tokens.popover
        : knob.hot ? Appearance.colors.colPrimary : Appearance.colors.colSecondaryContainer
    border.width: crate ? Tokens.border : 0
    border.color: knob.hot ? Tokens.mark : Tokens.line

    Behavior on color {
        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(knob)
    }

    Ui.Glyph {
        objectName: "widgetGripGlyph"
        anchors.centerIn: parent
        visible: knob.crate
        name: knob.symbol
        size: 14
        color: knob.hot ? Tokens.mark : Tokens.inkSecondary
    }
    MaterialSymbol {
        anchors.centerIn: parent
        visible: !knob.crate
        text: knob.symbol
        iconSize: knob.symbolSize
        color: knob.hot ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
    }
}
