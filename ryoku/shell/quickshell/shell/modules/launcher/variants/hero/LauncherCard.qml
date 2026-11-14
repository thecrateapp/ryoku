import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import Ryoku.Ui.Singletons
import "../../shared/Singletons"

// The launcher card's drawing: its shadow and the clipped plate the hero and
// the drawer sit in. The layer window (LauncherSurface) hosts it, so a probe or
// a scene can load the card offscreen. Under crate the card is the one glass:
// Tokens.glass in a hairline at Tokens.radius, no filled shadow under it, frosted
// by the compositor (decoration.lua crate-glass-blur). Stock keeps the drawer
// plate, the frame edge, the long and short corners and the hard offset shadow.
// The software renderer draws no shader effects (no clipping plate, no shadow),
// so there the content sits in a plain clipped plate of the same fill and edge.
Item {
    id: card

    property real s: 1
    property real longRadius: 0
    property real shortRadius: 0
    default property alias content: holder.data

    readonly property bool crate: Tokens.controlsCrate
    readonly property bool software: GraphicsInfo.api === GraphicsInfo.Software
    readonly property real cornerLong: crate ? Tokens.radius : longRadius
    readonly property real cornerShort: crate ? Tokens.radius : shortRadius

    RectangularShadow {
        objectName: "launcherCardShadow"
        visible: !card.crate
        width: card.width
        height: card.height
        color: Qt.rgba(0, 0, 0, 0.94)
        offset: Qt.vector2d(8 * card.s, 8 * card.s)
        blur: Math.max(0.5, card.s)
        spread: 0
        topLeftRadius: card.longRadius
        topRightRadius: card.shortRadius
        bottomLeftRadius: card.shortRadius
        bottomRightRadius: card.longRadius
    }

    ClippingRectangle {
        id: plate
        objectName: "launcherCardPlate"
        width: card.width
        height: card.height
        color: card.crate ? Tokens.glass : Theme.drawer
        contentUnderBorder: true
        topLeftRadius: card.cornerLong
        topRightRadius: card.cornerShort
        bottomLeftRadius: card.cornerShort
        bottomRightRadius: card.cornerLong
        border.width: card.crate ? Tokens.border : 1
        border.color: card.crate ? Tokens.line : Theme.frame
        visible: !card.software
    }

    Rectangle {
        id: flat
        visible: card.software
        width: card.width
        height: card.height
        clip: true
        color: plate.color
        topLeftRadius: card.cornerLong
        topRightRadius: card.cornerShort
        bottomLeftRadius: card.cornerShort
        bottomRightRadius: card.cornerLong
    }

    Item {
        id: holder
        parent: card.software ? flat : plate.contentItem
        width: card.width
        height: card.height
    }

    // the edge over the content, as the clipping plate draws it
    Rectangle {
        visible: card.software
        width: card.width
        height: card.height
        color: "transparent"
        topLeftRadius: card.cornerLong
        topRightRadius: card.cornerShort
        bottomLeftRadius: card.cornerShort
        bottomRightRadius: card.cornerLong
        border.width: plate.border.width
        border.color: plate.border.color
    }
}
