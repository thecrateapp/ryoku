pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Ryoku.Ui
import Ryoku.Ui.Singletons
import shell.services

Item {
    id: root

    required property real s
    property bool active: false
    property real maximumHeight: 520 * s
    property bool modelMenuOpen: false
    property string draft: ""
    property bool showComposer: true
    property bool agentSurfaceReported: false
    readonly property bool motionAllowed: active && !Tokens.reduceMotion && !Motion.reduce
    // Under controls "crate" the chat draws from the kit on the glass: hairline
    // cards with no fills, tracked captions, kit buttons and pick rows, Solar
    // glyphs, and a Beam wherever work is in flight.
    readonly property bool crate: Tokens.controlsCrate

    signal inputFocusRequested()

    implicitHeight: Math.min(maximumHeight, 430 * s)

    function scrollEnd() {
        Qt.callLater(() => transcript.positionViewAtEnd());
    }

    function shortModel(value) {
        const text = String(value || "");
        const slash = Math.max(text.lastIndexOf("/"), text.lastIndexOf(":"));
        return slash >= 0 ? text.slice(slash + 1) : text;
    }

    function permissionOptions(permission) {
        if (!permission || !permission.options)
            return [{ id: "", name: I18n.tr("Decline"), kind: "reject_once" }];
        const options = permission.options.filter(option => String(option.kind || "") !== "reject_always");
        const hasReject = options.some(option => String(option.kind || "").indexOf("reject") >= 0);
        return hasReject ? options : options.concat([{ id: "", name: I18n.tr("Decline"), kind: "reject_once" }]);
    }

    function startNewChat() {
        Needle.newChat();
        draft = "";
        if (showComposer) composer.forceActiveFocus();
        else inputFocusRequested();
    }

    function send() {
        const text = draft.trim();
        if (text.length === 0 || Needle.busy)
            return;
        Needle.send(text);
        draft = "";
    }

    onActiveChanged: {
        if (active) {
            if (!agentSurfaceReported) {
                Needle.agentSurfaceOpened();
                agentSurfaceReported = true;
            }
            Needle.noteOpened();
            root.scrollEnd();
            if (showComposer)
                Qt.callLater(() => composer.forceActiveFocus());
        } else {
            if (agentSurfaceReported) {
                Needle.agentSurfaceClosed();
                agentSurfaceReported = false;
            }
            Needle.noteClosed();
            modelMenuOpen = false;
        }
    }

    Component.onDestruction: {
        if (agentSurfaceReported)
            Needle.agentSurfaceClosed();
    }

    Connections {
        target: Needle
        enabled: root.active
        function onTouched() { root.scrollEnd(); }
    }

    Column {
        anchors.fill: parent
        spacing: Tokens.s2 * root.s

        Item {
            width: parent.width
            height: 34 * root.s

            Rectangle {
                id: modelChip
                anchors.left: parent.left
                anchors.right: actionButtons.left
                anchors.rightMargin: Tokens.s2 * root.s
                anchors.verticalCenter: parent.verticalCenter
                height: 30 * root.s
                objectName: "askChatModel"
                radius: Tokens.radius * root.s
                color: root.crate ? "transparent"
                    : modelTap.pressed ? Tokens.tint16 : modelHover.hovered ? Tokens.tint10 : Tokens.tint5
                border.width: Tokens.border
                border.color: root.crate ? (root.modelMenuOpen ? Tokens.pickEdge : modelHover.hovered ? Tokens.markHover : Tokens.line)
                    : root.modelMenuOpen ? Tokens.bone : Tokens.lineStrong
                Behavior on border.color { enabled: root.crate; ColorAnimation { duration: 150 } }
                scale: root.crate ? 1
                    : modelTap.pressed && root.motionAllowed ? 0.94
                    : modelHover.hovered && root.motionAllowed ? 1.025 : 1
                Behavior on scale {
                    enabled: root.motionAllowed
                    NumberAnimation { duration: Tokens.snap; easing.type: Tokens.easeSnap }
                }
                Glyph {
                    visible: root.crate
                    anchors.left: parent.left
                    anchors.leftMargin: Tokens.s3 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    name: "cognition"
                    size: 16
                    color: Tokens.inkSecondary
                }
                Glyph {
                    visible: root.crate
                    anchors.right: parent.right
                    anchors.rightMargin: Tokens.s2 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    name: "expand_more"
                    size: 16
                    color: root.modelMenuOpen ? Tokens.mark : Tokens.inkSecondary
                    rotation: root.modelMenuOpen ? 180 : 0
                    Behavior on rotation { enabled: root.motionAllowed; NumberAnimation { duration: Tokens.move; easing.type: Tokens.ease } }
                }
                Text {
                    visible: !root.crate
                    anchors.left: parent.left
                    anchors.leftMargin: Tokens.s3 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    text: "cognition"
                    color: Tokens.inkDim
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: Tokens.fBody * root.s
                }
                Text {
                    id: modelLabel
                    anchors.centerIn: parent
                    width: parent.width - 54 * root.s
                    text: Needle.currentModel.length > 0 ? root.shortModel(Needle.currentModel) : I18n.tr("Choose model")
                    color: Tokens.ink
                    font.family: root.crate ? Tokens.mono : Tokens.ui
                    font.pixelSize: root.crate ? Tokens.fSmall : Tokens.fSmall * root.s
                    elide: Text.ElideMiddle
                    horizontalAlignment: Text.AlignHCenter
                }
                Text {
                    visible: !root.crate
                    anchors.right: parent.right
                    anchors.rightMargin: Tokens.s2 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    text: "expand_more"
                    rotation: root.modelMenuOpen ? 180 : 0
                    color: Tokens.inkMuted
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: Tokens.fBody * root.s
                    Behavior on rotation { enabled: root.motionAllowed; NumberAnimation { duration: Tokens.move; easing.type: Tokens.ease } }
                }
                HoverHandler { id: modelHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { id: modelTap; onTapped: root.modelMenuOpen = !root.modelMenuOpen }
            }

            Row {
                id: actionButtons
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: Tokens.s1 * root.s

                Btn {
                    objectName: "askChatTerminal"
                    visible: root.crate
                    compact: true
                    text: I18n.tr("Open in terminal")
                    onAct: Needle.openInTerminal()
                }

                Btn {
                    objectName: "askChatNew"
                    visible: root.crate
                    compact: true
                    text: I18n.tr("New chat")
                    onAct: root.startNewChat()
                }

                Rectangle {
                    visible: !root.crate
                    width: terminalText.implicitWidth + Tokens.s4 * root.s
                    height: 30 * root.s
                    radius: Tokens.radius * root.s
                    color: terminalTap.pressed ? Tokens.tint16
                        : terminalHover.hovered ? Tokens.tint10 : Tokens.tint5
                    border.width: Tokens.border
                    border.color: Tokens.lineStrong
                    scale: terminalTap.pressed && root.motionAllowed ? 0.94
                        : terminalHover.hovered && root.motionAllowed ? 1.025 : 1
                    Behavior on scale {
                        enabled: root.motionAllowed
                        NumberAnimation { duration: Tokens.snap; easing.type: Tokens.easeSnap }
                    }
                    Text {
                        id: terminalText
                        anchors.centerIn: parent
                        text: I18n.tr("Open in terminal")
                        color: Tokens.inkDim
                        font.family: Tokens.ui
                        font.pixelSize: Tokens.fSmall * root.s
                    }
                    HoverHandler { id: terminalHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { id: terminalTap; onTapped: Needle.openInTerminal() }
                }

                Rectangle {
                    visible: !root.crate
                    width: newChatText.implicitWidth + Tokens.s4 * root.s
                    height: 30 * root.s
                    radius: Tokens.radius * root.s
                    color: newTap.pressed ? Tokens.tint16 : newHover.hovered ? Tokens.tint10 : Tokens.tint5
                    border.width: Tokens.border
                    border.color: Tokens.lineStrong
                    scale: newTap.pressed && root.motionAllowed ? 0.94
                        : newHover.hovered && root.motionAllowed ? 1.025 : 1
                    Behavior on scale {
                        enabled: root.motionAllowed
                        NumberAnimation { duration: Tokens.snap; easing.type: Tokens.easeSnap }
                    }
                    Text {
                        id: newChatText
                        anchors.centerIn: parent
                        text: I18n.tr("New chat")
                        color: Tokens.inkDim
                        font.family: Tokens.ui
                        font.pixelSize: Tokens.fSmall * root.s
                    }
                    HoverHandler { id: newHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        id: newTap
                        onTapped: root.startNewChat()
                    }
                }
            }
        }

        Text {
            width: parent.width
            visible: Needle.pickUnavailable
            text: I18n.tr("Saved model unavailable in this session")
            color: Tokens.inkMuted
            font.family: Tokens.ui
            font.pixelSize: Tokens.fTiny * root.s
            wrapMode: Text.WordWrap
        }

        Rectangle {
            id: modelMenu
            readonly property real naturalHeight: Math.min(modelList.contentHeight + Tokens.s2 * root.s, 180 * root.s)
            width: parent.width
            visible: opacity > 0.001
            height: root.modelMenuOpen ? naturalHeight : 0
            opacity: root.modelMenuOpen ? 1 : 0
            scale: root.modelMenuOpen ? 1 : 0.98
            transformOrigin: Item.Top
            radius: Tokens.radius * root.s
            color: root.crate ? Tokens.popover : Tokens.paperLift
            border.width: Tokens.border
            border.color: root.crate ? Tokens.line : Tokens.lineStrong
            clip: true
            Behavior on height {
                enabled: root.motionAllowed
                NumberAnimation { duration: Tokens.swap; easing.type: Tokens.ease }
            }
            Behavior on opacity {
                enabled: root.motionAllowed
                NumberAnimation { duration: Tokens.swap; easing.type: Tokens.ease }
            }
            Behavior on scale {
                enabled: root.motionAllowed
                NumberAnimation { duration: Tokens.swap; easing.type: Tokens.ease }
            }
            ListView {
                id: modelList
                anchors.fill: parent
                anchors.margins: Tokens.s1 * root.s
                model: Needle.models
                spacing: Tokens.s1 * root.s
                boundsBehavior: Flickable.StopAtBounds
                delegate: Rectangle {
                    id: modelRow
                    required property var modelData
                    width: ListView.view ? ListView.view.width : 0
                    height: root.crate ? modelPick.implicitHeight : 32 * root.s
                    radius: Tokens.radius * root.s
                    readonly property bool current: String(modelData.id || "")
                        === String(Needle.pick || Needle.currentModel)
                    color: root.crate ? "transparent"
                        : modelRowTap.pressed ? Tokens.tint16
                        : current ? Tokens.bone
                        : modelRowHover.hovered ? Tokens.tint10 : "transparent"
                    scale: root.crate ? 1
                        : modelRowTap.pressed && root.motionAllowed ? 0.96
                        : modelRowHover.hovered && root.motionAllowed ? 1.015 : 1
                    PickRow {
                        id: modelPick
                        objectName: "askChatModelRow"
                        visible: root.crate
                        anchors.left: parent.left
                        anchors.right: parent.right
                        title: modelRow.modelData.name || root.shortModel(modelRow.modelData.id)
                        picked: modelRow.current
                        onClicked: {
                            Needle.setModel(modelRow.modelData.id);
                            root.modelMenuOpen = false;
                        }
                    }
                    Behavior on scale {
                        enabled: root.motionAllowed
                        NumberAnimation { duration: Tokens.snap; easing.type: Tokens.easeSnap }
                    }
                    Text {
                        visible: !root.crate
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: Tokens.s3 * root.s
                        anchors.rightMargin: Tokens.s3 * root.s
                        anchors.verticalCenter: parent.verticalCenter
                        text: (modelRow.current ? "✓  " : "")
                            + (modelRow.modelData.name || root.shortModel(modelRow.modelData.id))
                        color: modelRow.current ? Tokens.inkOnBone : Tokens.ink
                        font.family: Tokens.ui
                        font.pixelSize: Tokens.fSmall * root.s
                        elide: Text.ElideMiddle
                    }
                    HoverHandler { id: modelRowHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        id: modelRowTap
                        enabled: !root.crate
                        onTapped: {
                            Needle.setModel(modelRow.modelData.id);
                            root.modelMenuOpen = false;
                        }
                    }
                }
            }
        }

        ListView {
            id: transcript
            width: parent.width
            height: Math.max(120 * root.s, parent.height - y - composerFrame.height - working.height - parent.spacing * 2)
            clip: true
            spacing: Tokens.s3 * root.s
            model: Needle.convo
            boundsBehavior: Flickable.StopAtBounds
            cacheBuffer: 3200
            onCountChanged: root.scrollEnd()
            onContentHeightChanged: if (Needle.busy || atYEnd) root.scrollEnd()
            ScrollBar.vertical: ScrollRail { policy: ScrollBar.AsNeeded; visible: transcript.contentHeight > transcript.height + 1; motionEnabled: root.motionAllowed }

            delegate: Item {
                id: row
                required property int index
                required property string kind
                required property string role
                required property string body
                required property string thought
                required property bool open
                required property bool live
                required property bool cont
                required property bool failed
                required property string imagesJson
                required property string toolId
                required property string title
                required property string tkind
                required property string status
                required property string input
                required property string output
                required property string diffsJson
                required property bool auto
                required property string permJson
                required property string askId
                required property string question
                required property string answer
                property bool outputOpen: false
                property real revealProgress: 1

                readonly property bool isTool: kind === "tool"
                readonly property bool isHandoff: kind === "handoff"
                readonly property bool isUser: role === "user"
                readonly property var permission: {
                    if (!permJson) return null;
                    try { return JSON.parse(permJson); } catch (error) { return null; }
                }
                readonly property var images: {
                    try { return JSON.parse(imagesJson) || []; }
                    catch (error) { return []; }
                }
                width: ListView.view ? ListView.view.width : 0
                implicitHeight: rowBody.implicitHeight
                opacity: revealProgress
                transform: Translate {
                    x: (1 - row.revealProgress) * (row.isUser ? Tokens.s2 * root.s : -Tokens.s2 * root.s)
                }
                Component.onCompleted: {
                    if (root.motionAllowed) {
                        revealProgress = 0;
                        entrance.restart();
                    }
                }
                NumberAnimation {
                    id: entrance
                    target: row
                    property: "revealProgress"
                    from: 0
                    to: 1
                    duration: Tokens.swap
                    easing.type: Tokens.ease
                }

                Column {
                    id: rowBody
                    width: parent.width
                    spacing: Tokens.s2 * root.s

                    AskHandoffCard {
                        width: parent.width
                        visible: row.isHandoff
                        s: root.s
                        askId: row.askId
                        question: row.question
                        answer: row.answer
                    }

                    Row {
                        visible: !row.isTool && !row.isHandoff && (!row.cont || row.live)
                        anchors.right: row.isUser ? parent.right : undefined
                        spacing: Tokens.s1 * root.s
                        Rectangle {
                            id: liveDot
                            anchors.verticalCenter: parent.verticalCenter
                            visible: row.live
                            width: 6 * root.s
                            height: width
                            radius: width / 2
                            color: root.crate ? Tokens.mark : Tokens.inkDim
                            SequentialAnimation on opacity {
                                running: root.motionAllowed && row.live
                                loops: Animation.Infinite
                                NumberAnimation { from: 1; to: 0.45; duration: Tokens.dur(420); easing.type: Easing.InOutSine }
                                NumberAnimation { from: 0.45; to: 1; duration: Tokens.dur(420); easing.type: Easing.InOutSine }
                                onStopped: liveDot.opacity = 1
                            }
                        }
                        TrackLabel {
                            visible: root.crate
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.isUser ? I18n.tr("YOU") : I18n.tr("RASHIN")
                            tone: row.isUser ? "subtle" : "accent"
                        }
                        Text {
                            visible: !root.crate
                            text: row.isUser ? I18n.tr("YOU") : I18n.tr("RASHIN")
                            color: row.isUser ? Tokens.inkMuted : Tokens.inkDim
                            font.family: Tokens.mono
                            font.pixelSize: Tokens.fTiny * root.s
                            font.letterSpacing: Tokens.trackLabel
                        }
                    }

                    Rectangle {
                        visible: !row.isTool && !row.isHandoff && row.isUser
                        anchors.right: parent.right
                        width: Math.min(parent.width * 0.78, 480 * root.s)
                        implicitHeight: userText.implicitHeight + Tokens.s3 * root.s * 2
                        radius: Tokens.radius * root.s
                        color: root.crate ? Tokens.tint5 : Tokens.bone
                        border.width: root.crate ? Tokens.border : 0
                        border.color: Tokens.line
                        TextEdit {
                            id: userText
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: Tokens.s3 * root.s
                            text: row.body
                            color: root.crate ? Tokens.ink : Tokens.inkOnBone
                            font.family: Tokens.ui
                            font.pixelSize: Tokens.fSmall * root.s
                            wrapMode: TextEdit.Wrap
                            readOnly: true
                            selectByMouse: true
                        }
                    }

                    Flow {
                        width: parent.width
                        visible: !row.isTool && !row.isHandoff && row.images.length > 0
                        spacing: Tokens.s2 * root.s
                        Repeater {
                            model: row.images
                            delegate: Rectangle {
                                id: messageImage
                                required property string modelData
                                width: 72 * root.s
                                height: width
                                radius: Tokens.radius * root.s
                                color: root.crate ? "transparent" : Tokens.tint5
                                border.width: Tokens.border
                                border.color: root.crate ? Tokens.line : Tokens.lineSoft
                                clip: true
                                Image {
                                    anchors.fill: parent
                                    anchors.margins: Tokens.border
                                    source: "file://" + messageImage.modelData
                                    asynchronous: true
                                    fillMode: Image.PreserveAspectCrop
                                }
                                HoverHandler { cursorShape: Qt.PointingHandCursor }
                                TapHandler { onTapped: Spawn.runApp(["xdg-open", messageImage.modelData], { label: "image" }) }
                            }
                        }
                    }

                    Rectangle {
                        visible: !row.isTool && !row.isHandoff && !row.isUser && row.thought.length > 0
                        width: parent.width
                        implicitHeight: thoughtColumn.implicitHeight + Tokens.s3 * root.s * 2
                        radius: Tokens.radius * root.s
                        color: root.crate ? "transparent" : Tokens.tint5
                        border.width: Tokens.border
                        border.color: root.crate ? Tokens.line : Tokens.lineSoft
                        Column {
                            id: thoughtColumn
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: Tokens.s3 * root.s
                            spacing: Tokens.s1 * root.s
                            TrackLabel {
                                visible: root.crate
                                text: row.live ? I18n.tr("Thinking…") : I18n.tr("Thought")
                                tone: row.live ? "active" : "subtle"
                            }
                            Text {
                                visible: !root.crate
                                text: row.live ? I18n.tr("Thinking…") : I18n.tr("Thought")
                                color: row.live ? Tokens.inkDim : Tokens.inkMuted
                                font.family: Tokens.mono
                                font.pixelSize: Tokens.fTiny * root.s
                            }
                            TextEdit {
                                width: parent.width
                                text: row.thought
                                color: Tokens.inkMuted
                                font.family: Tokens.ui
                                font.pixelSize: Tokens.fSmall * root.s
                                font.italic: true
                                wrapMode: TextEdit.Wrap
                                readOnly: true
                                selectByMouse: true
                            }
                        }
                    }

                    TextEdit {
                        visible: !row.isTool && !row.isHandoff && !row.isUser && row.body.length > 0
                        width: parent.width
                        text: row.body.replace(/([^\n])\n(?!\n)/g, "$1  \n")
                        textFormat: TextEdit.MarkdownText
                        color: Tokens.inkDim
                        font.family: Tokens.ui
                        font.pixelSize: Tokens.fSmall * root.s
                        wrapMode: TextEdit.Wrap
                        readOnly: true
                        selectByMouse: true
                        selectionColor: root.crate ? Tokens.mark : Tokens.bone
                        selectedTextColor: root.crate ? Tokens.paper : Tokens.inkOnBone
                        onLinkActivated: url => Spawn.runApp(["xdg-open", url], { label: "browser" })
                    }

                    Rectangle {
                        visible: row.isTool
                        width: parent.width
                        objectName: "askChatTool"
                        implicitHeight: toolColumn.implicitHeight + Tokens.s3 * root.s * 2
                        radius: Tokens.radius * root.s
                        color: root.crate ? "transparent" : Tokens.tint5
                        border.width: Tokens.border
                        border.color: root.crate ? (row.status === "failed" ? Tokens.alert : Tokens.line)
                            : row.status === "failed" ? Tokens.lineStrong : Tokens.lineSoft
                        Column {
                            id: toolColumn
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: Tokens.s3 * root.s
                            spacing: Tokens.s1 * root.s
                            Row {
                                width: parent.width
                                spacing: Tokens.s2 * root.s
                                Glyph {
                                    visible: root.crate
                                    anchors.verticalCenter: parent.verticalCenter
                                    name: row.tkind === "execute" ? "terminal" : row.tkind === "search" ? "search" : row.tkind === "read" ? "description" : "build"
                                    size: 16
                                    color: Tokens.inkSecondary
                                }
                                Text {
                                    visible: !root.crate
                                    text: row.tkind === "execute" ? "terminal" : row.tkind === "search" ? "search" : row.tkind === "read" ? "description" : "build"
                                    color: row.status === "failed" ? Tokens.inkDim : Tokens.inkMuted
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: Tokens.fBody * root.s
                                }
                                Text {
                                    anchors.verticalCenter: root.crate ? parent.verticalCenter : undefined
                                    width: parent.width - 70 * root.s
                                    text: row.title.length > 0 ? row.title : row.tkind
                                    color: Tokens.ink
                                    font.family: Tokens.ui
                                    font.pixelSize: Tokens.fSmall * root.s
                                    elide: Text.ElideRight
                                }
                                // under crate the call's state: a Beam while it runs, else its glyph
                                Beam {
                                    objectName: "askChatToolBeam"
                                    visible: root.crate && row.output.trim().length === 0
                                        && row.status !== "completed" && row.status !== "failed"
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 40
                                    interactive: false
                                    indeterminate: true
                                }
                                Glyph {
                                    visible: root.crate && (row.output.trim().length > 0
                                        || row.status === "completed" || row.status === "failed")
                                    anchors.verticalCenter: parent.verticalCenter
                                    name: row.output.trim().length > 0
                                        ? (row.outputOpen ? "expand_less" : "expand_more")
                                        : row.status === "completed" ? "check" : "error"
                                    size: 16
                                    color: row.status === "failed" ? Tokens.alert
                                        : row.status === "completed" && row.output.trim().length === 0 ? Tokens.mark
                                        : Tokens.inkSecondary
                                }
                                Text {
                                    visible: !root.crate
                                    text: row.output.trim().length > 0
                                        ? (row.outputOpen ? "expand_less" : "expand_more")
                                        : row.status === "completed" ? "check" : row.status === "failed" ? "error" : "progress_activity"
                                    color: Tokens.inkMuted
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: Tokens.fBody * root.s
                                    RotationAnimation on rotation {
                                        running: root.motionAllowed && row.output.trim().length === 0
                                            && row.status !== "completed" && row.status !== "failed"
                                        loops: Animation.Infinite
                                        from: 0
                                        to: 360
                                        duration: Motion.spatial * 2
                                    }
                                }
                            }
                            TextEdit {
                                width: parent.width
                                visible: row.outputOpen && row.output.trim().length > 0
                                text: row.output
                                color: Tokens.inkMuted
                                font.family: Tokens.mono
                                font.pixelSize: Tokens.fTiny * root.s
                                wrapMode: TextEdit.WrapAnywhere
                                readOnly: true
                                selectByMouse: true
                            }
                        }
                        TapHandler {
                            enabled: row.output.trim().length > 0
                            onTapped: row.outputOpen = !row.outputOpen
                        }
                    }

                    Rectangle {
                        visible: row.permission !== null
                        width: parent.width
                        implicitHeight: permissionColumn.implicitHeight + Tokens.s3 * root.s * 2
                        radius: Tokens.radius * root.s
                        color: root.crate ? "transparent" : Tokens.tint10
                        border.width: Tokens.border
                        border.color: root.crate ? Tokens.mark : Tokens.lineStrong
                        Column {
                            id: permissionColumn
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: Tokens.s3 * root.s
                            spacing: Tokens.s2 * root.s
                            TrackLabel {
                                visible: root.crate
                                text: I18n.tr("Needs your approval")
                                tone: "active"
                            }
                            Text {
                                visible: !root.crate
                                text: I18n.tr("Needs your approval")
                                color: Tokens.inkMuted
                                font.family: Tokens.mono
                                font.pixelSize: Tokens.fTiny * root.s
                                font.letterSpacing: Tokens.trackLabel
                            }
                            Text {
                                width: parent.width
                                text: row.permission ? String(row.permission.input || row.permission.title || "") : ""
                                color: Tokens.ink
                                font.family: Tokens.mono
                                font.pixelSize: Tokens.fTiny * root.s
                                wrapMode: Text.WrapAnywhere
                            }
                            Flow {
                                width: parent.width
                                spacing: Tokens.s2 * root.s
                                Repeater {
                                    model: root.permissionOptions(row.permission)
                                    delegate: Rectangle {
                                        id: permissionChoice
                                        required property var modelData
                                        width: root.crate ? permissionBtn.implicitWidth : permissionLabel.implicitWidth + Tokens.s4 * root.s
                                        height: root.crate ? permissionBtn.implicitHeight : Tokens.ctlH * root.s
                                        radius: Tokens.radius * root.s
                                        color: root.crate ? "transparent"
                                            : permissionTap.pressed ? Tokens.tint16
                                            : permissionHover.hovered ? Tokens.tint10 : Tokens.tint5
                                        border.width: root.crate ? 0 : Tokens.border
                                        border.color: Tokens.lineStrong
                                        Btn {
                                            id: permissionBtn
                                            objectName: "askChatPermission"
                                            visible: root.crate
                                            anchors.fill: parent
                                            compact: true
                                            primary: String(permissionChoice.modelData.kind || "") === "allow_once"
                                            text: permissionLabel.text
                                            onAct: Needle.answerPermission(row.permission.requestId, permissionChoice.modelData.id)
                                        }
                                        Text {
                                            id: permissionLabel
                                            visible: !root.crate
                                            anchors.centerIn: parent
                                            text: String(permissionChoice.modelData.name || permissionChoice.modelData.id || I18n.tr("Decline"))
                                            color: Tokens.ink
                                            font.family: Tokens.ui
                                            font.pixelSize: Tokens.fTiny * root.s
                                        }
                                        HoverHandler { id: permissionHover; cursorShape: Qt.PointingHandCursor }
                                        TapHandler { id: permissionTap; enabled: !root.crate; onTapped: Needle.answerPermission(row.permission.requestId, permissionChoice.modelData.id) }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            footer: Column {
                width: transcript.width
                spacing: Tokens.s2 * root.s
                Repeater {
                    model: Needle.standalonePerms
                    delegate: Rectangle {
                        id: standalone
                        required property var modelData
                        width: transcript.width
                        implicitHeight: standaloneColumn.implicitHeight + Tokens.s3 * root.s * 2
                        radius: Tokens.radius * root.s
                        color: root.crate ? "transparent" : Tokens.tint10
                        border.width: Tokens.border
                        border.color: root.crate ? Tokens.mark : Tokens.lineStrong
                        Column {
                            id: standaloneColumn
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: Tokens.s3 * root.s
                            spacing: Tokens.s2 * root.s
                            TrackLabel {
                                visible: root.crate
                                text: I18n.tr("Needs your approval")
                                tone: "active"
                            }
                            Text {
                                visible: !root.crate
                                text: I18n.tr("Needs your approval")
                                color: Tokens.inkMuted
                                font.family: Tokens.mono
                                font.pixelSize: Tokens.fTiny * root.s
                            }
                            Flow {
                                width: parent.width
                                spacing: Tokens.s2 * root.s
                                Repeater {
                                    model: root.permissionOptions(standalone.modelData)
                                    delegate: Rectangle {
                                        id: standaloneChoice
                                        required property var modelData
                                        width: root.crate ? standaloneBtn.implicitWidth : standaloneLabel.implicitWidth + Tokens.s4 * root.s
                                        height: root.crate ? standaloneBtn.implicitHeight : Tokens.ctlH * root.s
                                        radius: Tokens.radius * root.s
                                        color: root.crate ? "transparent"
                                            : standaloneTap.pressed ? Tokens.tint16
                                            : standaloneHover.hovered ? Tokens.tint10 : Tokens.tint5
                                        Btn {
                                            id: standaloneBtn
                                            visible: root.crate
                                            anchors.fill: parent
                                            compact: true
                                            primary: String(standaloneChoice.modelData.kind || "") === "allow_once"
                                            text: standaloneLabel.text
                                            onAct: Needle.answerPermission(standalone.modelData.requestId, standaloneChoice.modelData.id)
                                        }
                                        Text {
                                            id: standaloneLabel
                                            visible: !root.crate
                                            anchors.centerIn: parent
                                            text: String(standaloneChoice.modelData.name || standaloneChoice.modelData.id || I18n.tr("Decline"))
                                            color: Tokens.ink
                                            font.family: Tokens.ui
                                            font.pixelSize: Tokens.fTiny * root.s
                                        }
                                        HoverHandler { id: standaloneHover; cursorShape: Qt.PointingHandCursor }
                                        TapHandler { id: standaloneTap; enabled: !root.crate; onTapped: Needle.answerPermission(standalone.modelData.requestId, standaloneChoice.modelData.id) }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            id: working
            width: parent.width
            height: Needle.busy ? 22 * root.s : 0
            visible: height > 0
            Text {
                id: workingLabel
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: Needle.activity.length > 0 ? Needle.activity : I18n.tr("working")
                color: Tokens.inkDim
                font.family: Tokens.ui
                font.pixelSize: Tokens.fSmall * root.s
                SequentialAnimation on opacity {
                    running: root.motionAllowed && Needle.busy
                    loops: Animation.Infinite
                    NumberAnimation { from: 1; to: 0.7; duration: Tokens.dur(900); easing.type: Easing.InOutSine }
                    NumberAnimation { from: 0.7; to: 1; duration: Tokens.dur(900); easing.type: Easing.InOutSine }
                    onStopped: workingLabel.opacity = 1
                }
            }
            Beam {
                objectName: "askChatWorkBeam"
                visible: root.crate && Needle.busy
                anchors.left: workingLabel.right
                anchors.leftMargin: Tokens.s3 * root.s
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                interactive: false
                indeterminate: true
            }
        }

        Rectangle {
            id: composerFrame
            width: parent.width
            height: root.showComposer ? 44 * root.s : 0
            visible: root.showComposer
            radius: Tokens.radius * root.s
            color: root.crate ? "transparent" : Tokens.paperLift
            border.width: Tokens.border
            border.color: root.crate ? (composer.activeFocus ? Tokens.markHover : Tokens.line)
                : composer.activeFocus ? Tokens.lineStrong : Tokens.line

            TextInput {
                id: composer
                anchors.left: parent.left
                anchors.right: root.crate ? sendIcon.left : sendButton.left
                anchors.leftMargin: Tokens.s3 * root.s
                anchors.rightMargin: Tokens.s2 * root.s
                anchors.verticalCenter: parent.verticalCenter
                text: root.draft
                color: Tokens.ink
                selectionColor: root.crate ? Tokens.mark : Tokens.bone
                selectedTextColor: root.crate ? Tokens.paper : Tokens.inkOnBone
                font.family: Tokens.ui
                font.pixelSize: Tokens.fBody * root.s
                selectByMouse: true
                clip: true
                onTextEdited: root.draft = text
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_N && (event.modifiers & Qt.ControlModifier)) {
                        Needle.newChat();
                        root.draft = "";
                        event.accepted = true;
                    } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                            && !(event.modifiers & Qt.ShiftModifier)) {
                        root.send();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Escape && Needle.busy) {
                        Needle.cancel();
                        event.accepted = true;
                    }
                }
            }
            Text {
                anchors.left: composer.left
                anchors.verticalCenter: parent.verticalCenter
                visible: composer.text.length === 0
                text: Needle.pendingHandoff ? I18n.tr("Continue from the ask…")
                    : I18n.tr("Message Rashin…")
                color: Tokens.inkFaint
                font.family: Tokens.ui
                font.pixelSize: Tokens.fBody * root.s
            }
            IconButton {
                id: sendIcon
                objectName: "askChatSend"
                visible: root.crate
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 36
                height: 36
                glyph: Needle.busy ? "stop" : "arrow_upward"
                on: !Needle.busy && composer.text.trim().length > 0
                onClicked: Needle.busy ? Needle.cancel() : root.send()
            }
            Rectangle {
                id: sendButton
                visible: !root.crate
                anchors.right: parent.right
                anchors.rightMargin: Tokens.s2 * root.s
                anchors.verticalCenter: parent.verticalCenter
                width: 30 * root.s
                height: width
                radius: Tokens.radius * root.s
                color: sendTap.pressed ? Tokens.tint16
                    : Needle.busy ? Tokens.tint10
                    : composer.text.trim().length > 0 ? Tokens.bone : Tokens.tint5
                Text {
                    anchors.centerIn: parent
                    text: Needle.busy ? "stop" : "arrow_upward"
                    color: Needle.busy ? Tokens.inkDim : composer.text.trim().length > 0 ? Tokens.inkOnBone : Tokens.inkMuted
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: Tokens.fBody * root.s
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                TapHandler { id: sendTap; onTapped: Needle.busy ? Needle.cancel() : root.send() }
            }
        }
    }
}
