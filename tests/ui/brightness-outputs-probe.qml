import QtQuick
import QtTest as Test
import Quickshell
import Quickshell.Io
import Ryoku.Ui.Singletons
import "modules/bar/barstyles/qsbar/modules" as Bar
import "modules/bar/barstyles/qsbar/panels" as Panels

ShellRoot {
    id: fixture

    function screenNamed(name) {
        return Quickshell.screens.find(s => s.name === name) ?? null;
    }

    QtObject {
        id: theme
        property var activePopupScreen: fixture.screenNamed("wayland0")
        readonly property string activePopupScreenName: activePopupScreen?.name ?? ""
        property var brightnessTarget: null
        property bool brightnessVisible: false
        property bool modBrightness: true
        property int brightnessBarX: 140
        property int v2BarHeight: 28
        property int panelRadius: 6
        property int panelOuterBorderW: 1
        property color panelBorder: "gray"
        property color panelOuterBorderColor: panelBorder
        property color bg: "black"
        property color ink: "white"
        property color seal: "cyan"
        property color pillShadow: "transparent"
        property bool barShadowEnabled: false
        property string barPosition: "top"
        property var tooltipOwner: null
        function activatePopupScreen(screen) { activePopupScreen = screen; }
        function setPanelInsetX(x) {}
        function showTooltip() {}
        function hideTooltip() {}
        function widgetContentColor(gid, fallback) { return fallback; }
        function widgetHasFill(gid) { return false; }
        function iconOnly(gid) { return false; }
    }

    Bar.BrightnessOutput { id: first; outputName: "wayland0" }
    Bar.BrightnessOutput { id: second; outputName: "wayland1" }
    Bar.BrightnessOutput { id: unsupported; outputName: "wayland2" }
    Panels.BrightnessPanel { id: panel; root: theme }

    FloatingWindow {
        visible: true
        implicitWidth: 400
        implicitHeight: 100
        Test.TestCase { id: input; when: false }
        Item {
            anchors.fill: parent
            Bar.BrightnessWidget {
                id: firstWidget
                root: theme
                screen: fixture.screenNamed(first.outputName)
                controller: first
            }
            Bar.BrightnessWidget {
                id: secondWidget
                x: 100
                root: theme
                screen: fixture.screenNamed(second.outputName)
                controller: second
            }
            Bar.BrightnessWidget {
                id: unsupportedWidget
                x: 200
                root: theme
                screen: fixture.screenNamed(unsupported.outputName)
                controller: unsupported
            }
        }
    }

    FileView {
        id: secondDevice
        path: fixture.devices + "wayland1"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
    }
    Process { id: connectionChange }
    readonly property string devices: Quickshell.env("XDG_RUNTIME_DIR") + "/"
    function moveDevice(from, to) {
        connectionChange.command = ["mv", devices + from, devices + to];
        connectionChange.running = true;
        expect(() => !connectionChange.running, "change simulated device connection");
    }

    function expect(predicate, description) {
        const deadline = Date.now() + 3000;
        while (!predicate() && Date.now() < deadline) input.wait(20);
        if (!predicate()) throw new Error(description);
    }

    function click(widget) {
        input.mouseClick(widget, widget.width / 2, widget.height / 2);
    }

    function panelControls() {
        const slider = input.findChild(panel.contentItem, "brightnessSlider");
        if (!slider) throw new Error("Crate slider not loaded");
        return slider.parent.parent;
    }

    Timer {
        interval: 100
        running: true
        onTriggered: {
            try {
                Tokens.controlsCrate = true;
                fixture.expect(() => firstWidget.visible && first.percent === 23
                                   && secondWidget.visible && second.percent === 71,
                               "indicators must read their own levels");
                if (unsupported.available || unsupportedWidget.visible)
                    throw new Error("unsupported output showed an actionable indicator");

                fixture.click(secondWidget);
                fixture.expect(() => theme.brightnessVisible && panel.screen === secondWidget.screen
                                   && fixture.panelControls().percent === 71, "second panel opens at 71%");
                input.mouseWheel(firstWidget, firstWidget.width/2, firstWidget.height/2, 0, 120);
                fixture.expect(() => first.percent === 28, "wheel on first output must target first");
                if (fixture.panelControls().percent !== 71) throw new Error("wheel retargeted open panel");

                fixture.panelControls().percentRequested(80);
                input.wait(120);
                fixture.panelControls().percentRequested(83);
                fixture.panelControls().percentRequested(86);
                fixture.click(firstWidget);
                fixture.expect(() => theme.brightnessVisible && panel.screen === firstWidget.screen
                                   && fixture.panelControls().percent === 28, "move open panel to first output");
                fixture.panelControls().stepRequested(false);
                fixture.expect(() => first.percent === 23 && second.percent === 86,
                               "queued writes and buttons must stay on their original outputs");
                fixture.panelControls().closeRequested();
                fixture.expect(() => !theme.brightnessVisible, "close panel");
                fixture.click(secondWidget);
                fixture.expect(() => theme.brightnessVisible && panel.screen === secondWidget.screen
                                   && fixture.panelControls().percent === 86, "second output reopened at its own level");

                fixture.expect(() => secondDevice.text().trim() === "86", "last slow write must reach hardware");
                fixture.moveDevice("wayland1", "unplugged");
                second.refresh();
                fixture.expect(() => !second.available && !secondWidget.visible && !panel.canAdjust,
                               "a lost DDC device must disable its open panel");
                fixture.panelControls().percentRequested(19);
                fixture.panelControls().stepRequested(false);
                fixture.panelControls().closeRequested();
                fixture.moveDevice("unplugged", "wayland1");
                second.refresh();
                fixture.expect(() => second.available && secondWidget.visible, "rediscover reconnected device");
                fixture.click(secondWidget);
                fixture.expect(() => panel.canAdjust && fixture.panelControls().percent === 86
                                   && first.percent === 23, "reconnected panel retains its hardware level");
                console.log("BRIGHTNESS-OUTPUTS-PROBE-PASS");
            } catch (error) {
                console.error("BRIGHTNESS-OUTPUTS-PROBE-FAIL", error);
            }
            Qt.quit();
        }
    }
}
