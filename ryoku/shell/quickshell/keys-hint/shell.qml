pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Ryoku.Ui.Singletons

// First-boot hint: a one-shot `qs -c keys-hint` toast the session launches
// exactly once, pointing a new user at Kit. The quiet top-centre card uses ink,
// key caps and hairlines, never accent. It does not take keyboard focus or time
// out; dismissing it quits the process and releases the launch flock. Under
// crate the cards are the one glass of every floating surface.
ShellRoot {
    id: app
    Component.onCompleted: Quickshell.watchFiles = !Quickshell.shellDir.startsWith(
        (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/quickshell/")

    property bool closing: false
    function dismiss() {
        if (app.closing)
            return;
        app.closing = true;
        quitTimer.start();
    }
    Timer {
        id: quitTimer
        interval: Tokens.durSmall + 30
        onTriggered: Qt.quit()
    }

    // The hint runs in its own process: read the shell's blur preference so the
    // crate glass turns opaque when blur is off, as it does in the shell.
    Binding {
        target: Tokens
        property: "glassBlur"
        value: !effects.lowPowerMode && !effects.disableBlur
        when: Tokens.controlsCrate
    }
    FileView {
        path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/ryoku/performance.json"
        printErrors: false
        JsonAdapter {
            id: effects
            property bool lowPowerMode: false
            property bool disableBlur: false
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            color: "transparent"
            exclusiveZone: 0
            WlrLayershell.namespace: "ryoku-keys-hint"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            anchors { top: true; left: true; right: true }
            implicitHeight: 210

            // Show only on the monitor the user is on when Ryoku first comes up.
            readonly property bool onFocused: {
                var fo = Wm.focusedOutput;
                return fo ? (modelData ? fo === modelData.name : false) : true;
            }
            visible: win.onFocused

            property real appear: 0
            NumberAnimation on appear {
                running: true
                from: 0
                to: 1
                duration: Tokens.durNormal
                easing.type: Easing.OutCubic
            }
            readonly property real shown: app.closing ? 0 : appear

            // the two stacked cards (HintCards): one X dismisses the set
            HintCards {
                id: stack
                objectName: "hintCards"
                anchors.horizontalCenter: parent.horizontalCenter
                y: Tokens.s5 + (win.shown - 1) * 14
                opacity: win.shown
                Behavior on opacity { NumberAnimation { duration: Tokens.durSmall; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: Tokens.durSmall; easing.type: Easing.OutCubic } }
                onDismissed: app.dismiss()
            }
        }
    }
}
