pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons

// The QS Bar Bluetooth panel under controls "crate": the Controls panel's
// Bluetooth sheet at panel size. A tracked head with the radio and close, then
// either why it is off or the devices as ListRows (connected first) with one
// compact action and forget; the head's rescan button and its sweep; settings.
// It reads the panel and calls its functions, so a probe can drive it with a
// stand-in panel.
Column {
    id: details

    required property var panel
    signal closeRequested()
    signal powerRequested()
    signal settingsRequested()

    // a device's glyph: its freedesktop icon when the kit draws it, else Bluetooth
    function glyphFor(dev) {
        const icon = String(dev && dev.icon ? dev.icon : "");
        return icon.length > 0 && Kit.GlyphCatalog.has(icon) ? icon : "bluetooth";
    }

    spacing: Tokens.s3

    CrateResourceHeader {
        width: parent.width
        title: details.panel.numConnected > 0
            ? I18n.tr("Bluetooth · %1").arg(details.panel.numConnected) : I18n.tr("Bluetooth")
        closeObjectName: "closeBluetooth"
        onCloseRequested: details.closeRequested()
        Kit.IconButton {
            objectName: "btScan"
            visible: details.panel.btOn
            width: 32
            height: 32
            glyph: "refresh"
            on: details.panel.scanning
            Accessible.name: details.panel.scanning ? I18n.tr("Stop scanning") : I18n.tr("Scan for devices")
            onClicked: details.panel.toggleScan()
        }
        Kit.Sw {
            objectName: "btRadio"
            anchors.verticalCenter: parent.verticalCenter
            on: details.panel.btOn
            enabled: !details.panel.blocked
            Accessible.name: I18n.tr("Bluetooth radio")
            onToggled: details.powerRequested()
        }
    }

    Kit.Beam {
        visible: details.panel.scanning
        width: parent.width
        height: 8
        interactive: false
        indeterminate: true
    }

    Text {
        objectName: "btOffNote"
        visible: !details.panel.btOn
        width: parent.width
        text: details.panel.blocked ? I18n.tr("Bluetooth is blocked") : I18n.tr("Bluetooth is off")
        color: Tokens.inkMuted
        font.family: Tokens.ui
        font.pixelSize: 12
        wrapMode: Text.WordWrap
    }

    Column {
        visible: details.panel.btOn
        width: parent.width
        spacing: 6
        Repeater {
            objectName: "btDevices"
            model: details.panel.btOn ? details.panel.shownDevices : []
            delegate: Kit.ListRow {
                id: dev
                required property var modelData
                required property int index
                readonly property bool paired: !!(dev.modelData.paired || dev.modelData.bonded)
                width: parent ? parent.width : 0
                on: !!dev.modelData.connected
                quiet: !dev.modelData.connected && !dev.paired
                title: details.panel.deviceLabel(dev.modelData)
                sub: details.panel.deviceStatus(dev.modelData)
                glyph: details.glyphFor(dev.modelData)
                Kit.IconButton {
                    visible: dev.paired && !dev.modelData.connected
                    width: 28
                    height: 28
                    iconSize: 16
                    glyph: "delete"
                    enabled: !details.panel.busy
                    Accessible.name: I18n.tr("Forget")
                    onClicked: details.panel.forgetDevice(dev.modelData)
                }
                Kit.Btn {
                    compact: true
                    outline: !dev.modelData.connected
                    text: dev.modelData.connected ? I18n.tr("Disconnect")
                        : dev.paired ? I18n.tr("Connect") : I18n.tr("Pair")
                    armed: !details.panel.busy
                    onAct: details.panel.activateDevice(dev.modelData)
                }
            }
        }
    }

    Text {
        visible: details.panel.btOn && details.panel.shownDevices.length === 0
        width: parent.width
        text: details.panel.scanning ? I18n.tr("Searching…") : I18n.tr("No devices yet. Scan to find nearby ones.")
        color: Tokens.inkMuted
        font.family: Tokens.ui
        font.pixelSize: 12
    }

    Text {
        visible: details.panel.pairError.length > 0
        width: parent.width
        text: details.panel.pairError
        color: Tokens.alert
        font.family: Tokens.ui
        font.pixelSize: 11
        wrapMode: Text.WordWrap
    }

    Kit.Btn {
        objectName: "btSettings"
        width: parent.width
        outline: true
        text: I18n.tr("Bluetooth settings")
        onAct: details.settingsRequested()
    }
}
