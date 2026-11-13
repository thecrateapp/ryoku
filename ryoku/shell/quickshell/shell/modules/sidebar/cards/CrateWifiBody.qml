pragma ComponentBehavior: Bound

import QtQuick
import shell.services
import Ryoku.Ui.Singletons
import Ryoku.Ui as Kit

// The Wi-Fi sheet under controls "crate", per the second mock-up: a sheet head
// (back, title, rescan, radio), a scanning sweep, the current network as the
// active row, the password form inline under the network it is for, the rest
// as list rows with their signal and one action, then hidden network and forget.
// It reads the page's state and calls its functions; the page owns the logic.
Column {
    id: body

    required property var page
    property real s: 1

    function focusPassword() { passwordField.grabFocus(); }
    function focusHidden() { hiddenSsidField.grabFocus(); }

    readonly property bool radioOn: Network.wifiPresent && Network.wifiRadio
    readonly property bool connected: Network.activeSsid !== ""
    readonly property var listed: body.page.pendingAp === null ? body.page.availableNets
        : body.page.availableNets.filter(ap => body.page.networkKey(ap) !== body.page.networkKey(body.page.pendingAp))

    function apSub(ap) {
        return (body.page.isOpen(ap) ? I18n.tr("Open") : String(ap.security || I18n.tr("Secure")))
            + (ap.saved ? " · " + I18n.tr("Saved") : "")
            + (body.page.multiBandSsids[ap.ssid] && ap.band ? " · " + I18n.tr("%1 GHz").arg(ap.band) : "")
            + " · " + (ap.strength || 0) + " %";
    }

    spacing: 12 * body.s

    Kit.SheetHeader {
        width: parent.width
        s: body.s
        title: I18n.tr("Wi-Fi")
        onBackRequested: body.page.backRequested()
        Kit.IconButton {
            width: 32 * body.s
            height: 32 * body.s
            iconSize: 18 * body.s
            glyph: "refresh"
            enabled: body.radioOn && !body.page.scanning
            Accessible.name: I18n.tr("Search for networks")
            onClicked: body.page.refresh()
        }
        Kit.Sw {
            anchors.verticalCenter: parent.verticalCenter
            on: Network.wifiRadio
            enabled: Network.wifiPresent
            Accessible.name: I18n.tr("Wi-Fi radio")
            onToggled: Network.setWifiEnabled(!Network.wifiRadio)
        }
    }

    Kit.Beam {
        visible: body.page.scanning
        width: parent.width
        height: 8 * body.s
        interactive: false
        indeterminate: true
    }

    // the current network, or why there is none
    Kit.ListRow {
        visible: body.radioOn && body.connected
        width: parent.width
        s: body.s
        on: true
        title: Network.activeSsid
        sub: Network.wifiConnectivity === "Connecting" ? I18n.tr("Connecting…")
            : I18n.tr("Connected · %1 %").arg(Network.wifi.strength || 0)
        leading: Component { Kit.SignalBars { strength: Network.wifi.strength || 0; on: true; s: body.s } }
        Kit.Btn {
            compact: true
            text: I18n.tr("Disconnect")
            onAct: Network.disconnectWifi()
        }
    }
    Row {
        visible: !body.radioOn || (!body.connected && !body.page.scanning && body.page.availableNets.length === 0)
        width: parent.width
        spacing: 14 * body.s
        Kit.Glyph {
            anchors.verticalCenter: parent.verticalCenter
            name: "wifi_off"
            size: 22 * body.s
            color: Tokens.inkMuted
        }
        Column {
            width: parent.width - 36 * body.s
            spacing: 2 * body.s
            Text {
                width: parent.width
                text: !Network.wifiPresent ? I18n.tr("No Wi-Fi hardware")
                    : !Network.wifiRadio ? I18n.tr("Wi-Fi is off") : I18n.tr("No networks found")
                color: Tokens.ink
                font.family: Tokens.ui
                font.pixelSize: 13 * body.s
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                text: !Network.wifiPresent ? I18n.tr("This machine has no available wireless adapter.")
                    : !Network.wifiRadio ? I18n.tr("Turn on the radio to search for nearby networks.")
                    : I18n.tr("Move closer to an access point, then search again.")
                color: Tokens.inkMuted
                font.family: Tokens.ui
                font.pixelSize: 11 * body.s
                wrapMode: Text.WordWrap
            }
        }
    }
    Kit.Btn {
        visible: Network.wifiPresent && !Network.wifiRadio
        anchors.right: parent.right
        primary: true
        text: I18n.tr("Turn on Wi-Fi")
        onAct: Network.setWifiEnabled(true)
    }

    // the network a password is being asked for, with the form inline
    Column {
        visible: body.page.pendingAp !== null
        width: parent.width
        spacing: 8 * body.s
        Kit.ListRow {
            width: parent.width
            s: body.s
            on: true
            title: body.page.pendingAp ? body.page.pendingAp.ssid : ""
            sub: body.page.pendingAp ? body.apSub(body.page.pendingAp) : ""
            leading: Component { Kit.SignalBars { strength: body.page.pendingAp ? body.page.pendingAp.strength || 0 : 0; on: true; s: body.s } }
        }
        Kit.Field {
            id: passwordField
            width: parent.width
            toolbar: true
            secret: true
            placeholder: I18n.tr("Password")
            onEdited: v => body.page.password = v
            onAccepted: body.page.submitPassword()
            onEscaped: if (!body.page.busy) body.page.clearForm()
        }
        Text {
            visible: body.page.errorText.length > 0
            width: parent.width
            text: body.page.errorText
            color: Tokens.alert
            font.family: Tokens.ui
            font.pixelSize: 11 * body.s
            wrapMode: Text.WordWrap
        }
        Row {
            anchors.right: parent.right
            spacing: 8 * body.s
            Kit.Btn { outline: true; text: I18n.tr("Cancel"); armed: !body.page.busy; onAct: body.page.clearForm() }
            Kit.Btn {
                primary: true
                text: body.page.busy ? I18n.tr("Connecting…") : I18n.tr("Connect")
                armed: !body.page.busy && body.page.password.length > 0
                onAct: body.page.submitPassword()
            }
        }
        Kit.Divider { width: parent.width; quiet: true }
    }

    // a hidden network, typed in
    Column {
        visible: body.page.hiddenForm
        width: parent.width
        spacing: 8 * body.s
        Kit.TrackLabel { text: I18n.tr("Hidden network") }
        Kit.Field {
            id: hiddenSsidField
            width: parent.width
            toolbar: true
            placeholder: I18n.tr("Network name (SSID)")
            onEdited: v => body.page.hiddenSsid = v
            onAccepted: hiddenPasswordField.grabFocus()
            onEscaped: if (!body.page.busy) body.page.clearForm()
        }
        Kit.Field {
            id: hiddenPasswordField
            width: parent.width
            toolbar: true
            secret: true
            placeholder: I18n.tr("Password (leave empty if open)")
            onEdited: v => body.page.password = v
            onAccepted: body.page.submitHidden()
            onEscaped: if (!body.page.busy) body.page.clearForm()
        }
        Text {
            visible: body.page.errorText.length > 0
            width: parent.width
            text: body.page.errorText
            color: Tokens.alert
            font.family: Tokens.ui
            font.pixelSize: 11 * body.s
            wrapMode: Text.WordWrap
        }
        Row {
            anchors.right: parent.right
            spacing: 8 * body.s
            Kit.Btn { outline: true; text: I18n.tr("Cancel"); armed: !body.page.busy; onAct: body.page.clearForm() }
            Kit.Btn {
                primary: true
                text: body.page.busy ? I18n.tr("Connecting…") : I18n.tr("Join")
                armed: !body.page.busy && body.page.hiddenSsid.trim().length > 0
                onAct: body.page.submitHidden()
            }
        }
        Kit.Divider { width: parent.width; quiet: true }
    }

    Item {
        visible: body.radioOn && body.listed.length > 0
        width: parent.width
        height: 20 * body.s
        Kit.TrackLabel {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: I18n.tr("Available networks")
        }
        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: body.page.scanning ? I18n.tr("Searching…") : String(body.listed.length)
            color: body.page.scanning ? Tokens.mark : Tokens.inkSubtle
            font.family: Tokens.mono
            font.pixelSize: 11 * body.s
            font.features: { "tnum": 1 }
        }
    }

    Column {
        visible: body.radioOn
        width: parent.width
        spacing: 6 * body.s
        Repeater {
            model: body.radioOn ? body.listed : []
            delegate: Kit.ListRow {
                id: apRow
                required property var modelData
                required property int index
                readonly property bool connecting: body.page.busy
                    && body.page.pendingKey === body.page.networkKey(apRow.modelData)
                width: parent ? parent.width : 0
                s: body.s
                quiet: apRow.index >= 4
                title: apRow.modelData.ssid
                sub: body.apSub(apRow.modelData)
                leading: Component { Kit.SignalBars { strength: apRow.modelData.strength || 0; s: body.s } }
                Kit.Btn {
                    compact: true
                    outline: true
                    text: apRow.connecting ? I18n.tr("Connecting…") : I18n.tr("Connect")
                    armed: !body.page.busy
                    onAct: body.page.choose(apRow.modelData)
                }
            }
        }
    }

    Row {
        visible: body.radioOn && !body.page.hiddenForm && body.page.pendingAp === null
        spacing: 8 * body.s
        Kit.Btn {
            compact: true
            text: I18n.tr("Hidden network")
            onAct: {
                body.page.pendingAp = null;
                body.page.hiddenForm = true;
                body.page.hiddenSsid = "";
                body.page.password = "";
                body.page.errorText = "";
                Qt.callLater(() => body.focusHidden());
            }
        }
        Kit.Btn {
            compact: true
            visible: body.connected
            text: I18n.tr("Forget %1").arg(Network.activeSsid)
            onAct: Network.forgetWifi(Network.activeSsid)
        }
    }

    // a cleared password (after a failed attempt) empties the fields too
    Connections {
        target: body.page
        function onPasswordChanged() {
            if (body.page.password === "") {
                passwordField.clear();
                hiddenPasswordField.clear();
            }
        }
        function onHiddenFormChanged() {
            if (!body.page.hiddenForm)
                hiddenSsidField.clear();
        }
    }
}
