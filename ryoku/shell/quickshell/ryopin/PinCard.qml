import QtQuick
import QtQuick.Effects
import Ryoku.Ui.Singletons
import "Singletons"

// What a pin draws: the card holding the pinned image, its drop shadow and the
// hover strip of actions. Pure drawing and pointer input in card-local px; the
// pin's layer window owns the position, the size and the actions, and hosts
// this Item (a layer window needs a compositor, the Item loads offscreen).
//
// Under controls "crate" the image is content: an opaque popover card with the
// shared corner and a 1 px line, no drop shadow. The strip is chrome: the one
// glass (Tokens.glass, frosted by the crate-glass rule on the "ryopin" layer),
// set in the gutter above the card's right edge so it never covers the image,
// holding the kit's IconButtons.
Item {
    id: card

    property string path: ""
    // keep the action strip shown without the pointer over the card
    property bool showStrip: false

    readonly property int natW: shot.sourceSize.width
    readonly property int natH: shot.sourceSize.height
    readonly property bool crate: Tokens.controlsCrate
    readonly property bool hot: hoverH.hovered || stripHover.hovered || card.showStrip

    signal grabbed()
    signal dragged(real dx, real dy)
    signal zoomed(real factor)
    signal editRequested()
    signal copyRequested()
    signal linkRequested()
    signal closeRequested()

    HoverHandler { id: hoverH }

    MultiEffect {
        id: shadowFx
        objectName: "ryopinShadow"
        visible: !card.crate
        anchors.fill: frame
        source: frame
        shadowEnabled: true
        shadowColor: Theme.shadow
        shadowBlur: 1.0
        shadowVerticalOffset: 8
        blurMax: 32
        autoPaddingEnabled: true
    }

    Rectangle {
        id: frame
        objectName: "ryopinFrame"
        anchors.fill: parent
        radius: Theme.radius
        color: card.crate ? Tokens.popover : Theme.panelSolid
        border.color: card.crate ? Tokens.line : Theme.hair
        border.width: 1

        Image {
            id: shot
            anchors.fill: parent
            anchors.margins: 6
            source: card.path.length > 0 ? "file://" + card.path : ""
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            onStatusChanged: if (status === Image.Error) console.error("ryopin: cannot load " + card.path)
        }
    }

    MouseArea {
        id: drag
        anchors.fill: frame
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor

        property bool dragging: false
        property real px: 0
        property real py: 0

        onPressed: (m) => {
            card.grabbed();
            if (m.button === Qt.MiddleButton) { card.closeRequested(); return; }
            dragging = true;
            px = m.x;
            py = m.y;
        }
        onReleased: dragging = false
        onPositionChanged: (m) => {
            if (!dragging) return;
            card.dragged(m.x - px, m.y - py);
        }
        onWheel: (w) => card.zoomed(w.angleDelta.y > 0 ? 1.1 : 0.9)
    }

    // Stock: a bare row over the image's top right. Crate: a glass plate in the
    // gutter above the card; the hover area runs down to the card's edge so the
    // pointer can cross the gap without the strip fading.
    Item {
        id: stripBox
        anchors.right: frame.right
        anchors.rightMargin: card.crate ? 0 : 8
        y: card.crate ? -(plate.height + Theme.stripGap) : 8
        width: plate.width
        height: card.crate ? plate.height + Theme.stripGap : plate.height
        opacity: card.hot ? 1 : 0
        visible: opacity > 0.01

        Behavior on opacity { NumberAnimation { duration: Theme.snap } }

        HoverHandler { id: stripHover }

        Rectangle {
            id: plate
            objectName: "ryopinStripPlate"
            visible: card.crate
            width: strip.width + (card.crate ? Theme.stripPad * 2 : 0)
            height: strip.height + (card.crate ? Theme.stripPad * 2 : 0)
            radius: Tokens.radius
            color: Tokens.glass
            border.color: Tokens.line
            border.width: 1
        }

        Row {
            id: strip
            objectName: "ryopinStrip"
            x: card.crate ? Theme.stripPad : 0
            y: card.crate ? Theme.stripPad : 0
            spacing: card.crate ? 0 : 4

            PinButton { glyph: "\u270E"; solar: "pen"; onClicked: card.editRequested() }
            PinButton { glyph: "\u29C9"; solar: "copy"; onClicked: card.copyRequested() }
            PinButton { glyph: "\u26D3"; solar: "link"; onClicked: card.linkRequested() }
            PinButton { glyph: "\u2715"; solar: "close"; onClicked: card.closeRequested() }
        }
    }
}
