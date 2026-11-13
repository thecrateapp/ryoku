import QtQuick
import Quickshell
import Ryoku.Ui.Singletons

// Drives the QS Bar's crate Bluetooth body with a stand-in panel: connected and
// paired devices list with the right actions, forget reaches the panel, and the
// off state hides the list.
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

    Item {
        width: 320
        height: 400
        CrateBluetoothDetails { id: details; width: 320; panel: panel }
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
            const list = find(details, "btDevices");
            if (!list || list.count !== 2)
                throw new Error("Both devices must list, got " + (list ? list.count : "none"));
            const first = list.itemAt(0), second = list.itemAt(1);
            if (!first.on || second.on)
                throw new Error("Only the connected device takes the active row");
            if (details.glyphFor(mouse) !== "input-mouse" || details.glyphFor({ icon: "nope" }) !== "bluetooth")
                throw new Error("A device glyph must fall back to Bluetooth when the kit lacks it");
            panel.forgetDevice(phones);
            if (panel.forgotten !== phones)
                throw new Error("Forget must reach the panel");
            panel.btOn = false;
            if (list.count !== 0 || !find(details, "btOffNote").visible)
                throw new Error("Off must hide the list and say so");
            console.log("BLUETOOTH-DETAILS-PROBE-PASS");
            Qt.quit();
        }
    }
}
