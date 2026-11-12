pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC
import Ryoku.Ui.Singletons
import Ryoku.Ui as Kit
import shell.services

QQC.AbstractButton {
    id: root
    property real s: 1
    property bool compact: false
    property bool on: false
    property string detail: ""
    property string glyph: ""
    signal toggleRequested(bool value)

    implicitWidth: text === "" ? 48 * s : 200 * s
    implicitHeight: compact ? 44 * s : Math.max(60 * s, copy.implicitHeight + Tokens.s2 * s * 2)
    hoverEnabled: true
    leftPadding: compact ? 0 : Tokens.s2 * s
    rightPadding: compact ? 0 : Tokens.s2 * s
    Accessible.role: Accessible.CheckBox
    Accessible.name: text
    Accessible.description: detail
    Accessible.checkable: true
    Accessible.checked: on
    onClicked: toggleRequested(!on)
    background: Rectangle {
        radius: Tokens.radius * root.s * 1.5
        color: root.down ? Tokens.tint16 : root.hovered ? Tokens.tint5 : "transparent"
        border.width: Tokens.border
        border.color: root.visualFocus ? Tokens.bone : "transparent"
    }
    contentItem: Item {
        Text {
            id: icon
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            visible: root.glyph !== ""
            width: visible ? 24 * root.s : 0
            text: root.glyph
            readonly property color ink: Tokens.inkDim
            color: iconSolar.drawn ? "transparent" : icon.ink
            font.family: "Material Symbols Rounded"
            font.pixelSize: 22 * root.s
            Accessible.ignored: true

            // crate-mark: the kit catalogue's Solar glyph over the font glyph
            Kit.Glyph {
                id: iconSolar
                visible: iconSolar.drawn
                anchors.centerIn: parent
                name: root.glyph
                color: icon.ink
                size: Math.round((22 * root.s) * 0.85)
            }
        }
        Column {
            id: copy
            anchors { left: icon.right; right: track.left; verticalCenter: parent.verticalCenter }
            anchors.leftMargin: icon.visible ? Tokens.s3 * root.s : 0
            anchors.rightMargin: Tokens.s3 * root.s
            spacing: Tokens.s1 * root.s
            Text {
                width: parent.width
                text: root.text
                color: Tokens.ink
                font.family: Tokens.ui
                font.pixelSize: Tokens.fRow * root.s
                font.weight: Font.Medium
                wrapMode: Text.Wrap
            }
            Text {
                visible: root.detail !== ""
                width: parent.width
                text: root.detail
                color: Tokens.inkMuted
                font.family: Tokens.ui
                font.pixelSize: Tokens.fSmall * root.s
                elide: Text.ElideRight
            }
        }
        Rectangle {
            id: track
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            width: (Tokens.controlsCrate ? 34 : 48) * root.s
            height: (Tokens.controlsCrate ? 18 : 28) * root.s
            radius: height / 2
            color: Tokens.controlsCrate ? (root.on ? Qt.rgba(Tokens.mark.r, Tokens.mark.g, Tokens.mark.b, 0.12) : "transparent") : root.on ? Tokens.bone : Tokens.tint16
            border.width: Tokens.border
            border.color: Tokens.controlsCrate ? (root.on ? Tokens.mark : Tokens.line) : root.on ? Tokens.bone : Tokens.lineStrong
            Rectangle {
                width: (Tokens.controlsCrate ? 10 : 20) * root.s; height: width; radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                x: root.on ? track.width - width - 4 * root.s : 4 * root.s
                color: Tokens.controlsCrate ? (root.on ? Tokens.mark : Tokens.inkDim) : root.on ? Tokens.inkOnBone : Tokens.inkDim
                Behavior on x {
                    enabled: !Motion.reduce && !Tokens.reduceMotion
                    NumberAnimation { duration: Tokens.snap; easing.type: Tokens.easeSnap }
                }
            }
        }
    }
    HoverHandler { cursorShape: Qt.PointingHandCursor }
}
