pragma ComponentBehavior: Bound
import QtQuick
import Ryoku.Ui
import Ryoku.Ui.Singletons

// Two stacked cards, appearing together: the Kit pointer and the sidebar /
// settings shortcuts. One X dismisses the whole set. Stock draws them as raised
// paper cards led by a rule and the seal; under crate they are the one glass of
// every floating surface (Tokens.glass, frosted by the crate-glass rule), on the
// shared corner, without the lead rule, the kanji kept after the gloss setting,
// and the X is the kit's icon button.
Column {
    id: stack

    signal dismissed()

    readonly property bool crate: Tokens.controlsCrate

    spacing: Tokens.s3

    // both cards take the wider content's width so they stack flush.
    readonly property real cardW: Math.max(kRow.implicitWidth, hintCol.implicitWidth) + Tokens.s5 * 2

    // A hairline mono cap, the legend's key vocabulary.
    component Cap: Rectangle {
        property string text: ""
        implicitHeight: 22
        implicitWidth: Math.max(22, capLabel.implicitWidth + 14)
        radius: Tokens.radius
        color: "transparent"
        border.width: Tokens.border
        border.color: Tokens.line
        Text {
            id: capLabel
            anchors.centerIn: parent
            text: parent.text
            color: Tokens.inkDim
            font.family: Tokens.mono
            font.pixelSize: Tokens.fMicro
        }
    }

    // A shortcut line: Super + <key> + what it does, in the same cap vocabulary.
    component Hint: Row {
        id: hint
        property string keyCap: ""
        property string label: ""
        spacing: Tokens.s3
        Cap { anchors.verticalCenter: parent.verticalCenter; text: "Super" }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "+"; color: Tokens.inkFaint
            font.family: Tokens.ui; font.pixelSize: Tokens.fMicro
        }
        Cap { anchors.verticalCenter: parent.verticalCenter; text: hint.keyCap }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: hint.label; color: Tokens.inkDim
            font.family: Tokens.ui; font.pixelSize: Tokens.fBody
        }
    }

    // ── card 1: Kit + dismiss ──
    Rectangle {
        objectName: "hintCard"
        width: stack.cardW
        height: 54
        radius: stack.crate ? Tokens.radius : Tokens.radius * 1.5
        color: stack.crate ? Tokens.glass : Tokens.paperLift
        border.width: Tokens.border
        border.color: Tokens.line

        Row {
            id: kRow
            anchors.centerIn: parent
            spacing: Tokens.s3

            Rectangle {
                objectName: "hintLead"
                visible: !stack.crate
                anchors.verticalCenter: parent.verticalCenter
                width: 12; height: 1; color: Tokens.ink
            }
            Text {
                objectName: "hintSeal"
                // under crate only the kanji, and only with the gloss on
                visible: !stack.crate || UiPreferences.showJapaneseGloss
                anchors.verticalCenter: parent.verticalCenter
                text: UiPreferences.brandMark("力"); color: Tokens.ink
                font.family: Tokens.jp; font.pixelSize: Tokens.fBody
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: I18n.tr("Press"); color: Tokens.ink
                font.family: Tokens.ui; font.pixelSize: Tokens.fBody
            }
            Cap { anchors.verticalCenter: parent.verticalCenter; text: "Super" }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "+"; color: Tokens.inkFaint
                font.family: Tokens.ui; font.pixelSize: Tokens.fMicro
            }
            Cap { anchors.verticalCenter: parent.verticalCenter; text: "K" }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: I18n.tr("to open Kit"); color: Tokens.inkDim
                font.family: Tokens.ui; font.pixelSize: Tokens.fBody
            }

            Item { visible: !stack.crate; width: Tokens.s2; height: 1 }

            Rectangle {
                objectName: "hintCloseStock"
                visible: !stack.crate
                anchors.verticalCenter: parent.verticalCenter
                width: 28; height: 28
                radius: Tokens.radius
                color: closeHover.hovered ? Tokens.tint10 : "transparent"
                border.width: Tokens.border
                border.color: closeHover.hovered ? Tokens.lineStrong : Tokens.line
                Behavior on color { ColorAnimation { duration: Tokens.snap } }
                Text {
                    anchors.centerIn: parent
                    text: "✕"; color: Tokens.inkDim
                    font.family: Tokens.ui; font.pixelSize: Tokens.fMicro
                }
                HoverHandler { id: closeHover }
                TapHandler { onTapped: stack.dismissed() }
            }
            IconButton {
                objectName: "hintClose"
                visible: stack.crate
                anchors.verticalCenter: parent.verticalCenter
                width: visible ? implicitWidth : 0
                glyph: "close"
                iconSize: 16
                Accessible.name: I18n.tr("Close")
                onClicked: stack.dismissed()
            }
        }
    }

    // ── card 2: the sidebar + settings shortcuts ──
    Rectangle {
        objectName: "hintCard"
        width: stack.cardW
        height: hintCol.implicitHeight + Tokens.s4 * 2
        radius: stack.crate ? Tokens.radius : Tokens.radius * 1.5
        color: stack.crate ? Tokens.glass : Tokens.paperLift
        border.width: Tokens.border
        border.color: Tokens.line

        Column {
            id: hintCol
            anchors.centerIn: parent
            spacing: Tokens.s2
            Hint { keyCap: "Esc"; label: I18n.tr("for the sidebar") }
            Hint { keyCap: ","; label: I18n.tr("for settings") }
        }
    }
}
