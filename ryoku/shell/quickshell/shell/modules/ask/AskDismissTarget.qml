pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.Ui
import Ryoku.Ui.Singletons
import shell.services

// Where a dragged bubble goes to be removed. It shows only while the bubble is
// being dragged (`armed`) and lights when the bubble is over it. Stock is a
// pill that fills with bone; under controls "crate" it is the glass at the
// shared corner, edged and inked in alert when the bubble is over it.
Rectangle {
    id: root

    required property real s
    property bool armed: false
    property bool overDismiss: false
    property bool motionAllowed: true
    readonly property bool crate: Tokens.controlsCrate

    width: 132 * s
    height: 54 * s
    radius: crate ? Tokens.radius * s : height / 2
    color: crate ? Tokens.glass : overDismiss ? Tokens.bone : Tokens.paperLift
    border.width: Tokens.border
    border.color: crate ? (overDismiss ? Tokens.alert : Tokens.line)
        : overDismiss ? Tokens.bone : Tokens.lineStrong
    opacity: armed ? 1 : 0
    scale: armed ? 1 : 0.86
    Behavior on opacity { enabled: root.motionAllowed; NumberAnimation { duration: Tokens.move } }
    Behavior on scale { enabled: root.motionAllowed; NumberAnimation { duration: Tokens.swap; easing.type: Easing.OutBack } }

    Row {
        anchors.centerIn: parent
        spacing: Tokens.s2 * root.s
        Text {
            visible: !root.crate
            text: "delete"
            color: root.overDismiss ? Tokens.inkOnBone : Tokens.inkMuted
            font.family: "Material Symbols Rounded"
            font.pixelSize: Tokens.fBody * root.s
        }
        Text {
            visible: !root.crate
            text: I18n.tr("Remove")
            color: root.overDismiss ? Tokens.inkOnBone : Tokens.inkDim
            font.family: Tokens.ui
            font.pixelSize: Tokens.fSmall * root.s
        }
        Glyph {
            objectName: "askDismissGlyph"
            visible: root.crate
            anchors.verticalCenter: parent.verticalCenter
            name: "delete"
            size: 18
            color: root.overDismiss ? Tokens.alert : Tokens.inkSecondary
        }
        TrackLabel {
            visible: root.crate
            anchors.verticalCenter: parent.verticalCenter
            text: I18n.tr("Remove")
            tone: root.overDismiss ? "active" : "subtle"
            color: root.overDismiss ? Tokens.alert : toneInk
        }
    }
}
