pragma ComponentBehavior: Bound

import QtQuick
import shell.services
import Ryoku.Ui.Singletons
import Ryoku.Ui as Kit

// The Bluetooth sheet under controls "crate", per the second mock-up: a sheet
// head (back, title, radio), a discovery sweep, then connected, paired and
// nearby devices as three counted lists of ListRows, each device with its glyph,
// a one-line status and its actions (trust, forget, the primary one). Off, it
// says so and offers to turn the radio on. It reads the page's state and calls
// its functions; the page owns the logic.
Column {
    id: body

    required property var page
    property real s: 1

    readonly property bool on: body.page.adapterAvailable && body.page.adapterEnabled

    spacing: 12 * body.s

    component Counted: Item {
        id: counted
        property string label: ""
        property string count: ""
        property bool live: false
        width: body.width
        height: 20 * body.s
        Kit.TrackLabel {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: counted.label
        }
        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: counted.count
            color: counted.live ? Tokens.mark : Tokens.inkSubtle
            font.family: Tokens.mono
            font.pixelSize: 11 * body.s
            font.features: { "tnum": 1 }
        }
    }

    component Note: Text {
        width: body.width
        color: Tokens.inkMuted
        font.family: Tokens.ui
        font.pixelSize: 11 * body.s
        wrapMode: Text.WordWrap
    }

    component Device: Kit.ListRow {
        id: dev
        required property var modelData
        required property int index
        property bool tail: false
        readonly property var device: dev.modelData
        readonly property bool paired: !!dev.device && (dev.device.paired || dev.device.bonded)
        readonly property bool connecting: body.page.busy
            && body.page.busyAddress === String(dev.device ? dev.device.address : "")
        width: body.width
        s: body.s
        on: !!dev.device && dev.device.connected
        quiet: dev.tail
        title: BtLink.label(dev.device)
        sub: body.page.deviceStatus(dev.device)
        glyph: BtLink.glyphFor(dev.device)

        Kit.IconButton {
            visible: dev.paired
            width: 28 * body.s
            height: 28 * body.s
            iconSize: 16 * body.s
            glyph: dev.device && dev.device.trusted ? "verified" : "verified_off"
            on: !!dev.device && dev.device.trusted
            Accessible.name: dev.device && dev.device.trusted ? I18n.tr("Untrust") : I18n.tr("Trust")
            onClicked: if (dev.device) dev.device.trusted = !dev.device.trusted
        }
        Kit.IconButton {
            visible: dev.paired && !(dev.device && dev.device.connected)
            width: 28 * body.s
            height: 28 * body.s
            iconSize: 16 * body.s
            glyph: "delete"
            Accessible.name: I18n.tr("Forget %1").arg(BtLink.label(dev.device))
            onClicked: if (dev.device) dev.device.forget()
        }
        Kit.Btn {
            compact: true
            outline: !(dev.device && dev.device.connected)
            text: dev.connecting ? I18n.tr("Connecting…")
                : dev.device && dev.device.connected ? I18n.tr("Disconnect")
                : dev.paired ? I18n.tr("Connect")
                : I18n.tr("Pair")
            armed: !body.page.busy
            onAct: body.page.primaryAction(dev.device)
        }
    }

    Kit.SheetHeader {
        width: parent.width
        s: body.s
        title: I18n.tr("Bluetooth")
        onBackRequested: body.page.backRequested()
        Kit.Sw {
            anchors.verticalCenter: parent.verticalCenter
            on: body.page.adapterEnabled
            enabled: body.page.adapterAvailable && !BluetoothPower.blocked
            Accessible.name: I18n.tr("Bluetooth radio")
            onToggled: BluetoothPower.toggle()
        }
    }

    Kit.Beam {
        visible: body.page.scanning
        width: parent.width
        height: 8 * body.s
        interactive: false
        indeterminate: true
    }

    // off, blocked or missing: say so, and offer the radio
    Row {
        visible: !body.on
        width: parent.width
        spacing: 14 * body.s
        topPadding: 8 * body.s
        Kit.Glyph {
            anchors.verticalCenter: parent.verticalCenter
            name: "bluetooth_disabled"
            size: 22 * body.s
            color: Tokens.inkMuted
        }
        Column {
            width: parent.width - 36 * body.s
            spacing: 2 * body.s
            Text {
                width: parent.width
                text: BluetoothPower.blocked ? I18n.tr("Bluetooth is blocked")
                    : !body.page.adapterAvailable ? I18n.tr("No Bluetooth hardware")
                    : I18n.tr("Bluetooth is off")
                color: Tokens.ink
                font.family: Tokens.ui
                font.pixelSize: 13 * body.s
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                text: !body.page.adapterAvailable ? I18n.tr("This machine has no available Bluetooth adapter.")
                    : I18n.tr("Turn it on to see your paired devices and find others.")
                color: Tokens.inkMuted
                font.family: Tokens.ui
                font.pixelSize: 11 * body.s
                wrapMode: Text.WordWrap
            }
        }
    }
    Kit.Btn {
        visible: !body.on && body.page.adapterAvailable && !BluetoothPower.blocked
        anchors.right: parent.right
        primary: true
        text: I18n.tr("Turn on Bluetooth")
        onAct: BluetoothPower.toggle()
    }

    Note {
        visible: body.page.errorText.length > 0
        text: body.page.errorText
        color: Tokens.alert
    }

    Counted {
        visible: body.on
        label: I18n.tr("Connected")
        count: String(body.page.connectedDevices.length)
    }
    Note {
        visible: body.on && body.page.connectedDevices.length === 0
        text: I18n.tr("No Bluetooth devices are connected.")
    }
    Column {
        visible: body.on
        width: parent.width
        spacing: 6 * body.s
        Repeater {
            model: body.on ? body.page.connectedDevices : []
            delegate: Device {}
        }
    }

    Counted {
        visible: body.on && body.page.pairedDevices.length > 0
        label: I18n.tr("Paired")
        count: String(body.page.pairedDevices.length)
    }
    Column {
        visible: body.on
        width: parent.width
        spacing: 6 * body.s
        Repeater {
            model: body.on ? body.page.pairedDevices : []
            delegate: Device {}
        }
    }

    Counted {
        visible: body.on
        label: I18n.tr("Nearby")
        count: body.page.scanning ? I18n.tr("Searching…") : String(body.page.discoveredDevices.length)
        live: body.page.scanning
    }
    Note {
        visible: body.on && body.page.discoveredDevices.length === 0
        text: body.page.scanning ? I18n.tr("Looking for devices… Keep the device nearby and in pairing mode.")
            : I18n.tr("Discovery pauses when you leave this page.")
    }
    Column {
        visible: body.on
        width: parent.width
        spacing: 6 * body.s
        Repeater {
            model: body.on ? body.page.discoveredDevices : []
            delegate: Device { tail: true }
        }
    }
}
