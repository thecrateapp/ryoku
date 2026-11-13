import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import "modules/bar/barstyles/qsbar/panels"

// The QS Bar's crate Bluetooth body with a stand-in panel: one connected mouse,
// one paired headset.
ShellRoot {
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
        id: panel
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

    FloatingWindow {
        implicitWidth: 360
        implicitHeight: 300
        color: Tokens.popover

        Rectangle {
            id: sheet
            width: 360
            height: details.implicitHeight + 40
            color: Tokens.popover
            CrateBluetoothDetails { id: details; x: 20; y: 20; width: 320; panel: panel }
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
