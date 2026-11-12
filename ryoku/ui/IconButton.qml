import QtQuick
import QtQuick.Shapes
import "Singletons"

// An icon button. Under controls "crate" it is crate-mark's: an 18 px glyph with
// no plate, secondary ink, the mark on hover and when on, a 44 px hit area.
// Otherwise it keeps IconBtn's stock square plate. The icon is either a 24-unit
// SVG path (`path`, stroked like Solar line icons) or a glyph name (`glyph`),
// drawn through Glyph: the catalogue's Solar icon under crate, else the font.
Item {
    id: ib

    property string path: ""
    property string glyph: ""
    property string glyphFont: Tokens.ui
    property bool on: false
    // alert ink, for a state that needs attention (a muted channel)
    property bool alert: false
    property int iconSize: 18
    signal clicked()

    readonly property bool crate: Tokens.controlsCrate
    readonly property bool hot: hover.hovered && ib.enabled
    readonly property color ink: ib.alert ? Tokens.alert
        : ib.crate ? (ib.on || ib.hot ? Tokens.mark : Tokens.inkSecondary)
        : (ib.on ? Tokens.inkOnBone : Tokens.inkDim)

    implicitWidth: ib.crate ? 44 : 26
    implicitHeight: ib.crate ? 44 : 26
    opacity: ib.enabled ? 1 : (ib.crate ? 0.5 : 0.3)
    activeFocusOnTab: ib.enabled
    Keys.onSpacePressed: ib.clicked()
    Keys.onReturnPressed: ib.clicked()

    // stock plate (and the focus edge in both looks)
    Rectangle {
        anchors.fill: parent
        anchors.margins: ib.crate ? 8 : 0
        radius: ib.crate ? width / 2 : Tokens.radius
        color: ib.crate ? "transparent"
            : ib.on ? Tokens.bone
            : tap.pressed ? Tokens.tint16 : ib.hot ? Tokens.tint10 : "transparent"
        border.width: ib.crate ? (ib.activeFocus ? 1 : 0) : Tokens.border
        border.color: ib.crate ? Tokens.mark : (ib.hot ? Tokens.lineStrong : Tokens.line)
        Behavior on color { ColorAnimation { duration: Tokens.snap } }
    }

    Shape {
        visible: ib.path.length > 0
        anchors.centerIn: parent
        width: ib.crate ? ib.iconSize : 14
        height: width
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: ib.ink
            strokeWidth: 1.5
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            scale: Qt.size((ib.crate ? ib.iconSize : 14) / 24, (ib.crate ? ib.iconSize : 14) / 24)
            PathSvg { path: ib.path }
        }
    }
    // a glyph name: the kit catalogue's Solar icon under crate, the font glyph otherwise
    Glyph {
        visible: ib.path.length === 0
        anchors.centerIn: parent
        name: ib.glyph
        color: ib.ink
        fallbackFont: ib.glyphFont
        size: ib.crate ? ib.iconSize : 12
    }

    HoverHandler { id: hover; enabled: ib.enabled; cursorShape: Qt.PointingHandCursor }
    TapHandler { id: tap; enabled: ib.enabled; onTapped: ib.clicked() }
}
