pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons

// The QS Bar network panel under controls "crate": the Controls Wi-Fi sheet's
// language at panel size. A tracked head (rescan, the Wi-Fi radio, close); the
// current connection as the active ListRow with its link details and an optional
// speed test as key/value MeterRows; available and saved networks as ListRows
// (forget asks twice); the NetworkManager password and the hidden network inline;
// then network settings. It reads the panel and calls its functions, so a probe
// can drive it with a stand-in panel.
Column {
    id: details

    required property var panel
    signal closeRequested()
    signal settingsRequested()

    function focusPassword() { passwordField.grabFocus(); }
    function clearPassword() { passwordField.clear(); }
    function focusHidden() { hiddenSsidField.grabFocus(); }

    readonly property bool wifiOn: details.panel.hasWifi && !details.panel.wifiBlocked
    readonly property bool listUsable: details.wifiOn && (!details.panel.useNM || details.panel.nmAdapterReady)
    readonly property var speed: details.panel.speed

    spacing: Tokens.s3

    CrateResourceHeader {
        width: parent.width
        title: I18n.tr("Network")
        closeObjectName: "closeNetwork"
        onCloseRequested: details.closeRequested()
        Kit.IconButton {
            objectName: "netScan"
            visible: details.listUsable
            width: 32
            height: 32
            glyph: "refresh"
            on: details.panel.scanning
            Accessible.name: I18n.tr("Search for networks")
            onClicked: details.panel.scan()
        }
        Kit.Sw {
            objectName: "netRadio"
            visible: details.panel.hasWifi
            anchors.verticalCenter: parent.verticalCenter
            on: !details.panel.wifiBlocked
            Accessible.name: I18n.tr("Wi-Fi radio")
            onToggled: details.panel.toggleWifi()
        }
    }

    Kit.Beam {
        visible: details.panel.scanning
        width: parent.width
        height: 8
        interactive: false
        indeterminate: true
    }

    // the current connection
    Kit.ListRow {
        objectName: "netCurrent"
        visible: details.panel.mode !== "none"
        width: parent.width
        on: true
        title: details.panel.mode === "wifi" ? details.panel.ssid : I18n.tr("Ethernet")
        sub: [details.panel.mode === "wifi" ? details.panel.signal + " %" : I18n.tr("Connected"),
              details.panel.freq, details.panel.ipAddr].filter(part => part && part.length > 0).join(" · ")
        glyph: details.panel.mode === "wifi" ? "" : "lan"
        leading: details.panel.mode === "wifi"
            ? currentBars : null
        Component { id: currentBars; Kit.SignalBars { strength: details.panel.signal; on: true } }
    }
    Text {
        objectName: "netOffline"
        visible: details.panel.mode === "none"
        width: parent.width
        text: I18n.tr("Offline")
        color: Tokens.inkMuted
        font.family: Tokens.ui
        font.pixelSize: 12
    }

    // each group of key/value rows shares its widest caption
    Column {
        id: linkRows
        visible: details.panel.mode !== "none"
        width: parent.width
        readonly property real captionWidth: Math.max(ifaceRow.labelImplicitWidth, linkRow.labelImplicitWidth, edgeRow.labelImplicitWidth)
        Kit.InfoRow { id: ifaceRow; width: parent.width; labelWidth: linkRows.captionWidth; label: I18n.tr("Interface"); valueText: details.panel.iface || "—" }
        Kit.InfoRow { id: linkRow; visible: details.panel.linkSpeed !== ""; width: parent.width; labelWidth: linkRows.captionWidth; label: I18n.tr("Link"); valueText: details.panel.linkSpeed }
        Kit.InfoRow { id: edgeRow; width: parent.width; labelWidth: linkRows.captionWidth; label: I18n.tr("Edge"); valueText: details.panel.edgeText() }
    }

    // the optional speed test
    Item {
        visible: details.speed !== null && details.speed !== undefined
        width: parent.width
        height: 28
        Kit.TrackLabel {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: I18n.tr("Speed test")
        }
        Kit.Btn {
            objectName: "netSpeed"
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            compact: true
            outline: true
            armed: details.speed && (details.speed.running || details.panel.mode !== "none")
            text: details.speed && details.speed.running ? I18n.tr("Stop") : I18n.tr("Start")
            onAct: details.panel.toggleSpeedTest()
        }
    }
    Column {
        id: speedRows
        visible: details.panel.speedDetailsVisible
        width: parent.width
        readonly property real captionWidth: Math.max(pingRow.labelImplicitWidth, downRow.labelImplicitWidth, upRow.labelImplicitWidth)
        Kit.InfoRow {
            id: pingRow
            labelWidth: speedRows.captionWidth
            width: parent.width
            label: I18n.tr("Ping")
            valueText: details.speed && details.speed.phase === "latency" ? I18n.tr("Testing…")
                : details.panel.speedRunOk ? details.panel.formatPing(details.speed.pingMs) : "—"
        }
        Kit.InfoRow {
            id: downRow
            labelWidth: speedRows.captionWidth
            width: parent.width
            label: I18n.tr("Download")
            valueText: details.speed && details.speed.phase === "download" ? I18n.tr("Testing…")
                : details.panel.speedRunOk ? details.panel.formatMbps(details.speed.downloadMbps) : "—"
        }
        Kit.InfoRow {
            id: upRow
            labelWidth: speedRows.captionWidth
            width: parent.width
            label: I18n.tr("Upload")
            valueText: details.speed && details.speed.phase === "upload" ? I18n.tr("Testing…")
                : details.panel.speedRunOk ? details.panel.formatMbps(details.speed.uploadMbps) : "—"
        }
    }

    Kit.Divider { width: parent.width; quiet: true }

    Text {
        objectName: "netWifiOff"
        visible: details.panel.hasWifi && details.panel.wifiBlocked
        width: parent.width
        text: I18n.tr("Wi-Fi is off")
        color: Tokens.inkMuted
        font.family: Tokens.ui
        font.pixelSize: 12
    }
    Text {
        visible: details.wifiOn && details.panel.useNM && !details.panel.nmAdapterReady
        width: parent.width
        text: I18n.tr("Managed by NetworkManager. Open the network settings to choose a network.")
        color: Tokens.inkMuted
        font.family: Tokens.ui
        font.pixelSize: 12
        wrapMode: Text.WordWrap
    }

    // the NetworkManager password, asked for in place
    Column {
        objectName: "netPassword"
        visible: details.panel.nmPasswordSsid !== ""
        width: parent.width
        spacing: Tokens.s2
        Kit.TrackLabel { text: I18n.tr("Password for %1").arg(details.panel.nmPasswordSsid) }
        Kit.Field {
            id: passwordField
            width: parent.width
            toolbar: true
            secret: true
            placeholder: I18n.tr("Password")
            onEdited: v => details.panel.nmPasswordText = v
            onAccepted: details.panel.submitNmPassword()
            onEscaped: details.panel.clearNmPassword()
        }
        Text {
            visible: details.panel.nmConnectionError !== ""
            width: parent.width
            text: details.panel.nmConnectionError
            color: Tokens.alert
            font.family: Tokens.ui
            font.pixelSize: 11
            wrapMode: Text.WordWrap
        }
        Row {
            anchors.right: parent.right
            spacing: Tokens.s2
            Kit.Btn { compact: true; text: I18n.tr("Forget"); onAct: details.panel.forgetPasswordNetwork() }
            Kit.Btn { compact: true; outline: true; text: I18n.tr("Cancel"); onAct: details.panel.clearNmPassword() }
            Kit.Btn {
                compact: true
                primary: true
                text: details.panel.nmConnecting ? I18n.tr("Connecting…") : I18n.tr("Connect")
                armed: !details.panel.nmConnecting && details.panel.nmPasswordText !== ""
                onAct: details.panel.submitNmPassword()
            }
        }
    }

    // available or saved networks
    Row {
        visible: details.listUsable
        spacing: Tokens.s2
        Kit.Chip {
            objectName: "netAvailable"
            text: I18n.tr("Available")
            on: !details.panel.savedOnly
            onClicked: { details.panel.savedOnly = false; details.panel.scan(); }
        }
        Kit.Chip {
            objectName: "netSaved"
            text: details.panel.savedCount > 0 ? I18n.tr("Saved · %1").arg(details.panel.savedCount) : I18n.tr("Saved")
            on: details.panel.savedOnly
            onClicked: details.panel.savedOnly = true
        }
    }

    Flickable {
        visible: details.listUsable
        width: parent.width
        height: Math.min(netList.implicitHeight, 260)
        contentHeight: netList.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        Column {
            id: netList
            width: parent.width
            spacing: 6
            Repeater {
                objectName: "netList"
                model: details.listUsable ? details.panel.shownNetworks : []
                delegate: Kit.ListRow {
                    id: net
                    required property var modelData
                    required property int index
                    readonly property bool confirming: details.panel.pendingForgetKey === details.panel.networkKey(net.modelData)
                    width: netList.width
                    on: !!net.modelData.conn
                    quiet: !net.modelData.conn && net.index >= 4
                    title: net.modelData.ssid || ""
                    sub: details.panel.protectionLabel(net.modelData)
                        + (details.panel.isNeverConnected(net.modelData) ? " · " + I18n.tr("Never connected")
                            : net.modelData.known ? " · " + I18n.tr("Saved") : "")
                        + (net.modelData.sig !== undefined ? " · " + net.modelData.sig + " %" : "")
                    leading: Component { Kit.SignalBars { strength: net.modelData.sig || 0; on: !!net.modelData.conn } }
                    Kit.IconButton {
                        visible: !!net.modelData.known
                        width: 28
                        height: 28
                        iconSize: 16
                        glyph: "delete"
                        alert: net.confirming
                        Accessible.name: net.confirming ? I18n.tr("Confirm forget") : I18n.tr("Forget")
                        onClicked: details.panel.requestForget(net.modelData)
                    }
                    Kit.Btn {
                        compact: true
                        outline: !net.modelData.conn
                        text: net.confirming ? I18n.tr("Cancel")
                            : net.modelData.conn ? I18n.tr("Disconnect")
                            : net.modelData.known ? I18n.tr("Connect") : I18n.tr("Join")
                        onAct: {
                            if (net.confirming) details.panel.cancelForget();
                            else details.panel.activateNetwork(net.modelData);
                        }
                    }
                }
            }
        }
    }
    Text {
        visible: details.listUsable && details.panel.shownNetworks.length === 0
        width: parent.width
        text: details.panel.savedOnly ? I18n.tr("No saved networks") : I18n.tr("No networks found")
        color: Tokens.inkMuted
        font.family: Tokens.ui
        font.pixelSize: 12
    }
    Text {
        visible: details.panel.networkActionError !== ""
        width: parent.width
        text: details.panel.networkActionError
        color: Tokens.alert
        font.family: Tokens.ui
        font.pixelSize: 11
        wrapMode: Text.WordWrap
    }

    // a hidden network, typed in
    Kit.Btn {
        visible: details.wifiOn && !details.panel.hiddenOpen && details.panel.nmPasswordSsid === ""
        compact: true
        text: I18n.tr("Hidden network")
        onAct: details.panel.openHidden()
    }
    Column {
        objectName: "netHidden"
        visible: details.panel.hiddenOpen
        width: parent.width
        spacing: Tokens.s2
        Kit.TrackLabel { text: I18n.tr("Hidden network") }
        Kit.Field {
            id: hiddenSsidField
            width: parent.width
            toolbar: true
            placeholder: I18n.tr("Network name (SSID)")
            onEdited: v => details.panel.hiddenSsid = v
            onAccepted: hiddenPasswordField.grabFocus()
            onEscaped: details.panel.cancelHidden()
        }
        Kit.Field {
            id: hiddenPasswordField
            width: parent.width
            toolbar: true
            secret: true
            placeholder: I18n.tr("Password (leave empty if open)")
            onEdited: v => details.panel.hiddenPassword = v
            onAccepted: details.panel.submitHidden()
            onEscaped: details.panel.cancelHidden()
        }
        Text {
            visible: details.panel.hiddenError
            width: parent.width
            text: I18n.tr("Could not connect")
            color: Tokens.alert
            font.family: Tokens.ui
            font.pixelSize: 11
        }
        Row {
            anchors.right: parent.right
            spacing: Tokens.s2
            Kit.Btn { compact: true; outline: true; text: I18n.tr("Cancel"); onAct: details.panel.cancelHidden() }
            Kit.Btn {
                compact: true
                primary: true
                text: details.panel.hiddenConnecting ? I18n.tr("Connecting…") : I18n.tr("Join")
                armed: details.panel.hiddenSsid !== "" && !details.panel.hiddenConnecting
                onAct: details.panel.submitHidden()
            }
        }
    }

    Kit.Btn {
        objectName: "netSettings"
        width: parent.width
        outline: true
        text: I18n.tr("Network settings")
        onAct: details.settingsRequested()
    }

    // a cleared field on the panel empties the crate field too
    Connections {
        target: details.panel
        function onHiddenOpenChanged() {
            if (!details.panel.hiddenOpen) {
                hiddenSsidField.clear();
                hiddenPasswordField.clear();
            }
        }
        function onNmPasswordSsidChanged() {
            if (details.panel.nmPasswordSsid === "")
                passwordField.clear();
        }
    }
}
