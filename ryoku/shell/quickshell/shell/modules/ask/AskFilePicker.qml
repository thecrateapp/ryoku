pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Ryoku.Ui
import Ryoku.Ui.Singletons
import shell.services

Rectangle {
    id: root

    required property real s
    property bool open: false
    property string mode: "compress"
    property url folder: "file://" + home
    property var selected: ({})
    readonly property string home: Quickshell.env("HOME") || ""
    readonly property int selectedCount: Object.keys(selected).length
    readonly property bool motionAllowed: !Tokens.reduceMotion && !Motion.reduce
    // Under controls "crate" the picker is a hairline frame on the glass: files
    // are kit pick rows (picked when chosen), the actions kit buttons, the count
    // a tracked caption.
    readonly property bool crate: Tokens.controlsCrate

    signal cancelled()
    signal confirmed(var paths)

    implicitHeight: open ? 360 * s : 0
    visible: open && height > 0
    radius: Tokens.radius * s
    color: crate ? "transparent" : Tokens.paperLift
    border.width: Tokens.border
    border.color: crate ? Tokens.line : Tokens.lineStrong
    clip: true

    Behavior on implicitHeight {
        enabled: root.motionAllowed
        NumberAnimation { duration: Tokens.swap; easing.type: Tokens.ease }
    }

    onOpenChanged: {
        if (!open)
            return;
        selected = ({});
        folder = "file://" + home;
        Qt.callLater(refresh);
    }
    onFolderChanged: if (open) refresh()
    onModeChanged: if (open) refresh()

    function localFolder() {
        const value = String(folder).replace(/^file:\/\//, "");
        try { return decodeURIComponent(value); } catch (error) { return value; }
    }

    function accepts(name) {
        const lower = String(name).toLowerCase();
        const patterns = mode === "install"
            ? [".appimage", ".pkg.tar.zst", ".pkg.tar.xz", ".deb", ".rpm", ".flatpak", ".tar.gz", ".tgz", ".tar.xz", ".tar.zst", ".tar"]
            : [".mp4", ".mkv", ".webm", ".mov", ".avi", ".m4v", ".png", ".jpg", ".jpeg", ".webp", ".bmp", ".gif", ".tiff"];
        return patterns.some(pattern => lower.endsWith(pattern));
    }

    function refresh() {
        files.clear();
        scan.running = false;
        scan.command = ["find", localFolder(), "-mindepth", "1", "-maxdepth", "1", "-printf", "%y\\t%f\\t%p\\n"];
        scan.running = true;
    }

    function toggle(path) {
        const next = Object.assign({}, selected);
        if (next[path]) delete next[path]; else next[path] = true;
        selected = next;
    }

    function goUp() {
        const current = String(folder);
        if (current === "file:///")
            return;
        folder = current.replace(/\/[^/]+\/?$/, "") || "file:///";
    }

    ListModel { id: files }

    Process {
        id: scan
        stdout: StdioCollector {
            onStreamFinished: {
                const rows = [];
                const lines = String(this.text).split("\n");
                for (let i = 0; i < lines.length; i++) {
                    const fields = lines[i].split("\t");
                    if (fields.length < 3)
                        continue;
                    const directory = fields[0] === "d";
                    const name = fields[1];
                    const path = fields.slice(2).join("\t");
                    if (name.charAt(0) === "." || (!directory && !root.accepts(name)))
                        continue;
                    rows.push({ fileName: name, filePath: path, fileIsDir: directory });
                }
                rows.sort((a, b) => a.fileIsDir !== b.fileIsDir ? (a.fileIsDir ? -1 : 1) : a.fileName.localeCompare(b.fileName));
                files.clear();
                rows.forEach(row => files.append(row));
            }
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: Tokens.s4 * root.s
        spacing: Tokens.s2 * root.s

        Item {
            width: parent.width
            height: 34 * root.s
            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: root.mode === "install" ? I18n.tr("Choose package files") : I18n.tr("Choose files to compress")
                color: Tokens.ink
                font.family: Tokens.ui
                font.pixelSize: Tokens.fRow * root.s
                font.weight: Font.DemiBold
            }
            TrackLabel {
                objectName: "askPickerCount"
                visible: root.crate
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: root.selectedCount === 0 ? I18n.tr("None selected") : I18n.tr("%1 selected").arg(root.selectedCount)
                tone: root.selectedCount > 0 ? "active" : "subtle"
            }
            Text {
                visible: !root.crate
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: root.selectedCount === 0 ? I18n.tr("None selected") : I18n.tr("%1 selected").arg(root.selectedCount)
                color: Tokens.inkMuted
                font.family: Tokens.mono
                font.pixelSize: Tokens.fTiny * root.s
            }
        }

        Rectangle {
            width: parent.width
            height: 32 * root.s
            radius: Tokens.radius * root.s
            color: root.crate ? "transparent"
                : folderTap.pressed ? Tokens.tint16 : folderHover.hovered ? Tokens.tint10 : Tokens.tint5
            border.width: Tokens.border
            border.color: root.crate ? (folderHover.hovered ? Tokens.markHover : Tokens.line) : Tokens.lineSoft
            Glyph {
                visible: root.crate
                anchors.left: parent.left
                anchors.leftMargin: Tokens.s3 * root.s
                anchors.verticalCenter: parent.verticalCenter
                name: "arrow_upward"
                size: 16
                color: folderHover.hovered ? Tokens.mark : Tokens.inkSecondary
            }
            Text {
                visible: !root.crate
                anchors.left: parent.left
                anchors.leftMargin: Tokens.s3 * root.s
                anchors.verticalCenter: parent.verticalCenter
                text: "arrow_upward"
                color: Tokens.inkMuted
                font.family: "Material Symbols Rounded"
                font.pixelSize: Tokens.fBody * root.s
            }
            Text {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 40 * root.s
                anchors.rightMargin: Tokens.s3 * root.s
                anchors.verticalCenter: parent.verticalCenter
                text: String(root.folder).replace("file://" + root.home, "~").replace("file://", "")
                color: Tokens.inkDim
                font.family: Tokens.mono
                font.pixelSize: Tokens.fTiny * root.s
                elide: Text.ElideLeft
            }
            HoverHandler { id: folderHover; cursorShape: Qt.PointingHandCursor }
            TapHandler { id: folderTap; onTapped: root.goUp() }
        }

        ListView {
            id: list
            width: parent.width
            height: parent.height - y - (root.crate ? crateFooter.height : footer.height) - parent.spacing
            clip: true
            model: files
            spacing: Tokens.s1 * root.s
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollRail { policy: ScrollBar.AsNeeded; visible: list.contentHeight > list.height + 1; motionEnabled: root.motionAllowed }
            delegate: Rectangle {
                id: fileRow
                required property string fileName
                required property string filePath
                required property bool fileIsDir
                readonly property bool chosen: !fileIsDir && root.selected[filePath] === true
                width: ListView.view ? ListView.view.width : 0
                height: root.crate ? 40 : 38 * root.s
                radius: Tokens.radius * root.s
                color: root.crate ? "transparent"
                    : chosen ? Tokens.bone : fileTap.pressed ? Tokens.tint16 : fileHover.hovered ? Tokens.tint10 : "transparent"
                border.width: root.crate ? 0 : Tokens.border
                border.color: chosen ? Tokens.bone : Tokens.lineSoft
                PickRow {
                    objectName: "askPickerRow"
                    visible: root.crate
                    anchors.fill: parent
                    glyph: fileRow.fileIsDir ? "folder" : root.mode === "install" ? "deployed_code" : "draft"
                    glyphFont: "Material Symbols Rounded"
                    title: fileRow.fileName
                    picked: fileRow.chosen
                    onClicked: fileRow.fileIsDir ? (root.folder = "file://" + fileRow.filePath) : root.toggle(fileRow.filePath)
                }
                Text {
                    visible: !root.crate
                    anchors.left: parent.left
                    anchors.leftMargin: Tokens.s3 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    text: fileRow.fileIsDir ? "folder" : root.mode === "install" ? "deployed_code" : "draft"
                    color: fileRow.chosen ? Tokens.inkOnBone : Tokens.inkMuted
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: Tokens.fBody * root.s
                }
                Text {
                    visible: !root.crate
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 42 * root.s
                    anchors.rightMargin: 36 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    text: fileRow.fileName
                    color: fileRow.chosen ? Tokens.inkOnBone : Tokens.ink
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fSmall * root.s
                    elide: Text.ElideMiddle
                }
                Text {
                    visible: !root.crate
                    anchors.right: parent.right
                    anchors.rightMargin: Tokens.s3 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    text: fileRow.fileIsDir ? "chevron_right" : fileRow.chosen ? "check" : "circle"
                    color: fileRow.chosen ? Tokens.inkOnBone : Tokens.inkFaint
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: Tokens.fBody * root.s
                }
                HoverHandler { id: fileHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { id: fileTap; enabled: !root.crate; onTapped: fileRow.fileIsDir ? (root.folder = "file://" + fileRow.filePath) : root.toggle(fileRow.filePath) }
            }
        }

        Item {
            id: crateFooter
            visible: root.crate
            width: parent.width
            height: cancelBtn.implicitHeight
            Btn {
                id: cancelBtn
                objectName: "askPickerCancel"
                anchors.left: parent.left
                compact: true
                text: I18n.tr("Cancel")
                onAct: root.cancelled()
            }
            Btn {
                objectName: "askPickerConfirm"
                anchors.right: parent.right
                compact: true
                primary: true
                armed: root.selectedCount > 0
                text: root.mode === "install" ? I18n.tr("Install") : I18n.tr("Compress")
                onAct: root.confirmed(Object.keys(root.selected))
            }
        }

        Row {
            id: footer
            visible: !root.crate
            width: parent.width
            spacing: Tokens.s2 * root.s
            Rectangle {
                width: cancelLabel.implicitWidth + Tokens.s4 * root.s
                height: Tokens.ctlH * root.s
                radius: Tokens.radius * root.s
                color: cancelTap.pressed ? Tokens.tint16 : cancelHover.hovered ? Tokens.tint10 : Tokens.tint5
                border.width: Tokens.border
                border.color: Tokens.lineStrong
                Text { id: cancelLabel; anchors.centerIn: parent; text: I18n.tr("Cancel"); color: Tokens.inkDim; font.family: Tokens.ui; font.pixelSize: Tokens.fSmall * root.s }
                HoverHandler { id: cancelHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { id: cancelTap; onTapped: root.cancelled() }
            }
            Item { width: Math.max(0, parent.width - cancelLabel.implicitWidth - confirm.width - 48 * root.s); height: 1 }
            Rectangle {
                id: confirm
                width: confirmLabel.implicitWidth + Tokens.s4 * root.s
                height: Tokens.ctlH * root.s
                radius: Tokens.radius * root.s
                color: root.selectedCount > 0 ? Tokens.bone : Tokens.tint5
                opacity: root.selectedCount > 0 ? 1 : 0.5
                Text {
                    id: confirmLabel
                    anchors.centerIn: parent
                    text: root.mode === "install" ? I18n.tr("Install") : I18n.tr("Compress")
                    color: root.selectedCount > 0 ? Tokens.inkOnBone : Tokens.inkMuted
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fSmall * root.s
                }
                HoverHandler { enabled: root.selectedCount > 0; cursorShape: Qt.PointingHandCursor }
                TapHandler { enabled: root.selectedCount > 0; onTapped: root.confirmed(Object.keys(root.selected)) }
            }
        }
    }
}
