import QtQuick
import QtTest
import Quickshell
import Quickshell.Services.UPower
import Ryoku.Ui.Singletons
import "modules" as Modules

ShellRoot {
    QtObject {
        id: device
        property bool isLaptopBattery: true
        property real percentage: 0.62
        property int state: UPowerDeviceState.Discharging
        property int timeToEmpty: 4800
        property int timeToFull: 2400
    }

    QtObject {
        id: theme
        property bool modBattery: true
        property bool batteryVisible: false
        property bool iconsOnly: false
        property bool filled: false
        property color ink: "#eeeeee"
        property color paper: "#151515"
        property color seal: "#dd6969"
        property color indigo: "#5b87ee"
        property string mono: "monospace"
        property var tooltipOwner: null
        property string tooltipText: ""
        function widgetContentColor(gid, fallback) { return filled ? paper : fallback }
        function widgetHasFill(gid) { return filled }
        function widgetAssignedColor(gid) { return indigo }
        function iconOnly(gid) { return iconsOnly }
        function showTooltip(text, x, top, bottom, owner) { tooltipOwner = owner; tooltipText = text }
        function hideTooltip(owner) { tooltipOwner = null }
    }

    FloatingWindow {
        implicitWidth: 200
        implicitHeight: 80
        TestCase { id: input; when: false }
        Modules.BatteryWidget {
            id: widget
            x: 20
            y: 20
            root: theme
            dev: device
        }
    }

    Timer {
        interval: 200
        running: true
        function check(condition, message) {
            if (!condition) throw Error(message)
        }
        onTriggered: {
            try {
                Tokens.controlsCrate = true
                const glyph = input.findChild(widget, "batteryGlyph")
                const label = input.findChild(widget, "batteryPercent")
                check(glyph && glyph.drawn && glyph.name === "battery-half" && glyph.size === 18, "real mid-level Solar glyph")
                check(label.visible && label.text === "62%" && label.font.features.tnum === 1, "tabular percentage")
                check(widget.shown && widget.timeText === "1h 20m", "display device and remaining time")
                input.mouseMove(widget, widget.width / 2, widget.height / 2)
                input.wait(380)
                check(theme.tooltipOwner === widget && theme.tooltipText === widget.tooltipText, "pointer tooltip")

                device.percentage = 0.20
                check(widget.low && glyph.name === "battery-low" && theme.tooltipText.includes("20%"), "low battery and live tooltip")
                input.wait(300)
                const icon = glyph.parent
                check(icon.opacity < 1, "low indicator pulses")
                Tokens.reduceMotion = true
                check(icon.opacity === 1 && glyph.name === "battery-low", "reduced motion restores full visibility immediately")
                const stoppedPulse = icon.pulse
                input.wait(300)
                check(icon.opacity === 1 && icon.pulse === stoppedPulse, "reduced motion stops the animation")
                Tokens.reduceMotion = false
                input.wait(300)
                check(icon.opacity < 1, "reenabling motion resumes the warning pulse")
                device.state = UPowerDeviceState.Charging
                check(glyph.parent.opacity === 1, "charging stops the warning pulse")
                check(!widget.low && glyph.name === "battery-charge" && widget.timeText === "40m", "charging at a low level")
                check(Qt.colorEqual(glyph.color, theme.indigo), "charging colour")
                device.state = UPowerDeviceState.FullyCharged
                check(glyph.name === "battery-full" && !widget.low, "fully charged takes precedence over capacity")
                device.state = UPowerDeviceState.Discharging
                device.percentage = 75
                check(glyph.name === "battery-full" && label.text === "75%", "upper range and 0–100 input")
                theme.filled = true
                check(Qt.colorEqual(glyph.color, theme.paper), "filled-widget contrast")

                input.mouseClick(widget, widget.width / 2, widget.height / 2)
                check(theme.batteryVisible && !theme.tooltipOwner, "click opens the panel and dismisses the tooltip")
                input.mouseClick(widget, widget.width / 2, widget.height / 2)
                check(!theme.batteryVisible, "second click closes the panel")
                check(widget.Accessible.role === Accessible.Button && widget.Accessible.description === widget.tooltipText, "accessible status")
                widget.Accessible.pressAction()
                check(theme.batteryVisible, "accessible action opens battery details")
                theme.iconsOnly = true
                input.wait(40)
                check(!label.visible && widget.implicitWidth === 36, "icon-only Crate dimensions")

                Tokens.controlsCrate = false
                input.wait(40)
                check(!input.findChild(widget, "batteryGlyph") && widget.implicitWidth === 37, "stock 19px drawing")
                Tokens.reduceMotion = true
                device.percentage = 0.15
                input.wait(300)
                check(icon.opacity < 1, "stock low warning retains its original pulse")
                theme.iconsOnly = false
                check(label.visible && label.font.family === theme.mono, "stock label")
                theme.modBattery = false
                check(!widget.visible && widget.implicitWidth === 0, "disabled widget")
                theme.modBattery = true
                device.isLaptopBattery = false
                check(!widget.visible && widget.implicitWidth === 0, "non-laptop display device")
                widget.dev = null
                check(!widget.visible && widget.percent === 0, "missing display device")

                console.log("BATTERY-WIDGET-PROBE-PASS")
            } catch (error) {
                console.error("BATTERY-WIDGET-PROBE-FAIL", error)
            }
            Qt.quit()
        }
    }
}
