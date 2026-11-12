import QtQuick
import "Singletons"

// The page head every app and Hub page shares, sized to its own content: the
// eyebrow lead (a rule, the 力 seal, a tracked label), an optional register label
// on the right joined by a soft rule, the display-face title, and an optional
// blurb. Promoted from Ryovm's PageHead so the Hub's 22 copies can become one.
Item {
    id: head

    property string eyebrow: ""
    property string register: ""
    property string title: ""
    property string blurb: ""
    property color titleColor: Tokens.ink
    property int titleSize: Tokens.fTitle

    implicitHeight: col.implicitHeight

    Column {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top }
        spacing: Tokens.s2

        Item {
            visible: head.eyebrow.length > 0 || head.register.length > 0
            width: parent.width
            height: Math.max(lead.implicitHeight, reg.implicitHeight)

            Row {
                id: lead
                spacing: Tokens.s2
                anchors.verticalCenter: parent.verticalCenter
                Rectangle { width: 16; height: Tokens.border; color: Tokens.ink; anchors.verticalCenter: parent.verticalCenter }
                Text { text: UiPreferences.brandMark("力"); color: Tokens.ink; font.family: Tokens.jp; font.pixelSize: Tokens.fMicro; anchors.verticalCenter: parent.verticalCenter }
                Text {
                    text: head.eyebrow
                    color: Tokens.inkMuted
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fTiny
                    font.weight: Font.Medium
                    font.letterSpacing: Tokens.trackMark
                    font.capitalization: Font.AllUppercase
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            Rectangle {
                visible: head.register.length > 0
                anchors.left: lead.right
                anchors.right: reg.left
                anchors.leftMargin: Tokens.s3
                anchors.rightMargin: Tokens.s3
                anchors.verticalCenter: parent.verticalCenter
                height: Tokens.border
                color: Tokens.lineSoft
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
                font.capitalization: Font.AllUppercase
            }
        }
        Text {
            visible: head.title.length > 0
            width: parent.width
            text: head.title
            color: head.titleColor
            font.family: Tokens.display
            font.weight: Tokens.displayWeight
            font.pixelSize: head.titleSize
            elide: Text.ElideRight
        }
        Text {
            visible: head.blurb.length > 0
            width: parent.width
            text: head.blurb
            color: Tokens.inkMuted
            font.family: Tokens.ui
            font.pixelSize: Tokens.fSmall
            wrapMode: Text.WordWrap
        }
    }
}
