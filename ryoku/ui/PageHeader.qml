import QtQuick
import "Singletons"

Item {
    id: head
    objectName: "pageHeader"

    property string eyebrow: ""
    property string register: ""
    property string title: ""
    property string blurb: ""
    property string gloss: ""
    property color titleColor: Tokens.ink
    property int titleSize: Tokens.fTitle
    property alias actions: trailing.data

    // Hub's stock heads have three printer's marks with different geometry.
    property bool hubStyle: false
    property bool ruled: false
    property bool endMarks: false
    property bool scaleEyebrow: !hubStyle
    property real eyebrowHeight: hubStyle ? Tokens.s5 : Math.max(lead.implicitHeight, reg.implicitHeight)
    property real blurbWidth: hubStyle ? Math.min(width, 720) : width

    implicitHeight: col.implicitHeight

    Column {
        id: col
        width: head.width
        spacing: Tokens.controlsCrate || !head.hubStyle ? Tokens.s2 : Tokens.s3

        Item {
            objectName: "stockEyebrow"
            visible: !Tokens.controlsCrate && (head.eyebrow.length > 0 || head.register.length > 0)
            width: parent.width
            height: head.eyebrowHeight

            Row {
                id: lead
                spacing: Tokens.s2
                anchors.verticalCenter: parent.verticalCenter
                Rectangle { width: 16; height: head.hubStyle && !head.register ? 1 : Tokens.border; color: Tokens.ink; anchors.verticalCenter: parent.verticalCenter }
                Text {
                    text: UiPreferences.brandMark("力")
                    color: Tokens.ink
                    font.family: Tokens.jp
                    font.pixelSize: head.scaleEyebrow ? Tokens.fMicro : 11
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: head.eyebrow
                    color: Tokens.inkMuted
                    font.family: Tokens.ui
                    font.pixelSize: head.scaleEyebrow ? Tokens.fTiny : 9
                    font.weight: Font.Medium
                    font.letterSpacing: Tokens.trackMark
                    font.capitalization: head.hubStyle ? Font.MixedCase : Font.AllUppercase
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            Rectangle {
                visible: head.ruled || head.endMarks || head.register.length > 0
                anchors.left: lead.right
                anchors.right: head.endMarks ? marks.left : reg.left
                anchors.leftMargin: Tokens.s3
                anchors.rightMargin: head.hubStyle && head.ruled && !head.register && !head.endMarks ? 0 : Tokens.s3
                anchors.verticalCenter: parent.verticalCenter
                height: head.hubStyle && !head.register ? 1 : Tokens.border
                color: Tokens.lineSoft
            }
            Row {
                id: marks
                visible: head.endMarks
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: Tokens.s2
                Text { text: "+"; color: Tokens.inkFaint; font.family: Tokens.mono; font.pixelSize: 10 }
                Text { text: "///"; color: Tokens.inkFaint; font.family: Tokens.mono; font.pixelSize: 10 }
            }
            Text {
                id: reg
                visible: head.register.length > 0
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: head.register
                color: Tokens.inkFaint
                font.family: Tokens.mono
                font.pixelSize: Tokens.fTiny
                font.letterSpacing: Tokens.trackLabel
                font.capitalization: head.hubStyle ? Font.MixedCase : Font.AllUppercase
            }
        }

        Item {
            id: titleRow
            width: parent.width
            visible: head.title !== "" || trailing.children.length > 0
            implicitHeight: Tokens.controlsCrate
                ? Math.max(titleLabel.implicitHeight, trailing.implicitHeight, crateRegister.implicitHeight)
                : titleLabel.implicitHeight

            Text {
                id: titleLabel
                anchors.left: parent.left
                anchors.right: trailing.left
                anchors.rightMargin: Tokens.controlsCrate && (trailing.children.length > 0 || head.register) ? Tokens.s2 : 0
                anchors.verticalCenter: parent.verticalCenter
                text: head.title
                color: head.titleColor
                font.family: Tokens.display
                font.weight: Tokens.displayWeight
                font.pixelSize: head.titleSize
                elide: Text.ElideRight
            }
            Row {
                id: trailing
                anchors.right: crateRegister.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: Tokens.s2
            }
            TrackLabel {
                id: crateRegister
                visible: Tokens.controlsCrate && head.register !== ""
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: visible ? Math.min(implicitWidth, titleRow.width / 2) : 0
                text: visible ? head.register : ""
            }
        }
        Text {
            visible: head.gloss !== "" && UiPreferences.showJapaneseGloss
            text: head.gloss
            color: Tokens.inkMuted
            font.family: Tokens.jp
            font.pixelSize: Tokens.fBody
        }
        Text {
            visible: head.blurb.length > 0
            width: head.blurbWidth
            text: head.blurb
            color: Tokens.controlsCrate ? Tokens.inkSecondary : Tokens.inkMuted
            font.family: Tokens.ui
            font.pixelSize: head.hubStyle ? Tokens.fBody : Tokens.fSmall
            wrapMode: Text.WordWrap
        }
    }
}
