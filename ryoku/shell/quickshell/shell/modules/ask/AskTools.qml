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
    property string query: ""
    property string tool: ""
    property real maximumHeight: 520 * s
    property int selectedIndex: 0
    property bool pickerOpen: false
    property string pickerMode: "compress"
    property bool recentOpen: false
    property bool installedOpen: false
    property string confirmUninstallId: ""
    property bool engineOpen: false
    readonly property bool motionAllowed: active && !Tokens.reduceMotion && !Motion.reduce
    // Under controls "crate" the tools draw from the kit on the glass: the
    // download mode is a Seg, commands are pick rows, actions kit buttons, the
    // engine a switch, progress and reading a Beam, captions tracked labels,
    // and every card a hairline with no fill.
    readonly property bool crate: Tokens.controlsCrate
    readonly property bool engineOn: Stash.cobaltState === "running" || Stash.cobaltState === "starting"
    // The download has been queued and the link is spent, so the field is
    // cleared rather than left holding a link that has already been taken.
    signal accepted()
    readonly property var commands: [
        { id: "download", glyph: "download", name: I18n.tr("Download URL"), hint: I18n.tr("Video, audio, or mute") },
        { id: "compress", glyph: "folder_zip", name: I18n.tr("Compress files"), hint: I18n.tr("Pick videos or images") },
        { id: "install", glyph: "deployed_code", name: I18n.tr("Install package files"), hint: I18n.tr("AppImage, package, or archive") },
        { id: "installed", glyph: "inventory_2", name: I18n.tr("Installed apps"), hint: I18n.tr("Remove apps installed through Stash") },
        { id: "recent", glyph: "history", name: I18n.tr("Recent downloads"), hint: I18n.tr("Open the Stash folder") },
        { id: "clear", glyph: "delete_sweep", name: I18n.tr("Clear recent"), hint: I18n.tr("Remove downloaded files") },
        { id: "dashboard", glyph: "dashboard", name: I18n.tr("Rashin dashboard"), hint: I18n.tr("Open setup and usage") }
    ]
    readonly property var filteredCommands: {
        const needle = query.trim().toLowerCase();
        if (needle.length === 0 || needle.indexOf("://") >= 0)
            return commands;
        return commands.filter(command => (command.name + " " + command.hint).toLowerCase().indexOf(needle) >= 0);
    }

    // The current chip's rungs, out of the one answer the probe already holds.
    // Switching chips re-renders from here and never asks again.
    readonly property var tiers: Stash.probeTiers

    implicitHeight: pickerOpen ? picker.implicitHeight : toolColumn.implicitHeight

    onToolChanged: if (active && (tool === "compress" || tool === "install")) openPicker(tool)

    // An answer about a link that is no longer in the field would offer formats
    // for something else, so it is dropped rather than redrawn. The probe itself
    // is not re-asked: a half-typed link is not worth a network round trip.
    onQueryChanged: {
        if (Stash.probeState !== "idle" && root.linkUrl() !== Stash.probedUrl)
            Stash.resetProbe();
    }
    onActiveChanged: {
        if (active && (tool === "compress" || tool === "install"))
            Qt.callLater(() => openPicker(tool));
    }
    onFilteredCommandsChanged: selectedIndex = Math.max(0, Math.min(selectedIndex, filteredCommands.length - 1))

    function openPicker(mode) {
        pickerMode = mode;
        pickerOpen = true;
    }

    function move(delta) {
        selectedIndex = Math.max(0, Math.min(filteredCommands.length - 1, selectedIndex + delta));
    }

    function activate(value) {
        const text = value === undefined ? query : String(value);
        if (text.trim().length > 0 && /^(https?:\/\/|www\.)/i.test(text.trim())) {
            readFormats(text);
            return;
        }
        const command = filteredCommands[selectedIndex];
        if (command)
            run(command.id);
    }

    function run(id) {
        if (id === "download") {
            if (query.trim().length > 0)
                readFormats(query);
        } else if (id === "compress" || id === "install") {
            openPicker(id);
        } else if (id === "recent") {
            recentOpen = !recentOpen;
            installedOpen = false;
            confirmUninstallId = "";
        } else if (id === "installed") {
            installedOpen = !installedOpen;
            recentOpen = false;
            confirmUninstallId = "";
            if (installedOpen)
                Stash.refreshInstalled();
        } else if (id === "clear") {
            Stash.clearAll();
        } else if (id === "dashboard") {
            Spawn.run(["ryoku-shell", "hub", "open", "rashin"]);
        }
    }

    // A link pasted with no scheme is still a link someone means to download,
    // so it gets one rather than being asked for it: the field takes commands
    // too, and "www." is unambiguously not one of those.
    function linkUrl(value) {
        const text = String(value === undefined ? query : value).trim();
        return /^www\./i.test(text) ? "https://" + text : text;
    }

    // Reading formats is a yt-dlp call, so it costs a deliberate press (Enter on
    // the link, or the Download row) and never a keystroke. Asking again for a
    // link whose answer is already on screen would spend the same call to redraw
    // the same list, so it is skipped.
    function readFormats(value) {
        const url = linkUrl(value);
        if (!Stash.probeAccepts(url)) {
            // Not something the probe can read: hand it to the queue anyway,
            // so the helper's own error is visible instead of a silent press.
            const text = String(value === undefined ? query : value).trim();
            if (text.length > 0)
                Stash.enqueueDownload(text, Stash.dlMode);
            return;
        }
        if ((Stash.probeState === "ready" || Stash.probeState === "probing")
                && Stash.probedUrl === url)
            return;
        Stash.probe(url);
    }

    function pick(tier) {
        const url = linkUrl();
        if (url.length === 0)
            return;
        Stash.enqueueDownload(url, Stash.dlMode, tier);
        Stash.resetProbe();
        root.accepted();
    }

    // The words above a tier are ours, the rung below it is the probe's. Video
    // answers in heights, audio in bitrates, and only the label is shared, so
    // the key alone decides what the row is called.
    function tierName(key) {
        switch ("" + key) {
        case "best": return I18n.tr("Best");
        case "avg": return I18n.tr("Mid");
        case "low": return I18n.tr("Low");
        case "high": return I18n.tr("High");
        case "std": return I18n.tr("Standard");
        case "light": return I18n.tr("Light");
        case "audio": return I18n.tr("Audio");
        }
        return I18n.tr("Quality");
    }

    // What the second line says depends on what the tier carries: a rung on the
    // resolution ladder for a video, a bitrate for a track. The tier's own field
    // decides rather than the chip, because an audio-only link probed under
    // Video still answers in bitrates. Neither is printed when the probe had
    // nothing to say, and the unit stays a unit: "k" and "p" are readouts.
    function tierDetail(tier) {
        if (tier.bitrate)
            return parseInt(tier.bitrate) + "k";
        const h = tier.height ? parseInt(tier.height) : 0;
        return h > 0 ? h + "p" : "";
    }

    // Sizes are the probe's estimate, so they never claim a decimal: a tenth of
    // a megabyte is noise, a whole gigabyte is not.
    function tierSize(tier) {
        const mb = tier.sizeMB != null ? parseFloat(tier.sizeMB) : NaN;
        if (isNaN(mb) || mb <= 0)
            return "";
        if (mb >= 1000)
            return I18n.tr("~%1 GB").arg((mb / 1000).toFixed(1));
        return I18n.tr("~%1 MB").arg(Math.round(mb));
    }

    AskFilePicker {
        id: picker
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        s: root.s
        open: root.pickerOpen
        mode: root.pickerMode
        onCancelled: root.pickerOpen = false
        onConfirmed: paths => {
            if (root.pickerMode === "install") Stash.install(paths);
            else Stash.compress(paths);
            root.pickerOpen = false;
        }
    }

    Column {
        id: toolColumn
        width: parent.width
        visible: !root.pickerOpen
        spacing: Tokens.s3 * root.s

        Rectangle {
            width: parent.width
            height: root.crate ? modeSeg.height : 42 * root.s
            radius: Tokens.radius * root.s
            color: root.crate ? "transparent" : Tokens.tint5
            border.width: root.crate ? 0 : Tokens.border
            border.color: Tokens.lineSoft

            Seg {
                id: modeSeg
                objectName: "askToolsModeSeg"
                visible: root.crate
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                options: ["auto", "audio", "mute"]
                labels: ({ auto: I18n.tr("Auto"), audio: I18n.tr("Audio"), mute: I18n.tr("Mute") })
                current: Stash.dlMode
                onChose: key => Stash.dlMode = key
            }

            TrackLabel {
                visible: root.crate
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: I18n.tr("Download mode")
            }

            Row {
                visible: !root.crate
                anchors.left: parent.left
                anchors.leftMargin: Tokens.s3 * root.s
                anchors.verticalCenter: parent.verticalCenter
                spacing: Tokens.s2 * root.s
                Repeater {
                    model: [
                        { id: "auto", label: I18n.tr("Auto") },
                        { id: "audio", label: I18n.tr("Audio") },
                        { id: "mute", label: I18n.tr("Mute") }
                    ]
                    delegate: Rectangle {
                        id: modeChip
                        required property var modelData
                        width: modeLabel.implicitWidth + Tokens.s3 * root.s
                        height: Tokens.ctlH * root.s
                        radius: Tokens.radius * root.s
                        color: Stash.dlMode === modeChip.modelData.id ? Tokens.bone
                            : modeTap.pressed ? Tokens.tint16
                            : modeHover.hovered ? Tokens.tint10 : "transparent"
                        Text {
                            id: modeLabel
                            anchors.centerIn: parent
                            text: modeChip.modelData.label
                            color: Stash.dlMode === modeChip.modelData.id ? Tokens.inkOnBone : Tokens.inkDim
                            font.family: Tokens.ui
                            font.pixelSize: Tokens.fTiny * root.s
                        }
                        HoverHandler { id: modeHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { id: modeTap; onTapped: Stash.dlMode = modeChip.modelData.id }
                    }
                }
            }
            Text {
                visible: !root.crate
                anchors.right: parent.right
                anchors.rightMargin: Tokens.s3 * root.s
                anchors.verticalCenter: parent.verticalCenter
                text: I18n.tr("Download mode")
                color: Tokens.inkMuted
                font.family: Tokens.mono
                font.pixelSize: Tokens.fTiny * root.s
            }
        }

        // The command list holds the same slot the format answer does: with a
        // link being read, the list is what it replaced, not a second thing
        // stacked under it. The engine row and the queue stay either way,
        // because they answer about the machine rather than about the link.
        Column {
            width: parent.width
            spacing: Tokens.s1 * root.s
            visible: Stash.probeState === "idle"
            Repeater {
                model: root.filteredCommands
                delegate: Rectangle {
                    id: commandRow
                    required property var modelData
                    required property int index
                    width: parent.width
                    height: 48 * root.s
                    radius: Tokens.radius * root.s
                    readonly property bool current: index === root.selectedIndex
                    color: root.crate ? "transparent"
                        : current ? Tokens.bone
                        : commandTap.pressed ? Tokens.tint16
                        : commandHover.hovered ? Tokens.tint10 : "transparent"
                    border.width: root.crate ? 0 : Tokens.border
                    border.color: current ? Tokens.bone : Tokens.lineSoft
                    PickRow {
                        objectName: "askToolsCommand"
                        visible: root.crate
                        anchors.fill: parent
                        glyph: commandRow.modelData.glyph
                        title: commandRow.modelData.name
                        sub: commandRow.modelData.hint
                        picked: commandRow.current
                        onClicked: root.run(commandRow.modelData.id)
                    }
                    Text {
                        id: commandGlyph
                        visible: !root.crate
                        anchors.left: parent.left
                        anchors.leftMargin: Tokens.s3 * root.s
                        anchors.verticalCenter: parent.verticalCenter
                        text: commandRow.modelData.glyph
                        color: commandRow.current ? Tokens.inkOnBone : Tokens.inkMuted
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: Tokens.fBody * root.s
                    }
                    Column {
                        visible: !root.crate
                        anchors.left: commandGlyph.right
                        anchors.right: keyHint.left
                        anchors.leftMargin: Tokens.s3 * root.s
                        anchors.rightMargin: Tokens.s2 * root.s
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 0
                        Text {
                            width: parent.width
                            text: commandRow.modelData.name
                            color: commandRow.current ? Tokens.inkOnBone : Tokens.ink
                            font.family: Tokens.ui
                            font.pixelSize: Tokens.fSmall * root.s
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }
                        Text {
                            width: parent.width
                            text: commandRow.modelData.hint
                            color: commandRow.current ? Tokens.inkOnBone : Tokens.inkMuted
                            font.family: Tokens.ui
                            font.pixelSize: Tokens.fTiny * root.s
                            elide: Text.ElideRight
                        }
                    }
                    Text {
                        id: keyHint
                        visible: !root.crate
                        anchors.right: parent.right
                        anchors.rightMargin: Tokens.s3 * root.s
                        anchors.verticalCenter: parent.verticalCenter
                        text: commandRow.current ? I18n.tr("Enter") : ""
                        color: commandRow.current ? Tokens.inkOnBone : Tokens.inkFaint
                        font.family: Tokens.mono
                        font.pixelSize: Tokens.fTiny * root.s
                    }
                    HoverHandler { id: commandHover; cursorShape: Qt.PointingHandCursor; onHoveredChanged: if (hovered) root.selectedIndex = commandRow.index }
                    TapHandler { id: commandTap; enabled: !root.crate; onTapped: root.run(commandRow.modelData.id) }
                }
            }
        }

        // ── Reading a link ──────────────────────────────────────────────
        // What a pasted link can be fetched as, in the slot the command list
        // occupies. Nothing here probes on its own: reading formats is a
        // yt-dlp call, so it costs Enter on the link or the Download row, and
        // this renders whatever `Stash.probeTiers` already holds.

        // A bare line while the list is being read, and deliberately not a box:
        // a second of waiting is not a state worth framing, and the field's own
        // border already says the link is one worth reading.
        Row {
            width: parent.width
            height: Tokens.fBody * root.s * 1.6
            spacing: Tokens.s2 * root.s
            visible: Stash.probeState === "probing"

            Beam {
                objectName: "askToolsProbeBeam"
                visible: root.crate
                anchors.verticalCenter: parent.verticalCenter
                width: 64
                interactive: false
                indeterminate: true
            }
            Text {
                id: probeSpinner
                visible: !root.crate
                anchors.verticalCenter: parent.verticalCenter
                text: "progress_activity"
                color: Tokens.inkMuted
                font.family: "Material Symbols Rounded"
                font.pixelSize: Tokens.fBody * root.s
                RotationAnimation on rotation {
                    running: root.motionAllowed && Stash.probeState === "probing"
                    loops: Animation.Infinite
                    from: 0; to: 360; duration: 900
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: I18n.tr("Reading formats")
                color: Tokens.inkMuted
                font.family: Tokens.ui
                font.pixelSize: Tokens.fBody * root.s
            }
        }

        // The file's own title heads the list, so the rows below read as
        // qualities of that file and not of whatever was last pasted. It wraps
        // and the box grows with it: a title cut to one ellipsis line says
        // nothing about what is on offer.
        Rectangle {
            width: parent.width
            visible: Stash.probeState === "ready" && root.tiers.length > 0
            implicitHeight: readyColumn.implicitHeight + Tokens.s3 * root.s * 2
            radius: Tokens.radius * root.s
            color: root.crate ? "transparent" : Tokens.tint5
            border.width: Tokens.border
            border.color: root.crate ? Tokens.line : Tokens.lineSoft
            Column {
                id: readyColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Tokens.s3 * root.s
                spacing: Tokens.s2 * root.s

                Text {
                    width: parent.width
                    text: Stash.probeTitle.length > 0 ? Stash.probeTitle : I18n.tr("Quality")
                    color: Tokens.ink
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fRow * root.s
                    font.weight: Font.DemiBold
                    wrapMode: Text.WordWrap
                    lineHeight: 1.25
                }

                Repeater {
                    model: root.tiers
                    delegate: Rectangle {
                        id: tierRow
                        required property var modelData
                        required property int index
                        width: parent.width
                        implicitHeight: tierColumn.implicitHeight + Tokens.s3 * root.s * 2
                        radius: Tokens.radius * root.s
                        color: root.crate ? "transparent" : tierHover.hovered ? Tokens.tint10 : "transparent"
                        border.width: Tokens.border
                        border.color: root.crate ? (tierHover.hovered ? Tokens.markHover : Tokens.line) : Tokens.lineSoft
                        Behavior on color { enabled: root.motionAllowed; ColorAnimation { duration: Tokens.snap } }

                        // Staggered in after the press.
                        opacity: 0
                        SequentialAnimation on opacity {
                            PauseAnimation { duration: root.motionAllowed ? tierRow.index * Tokens.snap / 2 : 0 }
                            NumberAnimation { to: 1; duration: root.motionAllowed ? Tokens.move : 0; easing.type: Tokens.ease }
                        }

                        // Hover only. The button on the right owns the action,
                        // so a pass over the row to read the numbers cannot
                        // start anything.
                        HoverHandler { id: tierHover }

                        // One Column so the row measures both lines it draws.
                        Column {
                            id: tierColumn
                            anchors.left: parent.left
                            anchors.right: tierDownload.left
                            anchors.leftMargin: Tokens.s3 * root.s
                            anchors.rightMargin: Tokens.s2 * root.s
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2 * root.s

                            Text {
                                width: parent.width
                                text: root.tierName(tierRow.modelData.key)
                                color: Tokens.ink
                                font.family: Tokens.ui
                                font.pixelSize: Tokens.fSmall * root.s
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            // The rung and the size share a line under the name:
                            // "720p . ~145 MB". A mono unit is a readout, not a
                            // word, so it is not a catalog string.
                            Text {
                                width: parent.width
                                text: {
                                    const parts = [root.tierDetail(tierRow.modelData), root.tierSize(tierRow.modelData)];
                                    return parts.filter(part => part.length > 0).join("  ·  ");
                                }
                                color: Tokens.inkMuted
                                font.family: Tokens.mono
                                font.pixelSize: Tokens.fMicro * root.s
                                elide: Text.ElideRight
                            }
                        }

                        Rectangle {
                            id: tierDownload
                            anchors.right: parent.right
                            anchors.rightMargin: Tokens.s3 * root.s
                            anchors.verticalCenter: parent.verticalCenter
                            width: root.crate ? downloadBtn.implicitWidth : downloadLabel.implicitWidth + Tokens.s3 * root.s
                            height: root.crate ? downloadBtn.implicitHeight : Tokens.ctlH * root.s
                            radius: Tokens.radius * root.s
                            color: root.crate ? "transparent"
                                : downloadTap.pressed ? Tokens.tint16
                                : downloadHover.hovered ? Tokens.tint10 : Tokens.tint5
                            border.width: root.crate ? 0 : Tokens.border
                            border.color: Tokens.lineSoft

                            Btn {
                                id: downloadBtn
                                objectName: "askToolsTierDownload"
                                visible: root.crate
                                anchors.fill: parent
                                compact: true
                                text: I18n.tr("Download")
                                onAct: root.pick(tierRow.modelData)
                            }
                            Behavior on color { enabled: root.motionAllowed; ColorAnimation { duration: Tokens.snap } }

                            Text {
                                id: downloadLabel
                                visible: !root.crate
                                anchors.centerIn: parent
                                text: I18n.tr("Download")
                                color: Tokens.ink
                                font.family: Tokens.ui
                                font.pixelSize: Tokens.fSmall * root.s
                                font.weight: Font.DemiBold
                            }
                            HoverHandler { id: downloadHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler { id: downloadTap; enabled: !root.crate; onTapped: root.pick(tierRow.modelData) }
                        }
                    }
                }
            }
        }

        // The link read fine but this mode has no rungs: say so quietly.
        Row {
            width: parent.width
            height: Tokens.fBody * root.s * 1.6
            spacing: Tokens.s2 * root.s
            visible: Stash.probeState === "ready" && root.tiers.length === 0

            Glyph {
                visible: root.crate
                anchors.verticalCenter: parent.verticalCenter
                name: Stash.dlMode === "audio" ? "volume_off" : "visibility_off"
                size: 16
                color: Tokens.inkSecondary
            }
            Text {
                visible: !root.crate
                anchors.verticalCenter: parent.verticalCenter
                text: Stash.dlMode === "audio" ? "volume_off" : "visibility_off"
                color: Tokens.inkMuted
                font.family: "Material Symbols Rounded"
                font.pixelSize: Tokens.fBody * root.s
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Stash.dlMode === "audio" ? I18n.tr("No audio tracks")
                    : I18n.tr("No formats for this")
                color: Tokens.inkMuted
                font.family: Tokens.ui
                font.pixelSize: Tokens.fBody * root.s
            }
        }

        // A link that cannot be read is still a link the user wants, so the
        // row offers the old behaviour rather than a dead end.
        Rectangle {
            width: parent.width
            visible: Stash.probeState === "error"
            implicitHeight: errorColumn.implicitHeight + Tokens.s3 * root.s * 2
            radius: Tokens.radius * root.s
            color: root.crate ? "transparent" : Tokens.tint5
            border.width: Tokens.border
            border.color: root.crate ? Tokens.line : Tokens.lineSoft
            Column {
                id: errorColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Tokens.s3 * root.s
                spacing: Tokens.s2 * root.s

                Row {
                    width: parent.width
                    spacing: Tokens.s2 * root.s
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: I18n.tr("Couldn't read formats")
                        color: Tokens.inkDim
                        font.family: Tokens.ui
                        font.pixelSize: Tokens.fSmall * root.s
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: root.crate ? bestBtn.implicitWidth : bestLabel.implicitWidth + Tokens.s3 * root.s
                        height: root.crate ? bestBtn.implicitHeight : Tokens.ctlH * root.s
                        radius: Tokens.radius * root.s
                        color: root.crate ? "transparent"
                            : bestTap.pressed ? Tokens.tint16
                            : bestHover.hovered ? Tokens.tint10 : "transparent"
                        border.width: root.crate ? 0 : Tokens.border
                        border.color: Tokens.lineSoft

                        Btn {
                            id: bestBtn
                            visible: root.crate
                            anchors.fill: parent
                            compact: true
                            text: I18n.tr("Download best")
                            onAct: root.pick(null)
                        }
                        Behavior on color { enabled: root.motionAllowed; ColorAnimation { duration: Tokens.snap } }

                        Text {
                            id: bestLabel
                            visible: !root.crate
                            anchors.centerIn: parent
                            text: I18n.tr("Download best")
                            color: Tokens.ink
                            font.family: Tokens.ui
                            font.pixelSize: Tokens.fSmall * root.s
                            font.weight: Font.DemiBold
                        }
                        HoverHandler { id: bestHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { id: bestTap; enabled: !root.crate; onTapped: root.pick(null) }
                    }
                }

                // The helper's own words, not ours: "Unsupported URL" names the
                // failure and a private video says to try another one. Mono
                // because the helper is speaking.
                Text {
                    width: parent.width
                    visible: Stash.probeMsg.length > 0
                    text: Stash.probeMsg
                    color: Tokens.inkMuted
                    font.family: Tokens.mono
                    font.pixelSize: Tokens.fMicro * root.s
                    wrapMode: Text.WordWrap
                }
            }
        }

        Rectangle {
            width: parent.width
            objectName: "askToolsEngine"
            height: 44 * root.s
            radius: Tokens.radius * root.s
            color: root.crate ? "transparent"
                : engineTap.pressed ? Tokens.tint16 : engineHover.hovered ? Tokens.tint10 : Tokens.tint5
            border.width: Tokens.border
            border.color: root.crate ? (Stash.cobaltState === "error" ? Tokens.alert : engineHover.hovered ? Tokens.markHover : Tokens.line)
                : Stash.cobaltState === "error" ? Tokens.lineStrong : Tokens.lineSoft
            Glyph {
                visible: root.crate
                anchors.left: parent.left
                anchors.leftMargin: Tokens.s3 * root.s
                anchors.verticalCenter: parent.verticalCenter
                name: "memory"
                size: 18
                color: Stash.cobaltState === "error" ? Tokens.alert : root.engineOn ? Tokens.mark : Tokens.inkSecondary
            }
            Text {
                visible: !root.crate
                anchors.left: parent.left
                anchors.leftMargin: Tokens.s3 * root.s
                anchors.verticalCenter: parent.verticalCenter
                text: "memory"
                color: Stash.cobaltState === "error" ? Tokens.inkDim : Tokens.inkMuted
                font.family: "Material Symbols Rounded"
                font.pixelSize: Tokens.fBody * root.s
            }
            Column {
                anchors.left: parent.left
                anchors.right: root.crate ? engineSwitch.left : engineToggle.left
                anchors.leftMargin: 42 * root.s
                anchors.rightMargin: Tokens.s3 * root.s
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    text: I18n.tr("Download engine")
                    color: Tokens.ink
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fSmall * root.s
                    font.weight: Font.Medium
                }
                Text {
                    text: Stash.setupState === "running" ? I18n.tr("Setting up…")
                        : Stash.cobaltState === "running" ? I18n.tr("Cobalt is on")
                        : Stash.cobaltState === "starting" ? I18n.tr("Starting Cobalt…")
                        : Stash.cobaltState === "error" ? (Stash.cobaltMsg || I18n.tr("Failed to start"))
                        : I18n.tr("Using yt-dlp")
                    color: Tokens.inkMuted
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fTiny * root.s
                }
            }
            // The row owns the press (it opens setup when the engine is not
            // ready), so the switch only shows the state.
            Sw {
                id: engineSwitch
                objectName: "askToolsEngineSwitch"
                visible: root.crate
                enabled: false
                anchors.right: parent.right
                anchors.rightMargin: Tokens.s3 * root.s
                anchors.verticalCenter: parent.verticalCenter
                on: root.engineOn
            }
            Rectangle {
                id: engineToggle
                visible: !root.crate
                anchors.right: parent.right
                anchors.rightMargin: Tokens.s3 * root.s
                anchors.verticalCenter: parent.verticalCenter
                width: 38 * root.s
                height: 22 * root.s
                radius: height / 2
                color: Stash.cobaltState === "running" || Stash.cobaltState === "starting" ? Tokens.bone : Tokens.tint10
                Rectangle {
                    width: 16 * root.s
                    height: width
                    radius: width / 2
                    x: Stash.cobaltState === "running" || Stash.cobaltState === "starting" ? parent.width - width - 3 * root.s : 3 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    color: Stash.cobaltState === "running" || Stash.cobaltState === "starting" ? Tokens.inkOnBone : Tokens.inkMuted
                    Behavior on x { enabled: root.motionAllowed; NumberAnimation { duration: Tokens.move; easing.type: Tokens.ease } }
                }
            }
            HoverHandler { id: engineHover; cursorShape: Qt.PointingHandCursor }
            TapHandler {
                id: engineTap
                onTapped: {
                    if (Stash.cobaltState === "running" || Stash.cobaltState === "starting") {
                        Stash.setEngine(false);
                    } else if (Stash.dockerState === "ready") {
                        Stash.setEngine(true);
                    } else {
                        root.engineOpen = !root.engineOpen;
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            visible: root.engineOpen
            implicitHeight: visible ? engineDetails.implicitHeight + Tokens.s3 * root.s * 2 : 0
            radius: Tokens.radius * root.s
            color: root.crate ? "transparent" : Tokens.paperLift
            border.width: Tokens.border
            border.color: root.crate ? Tokens.line : Tokens.lineSoft
            Column {
                id: engineDetails
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Tokens.s3 * root.s
                spacing: Tokens.s2 * root.s
                Text {
                    width: parent.width
                    text: Stash.dockerState === "missing" ? I18n.tr("Docker is missing. Ryoku Update installs it.")
                        : Stash.dockerState === "denied" ? I18n.tr("The container helper is unavailable.")
                        : I18n.tr("Set up the local Rashin engine once.")
                    color: Tokens.inkMuted
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fSmall * root.s
                    wrapMode: Text.WordWrap
                }
                Repeater {
                    model: Stash.setupSteps
                    delegate: Row {
                        id: setupRow
                        required property string label
                        required property string stepState
                        required property string msg
                        spacing: Tokens.s2 * root.s
                        // under crate: the kit glyph once a step settles, a dot
                        // (the mark, pulsing, while it runs) before that
                        Glyph {
                            visible: root.crate && (setupRow.stepState === "done" || setupRow.stepState === "failed")
                            anchors.verticalCenter: parent.verticalCenter
                            name: setupRow.stepState === "done" ? "check_circle" : "error"
                            size: 16
                            color: setupRow.stepState === "failed" ? Tokens.alert : Tokens.mark
                        }
                        Item {
                            visible: root.crate && setupRow.stepState !== "done" && setupRow.stepState !== "failed"
                            anchors.verticalCenter: parent.verticalCenter
                            width: 16
                            height: 16
                            Rectangle {
                                id: stepDot
                                anchors.centerIn: parent
                                width: 6
                                height: 6
                                radius: 3
                                color: setupRow.stepState === "running" ? Tokens.mark : Tokens.inkFaint
                                SequentialAnimation on opacity {
                                    running: root.motionAllowed && setupRow.stepState === "running"
                                    loops: Animation.Infinite
                                    NumberAnimation { from: 1; to: 0.45; duration: Tokens.dur(420); easing.type: Easing.InOutSine }
                                    NumberAnimation { from: 0.45; to: 1; duration: Tokens.dur(420); easing.type: Easing.InOutSine }
                                    onStopped: stepDot.opacity = 1
                                }
                            }
                        }
                        Text {
                            visible: !root.crate
                            text: setupRow.stepState === "done" ? "check_circle" : setupRow.stepState === "failed" ? "error" : setupRow.stepState === "running" ? "progress_activity" : "circle"
                            color: setupRow.stepState === "pending" ? Tokens.inkFaint : Tokens.inkDim
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: Tokens.fBody * root.s
                        }
                        Text {
                            anchors.verticalCenter: root.crate ? parent.verticalCenter : undefined
                            text: setupRow.msg.length > 0 ? I18n.tr(setupRow.label) + " · " + setupRow.msg : I18n.tr(setupRow.label)
                            color: Tokens.inkDim
                            font.family: Tokens.ui
                            font.pixelSize: Tokens.fTiny * root.s
                        }
                    }
                }
                Btn {
                    objectName: "askToolsSetup"
                    visible: root.crate && Stash.setupState !== "running" && Stash.setupState !== "done"
                    compact: true
                    primary: true
                    text: Stash.setupState === "failed" ? I18n.tr("Retry setup") : I18n.tr("Set up")
                    onAct: Stash.startSetup()
                }
                Rectangle {
                    width: setupLabel.implicitWidth + Tokens.s4 * root.s
                    height: Tokens.ctlH * root.s
                    radius: Tokens.radius * root.s
                    color: Tokens.bone
                    visible: !root.crate && Stash.setupState !== "running" && Stash.setupState !== "done"
                    Text { id: setupLabel; anchors.centerIn: parent; text: Stash.setupState === "failed" ? I18n.tr("Retry setup") : I18n.tr("Set up"); color: Tokens.inkOnBone; font.family: Tokens.ui; font.pixelSize: Tokens.fSmall * root.s }
                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: Stash.startSetup() }
                }
            }
        }

        Column {
            width: parent.width
            visible: Stash.queueModel.count > 0
            spacing: Tokens.s1 * root.s
            TrackLabel {
                visible: root.crate
                text: I18n.tr("ACTIVE JOBS")
            }
            Text {
                visible: !root.crate
                text: I18n.tr("ACTIVE JOBS")
                color: Tokens.inkMuted
                font.family: Tokens.mono
                font.pixelSize: Tokens.fTiny * root.s
                font.letterSpacing: Tokens.trackLabel
            }
            Repeater {
                model: Stash.queueModel
                delegate: Rectangle {
                    id: queueRow
                    required property var model
                    required property int index
                    width: parent.width
                    implicitHeight: queueColumn.implicitHeight + Tokens.s3 * root.s * 2
                    objectName: "askToolsJob"
                    radius: Tokens.radius * root.s
                    color: root.crate ? "transparent" : Tokens.tint5
                    border.width: Tokens.border
                    border.color: root.crate ? (queueRow.model.state === "error" ? Tokens.alert : Tokens.line)
                        : queueRow.model.state === "error" ? Tokens.lineStrong : Tokens.lineSoft
                    Column {
                        id: queueColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: Tokens.s3 * root.s
                        spacing: Tokens.s2 * root.s
                        Row {
                            width: parent.width
                            spacing: Tokens.s2 * root.s
                            Text {
                                width: parent.width - queueActions.width - parent.spacing
                                text: queueRow.model.name || queueRow.model.arg
                                color: Tokens.ink
                                font.family: Tokens.ui
                                font.pixelSize: Tokens.fSmall * root.s
                                elide: Text.ElideMiddle
                            }
                            // Three affordances, one per row state. Cancel wears
                            // the close glyph on purpose: it is the same shape as
                            // "this row goes away", which is what pressing it
                            // means, rather than a new icon to learn.
                            Row {
                                id: queueActions
                                spacing: Tokens.s2 * root.s
                                IconButton {
                                    objectName: "askToolsJobCancel"
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: root.crate && (queueRow.model.state === "running" || queueRow.model.state === "queued")
                                    width: 28
                                    height: 28
                                    iconSize: 16
                                    glyph: "close"
                                    onClicked: Stash.cancelJob(queueRow.index)
                                }
                                IconButton {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: root.crate && (queueRow.model.state === "error" || queueRow.model.state === "cancelled")
                                    width: 28
                                    height: 28
                                    iconSize: 16
                                    glyph: "refresh"
                                    onClicked: Stash.retryJob(queueRow.index)
                                }
                                IconButton {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: root.crate && (queueRow.model.state === "done" || queueRow.model.state === "error" || queueRow.model.state === "cancelled")
                                    width: 28
                                    height: 28
                                    iconSize: 16
                                    glyph: "close"
                                    onClicked: Stash.dismissJob(queueRow.index)
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: !root.crate && (queueRow.model.state === "running" || queueRow.model.state === "queued")
                                    text: "close"
                                    color: cancelHover.hovered ? Tokens.ink : Tokens.inkMuted
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: Tokens.fBody * root.s
                                    HoverHandler { id: cancelHover; cursorShape: Qt.PointingHandCursor }
                                    TapHandler { onTapped: Stash.cancelJob(queueRow.index) }
                                }
                                // Retry re-queues whatever the row was, a stopped
                                // one included, so a cancel costs the place in
                                // the queue and nothing else.
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: !root.crate && (queueRow.model.state === "error" || queueRow.model.state === "cancelled")
                                    text: "refresh"
                                    color: retryHover.hovered ? Tokens.ink : Tokens.inkMuted
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: Tokens.fBody * root.s
                                    HoverHandler { id: retryHover; cursorShape: Qt.PointingHandCursor }
                                    TapHandler { onTapped: Stash.retryJob(queueRow.index) }
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: !root.crate && (queueRow.model.state === "done" || queueRow.model.state === "error" || queueRow.model.state === "cancelled")
                                    text: "close"
                                    color: dropHover.hovered ? Tokens.ink : Tokens.inkMuted
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: Tokens.fBody * root.s
                                    HoverHandler { id: dropHover; cursorShape: Qt.PointingHandCursor }
                                    TapHandler { onTapped: Stash.dismissJob(queueRow.index) }
                                }
                            }
                        }
                        Beam {
                            objectName: "askToolsJobBeam"
                            visible: root.crate && (queueRow.model.state === "running" || queueRow.model.state === "queued")
                            width: parent.width
                            interactive: false
                            indeterminate: queueRow.model.state === "queued"
                            value: Math.max(0, Math.min(1, Number(queueRow.model.pct || 0) / 100))
                        }
                        Rectangle {
                            visible: !root.crate && (queueRow.model.state === "running" || queueRow.model.state === "queued")
                            width: parent.width
                            height: 3 * root.s
                            radius: height / 2
                            color: Tokens.tint10
                            Rectangle {
                                width: parent.width * Math.max(0, Math.min(1, Number(queueRow.model.pct || 0) / 100))
                                height: parent.height
                                radius: parent.radius
                                color: Tokens.bone
                                Behavior on width { enabled: root.motionAllowed; NumberAnimation { duration: Tokens.move; easing.type: Tokens.ease } }
                            }
                        }
                        // A row that was stopped says so in the same quiet ink
                        // as one that is waiting: nothing went wrong, so it is
                        // not painted like a failure.
                        Text {
                            width: parent.width
                            text: queueRow.model.state === "running" ? queueRow.model.pct + "%"
                                : queueRow.model.state === "error" ? (queueRow.model.msg || I18n.tr("Failed"))
                                : queueRow.model.state === "done" ? I18n.tr("Done")
                                : queueRow.model.state === "cancelled" ? I18n.tr("Cancelled") : I18n.tr("Queued")
                            color: Tokens.inkMuted
                            font.family: Tokens.ui
                            font.pixelSize: Tokens.fTiny * root.s
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }

        Column {
            width: parent.width
            visible: root.installedOpen
            spacing: Tokens.s1 * root.s

            TrackLabel {
                visible: root.crate
                text: I18n.tr("INSTALLED THROUGH STASH")
            }
            Text {
                visible: !root.crate
                text: I18n.tr("INSTALLED THROUGH STASH")
                color: Tokens.inkMuted
                font.family: Tokens.mono
                font.pixelSize: Tokens.fTiny * root.s
                font.letterSpacing: Tokens.trackLabel
            }

            Text {
                width: parent.width
                text: I18n.tr("Uninstall removes the app and launcher. Your app data stays.")
                color: Tokens.inkMuted
                font.family: Tokens.ui
                font.pixelSize: Tokens.fTiny * root.s
                wrapMode: Text.WordWrap
            }

            Text {
                visible: Stash.installedState === "loading"
                text: I18n.tr("Reading installed apps…")
                color: Tokens.inkMuted
                font.family: Tokens.ui
                font.pixelSize: Tokens.fSmall * root.s
            }

            Text {
                visible: Stash.installedState === "ready" && Stash.installedModel.count === 0
                text: I18n.tr("No apps installed through Stash")
                color: Tokens.inkMuted
                font.family: Tokens.ui
                font.pixelSize: Tokens.fSmall * root.s
            }

            Text {
                visible: Stash.installedState === "error"
                text: I18n.tr("Couldn't read installed apps")
                color: Tokens.inkDim
                font.family: Tokens.ui
                font.pixelSize: Tokens.fSmall * root.s
            }

            Repeater {
                model: Stash.installedModel
                delegate: Rectangle {
                    id: installedRow
                    required property string appId
                    required property string label
                    width: parent.width
                    height: 44 * root.s
                    radius: Tokens.radius * root.s
                    color: root.crate ? "transparent" : installedHover.hovered ? Tokens.tint10 : "transparent"
                    border.width: Tokens.border
                    border.color: root.crate ? (installedHover.hovered ? Tokens.markHover : Tokens.line) : Tokens.lineSoft

                    Text {
                        anchors.left: parent.left
                        anchors.right: root.crate ? uninstallBtn.left : uninstallButton.left
                        anchors.leftMargin: Tokens.s3 * root.s
                        anchors.rightMargin: Tokens.s2 * root.s
                        anchors.verticalCenter: parent.verticalCenter
                        text: installedRow.label
                        color: Tokens.ink
                        font.family: Tokens.ui
                        font.pixelSize: Tokens.fSmall * root.s
                        elide: Text.ElideMiddle
                    }

                    Btn {
                        id: uninstallBtn
                        objectName: "askToolsUninstall"
                        visible: root.crate
                        anchors.right: parent.right
                        anchors.rightMargin: Tokens.s2 * root.s
                        anchors.verticalCenter: parent.verticalCenter
                        compact: true
                        primary: root.confirmUninstallId === installedRow.appId
                        armed: Stash.uninstallingId.length === 0
                        text: uninstallLabel.text
                        onAct: {
                            if (root.confirmUninstallId === installedRow.appId) {
                                root.confirmUninstallId = "";
                                Stash.uninstallApp(installedRow.appId);
                            } else {
                                root.confirmUninstallId = installedRow.appId;
                            }
                        }
                    }

                    Rectangle {
                        id: uninstallButton
                        visible: !root.crate
                        anchors.right: parent.right
                        anchors.rightMargin: Tokens.s2 * root.s
                        anchors.verticalCenter: parent.verticalCenter
                        width: uninstallLabel.implicitWidth + Tokens.s3 * root.s
                        height: Tokens.ctlH * root.s
                        radius: Tokens.radius * root.s
                        color: uninstallTap.pressed ? Tokens.tint16
                            : uninstallHover.hovered ? Tokens.tint10 : Tokens.tint5
                        border.width: Tokens.border
                        border.color: root.confirmUninstallId === installedRow.appId
                            ? Tokens.lineStrong : Tokens.lineSoft

                        Text {
                            id: uninstallLabel
                            anchors.centerIn: parent
                            text: Stash.uninstallingId === installedRow.appId ? I18n.tr("Removing…")
                                : root.confirmUninstallId === installedRow.appId ? I18n.tr("Confirm")
                                : I18n.tr("Uninstall")
                            color: Tokens.ink
                            font.family: Tokens.ui
                            font.pixelSize: Tokens.fTiny * root.s
                            font.weight: Font.DemiBold
                        }
                        HoverHandler { id: uninstallHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            id: uninstallTap
                            enabled: Stash.uninstallingId.length === 0
                            onTapped: {
                                if (root.confirmUninstallId === installedRow.appId) {
                                    root.confirmUninstallId = "";
                                    Stash.uninstallApp(installedRow.appId);
                                } else {
                                    root.confirmUninstallId = installedRow.appId;
                                }
                            }
                        }
                    }
                    HoverHandler { id: installedHover }
                }
            }
        }

        Column {
            width: parent.width
            visible: root.recentOpen
            spacing: Tokens.s1 * root.s
            Text {
                visible: Stash.recentFiles.length === 0
                text: I18n.tr("No recent downloads")
                color: Tokens.inkMuted
                font.family: Tokens.ui
                font.pixelSize: Tokens.fSmall * root.s
            }
            Repeater {
                model: Stash.recentFiles
                delegate: Rectangle {
                    id: recentRow
                    required property var modelData
                    width: parent.width
                    height: 38 * root.s
                    radius: Tokens.radius * root.s
                    color: root.crate ? "transparent"
                        : recentTap.pressed ? Tokens.tint16 : recentHover.hovered ? Tokens.tint10 : "transparent"
                    border.width: root.crate ? Tokens.border : 0
                    border.color: recentHover.hovered ? Tokens.markHover : "transparent"
                    Text {
                        anchors.left: parent.left
                        anchors.right: root.crate ? removeRecentIcon.left : removeRecent.left
                        anchors.leftMargin: Tokens.s3 * root.s
                        anchors.rightMargin: Tokens.s2 * root.s
                        anchors.verticalCenter: parent.verticalCenter
                        text: recentRow.modelData.name
                        color: Tokens.ink
                        font.family: Tokens.ui
                        font.pixelSize: Tokens.fSmall * root.s
                        elide: Text.ElideMiddle
                    }
                    IconButton {
                        id: removeRecentIcon
                        visible: root.crate
                        anchors.right: parent.right
                        anchors.rightMargin: Tokens.s1 * root.s
                        anchors.verticalCenter: parent.verticalCenter
                        width: 28
                        height: 28
                        iconSize: 16
                        glyph: "close"
                        onClicked: Stash.removeFile(recentRow.modelData.path)
                    }
                    Text {
                        id: removeRecent
                        visible: !root.crate
                        anchors.right: parent.right
                        anchors.rightMargin: Tokens.s3 * root.s
                        anchors.verticalCenter: parent.verticalCenter
                        text: "close"
                        color: Tokens.inkMuted
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: Tokens.fBody * root.s
                        TapHandler { onTapped: Stash.removeFile(recentRow.modelData.path) }
                    }
                    HoverHandler { id: recentHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        id: recentTap
                        onTapped: eventPoint => {
                            // under crate the remove button sits inside the row and keeps its own press
                            if (root.crate && removeRecentIcon.contains(removeRecentIcon.mapFromItem(recentRow, eventPoint.position)))
                                return;
                            Stash.openFile(recentRow.modelData.path);
                        }
                    }
                }
            }
        }
    }
}
