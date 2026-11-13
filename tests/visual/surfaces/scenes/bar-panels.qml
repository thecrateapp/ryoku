import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import "modules/bar/barstyles/qsbar/panels"

// Every QS Bar panel body side by side, each in a card at its panel's real width
// with the 16 px inset, fed stand-in data, to check they read as one family.
ShellRoot {
    QtObject {
        id: battery
        property bool hasReading: true
        property int percent: 67
        property bool charging: false
        property string status: "discharging"
        property string timeText: "2 h 30 min"
        property string powerRate: "9.3 W"
        property string sizeText: "49 Wh"
        property string healthText: "90 %"
        property string healthLabel: "Health"
        property int cycles: 175
        function statusTitle(s) { return "Discharging" }
    }
    QtObject {
        id: theme
        property int systemMemTotalMiB: 32768
        property int systemMemAvailMiB: 19456
        readonly property int systemMemUsedMiB: systemMemTotalMiB - systemMemAvailMiB
        property int memorySpeedMTs: 5600
        property string memoryType: "DDR5"
        property bool storageAvailable: true
        property bool storageInventoryAvailable: true
        property var storageDrives: [
            { model: "Samsung 990 PRO", state: "healthy", percent: 42, driveType: "nvme", media: "NVMe", fileSystems: "BTRFS",
              size: 1000000000000, usedBytes: 84 * 1073741824, freeBytes: 116 * 1073741824, totalBytes: 200 * 1073741824 }
        ]
        property string mono: "monospace"
    }
    QtObject {
        id: memory
        readonly property var root: theme
        readonly property bool visible: true
        readonly property int pct: Math.round(theme.systemMemUsedMiB / theme.systemMemTotalMiB * 100)
        readonly property int memTotal: theme.systemMemTotalMiB
        readonly property int memUsed: theme.systemMemUsedMiB
        readonly property int memAvail: theme.systemMemAvailMiB
    }
    QtObject {
        id: storage
        readonly property var root: theme
        readonly property int pct: 42
        readonly property real usedGiB: 84
        readonly property real freeGiB: 116
        readonly property real totalGiB: 200
        function formatGiB(b) { return (b / 1073741824).toFixed(0) + " GiB" }
        function formatFree(b) { return (b / 1073741824).toFixed(0) + " GiB free" }
        function formatCapacity(b) { return (b / 1e12).toFixed(1) + " TB" }
    }
    QtObject {
        id: mouse
        property string name: "MX Master 3"
        property string address: "AA:BB:CC:DD:EE:01"
        property string icon: "input-mouse"
        property bool connected: true
        property bool paired: true
        property bool bonded: true
    }
    QtObject {
        id: phones
        property string name: "Jabra Evolve"
        property string address: "AA:BB:CC:DD:EE:02"
        property string icon: "audio-headphones"
        property bool connected: false
        property bool paired: true
        property bool bonded: true
    }
    QtObject {
        id: btPanel
        property bool btOn: true
        property bool blocked: false
        property bool scanning: false
        property bool busy: false
        property int numConnected: 1
        property string pairError: ""
        property var shownDevices: [mouse, phones]
        property var forgotten: null
        property var activated: null
        function deviceLabel(dev) { return dev.name }
        function deviceStatus(dev) { return dev.connected ? "Connected" : "Paired" }
        function forgetDevice(dev) { forgotten = dev }
        function activateDevice(dev) { activated = dev }
        function toggleScan() {}
    }

    QtObject {
        id: speedObj
        property bool running: false
        property string phase: "success"
        property real pingMs: 14
        property real downloadMbps: 412
        property real uploadMbps: 96
    }
    QtObject {
        id: netPanel
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
        property var speed: speedObj
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


    component Card: Rectangle {
        default property alias body: inner.data
        property real cardWidth: 320
        width: cardWidth
        height: inner.childrenRect.height + 32
        radius: 10
        color: Tokens.popover
        border.width: 1
        border.color: Tokens.line
        Item { id: inner; x: 16; y: 16; width: parent.width - 32 }
    }

    FloatingWindow {
        implicitWidth: 1760
        implicitHeight: 900
        color: Tokens.paper

        Rectangle {
            id: sheet
            width: 1760
            height: 900
            color: Tokens.paper
            Row {
                x: 16; y: 16
                spacing: 16
                Card { cardWidth: 320; CrateBatteryDetails { width: parent.width; battery: battery } }
                Card { cardWidth: 320; CrateMemoryDetails { width: parent.width; memory: memory } }
                Card { cardWidth: 320; CrateStorageDetails { width: parent.width; storage: storage; availableHeight: 600 } }
                Card { cardWidth: 320; CrateBrightnessControls { width: parent.width; percent: 70 } }
            }
            Row {
                x: 16; y: 470
                spacing: 16
                Card { cardWidth: 320; CrateBluetoothDetails { width: parent.width; panel: btPanel } }
                Card { cardWidth: 320; CrateNetworkDetails { width: parent.width; panel: netPanel } }
            }
        }

        Timer {
            interval: Number(Quickshell.env("BENCH_WAIT") || 2000)
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
