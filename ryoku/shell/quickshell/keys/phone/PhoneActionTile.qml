import QtQuick
import Ryoku.Ui.Singletons

Rectangle {
    id: root

    property string glyph: ""
    property string label: ""
    property string detail: ""
    property bool armed: true
    signal act()

    activeFocusOnTab: armed
    Keys.onPressed: event => {
        if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)
                && root.armed) {
            if (!event.isAutoRepeat)
                root.act();
            event.accepted = true;
        }
    }

    readonly property bool crate: Tokens.controlsCrate

    implicitHeight: Tokens.cellH + Tokens.s5
    radius: Tokens.radius
    // under crate a flat tile on the 1 px hairline of the opaque pane: no plate
    // of its own, the mark's hover edge, the mark when focused
    color: tap.pressed && armed ? Tokens.tint16
        : hover.hovered && armed ? (root.crate ? Tokens.tint5 : Tokens.tint10)
        : (root.crate ? "transparent" : Tokens.paperLift)
    border.width: Tokens.border
    border.color: activeFocus ? (root.crate ? Tokens.mark : Tokens.bone)
        : hover.hovered && armed ? (root.crate ? Tokens.markHover : Tokens.lineStrong)
        : (root.crate ? Tokens.line : Tokens.lineSoft)
    opacity: armed ? 1 : 0.58
    scale: tap.pressed && armed ? 0.985
        : hover.hovered && armed ? 1.008 : 1
    Behavior on color {
        enabled: !Tokens.reduceMotion
        ColorAnimation { duration: Tokens.snap; easing.type: Easing.OutCubic }
    }
    Behavior on opacity {
        enabled: !Tokens.reduceMotion
        NumberAnimation { duration: Tokens.snap; easing.type: Easing.OutCubic }
    }
    Behavior on scale {
        enabled: !Tokens.reduceMotion
        NumberAnimation { duration: Tokens.snap; easing.type: Easing.OutCubic }
    }

    Column {
        id: body
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Tokens.s4
        spacing: Tokens.s2

        PhoneGlyph {
            name: root.glyph
            color: Tokens.inkDim
            pixelSize: Tokens.fValue
        }
        Text {
            width: parent.width
            text: root.label
            color: Tokens.ink
            font.family: Tokens.ui
            font.pixelSize: Tokens.fRow
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }
        Text {
            width: parent.width
            text: root.detail
            color: Tokens.inkMuted
            font.family: Tokens.ui
            font.pixelSize: Tokens.fSmall
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }
    }

    HoverHandler {
        id: hover
        enabled: root.armed
        cursorShape: Qt.PointingHandCursor
    }
    TapHandler {
        id: tap
        enabled: root.armed
        onTapped: root.act()
    }
}
