pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import "../../shared/Singletons"
import Ryoku.Ui.Singletons
import Ryoku.Ui
import "." as HeroVariant

Item {
    id: root

    property real s: 1
    property bool open: false
    property bool animationsEnabled: true
    property var entry: null
    property bool focusActive: false
    property string focusedAddress: ""
    property int focusSerial: 0
    property string observedEntryKey: ""

    signal focusRequested(string address)

    readonly property bool crate: Tokens.controlsCrate

    readonly property var windows: {
        void Wm.windows;
        var result = root.entry;
        if (!result || !root.open || String(result.type || "") !== "App")
            return [];

        var wantedAddress = String(result.windowAddress || "");
        var wantedId = String(result.appId || result.id || "")
            .toLowerCase().replace(/\.desktop$/, "");
        var wantedTitle = String(result.title || "").toLowerCase();
        var wantedTokens = wantedTitle.split(/[^a-z0-9]+/).filter(
            token => token.length > 2);
        var values = Wm.windows || [];
        var out = [];
        for (var index = 0; index < values.length; index++) {
            var w = values[index];
            if (!w || !w.id)
                continue;
            var address = String(w.id);
            var cls = String(w.appId || "");
            var lowerClass = cls.toLowerCase();
            var lowerTitle = String(w.title || "").toLowerCase();
            var exactWindow = wantedAddress.length > 0
                && address === wantedAddress;
            var exactId = wantedId.length > 0
                && (lowerClass === wantedId
                    || lowerClass.split(".").pop() === wantedId);
            var titleMatch = wantedTokens.some(token =>
                lowerClass.indexOf(token) >= 0 || lowerTitle.indexOf(token) >= 0);
            if (exactWindow || exactId || titleMatch) {
                out.push({
                    address: address,
                    title: String(w.title || cls || I18n.tr("OPEN WINDOW")),
                    cls: cls,
                    workspace: String(w.workspace || I18n.tr("CURRENT"))
                });
            }
        }
        return out.slice(0, 6);
    }

    readonly property bool hasWindows: windows.length > 0
    readonly property int windowCount: windows.length
    readonly property var windowAddresses: windows.map(window => window.address)
    // Leave a real breathing gap below the ledger: the rail reads as a small
    // overview floater, not a continuation of the result list.
    readonly property real targetHeight: open && hasWindows ? 96 * s : 0

    implicitHeight: targetHeight
    height: targetHeight
    clip: true

    Behavior on height {
        enabled: root.animationsEnabled
        NumberAnimation { duration: Motion.drawer; easing.type: Easing.OutCubic }
    }

    function resetFocus() {
        focusedAddress = windows.length > 0 ? String(windows[0].address) : "";
        if (focusedAddress.length > 0)
            focusRequested(focusedAddress);
    }

    function resetForEntry() {
        var next = entry ? String(entry.resultKey || entry.id || "") : "";
        if (next === observedEntryKey)
            return;
        observedEntryKey = next;
        resetFocus();
    }

    function focusRelative(delta) {
        if (windows.length === 0)
            return;
        var current = -1;
        for (var index = 0; index < windows.length; index++)
            if (String(windows[index].address) === focusedAddress)
                current = index;
        var next = current < 0 ? 0 : (current + delta + windows.length)
            % windows.length;
        focusedAddress = String(windows[next].address);
        focusSerial++;
        focusRequested(focusedAddress);
    }

    onEntryChanged: resetForEntry()
    onWindowsChanged: {
        if (focusedAddress.length === 0 && windows.length > 0)
            resetFocus();
    }

    Item {
        id: railHeader
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 20 * root.s
        anchors.leftMargin: 8 * root.s
        anchors.rightMargin: 8 * root.s

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: root.windows.length === 1
                ? I18n.tr("OPEN WINDOWS  /  %1 WINDOW").arg(root.windows.length)
                : I18n.tr("OPEN WINDOWS  /  %1 WINDOWS").arg(root.windows.length)
            visible: !root.crate
            color: Theme.subtle
            font.family: Theme.mono
            font.pixelSize: 7.5 * root.s
            font.weight: Font.DemiBold
            font.letterSpacing: 0.8 * root.s
        }

        TrackLabel {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            visible: root.crate
            text: root.windows.length === 1
                ? I18n.tr("OPEN WINDOWS  /  %1 WINDOW").arg(root.windows.length)
                : I18n.tr("OPEN WINDOWS  /  %1 WINDOWS").arg(root.windows.length)
        }

        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.focusActive
                ? I18n.tr("LEFT / RIGHT  ·  ENTER  SWITCH")
                : I18n.tr("TAB  ·  FOCUS WINDOWS")
            visible: !root.crate
            color: root.focusActive ? Theme.bright : Theme.faint
            font.family: Theme.mono
            font.pixelSize: 7 * root.s
            font.letterSpacing: 0.5 * root.s
        }

        TrackLabel {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: root.crate
            tone: root.focusActive ? "active" : "subtle"
            text: root.focusActive
                ? I18n.tr("LEFT / RIGHT  ·  ENTER  SWITCH")
                : I18n.tr("TAB  ·  FOCUS WINDOWS")
        }
    }

    ListView {
        id: windowList
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: railHeader.bottom
        anchors.bottom: parent.bottom
        anchors.leftMargin: 8 * root.s
        anchors.rightMargin: 8 * root.s
        orientation: ListView.Horizontal
        spacing: 7 * root.s
        clip: true
        model: root.windows
        boundsBehavior: Flickable.StopAtBounds

        delegate: HeroVariant.WindowTile {
            required property var modelData
            s: root.s
            title: modelData.title
            cls: modelData.cls
            workspace: modelData.workspace
            picked: String(modelData.address) === root.focusedAddress
                && root.focusActive
        }
    }
}
