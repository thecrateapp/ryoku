import QtQuick
import Quickshell
import Ryoku.Ui.Singletons

// Drives the QS Bar's crate network body with a stand-in panel: the current
// network leads, the list shows available networks, forget asks twice, the
// NetworkManager password shows inline, and a blocked radio hides the list.
ShellRoot {
    QtObject {
        id: speed
        property bool running: false
        property string phase: "idle"
        property real pingMs: 0
        property real downloadMbps: 0
        property real uploadMbps: 0
    }
    QtObject {
        id: panel
        property string mode: "wifi"
        property string ssid: "Casa-5G"
        property int signal: 82
        property string iface: "wlan0"
        property string ipAddr: "192.168.1.20"
        property string freq: "5 GHz"
        property string linkSpeed: "866 Mb/s"
        property bool hasWifi: true
        property bool wifiBlocked: false
        property bool useNM: false
        property bool nmAdapterReady: false
        property bool scanning: false
        property bool savedOnly: false
        property int savedCount: 1
        property string pendingForgetKey: ""
        property string nmPasswordSsid: ""
        property string nmPasswordText: ""
        property string nmConnectionError: ""
        property bool nmConnecting: false
        property string networkActionError: ""
        property bool hiddenOpen: false
        property string hiddenSsid: ""
        property string hiddenPassword: ""
        property bool hiddenConnecting: false
        property bool hiddenError: false
        property var speed: speed
        property bool speedDetailsVisible: false
        property bool speedRunOk: false
        property var shownNetworks: [
            { ssid: "Casa-5G", conn: true, known: true, sec: "psk", sig: 82 },
            { ssid: "Estudio", conn: false, known: false, sec: "psk", sig: 71 }
        ]
        property var activated: null
        function networkKey(e) { return e ? "ssid:" + e.ssid : "" }
        function protectionLabel(e) { return e.sec === "open" ? "Open" : "PSK" }
        function isNeverConnected(e) { return false }
        function edgeText() { return "MAD" }
        function formatPing(v) { return v + " ms" }
        function formatMbps(v) { return v + " Mb/s" }
        function scan() {}
        function toggleWifi() { wifiBlocked = !wifiBlocked }
        function activateNetwork(e) { activated = e }
        function requestForget(e) {
            const key = networkKey(e);
            pendingForgetKey = pendingForgetKey === key ? "" : key;
        }
        function cancelForget() { pendingForgetKey = "" }
        function submitNmPassword() {}
        function clearNmPassword() { nmPasswordSsid = "" }
        function forgetPasswordNetwork() { nmPasswordSsid = "" }
        function openHidden() { hiddenOpen = true }
        function cancelHidden() { hiddenOpen = false }
        function submitHidden() {}
        function toggleSpeedTest() {}
    }

    Item {
        width: 320
        height: 700
        CrateNetworkDetails { id: details; width: 320; panel: panel }
    }

    function find(item, name) {
        if (!item) return null;
        if (item.objectName === name) return item;
        for (const child of item.children) {
            const hit = find(child, name);
            if (hit) return hit;
        }
        return null;
    }

    Timer {
        interval: 100
        running: true
        onTriggered: {
            Tokens.controlsCrate = true;
            if (!find(details, "netCurrent").visible)
                throw new Error("The current network must lead the panel");
            const list = find(details, "netList");
            if (!list || list.count !== 2)
                throw new Error("Both networks must list, got " + (list ? list.count : "none"));
            if (!list.itemAt(0).on || list.itemAt(1).on)
                throw new Error("Only the connected network takes the active row");
            panel.requestForget(panel.shownNetworks[0]);
            if (!list.itemAt(0).confirming)
                throw new Error("Forget must ask before it forgets");
            panel.nmPasswordSsid = "Estudio";
            if (!find(details, "netPassword").visible)
                throw new Error("The password must show inline");
            panel.wifiBlocked = true;
            if (list.count !== 0 || !find(details, "netWifiOff").visible)
                throw new Error("A blocked radio must hide the list and say so");
            console.log("NETWORK-DETAILS-PROBE-PASS");
            Qt.quit();
        }
    }
}
