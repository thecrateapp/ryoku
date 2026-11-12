import QtQuick
import "Singletons"

// The tab bar, once. Selection is typography, not a coloured bar: the active
// plate inverts to bone and its label takes the sheet's // lead, the reference
// poster's `001 // ABOUT` register. One fixed layout on every page: the lead is
// a slot reserved on EVERY plate and only inked when active, so selecting a tab
// never widens it or shoves the tabs beside it sideways. A theme that drops the
// selection fill (themeStyle selectFill: false) draws the live tab as its
// navigation does instead: the label in the mark colour over a 2 px underline,
// no plate and no lead.
Row {
    id: tabs

    property var options: []        // list of labels
    property string current: ""
    signal chose(string label)

    spacing: Tokens.s2

    Repeater {
        model: tabs.options
        Rectangle {
            id: plate
            required property string modelData
            readonly property bool on: tabs.current === modelData

            // the lead slot is in the row on every plate, so the width is the
            // same whether the plate is inked or not
            width: lab.implicitWidth + Tokens.s3 * 2
            height: 34
            radius: Tokens.radius
            color: !Tokens.selectFill ? "transparent"
                : (on ? Tokens.bone : (tap.pressed ? Tokens.tint16 : (th.hovered ? Tokens.tint5 : "transparent")))
            border.width: Tokens.selectFill ? Tokens.border : 0
            border.color: on ? Tokens.bone : Tokens.line
            Behavior on color { ColorAnimation { duration: Tokens.snap } }

            Row {
                id: lab
                anchors.centerIn: parent
                spacing: Tokens.s2
                Text {
                    id: lead
                    text: "//"
                    visible: Tokens.selectFill
                    opacity: plate.on ? 1 : 0
                    color: Tokens.inkOnBoneDim
                    font.family: Tokens.mono
                    font.pixelSize: 10
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on opacity { NumberAnimation { duration: Tokens.snap } }
                }
                Text {
                    // translate the display, emit the original value on tap so the
                    // tab key still matches for filtering/selection.
                    text: I18n.tr(plate.modelData).toUpperCase()
                    color: plate.on ? (Tokens.selectFill ? Tokens.inkOnBone : Tokens.mark)
                        : (th.hovered && Tokens.accentMarks ? Tokens.hoverInk : Tokens.inkDim)
                    font.family: Tokens.navCaps ? Tokens.navFont : Tokens.ui
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    font.letterSpacing: Tokens.navCaps ? Tokens.trackNav : Tokens.trackLabel
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: Tokens.snap } }
                }
            }
            // the live tab's underline, for a theme without the selection fill
            Rectangle {
                visible: plate.on && !Tokens.selectFill
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: lab.implicitWidth
                height: 2
                radius: 1
                color: Tokens.mark
            }
            HoverHandler { id: th; cursorShape: Qt.PointingHandCursor }
            TapHandler { id: tap; onTapped: tabs.chose(plate.modelData) }
        }
    }
}
