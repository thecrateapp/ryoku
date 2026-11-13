import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import "modules/bar/barstyles/qsbar/panels"

// The QS Bar's crate network body with a stand-in panel: connected to Casa-5G
// after a speed test, three more networks nearby.
ShellRoot {
    QtObject {
        id: speed
        property bool running: false
        property string phase: "success"
        property real pingMs: 14
        property real downloadMbps: 412
        property real uploadMbps: 96
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
        property bool speedDetailsVisible: true
        property bool speedRunOk: true
        property var shownNetworks: [
            { ssid: "Casa-5G", conn: true, known: true, sec: "psk", sig: 82 },
            { ssid: "Estudio", conn: false, known: false, sec: "psk", sig: 71 },
            { ssid: "Café Lumen", conn: false, known: false, sec: "open", sig: 48 },
            { ssid: "Oficina", conn: false, known: true, sec: "psk", sig: 30 }
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

    FloatingWindow {
        implicitWidth: 360
        implicitHeight: 800
        color: Tokens.popover

        Rectangle {
            id: sheet
            width: 360
            height: details.implicitHeight + 40
            color: Tokens.popover
            CrateNetworkDetails { id: details; x: 20; y: 20; width: 320; panel: panel }
        }

        Timer {
            interval: Number(Quickshell.env("BENCH_WAIT") || 1500)
            running: true
            onTriggered: sheet.grabToImage(r => { r.saveToFile(Quickshell.env("BENCH_OUT")); Qt.quit(); })
        }

        Component.onCompleted: {
            const look = Quickshell.env("BENCH_CRATE");
            if (look === "1" || look === "0")
                Tokens.controlsCrate = look === "1";
        }
    }
}
