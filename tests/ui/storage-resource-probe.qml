import QtQuick
import QtTest
import Quickshell
import Ryoku.Ui.Singletons
import "bar/modules" as Modules
import "bar/panels" as Panels

ShellRoot {
    id: fixture

    QtObject {
        id: theme
        property bool modStorage: true
        property bool storageVisible: false
        property bool storageAvailable: true
        property bool storageInventoryAvailable: false
        property var storageDrives: []
        property int storagePercent: 42
        property real storageTotalGiB: 200
        property real storageUsedGiB: 84
        property color widgetIconColor: "red"
        property string mono: "monospace"
        property bool iconsOnly: false
        property var tooltipOwner: null
        property string tooltipText: ""
        function widgetContentColor(id, fallback) { return fallback }
        function iconOnly(id) { return iconsOnly }
        function showTooltip(text, x, top, bottom, owner) { tooltipOwner = owner; tooltipText = text }
        function hideTooltip(owner) { tooltipOwner = null }
        property var activePopupScreen: Quickshell.screens[0]
        property int storageBarX: 180
        property int v2BarHeight: 28
        property int panelRadius: 6
        property int panelOuterBorderW: 1
        property color panelOuterBorderColor: "gray"
        property color panelBorder: "gray"
        property color bg: "black"
        property color ink: "white"
        property color sumi: "gray"
        property color sumiHi: "gray"
        property color sep: "gray"
        property color sectionInk: "gray"
        property color fillActive: "gray"
        property color seal: "cyan"
        property color pillShadow: "transparent"
        property bool barShadowEnabled: false
        property string barPosition: "top"
        function setPanelInsetX(x) {}
    }
    Panels.StoragePanel { id: panel; root: theme }

    FloatingWindow {
        implicitWidth: 380
        implicitHeight: 500
        TestCase { id: input; when: false }
        Modules.StorageWidget { id: widget; root: theme }
        Item { id: stage; y: 48; width: parent.width; height: parent.height - y }
    }

    function check(condition, message) {
        if (!condition) throw Error(message)
    }
    function texts(item, found) {
        if (!item.visible) return
        if (typeof item.text === "string") found.push(item.text)
        for (const child of item.children) texts(child, found)
    }
    function labels(expected) {
        const found = []
        texts(stage, found)
        for (const text of expected)
            check(found.includes(text), "missing " + text + " in " + found.join(" / "))
    }
    function drive(model, state, percent, used, free) {
        return { model, state, percent, driveType: "nvme", media: "NVMe", fileSystems: "BTRFS",
            size: 1000000000000, usedBytes: used * 1073741824, freeBytes: free * 1073741824,
            totalBytes: used < 0 ? -1 : (used + free) * 1073741824 }
    }
    Timer {
        interval: 150
        running: true
        onTriggered: {
            try {
                Tokens.controlsCrate = true
                const glyph = input.findChild(widget, "storageGlyph")
                const pct = input.findChild(widget, "storagePercent")
                fixture.check(glyph.visible && glyph.drawn && glyph.size === 18, "Solar storage icon")
                fixture.check(pct.text === "42%" && pct.font.features.tnum === 1, "tabular indicator")
                fixture.check(Qt.colorEqual(glyph.color, theme.widgetIconColor), "configured ink")
                input.mouseMove(widget, widget.width / 2, widget.height / 2)
                input.wait(380)
                fixture.check(theme.tooltipOwner === widget && theme.tooltipText.includes("84.0/200.0"), "hover tooltip")
                input.mouseClick(widget, widget.width / 2, widget.height / 2)
                fixture.check(theme.storageVisible && theme.tooltipOwner === null, "open panel")
                input.wait(80)
                let card = input.findChild(panel.contentItem, "closeStorage")
                fixture.check(!!card, "loaded Crate panel in its normal host")
                while (card.parent !== panel.contentItem) card = card.parent
                card.parent = stage
                input.wait(80)
                fixture.labels(["42%", "84.0 GiB", "116.0 GiB", "200.0 GiB", "Reading drive information…"])
                const beam = input.findChild(stage, "usageBeam")
                fixture.check(beam.value === 0.42 && !beam.interactive, "read-only root meter")
                theme.storageInventoryAvailable = true
                fixture.labels(["No physical drives found"])
                theme.storageDrives = [fixture.drive("Disk A", "/", 40, 40, 60),
                    fixture.drive("Disk B", "/boot", 50, 1, 1), fixture.drive("Disk C", "Not mounted", -1, -1, -1)]
                input.wait(50)
                fixture.labels(["Disk A", "Disk B", "Disk C", "1.0 TB", "40%", "40.0 GiB", "60.0 GiB", "100.0 GiB",
                    "NVMe · BTRFS · /boot · 50% · 1.0 GiB free", "NVMe · BTRFS · Not mounted"])
                const viewport = input.findChild(stage, "storageDetailsViewport")
                theme.storageDrives = Array(12).fill(fixture.drive("External Disk", "/data", 80, 80, 20))
                input.wait(70)
                fixture.check(viewport.interactive && card.height < stage.height, "large inventories fit the output")
                viewport.forceActiveFocus()
                input.keyClick(Qt.Key_PageDown)
                fixture.check(viewport.contentY > 0, "keyboard scroll reaches more drives")
                input.keyClick(Qt.Key_PageUp)
                fixture.check(viewport.contentY === 0, "return to summary")
                theme.storagePercent = 0
                theme.storageUsedGiB = 0
                fixture.labels(["0%", "0.0 GiB"])
                theme.storageAvailable = false
                input.wait(30)
                fixture.check(!widget.visible && !beam.visible, "missing telemetry hides indicator and beam")
                fixture.labels(["\u2014"])
                theme.storageAvailable = true
                theme.iconsOnly = true
                fixture.check(!pct.visible, "icon only")
                theme.storageDrives = []
                input.findChild(stage, "closeStorage").forceActiveFocus()
                input.keyClick(Qt.Key_Return)
                fixture.check(!theme.storageVisible, "keyboard close")
                theme.storageVisible = true
                Tokens.controlsCrate = false
                input.wait(70)
                fixture.check(!glyph.visible && !input.findChild(stage, "storageDetailsViewport"), "classic controls")
                fixture.labels(["ROOT", "No physical drives found"])
                theme.modStorage = false
                fixture.check(!widget.visible, "honor widget toggle")
                console.log("STORAGE-RESOURCE-PROBE-PASS")
            } catch (error) {
                console.error("STORAGE-RESOURCE-PROBE-FAIL", error)
            }
            Qt.quit()
        }
    }
}
