pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.Ui
import Ryoku.Ui.Singletons
import shell.services

Rectangle {
    id: root

    required property real s
    property string askId: ""
    property string question: ""
    property string answer: ""
    property bool expanded: false
    readonly property bool hasAnswer: answer.trim().length > 0
    readonly property bool motionAllowed: !Tokens.reduceMotion && !Motion.reduce
    // Under controls "crate": a hairline card on the glass, edged on hover, with
    // a tracked caption and the kit's glyph.
    readonly property bool crate: Tokens.controlsCrate

    implicitHeight: cardColumn.implicitHeight + Tokens.s3 * s * 2
    radius: Tokens.radius * s
    color: crate ? "transparent"
        : cardTap.pressed ? Tokens.tint16
        : cardHover.hovered && hasAnswer ? Tokens.tint10 : Tokens.tint5
    border.width: Tokens.border
    border.color: crate ? (cardHover.hovered && hasAnswer ? Tokens.markHover : Tokens.line) : Tokens.lineSoft
    scale: crate ? 1
        : cardTap.pressed && motionAllowed ? 0.96
        : cardHover.hovered && motionAllowed ? 1.02 : 1

    Column {
        id: cardColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Tokens.s3 * root.s
        spacing: Tokens.s2 * root.s

        Row {
            width: parent.width
            spacing: Tokens.s2 * root.s

            Glyph {
                visible: root.crate
                anchors.verticalCenter: parent.verticalCenter
                name: "north_east"
                size: 14
                color: Tokens.inkSecondary
            }

            TrackLabel {
                objectName: "askHandoffCaption"
                visible: root.crate
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - toggleLabel.width - Tokens.s6 * root.s
                text: I18n.tr("From Ask")
            }

            Text {
                visible: !root.crate
                text: "north_east"
                color: Tokens.inkMuted
                font.family: "Material Symbols Rounded"
                font.pixelSize: Tokens.fSmall * root.s
            }

            Text {
                visible: !root.crate
                width: parent.width - toggleLabel.width - Tokens.s6 * root.s
                text: I18n.tr("From Ask")
                color: Tokens.inkMuted
                font.family: Tokens.mono
                font.pixelSize: Tokens.fTiny * root.s
                font.letterSpacing: Tokens.trackLabel
            }

            Text {
                id: toggleLabel
                visible: root.hasAnswer
                text: root.expanded ? I18n.tr("Hide answer") : I18n.tr("Show answer")
                color: Tokens.inkDim
                font.family: Tokens.ui
                font.pixelSize: Tokens.fTiny * root.s
            }
        }

        Text {
            width: parent.width
            text: root.question
            color: Tokens.ink
            font.family: Tokens.ui
            font.pixelSize: Tokens.fSmall * root.s
            font.weight: Font.DemiBold
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: root.hasAnswer ? root.answer : I18n.tr("No answer yet")
            color: Tokens.inkMuted
            font.family: Tokens.ui
            font.pixelSize: Tokens.fTiny * root.s
            font.italic: !root.hasAnswer
            wrapMode: Text.WordWrap
            maximumLineCount: root.expanded ? 20 : 2
            elide: root.expanded ? Text.ElideNone : Text.ElideRight
        }
    }

    HoverHandler {
        id: cardHover
        enabled: root.hasAnswer
        cursorShape: Qt.PointingHandCursor
    }
    TapHandler {
        id: cardTap
        enabled: root.hasAnswer
        onTapped: root.expanded = !root.expanded
    }
    Behavior on color {
        enabled: root.motionAllowed
        ColorAnimation { duration: Tokens.snap }
    }
    Behavior on scale {
        enabled: root.motionAllowed
        NumberAnimation { duration: Tokens.snap; easing.type: Tokens.easeSnap }
    }
}
