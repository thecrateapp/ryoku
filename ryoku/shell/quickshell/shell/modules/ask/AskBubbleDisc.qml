pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Ryoku.Ui.Singletons
import shell.services

// The pinned bubble's face: Rashin's orb on a disc, with a dot while an answer
// waits unread. Stock draws a bone disc over a soft shadow. Under controls
// "crate" the disc is the one glass with a hairline and no shadow under it, the
// orb takes ink and the unread dot the mark.
Item {
    id: root

    required property real s
    property bool shown: false
    property bool busy: false
    property string activity: ""
    property bool unread: false
    readonly property bool crate: Tokens.controlsCrate

    RectangularShadow {
        objectName: "askBubbleShadow"
        anchors.fill: disc
        visible: !root.crate
        radius: disc.radius
        blur: Tokens.s3 * root.s
        spread: Tokens.border
        color: Qt.alpha(Tokens.paper, 0.52)
    }

    Rectangle {
        id: disc
        objectName: "askBubbleDisc"
        anchors.fill: parent
        radius: width / 2
        color: root.crate ? Tokens.glass : Tokens.bone
        border.width: Tokens.border
        border.color: Tokens.line
    }

    AskOrb {
        objectName: "askBubbleOrb"
        anchors.centerIn: parent
        s: root.s
        orbSize: root.width - Tokens.s3 * root.s
        active: root.shown
        mode: "chat"
        chatBusy: root.busy
        chatActivity: root.activity
        preset: "avatar"
        ink: root.crate ? Tokens.ink : Tokens.inkOnBone
    }

    Rectangle {
        objectName: "askBubbleUnread"
        anchors.right: parent.right
        anchors.top: parent.top
        width: 8 * root.s
        height: width
        radius: width / 2
        visible: root.unread
        color: root.crate ? Tokens.mark : Tokens.ink
    }
}
