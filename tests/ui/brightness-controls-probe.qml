import QtQuick
import QtTest
import Quickshell
import Ryoku.Ui.Singletons
import "panels" as Panels

ShellRoot {
    FloatingWindow {
        implicitWidth: 280
        implicitHeight: 180
        TestCase { id: input; when: false }

        Panels.CrateBrightnessControls {
            id: controls
            width: 248
            percent: 64
            property var steps: []
            property int closes: 0
            onPercentRequested: next => percent = next
            onStepRequested: up => steps.push(up)
            onCloseRequested: closes++
        }
    }

    Timer {
        running: true
        interval: 100
        onTriggered: {
            try {
                Tokens.controlsCrate = true;
                const slider = input.findChild(controls, "brightnessSlider");
                input.mouseClick(slider, 0, slider.height / 2);
                if (controls.percent !== 1)
                    throw Error("a pointer press at the start must request 1%");
                input.mouseClick(slider, slider.width - 1, slider.height / 2);
                if (controls.percent < 99)
                    throw Error("a pointer press at the end must request full brightness");
                slider.forceActiveFocus();
                input.keyClick(Qt.Key_Right);
                if (controls.percent !== 100)
                    throw Error("the upper limit must be 100%");
                input.keyClick(Qt.Key_Left);
                if (controls.percent !== 99)
                    throw Error("the slider must allow one-percent keyboard adjustments");
                input.keyClick(Qt.Key_Tab);
                input.keyClick(Qt.Key_Space);
                input.keyClick(Qt.Key_Tab);
                input.keyClick(Qt.Key_Return);
                if (controls.steps.join(",") !== "false,true")
                    throw Error("step controls must forward decrease then increase");
                slider.forceActiveFocus();
                input.keyClick(Qt.Key_Backtab);
                input.keyClick(Qt.Key_Return);
                if (controls.closes !== 1)
                    throw Error("the close button must be keyboard-accessible");
                console.log("BRIGHTNESS-CONTROLS-PROBE-PASS");
            } catch (error) {
                console.error("BRIGHTNESS-CONTROLS-PROBE-FAIL", error);
            }
            Qt.quit();
        }
    }
}
