pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC
import Ryoku.Ui.Singletons
import shell.services

QQC.AbstractButton {
    id: root
    property real s: 1
    property string glyph: ""
    property bool primary: false
    property bool armed: true
    property bool compact: false
    property bool motionEnabled: !Motion.reduce && !Tokens.reduceMotion
    signal act()

    enabled: armed
    hoverEnabled: true
    implicitWidth: Math.ceil(Math.max(44 * s, label.implicitWidth + (glyph !== "" ? (20 + Tokens.s2) * s : 0) + Tokens.s3 * s * 2))
    implicitHeight: (Tokens.controlsCrate && text !== "" ? 32 : (compact ? 40 : 44)) * s
    padding: Tokens.s3 * s
    Accessible.name: text
    onClicked: act()
    opacity: enabled ? 1 : 0.5
    background: Rectangle {
        // crate-mark: a labelled button is a straight chip, an icon-only one has no plate
        radius: Tokens.controlsCrate ? Tokens.radius * root.s : Tokens.radius * root.s * 1.5
        color: Tokens.controlsCrate ? (root.primary ? Tokens.mark : root.text === "" ? "transparent" : (root.hovered ? Tokens.tint5 : "transparent"))
            : root.primary ? Tokens.bone : root.down ? Tokens.tint16 : root.hovered ? Tokens.tint10 : Tokens.tint5
        border.width: Tokens.controlsCrate && root.text === "" ? (root.visualFocus ? Tokens.border : 0) : Tokens.border
        border.color: Tokens.controlsCrate ? (root.visualFocus ? Tokens.focus : root.primary ? Tokens.mark : root.hovered ? Tokens.markHover : Tokens.line)
            : root.visualFocus ? Tokens.bone : root.primary ? Tokens.bone : Tokens.lineSoft
        Behavior on color { enabled: root.motionEnabled; ColorAnimation { duration: Tokens.snap } }
    }
    contentItem: Item {
        implicitWidth: label.implicitWidth + (root.glyph !== "" ? (20 + Tokens.s2) * root.s : 0)
        Text {
            id: icon
            visible: root.glyph !== ""
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            width: 20 * root.s
            text: root.glyph
            color: Tokens.controlsCrate ? (root.primary ? Tokens.paper : root.hovered ? Tokens.mark : Tokens.inkSecondary) : (root.primary ? Tokens.inkOnBone : Tokens.inkDim)
            font.family: "Material Symbols Rounded"
            font.pixelSize: 20 * root.s
            Accessible.ignored: true
        }
        Text {
            id: label
            anchors { left: root.glyph !== "" ? icon.right : parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
            anchors.leftMargin: root.glyph !== "" ? Tokens.s2 * root.s : 0
            text: root.text
            color: Tokens.controlsCrate ? (root.primary ? Tokens.paper : root.hovered ? Tokens.ink : Tokens.inkSecondary) : (root.primary ? Tokens.inkOnBone : Tokens.ink)
            font.family: Tokens.controlsCrate ? Tokens.mono : Tokens.ui
            font.pixelSize: (Tokens.controlsCrate ? 12 : Tokens.fRow) * root.s
            font.weight: Tokens.controlsCrate ? Font.Normal : Font.Medium
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
    }
    CornerTip { s: root.s; visible: root.hovered && (label.truncated || root.text === ""); text: root.Accessible.name }
    HoverHandler { cursorShape: Qt.PointingHandCursor }
}
