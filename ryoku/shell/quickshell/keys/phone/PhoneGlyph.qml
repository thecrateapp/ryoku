import QtQuick
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons

// A phone-tab icon by its Material Symbols name. Under crate it is the kit's
// Solar glyph (Kit.Glyph resolves the Material name through the catalogue's
// aliases); the stock look keeps the Material Symbols text exactly as before.
Item {
    id: g

    property string name: ""
    property color color: Tokens.inkDim
    property real pixelSize: Tokens.fValue

    readonly property bool crate: Tokens.controlsCrate

    implicitWidth: crate ? glyph.implicitWidth : txt.implicitWidth
    implicitHeight: crate ? glyph.implicitHeight : txt.implicitHeight

    Text {
        id: txt
        visible: !g.crate
        anchors.centerIn: parent
        text: g.name
        color: g.color
        font.family: "Material Symbols Rounded"
        font.pixelSize: g.pixelSize
    }
    Kit.Glyph {
        id: glyph
        objectName: "phoneGlyph"
        visible: g.crate
        anchors.centerIn: parent
        name: g.name
        size: g.pixelSize
        color: g.color
    }
}
