import QtQuick
import "Singletons"

// set membership -- not a choice. members toggle independently, so a member
// carries its own in/out mark rather than borrowing the exclusive grammar.
Flow {
    id: multi
    property var options: []
    property var chosen: []
    signal toggled(string key)

    spacing: Tokens.controlsCrate ? 8 : 5

    Repeater {
        model: multi.options
        Rectangle {
            required property string modelData
            readonly property bool on: multi.chosen.indexOf(modelData) >= 0
            width: row.width + (Tokens.controlsCrate ? 28 : 20)
            height: Tokens.controlsCrate ? 32 : 24
            radius: Tokens.radius
            color: on ? (Tokens.controlsCrate ? Tokens.mark : Tokens.bone) : Tokens.controlsCrate ? "transparent" : (tap.pressed ? Tokens.tint16 : (mh.hovered ? Tokens.tint10 : "transparent"))
            border.width: Tokens.border
            border.color: on && Tokens.controlsCrate ? Tokens.mark : mh.hovered && !on ? (Tokens.controlsCrate || Tokens.accentMarks ? Tokens.markHover : Tokens.lineStrong) : Tokens.line
            Behavior on color { ColorAnimation { duration: Tokens.snap } }
            Row {
                id: row
                anchors.centerIn: parent
                spacing: 5
                Text {
                    text: parent.parent.on ? "✓" : "+"
                    color: parent.parent.on ? (Tokens.controlsCrate ? Tokens.paper : Tokens.inkOnBone) : Tokens.inkFaint
                    font.family: Tokens.controlsCrate ? Tokens.mono : Tokens.ui
                    font.pixelSize: Tokens.controlsCrate ? 11 : 9
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: I18n.tr(parent.parent.modelData)
                    color: parent.parent.on ? (Tokens.controlsCrate ? Tokens.paper : Tokens.inkOnBone) : Tokens.controlsCrate ? (mh.hovered ? Tokens.ink : Tokens.inkSecondary) : (mh.hovered && Tokens.accentMarks ? Tokens.hoverInk : Tokens.inkDim)
                    font.family: Tokens.controlsCrate ? Tokens.mono : Tokens.ui
                    font.pixelSize: Tokens.controlsCrate ? 12 : 10
                    font.weight: Tokens.controlsCrate ? Font.Normal : Font.Medium
                }
            }
            HoverHandler { id: mh; cursorShape: Qt.PointingHandCursor }
            TapHandler { id: tap; onTapped: multi.toggled(parent.modelData) }
        }
    }
}
