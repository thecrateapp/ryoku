import QtQuick

// One launcher mark, drawn the way the bar draws it: a wordmark (mode "text"),
// a font glyph, or a drawn glyph for a mark no font carries (the Crate logo).
// The bar's LauncherWidget and the Identity picker both draw through here, so
// a tile previews exactly what the bar will show. Resolvers live in Theme.
Item {
    id: mark

    property var root: null            // the qsbar Theme
    property string mode: "text"       // "text" | "icon"
    property string markId: ""
    property color color: "white"
    property real fitWidth: 0          // > 0: shrink a long wordmark to this width (picker tiles)

    readonly property bool iconMode: mode === "icon"
    readonly property bool drawn: iconMode && !!root && root.launcherLogoIconDrawn(markId)
    readonly property string text: drawn ? "" : label.text

    implicitWidth: drawn ? glyph.width : label.implicitWidth
    implicitHeight: drawn ? glyph.height : label.implicitHeight

    Text {
        id: label
        anchors.centerIn: parent
        visible: !mark.drawn
        width: mark.fitWidth > 0 ? mark.fitWidth : implicitWidth
        horizontalAlignment: Text.AlignHCenter
        text: !mark.root ? mark.markId
            : mark.iconMode ? mark.root.launcherLogoIconGlyph(mark.markId)
            : mark.root.launcherLogoTextLabel(mark.markId)
        color: mark.color
        renderType: Text.NativeRendering
        font.family: !mark.root ? "monospace"
            : mark.iconMode ? mark.root.launcherLogoIconFont(mark.markId) : mark.root.mono
        font.pixelSize: mark.iconMode && mark.root ? mark.root.launcherLogoIconSize(mark.markId) : 12
        font.weight: Font.Bold
        font.letterSpacing: mark.iconMode ? 0 : 2
        fontSizeMode: mark.fitWidth > 0 ? Text.HorizontalFit : Text.FixedSize
        minimumPixelSize: 7
    }

    CrateGlyph {
        id: glyph
        anchors.centerIn: parent
        visible: mark.drawn
        height: mark.root ? mark.root.launcherLogoIconSize(mark.markId) : 14
        width: implicitWidth
        color: mark.color
    }
}
