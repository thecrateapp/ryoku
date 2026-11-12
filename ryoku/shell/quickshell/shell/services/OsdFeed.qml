pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The daemon observes the native panel backlight. Key commands can also
// report DDC/CI changes directly, with the output captured at the keypress.
Singleton {
    id: root

    property real brightness: 0
    property int brightnessSeq: 0
    property bool receivedBrightnessSnapshot: false
    property int previewSeq: 0
    property real expectedMicVolume: -1
    property double expectedMicVolumeAt: 0

    function expectMicVolume(value) {
        root.expectedMicVolume = value
        root.expectedMicVolumeAt = Date.now()
    }

    function acceptsMicVolume(value) {
        return root.expectedMicVolumeAt > 0
            && Date.now() - root.expectedMicVolumeAt < 1500
            && Math.abs(value - root.expectedMicVolume) < 0.015
    }


    signal volumeRequested()
    signal brightnessRequested()
    signal brightnessOnOutput(string output, real level, bool keypress)
    signal micRequested()
    signal keyboardRequested()
    signal mediaRequested(string action)
    signal hideRequested()

    IpcHandler {
        target: "osd"
        function preview(): void { root.previewSeq++; }
        function volume(): void { root.volumeRequested(); }
        function brightness(): void { root.brightnessRequested(); }
        function mic(): void { root.micRequested(); }
        function keyboard(): void { root.keyboardRequested(); }
        function media(action: string): string {
            const normalized = action.length === 0 ? "play" : action
            if (!["play", "pause", "next", "previous"].includes(normalized))
                return "Unknown action: play, pause, next or previous"
            root.mediaRequested(normalized)
            return normalized
        }
        function hide(): void { root.hideRequested(); }
    }
    // Bar styles can register their own "osd" target. Key feedback must reach
    // this output-aware feed whichever one owns that target.
    IpcHandler {
        target: "brightnessOsd"
        function show(output: string, percent: int): void {
            if (output.length > 0 && percent >= 0 && percent <= 100)
                root.brightnessOnOutput(output, percent / 100, true);
        }
    }

    readonly property string sockPath: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/ryoku-shell.sock"

    function apply(line) {
        try {
            const b = JSON.parse(line).brightness;
            if (b && typeof b.value === "number" && typeof b.seq === "number") {
                const advanced = root.receivedBrightnessSnapshot && b.seq > root.brightnessSeq;
                root.receivedBrightnessSnapshot = true;
                root.brightness = Math.max(0, Math.min(1, b.value));
                root.brightnessSeq = b.seq;
                if (advanced && b.seq > 0 && typeof b.output === "string" && b.output)
                    root.brightnessOnOutput(b.output, root.brightness, false);
            }
        } catch (e) {
            // A malformed frame must never wedge the OSD; keep the last value.
        }
    }

    // Subscribe once for the whole shell; every screen's brightness OSD reads
    // this singleton rather than opening its own socket.
    Socket {
        id: sub
        path: root.sockPath
        parser: SplitParser { onRead: line => root.apply(line) }
        Component.onCompleted: connected = true
        onConnectionStateChanged: {
            if (connected) {
                root.receivedBrightnessSnapshot = false;
                write("subscribe osd\n");
                flush();
            } else {
                retry.restart();
            }
        }
    }

    // The daemon may be down at load or restart under the shell; retry quietly.
    Timer {
        id: retry
        interval: 2000
        onTriggered: if (!sub.connected) sub.connected = true
    }
}
