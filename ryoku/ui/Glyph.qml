import QtQuick
import "Singletons"
import "lib/glyphs.js" as Glyphs

// An icon by name. Under controls "crate" a name in the kit's catalogue (Solar
// line-duotone, or a Material Symbols name aliased to it, see lib/glyphs.js)
// draws as that SVG in `color`; otherwise, or for a name the catalogue lacks,
// it draws the Material Symbols glyph as before. `size` is the glyph's box.
Item {
    id: g

    property string name: ""
    property color color: Tokens.ink
    property real size: 18
    property string fallbackFont: "Material Symbols Rounded"

    readonly property bool drawn: Tokens.controlsCrate && Glyphs.has(g.name)

    implicitWidth: g.size
    implicitHeight: g.size

    Image {
        visible: g.drawn
        anchors.centerIn: parent
        width: g.size
        height: g.size
        sourceSize: Qt.size(Math.ceil(g.size * 2), Math.ceil(g.size * 2))
        source: g.drawn ? Glyphs.dataUri(g.name, g.color.toString()) : ""
        smooth: true
        mipmap: true
        asynchronous: false
        cache: true
    }

    Text {
        visible: !g.drawn
        anchors.centerIn: parent
        text: g.name
        color: g.color
        font.family: g.fallbackFont
        font.pixelSize: g.size
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        Accessible.ignored: true
    }
}
