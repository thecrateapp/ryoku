pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import Quickshell
import shell.services
import Ryoku.Ui.Singletons as Ui
import Ryoku.Ui as Kit
import "../../components"

// One notification card, shared by the history panel and the popup surface
// (contract 07 sec 2.3). A bordered surface tile with a header (app name, time,
// and an open/expand/close cluster), a bold summary, an optional body, and one
// primary button per action. The reference text-only look remains the default;
// the opt-in image setting adds a token-sized thumbnail row when an image,
// application icon, or fallback glyph resolves.
//
// Popups pass `compact: true`: the body clamps to two lines and the actions
// hide, so the toast stays a tidy glance; the expand chevron reveals the full
// body and its action buttons. The open button surfaces the freedesktop
// "default" action, which is otherwise unreachable from a toast. The history
// panel leaves `compact` false, so it is unchanged bar the open button appearing
// when an app sent a default action.
Rectangle {
    id: card

    required property var notif
    // The delegate outlives its model entry: a dismissed toast animates out while
    // the service has already dropped it, so every read goes through this instead
    // of dereferencing a null. It is a function, not a property: a property binds
    // once, and the object dying emits no change, so the cached reference stayed
    // dead and every read off it threw.
    function n() { return card.notif || ({}) }
    // Fired after an action runs; the panel closes the menu on it, the popup
    // ignores it (contract 07 sec 4.3).
    signal actionInvoked()

    // Popups start compact and expand on demand; the history panel is always
    // full (compact stays false).
    property bool compact: false
    property bool expanded: false
    property bool unifiedFrame: false

    // Per-monitor UI scale, threaded from the popup surface (default 1 = no-op,
    // so the history panel that composes this card unchanged stays identical).
    property real us: 1
    // Only explicit expand/collapse clicks ease the frame height. Image loads
    // and every other layout change snap to their measured height so the popup
    // surface never trails content that has already moved.
    readonly property real targetImplicitHeight: body.implicitHeight
        + (Ui.Tokens.controlsCrate ? 28 : Theme.paddingMd * 2) * card.us
    property real animatedImplicitHeight: 0
    property bool userHeightChange: false
    Component.onCompleted: card.animatedImplicitHeight = card.targetImplicitHeight
    function toggleExpanded() {
        card.userHeightChange = true;
        card.expanded = !card.expanded;
        heightAnimationStart.restart();
    }
    function animateUserHeightChange() {
        heightAnimation.stop();
        const targetHeight = card.targetImplicitHeight;
        heightAnimation.from = card.animatedImplicitHeight;
        heightAnimation.to = targetHeight;
        heightAnimation.start();
        card.userHeightChange = false;
    }
    onTargetImplicitHeightChanged: {
        if (card.userHeightChange) {
            heightAnimationStart.restart();
            return;
        }
        heightAnimation.stop();
        card.animatedImplicitHeight = card.targetImplicitHeight;
    }
    Timer {
        id: heightAnimationStart
        interval: 16
        onTriggered: card.animateUserHeightChange()
    }
    NumberAnimation {
        id: heightAnimation
        target: card
        property: "animatedImplicitHeight"
        duration: Motion.rowReveal
        easing.type: Motion.rowRevealCurve
    }

    // Only real actions get a button: the freedesktop "default" action (surfaced
    // as the open button, not a row button) and any action with no label are
    // dropped, so a bare default no longer draws an empty pill.
    readonly property var visibleActions: {
        const all = card.n().actions || [];
        const out = [];
        for (let i = 0; i < all.length; i++)
            if (all[i] && all[i].identifier !== "default" && (all[i].text || "").length > 0)
                out.push(all[i]);
        return out;
    }

    // The freedesktop default action ("click the notification to open"): surfaced
    // as the open button instead of a click target. null when the app sent none.
    readonly property var defaultAction: {
        const all = card.n().actions || [];
        for (let i = 0; i < all.length; i++)
            if (all[i] && all[i].identifier === "default")
                return all[i];
        return null;
    }

    // Compact clamps the body to two lines; the chevron shows only when expand
    // actually reveals something (a longer body or any action). `bodyOverflows`
    // is measured off a hidden unclamped copy so it stays true once expanded.
    readonly property int compactLines: 2
    readonly property bool showFull: !card.compact || card.expanded
    readonly property bool bodyOverflows: bodyMeasure.lineCount > card.compactLines
    readonly property bool expandable: card.compact && (card.visibleActions.length > 0 || card.bodyOverflows)

    readonly property bool imagesEnabled: Config.notifications?.show_images === true
    function imageSource(value, themed) {
        let raw = String(value || "");
        if (raw.length === 0)
            return "";
        if (raw.indexOf("image://icon/") === 0) {
            raw = decodeURIComponent(raw.substring(13));
            themed = true;
        }
        if (raw.charAt(0) === "/" || raw.indexOf("file:") === 0)
            return raw.indexOf("file:") === 0 ? raw : "file://" + raw;
        if (raw.indexOf(":") > 0)
            return raw;
        return themed ? Icons.path(raw, true) : raw;
    }
    readonly property string notificationImageSource: card.imagesEnabled
        ? card.imageSource(card.n().image, false) : ""
    readonly property string appIconSource: card.imagesEnabled
        ? card.imageSource(card.n().appIcon, true) : ""
    readonly property bool hasNotificationImage: card.notificationImageSource.length > 0

    // Countdown frame (popups only): a border that traces the card and drains
    // over the popup's lifespan, so a glance shows how long is left. The history
    // panel and persistent popups pass 0 and draw no frame.
    property int lifespanMs: 0
    readonly property bool countingDown: card.lifespanMs > 0 && !card.unifiedFrame
    property real remaining: 1
    NumberAnimation on remaining {
        running: card.countingDown
        from: 1
        to: 0
        duration: Math.max(1, card.lifespanMs)
        easing.type: Easing.Linear
    }

    readonly property bool crate: Ui.Tokens.controlsCrate
    radius: card.unifiedFrame ? 0 : (card.crate ? Ui.Tokens.radius : Theme.radiusWidget) * card.us
    // a theme style keeps the frame a hairline; the countdown carries the accent
    // a critical card (no countdown) keeps the full accent frame
    readonly property bool critical: card.n().urgency === 2
    border.width: card.unifiedFrame ? 0 : (Ui.Tokens.styled && !card.critical ? 1 : Theme.borderWidth) * card.us
    border.color: Ui.Tokens.styled ? (card.critical ? Ui.Tokens.mark : Ui.Tokens.line) : Theme.outline
    color: card.unifiedFrame ? "transparent" : card.crate ? Ui.Tokens.glass : Theme.surface
    implicitHeight: card.animatedImplicitHeight

    // A hidden, unclamped copy of the body, used only to learn whether the real
    // body would overflow the compact clamp (so the chevron appears only when it
    // has something to show). Never painted.
    Text {
        id: bodyMeasure
        visible: false
        width: card.width - (card.crate ? 32 : Theme.paddingMd * 2) * card.us
        text: card.n().body || ""
        font.family: Theme.fontPrimary
        font.pixelSize: (card.crate ? 12 : Theme.fontSm) * card.us
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
    }

    // One header affordance: a hover-tinted square icon button. Open, expand and
    // close share it so the cluster reads as one control set.
    component HeaderButton: Rectangle {
        id: hb
        property string glyph: ""
        property color activeColor: Theme.onSurface
        property real iconRotation: 0
        signal clicked()

        // crate-mark: a plateless 24 px button with a 14 px Solar glyph
        width: (card.crate ? 24 : Theme.iconSm + Theme.paddingSm * 2) * card.us
        height: width
        radius: Theme.radiusWidget * card.us
        color: hbHov.hovered && !card.crate
            ? Qt.tint(Theme.surface, Qt.rgba(Theme.onSurface.r, Theme.onSurface.g, Theme.onSurface.b, 0.08))
            : "transparent"

        Kit.Glyph {
            visible: card.crate
            anchors.centerIn: parent
            name: hb.glyph
            size: 14 * card.us
            color: hbHov.hovered ? Ui.Tokens.mark : Ui.Tokens.inkSecondary
            rotation: hb.iconRotation
            Behavior on rotation { NumberAnimation { duration: Motion.chevronRotate; easing.type: Motion.easeType; easing.bezierCurve: Motion.easeCurve } }
        }

        MaterialIcon {
            visible: !card.crate
            anchors.centerIn: parent
            text: hb.glyph
            font.pixelSize: Theme.iconSm * card.us
            color: hbHov.hovered ? hb.activeColor : Theme.onSurfaceVariant
            rotation: hb.iconRotation
            Behavior on rotation { NumberAnimation { duration: Motion.chevronRotate; easing.type: Motion.easeType; easing.bezierCurve: Motion.easeCurve } }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: hb.clicked()
            HoverHandler { id: hbHov }
        }
    }

    Column {
        id: body
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.paddingMd * card.us
        // crate-mark: 14 px top, 16 px at the sides, 8 px between blocks
        anchors.leftMargin: (card.crate ? 16 : Theme.paddingMd) * card.us
        anchors.rightMargin: (card.crate ? 16 : Theme.paddingMd) * card.us
        anchors.topMargin: (card.crate ? 14 : Theme.paddingMd) * card.us
        spacing: Theme.paddingMd * card.us

        // Header: app name (fills), arrival time, and the open/expand/close cluster.
        Item {
            width: parent.width
            height: Math.max(appName.implicitHeight, timeLabel.implicitHeight, btnRow.height)

            Text {
                id: appName
                anchors.left: parent.left
                anchors.right: timeLabel.left
                anchors.rightMargin: Theme.paddingSm * card.us
                anchors.verticalCenter: parent.verticalCenter
                text: card.n().appName || ""
                // the app's name reads as a caption under the theme style
                color: Ui.Tokens.labelAccent ? Ui.Tokens.caption : Theme.onSurfaceVariant
                font.family: Ui.Tokens.navCaps ? Ui.Tokens.navFont : Theme.fontPrimary
                font.pixelSize: Theme.fontSm * card.us
                font.weight: Font.Medium
                font.capitalization: Ui.Tokens.navCaps ? Font.AllUppercase : Font.MixedCase
                font.letterSpacing: Ui.Tokens.navCaps ? Ui.Tokens.trackNav : 0
                elide: Text.ElideRight
            }

            Text {
                id: timeLabel
                anchors.right: btnRow.left
                anchors.rightMargin: Theme.paddingSm * card.us
                anchors.verticalCenter: parent.verticalCenter
                text: Notifs.timeLabel(card.notif)
                color: card.crate ? Ui.Tokens.inkMuted : Theme.onSurfaceVariant
                font.family: card.crate ? Ui.Tokens.mono : Theme.fontPrimary
                font.pixelSize: (card.crate ? 12 : Theme.fontSm) * card.us
                font.features: { "tnum": 1 }
            }

            Row {
                id: btnRow
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                // Open: invoke the freedesktop default action; shown only when the
                // app sent one.
                HeaderButton {
                    glyph: "open_in_new"
                    visible: card.defaultAction !== null
                    onClicked: {
                        if (card.defaultAction)
                            card.defaultAction.invoke();
                        card.actionInvoked();
                    }
                }

                // Expand: reveal the full body and the action buttons; the chevron
                // turns over as it opens.
                HeaderButton {
                    glyph: "expand_more"
                    visible: card.expandable
                    iconRotation: card.expanded ? 180 : 0
                    onClicked: card.toggleExpanded()
                }

                HeaderButton {
                    glyph: "close"
                    onClicked: Notifs.dismiss(card.notif)
                }
            }
        }

        Rectangle {
            id: thumbnail
            readonly property bool imageReady: notificationImage.status === Image.Ready
            readonly property bool iconReady: appIconImage.status === Image.Ready
            readonly property bool imageUnavailable: !card.hasNotificationImage
                || notificationImage.status === Image.Error
            readonly property bool iconUnavailable: card.appIconSource.length === 0
                || appIconImage.status === Image.Error
            readonly property bool useImage: card.hasNotificationImage && thumbnail.imageReady
            readonly property bool useIcon: thumbnail.imageUnavailable && thumbnail.iconReady
            readonly property bool useGlyph: thumbnail.imageUnavailable && thumbnail.iconUnavailable

            // one of the three always shows in the end, so hold its space while it loads
            visible: card.imagesEnabled
            width: (Theme.iconLg + Theme.paddingLg) * card.us
            height: width
            radius: Theme.radiusWidget * card.us
            color: "transparent"
            clip: true

            Image {
                id: notificationImage
                anchors.fill: parent
                source: card.notificationImageSource
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                smooth: true
                visible: thumbnail.useImage
            }

            Image {
                id: appIconImage
                anchors.fill: parent
                anchors.margins: Theme.paddingSm * card.us
                source: card.appIconSource
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: true
                visible: thumbnail.useIcon
            }

            // crate: the kit's Solar bell (danger-circle when critical), the
            // critical one in the mark like the card's frame
            Kit.Glyph {
                objectName: "notifFallbackGlyph"
                anchors.centerIn: parent
                visible: thumbnail.useGlyph && card.crate
                name: card.critical ? "danger-circle" : "bell"
                size: 24 * card.us
                color: card.critical ? Ui.Tokens.mark : Ui.Tokens.inkSecondary
            }

            MaterialIcon {
                objectName: "notifFallbackMaterial"
                anchors.centerIn: parent
                visible: thumbnail.useGlyph && !card.crate
                text: card.n().urgency === 2 ? "priority_high" : "notifications"
                font.pixelSize: Theme.iconLg * card.us
                color: Theme.onSurfaceVariant
            }
        }

        // Summary: bold, wraps.
        Text {
            width: parent.width
            text: card.n().summary || ""
            color: Theme.onSurface
            font.family: Theme.fontPrimary
            // crate-mark: a 13 px title over a 12 px muted body
            font.pixelSize: (card.crate ? 13 : Theme.fontMd) * card.us
            font.weight: card.crate ? Font.Medium : Font.Bold
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        }

        // Body: present when non-empty; clamped to two lines while a popup is
        // compact and collapsed, full once expanded (or in the history panel).
        Text {
            width: parent.width
            visible: (card.n().body || "").length > 0
            text: card.n().body || ""
            color: card.crate ? Ui.Tokens.inkMuted : Theme.onSurfaceVariant
            font.family: Theme.fontPrimary
            font.pixelSize: (card.crate ? 12 : Theme.fontSm) * card.us
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            maximumLineCount: card.showFull ? 9999 : card.compactLines
            elide: card.showFull ? Text.ElideNone : Text.ElideRight
        }

        // Actions: one primary button per action, full width (contract 07 sec
        // 2.3). Hidden while a popup is compact and collapsed; the expand
        // chevron brings them in with a short fade.
        // crate-mark: the kit's buttons at their natural width, 8 px apart; the
        // first action confirms (filled), the rest navigate (outlined)
        Flow {
            id: crateActions
            width: parent.width
            spacing: 8 * card.us
            visible: card.crate && card.visibleActions.length > 0 && card.showFull
            opacity: card.showFull ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Motion.rowFade; easing.type: Motion.easeType; easing.bezierCurve: Motion.easeCurve } }

            Repeater {
                model: card.crate ? card.visibleActions : []

                delegate: Kit.Btn {
                    required property var modelData
                    required property int index
                    text: modelData.text
                    primary: index === 0
                    outline: index !== 0
                    onAct: {
                        modelData.invoke();
                        card.actionInvoked();
                    }
                }
            }
        }

        Column {
            id: actionCol
            width: parent.width
            spacing: Theme.paddingSm * card.us
            visible: !card.crate && card.visibleActions.length > 0 && card.showFull
            opacity: card.showFull ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Motion.rowFade; easing.type: Motion.easeType; easing.bezierCurve: Motion.easeCurve } }

            Repeater {
                model: card.visibleActions

                delegate: Rectangle {
                    id: actionBtn
                    required property var modelData
                    required property int index
                    // D4 under a theme style: the first action confirms (filled), the
                    // rest navigate (outlined); the stock look fills every action
                    readonly property bool filled: !Ui.Tokens.styled || actionBtn.index === 0

                    // the column by id, not `parent`: a Repeater delegate has no
                    // parent while it is being created, so a notification that
                    // carries actions logged a TypeError for every button.
                    width: actionCol.width
                    height: actionLabel.implicitHeight + Theme.paddingSm * 2 * card.us
                    radius: Theme.radiusWidget * card.us
                    color: actionBtn.filled ? (Ui.Tokens.accentMarks ? (actionHov.hovered ? Ui.Tokens.hoverInk : Ui.Tokens.mark)
                                                 : (actionHov.hovered ? Theme.vermLit : Theme.primary))
                        : (actionHov.hovered ? Ui.Tokens.rowWash : "transparent")
                    border.width: actionBtn.filled ? 0 : 1
                    border.color: Ui.Tokens.mark

                    Behavior on color { ColorAnimation { duration: Motion.rowFade; easing.type: Motion.easeType; easing.bezierCurve: Motion.easeCurve } }

                    Text {
                        id: actionLabel
                        anchors.centerIn: parent
                        width: parent.width - Theme.paddingMd * 2 * card.us
                        horizontalAlignment: Text.AlignHCenter
                        text: actionBtn.modelData.text
                        color: actionBtn.filled ? (Ui.Tokens.accentMarks ? Ui.Tokens.paper : Theme.onPrimary) : Ui.Tokens.mark
                        font.family: Theme.fontPrimary
                        font.pixelSize: Theme.fontSm * card.us
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            actionBtn.modelData.invoke();
                            card.actionInvoked();
                        }
                        HoverHandler { id: actionHov }
                    }
                }
            }
        }
    }

    // The draining countdown, stroked over the card's own border: the accent
    // traces the whole rounded rect at full life and recedes clockwise from the
    // top as the lifespan runs out, uncovering the plain outline underneath.
    Shape {
        id: timerFrame
        anchors.fill: parent
        visible: card.countingDown
        asynchronous: true

        readonly property real sw: (Ui.Tokens.styled ? 1 : Theme.borderWidth) * card.us + 1
        readonly property real o: sw / 2
        readonly property real w: Math.max(0, width - sw)
        readonly property real h: Math.max(0, height - sw)
        readonly property real rad: Math.max(0, Math.min(card.radius, w / 2, h / 2))
        readonly property real perim: 2 * (w - 2 * rad) + 2 * (h - 2 * rad) + 2 * Math.PI * rad

        ShapePath {
            fillColor: "transparent"
            strokeColor: Theme.primary
            strokeWidth: timerFrame.sw
            strokeStyle: ShapePath.DashLine
            capStyle: ShapePath.FlatCap
            joinStyle: ShapePath.MiterJoin
            // one dash the length of the outline; sliding it along drains the frame
            dashPattern: [timerFrame.perim / timerFrame.sw, timerFrame.perim / timerFrame.sw + 1]
            dashOffset: (1 - card.remaining) * timerFrame.perim / timerFrame.sw

            startX: timerFrame.o + timerFrame.w / 2
            startY: timerFrame.o
            PathLine { x: timerFrame.o + timerFrame.w - timerFrame.rad; y: timerFrame.o }
            PathArc { x: timerFrame.o + timerFrame.w; y: timerFrame.o + timerFrame.rad; radiusX: timerFrame.rad; radiusY: timerFrame.rad }
            PathLine { x: timerFrame.o + timerFrame.w; y: timerFrame.o + timerFrame.h - timerFrame.rad }
            PathArc { x: timerFrame.o + timerFrame.w - timerFrame.rad; y: timerFrame.o + timerFrame.h; radiusX: timerFrame.rad; radiusY: timerFrame.rad }
            PathLine { x: timerFrame.o + timerFrame.rad; y: timerFrame.o + timerFrame.h }
            PathArc { x: timerFrame.o; y: timerFrame.o + timerFrame.h - timerFrame.rad; radiusX: timerFrame.rad; radiusY: timerFrame.rad }
            PathLine { x: timerFrame.o; y: timerFrame.o + timerFrame.rad }
            PathArc { x: timerFrame.o + timerFrame.rad; y: timerFrame.o; radiusX: timerFrame.rad; radiusY: timerFrame.rad }
            PathLine { x: timerFrame.o + timerFrame.w / 2; y: timerFrame.o }
        }
    }
}
