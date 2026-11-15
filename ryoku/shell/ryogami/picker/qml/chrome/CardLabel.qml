import QtQuick
import Ryoku.Ui.Singletons

// The current card's labels: its type and favourite tags at the top, its name along
// the bottom. The box is the card's inner rectangle under the same shear card.frag
// draws, so the band follows the card's slant. Under crate the words stand upright
// (a counter-shear undoes the slant on the tags and the name, never on the band) in
// the mono's tracked caps, the applied wallpaper is a tag filled with the mark, and
// the lead bar, Ryoku marginalia, does not show.
Item {
    id: root

    property string type: ""
    property string name: ""
    property int badges: 0
    property bool showName: true
    // half the card's skew and edge tilt, the offsets card.frag shears its box by
    property real sx: 0
    property real ty: 0

    readonly property string typeText: {
        switch (root.type) {
        case "static": return Theme.crate ? I18n.tr("Still") : I18n.tr("PIC")
        case "video": return Theme.crate ? I18n.tr("Video") : I18n.tr("VID")
        case "we": return Theme.crate ? I18n.tr("Scene") : I18n.tr("WE")
        default: return ""
        }
    }
    readonly property bool favourite: (root.badges & 1) !== 0
    readonly property bool applied: (root.badges & 32) !== 0

    readonly property real _a: -2 * root.sx / Math.max(root.height, 1)
    readonly property real _b: -2 * root.ty / Math.max(root.width, 1)
    readonly property real _det: 1 - root._a * root._b
    // The shear's linear part inverted, about each upright item's own origin; the
    // stock look keeps the identity, so its words slant with the card as before.
    readonly property matrix4x4 upright: Theme.crate && Math.abs(root._det) > 1e-3
        ? Qt.matrix4x4(1 / root._det, -root._a / root._det, 0, 0,
                       -root._b / root._det, 1 / root._det, 0, 0,
                       0, 0, 1, 0,
                       0, 0, 0, 1)
        : Qt.matrix4x4()

    clip: true
    transform: Matrix4x4 {
        matrix: Qt.matrix4x4(1, -2 * root.sx / Math.max(root.height, 1), 0, root.sx,
                             -2 * root.ty / Math.max(root.width, 1), 1, 0, root.ty,
                             0, 0, 1, 0,
                             0, 0, 0, 1)
    }

    // A corner tag. Under crate every tag is one height, glass in a hairline, and an
    // on tag is filled with the mark; the stock look keeps its sizes and its plate.
    component Tag: Rectangle {
        id: tag
        property string text: ""
        property string glyph: ""
        property bool on: false
        readonly property Text face: tag.glyph.length > 0 ? tagGlyph : tagText
        readonly property real crateSide: crateCut.implicitHeight + Tokens.s1 * 2

        radius: Theme.radius
        color: Theme.crate ? (tag.on ? Tokens.mark : Tokens.glass) : Theme.withAlpha(Theme.background, 0.72)
        border.width: 1
        border.color: Theme.crate ? (tag.on ? Tokens.mark : Tokens.line) : Theme.withAlpha(Theme.outline, 0.40)
        implicitHeight: Theme.crate ? tag.crateSide : tag.face.implicitHeight + 6 * Theme.scale
        implicitWidth: Theme.crate && tag.glyph.length > 0 ? tag.crateSide
            : tag.face.implicitWidth + (Theme.crate ? Tokens.s2 * 2 : (tag.glyph.length > 0 ? 10 : 12) * Theme.scale)

        Text {
            id: crateCut
            visible: false
            text: "X"
            font: tagText.font
        }
        Text {
            id: tagText
            objectName: "cardTagText"
            visible: tag.glyph.length === 0
            anchors.centerIn: parent
            text: tag.text
            font.family: Theme.crate ? Theme.mono : Theme.sans
            font.weight: Theme.crate ? Font.Medium : Font.DemiBold
            font.pixelSize: Theme.fontFine
            font.capitalization: Theme.crate ? Font.AllUppercase : Font.MixedCase
            font.letterSpacing: Theme.crate ? Tokens.trackLabel : 0
            color: Theme.crate ? (tag.on ? Tokens.paper : Tokens.inkMuted) : Theme.withAlpha(Theme.surfaceText, 0.92)
            renderType: Text.NativeRendering
        }
        Text {
            id: tagGlyph
            visible: tag.glyph.length > 0
            anchors.centerIn: parent
            text: tag.glyph
            font.family: Theme.icon
            font.pixelSize: Theme.fontFine
            color: Theme.crate ? Tokens.inkMuted : Theme.withAlpha(Theme.surfaceText, 0.92)
            renderType: Text.NativeRendering
        }
    }

    Row {
        objectName: "cardTags"
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 8 * Theme.scale
        spacing: 5 * Theme.scale
        transform: Matrix4x4 { matrix: root.upright }

        Tag {
            objectName: "cardTypeTag"
            visible: root.typeText.length > 0
            text: root.typeText
        }
        Tag {
            objectName: "cardFavTag"
            visible: root.favourite
            glyph: "\u{f02d1}"
        }
        Tag {
            objectName: "cardLiveTag"
            visible: Theme.crate && root.applied
            text: I18n.tr("LIVE")
            on: true
        }
    }

    Rectangle {
        objectName: "cardNameBand"
        visible: root.showName
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        implicitHeight: nameLabel.implicitHeight + (Theme.crate ? Tokens.s2 * 2 : 12 * Theme.scale)
        color: Theme.crate ? Tokens.glass : Theme.withAlpha(Theme.background, 0.62)

        Rectangle {
            objectName: "cardLeadBar"
            visible: !Theme.crate && root.applied
            anchors.left: parent.left
            anchors.top: parent.top
            width: 3 * Theme.scale
            height: parent.height
            color: Theme.surfaceText
        }

        Text {
            id: nameLabel
            objectName: "cardNameText"
            x: Theme.crate ? Tokens.s3 : 12 * Theme.scale
            y: (parent.height - height) * 0.5
            width: parent.width - 2 * x
            transform: Matrix4x4 { matrix: root.upright }
            text: root.name
            elide: Text.ElideRight
            font.family: Theme.crate ? Theme.mono : Theme.sans
            font.weight: Theme.crate ? Font.Medium : Font.DemiBold
            font.pixelSize: Theme.crate ? Theme.fontMicro : Theme.fontBody
            font.capitalization: Theme.crate ? Font.AllUppercase : Font.MixedCase
            font.letterSpacing: Theme.crate ? Tokens.trackLabel : 0
            color: Theme.crate ? Tokens.inkMuted : Theme.surfaceText
            renderType: Text.NativeRendering
        }
    }
}
