import QtQuick
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons as Ui
import "../../components"
import "look"

// One Game Bar icon: a line glyph (`glyph`, GlyphIcon's names) or a Material
// symbol (`symbol`). Under crate a name the kit's Solar catalogue draws is the
// kit Glyph; a name it lacks keeps the Game Bar's own icon in either look.
Item {
    id: root

    property string glyph: ""
    property string symbol: ""
    property color color: GameBarLook.fg
    property real stroke: 1.6
    property real fill: 0

    readonly property string solar: Ui.Tokens.controlsCrate
        ? GameBarLook.solar(root.glyph.length > 0 ? root.glyph : root.symbol) : ""

    Kit.Glyph {
        objectName: "gameBarSolarGlyph"
        visible: root.solar.length > 0
        anchors.centerIn: parent
        size: Math.min(root.width, root.height)
        name: root.solar
        color: root.color
    }

    GlyphIcon {
        anchors.fill: parent
        visible: root.solar.length === 0 && root.glyph.length > 0
        name: root.glyph
        color: root.color
        stroke: root.stroke
    }

    MaterialIcon {
        anchors.fill: parent
        visible: root.solar.length === 0 && root.glyph.length === 0
        text: root.symbol
        color: root.color
        fill: root.fill
        font.pixelSize: Math.min(root.width, root.height)
    }
}
