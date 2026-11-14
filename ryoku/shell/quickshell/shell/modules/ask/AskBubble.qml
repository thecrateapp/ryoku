pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Ryoku.Ui.Singletons
import shell.services

Scope {
    id: root

    required property var screen
    property bool enabled: Config.askBubble.enabled
    property bool suppressed: false
    property bool cardOpen: false
    property bool unread: false

    readonly property real s: Tokens.uiScaleFor(screen ? screen.name : "")
    readonly property real screenWidth: screen && screen.width > 0 ? screen.width : 1280
    readonly property real screenHeight: screen && screen.height > 0 ? screen.height : 800
    readonly property real bubbleSize: 56 * s
    readonly property bool configuredScreen: Config.askBubble.screen.length > 0
        ? Config.askBubble.screen === String(screen ? screen.name : "")
        : Quickshell.screens.length > 0 && Quickshell.screens[0] === screen
    readonly property bool shown: enabled && configuredScreen && !suppressed
    readonly property bool motionAllowed: shown && !Tokens.reduceMotion && !Motion.reduce
    onSuppressedChanged: if (suppressed) cardOpen = false

    function restorePosition() {
        const maxX = Math.max(0, root.screenWidth - root.bubbleSize);
        const maxY = Math.max(0, root.screenHeight - root.bubbleSize);
        bubble.x = Math.round(maxX * Config.askBubble.x);
        bubble.y = Math.round(maxY * Config.askBubble.y);
    }

    property bool persisting: false

    // Each patch echoes back through Config before the next one is sent, so the
    // ratios are captured up front and the echo is ignored until all are written.
    function persistPosition() {
        const maxX = Math.max(1, root.screenWidth - root.bubbleSize);
        const maxY = Math.max(1, root.screenHeight - root.bubbleSize);
        const fx = Math.max(0, Math.min(1, bubble.x / maxX));
        const fy = Math.max(0, Math.min(1, bubble.y / maxY));
        root.persisting = true;
        Config.patchAskBubble("x", fx);
        Config.patchAskBubble("y", fy);
        Config.patchAskBubble("screen", String(screen ? screen.name : ""));
        root.persisting = false;
    }

    function finishDrag() {
        const centerX = bubble.x + bubble.width / 2;
        const centerY = bubble.y + bubble.height / 2;
        if (centerX >= dismissTarget.x && centerX <= dismissTarget.x + dismissTarget.width
                && centerY >= dismissTarget.y && centerY <= dismissTarget.y + dismissTarget.height) {
            cardOpen = false;
            Config.patchAskBubble("enabled", false);
            return;
        }
        const right = bubble.x + bubble.width / 2 >= root.screenWidth / 2;
        bubble.x = right ? root.screenWidth - bubble.width - Tokens.s3 * root.s : Tokens.s3 * root.s;
        bubble.y = Math.max(Tokens.s3 * root.s,
            Math.min(root.screenHeight - bubble.height - Tokens.s3 * root.s, bubble.y));
        persistPosition();
    }

    Component.onCompleted: restorePosition()
    onScreenChanged: Qt.callLater(restorePosition)

    Connections {
        target: Config
        function onAskBubbleChanged() {
            if (!drag.active && !root.persisting)
                root.restorePosition();
        }
    }

    Connections {
        target: Needle
        function onTouched() {
            if (root.cardOpen || Needle.convo.count === 0)
                return;
            const last = Needle.convo.get(Needle.convo.count - 1);
            if (last && last.kind !== "tool" && last.role !== "user" && String(last.body || "").length > 0)
                root.unread = true;
        }
    }

    PanelWindow {
        id: win
        screen: root.screen
        visible: root.shown
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0
        anchors { top: true; bottom: true; left: true; right: true }
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "ryoku-ask-bubble"
        WlrLayershell.keyboardFocus: root.cardOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        // The input region follows the bubble; while a drag is in flight it covers
        // the whole window, or the pointer leaves the region mid-drag and the
        // compositor cancels the grab before the bubble has moved.
        mask: Region {
            x: drag.active ? 0 : bubble.x
            y: drag.active ? 0 : bubble.y
            width: drag.active ? win.width : bubble.width
            height: drag.active ? win.height : bubble.height
            Region { item: root.cardOpen ? chatCard : null; intersection: Intersection.Combine }
        }

        FocusScope {
            anchors.fill: parent
            focus: root.cardOpen
            Keys.onEscapePressed: root.cardOpen = false

            AskDismissTarget {
                id: dismissTarget
                x: (parent.width - width) / 2
                y: parent.height - height - Tokens.s5 * root.s
                s: root.s
                armed: drag.active
                motionAllowed: root.motionAllowed
                overDismiss: drag.active
                    && bubble.x + bubble.width / 2 >= x
                    && bubble.x + bubble.width / 2 <= x + width
                    && bubble.y + bubble.height / 2 >= y
                    && bubble.y + bubble.height / 2 <= y + height
            }

            Item {
                id: bubble
                width: root.bubbleSize
                height: root.bubbleSize
                z: 3
                scale: bubbleTap.pressed && root.motionAllowed ? 0.92
                    : bubbleHover.hovered && root.motionAllowed ? 1.06 : 1

                Behavior on x {
                    enabled: root.motionAllowed && !drag.active
                    NumberAnimation { duration: Motion.spatial; easing.type: Easing.OutBack }
                }
                Behavior on y {
                    enabled: root.motionAllowed && !drag.active
                    NumberAnimation { duration: Tokens.swap; easing.type: Easing.OutBack }
                }
                Behavior on scale {
                    enabled: root.motionAllowed
                    NumberAnimation { duration: Tokens.snap; easing.type: Tokens.easeSnap }
                }

                AskBubbleDisc {
                    anchors.fill: parent
                    s: root.s
                    shown: root.shown
                    busy: !root.cardOpen && Needle.busy
                    activity: Needle.activity
                    unread: root.unread
                }

                HoverHandler { id: bubbleHover; cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor }
                TapHandler {
                    id: bubbleTap
                    onTapped: {
                        root.cardOpen = !root.cardOpen;
                        if (root.cardOpen)
                            root.unread = false;
                    }
                }
                DragHandler {
                    id: drag
                    target: bubble
                    xAxis.minimum: 0
                    xAxis.maximum: Math.max(0, win.width - bubble.width)
                    yAxis.minimum: 0
                    yAxis.maximum: Math.max(0, win.height - bubble.height)
                    onActiveChanged: {
                        if (active) root.cardOpen = false;
                        else root.finishDrag();
                    }
                }
            }

            AskBubbleCard {
                id: chatCard
                s: root.s
                visible: root.shown && root.cardOpen
                x: bubble.x < win.width / 2
                    ? Math.min(win.width - width - Tokens.s3 * root.s, bubble.x + bubble.width + Tokens.s3 * root.s)
                    : Math.max(Tokens.s3 * root.s, bubble.x - width - Tokens.s3 * root.s)
                y: Math.max(Tokens.s3 * root.s,
                    Math.min(win.height - height - Tokens.s3 * root.s, bubble.y - height / 2 + bubble.height / 2))
                width: Math.min(420 * root.s, win.width - Tokens.s5 * root.s * 2)
                height: Math.min(chat.implicitHeight + Tokens.s4 * root.s * 2, win.height * 0.46)
                z: 2
                opacity: root.cardOpen ? 1 : 0
                scale: root.cardOpen ? 1 : 0.96
                transformOrigin: bubble.x < win.width / 2 ? Item.Left : Item.Right
                Behavior on opacity { enabled: root.motionAllowed; NumberAnimation { duration: Tokens.swap } }
                Behavior on scale { enabled: root.motionAllowed; NumberAnimation { duration: Motion.spatial; easing.type: Easing.OutBack } }

                AskChat {
                    id: chat
                    anchors.fill: parent
                    anchors.margins: Tokens.s4 * root.s
                    s: root.s
                    active: root.shown && root.cardOpen
                    maximumHeight: win.height * 0.46 - Tokens.s4 * root.s * 2
                }
            }
        }
    }
}
