import QtQuick
import Quickshell
import shell.services
import "modules/bar/barstyles/orpheus/cards/controls" as Orpheus
import "modules/bar/barstyles/kairos/quicksettings/pages" as Kairos
import "modules/bar/framebars/menus" as Menus

ShellRoot {
    id: root
    component TestNode: QtObject {
        property bool isSink: false
        property bool isStream: false
        property real boost: 1
        readonly property QtObject audio: QtObject {
            property real volume: 0.8
            property bool muted: true
        }
    }
    TestNode { id: speaker; isSink: true; boost: 1.5 }
    TestNode { id: microphone }
    TestNode { id: stream; isSink: true; isStream: true }
    Orpheus.SoundPage { id: orpheus; scene: null; width: 320 }
    Kairos.SoundPage { id: kairos; width: 320 }
    Menus.MenuVolumeFader { id: frame; open: false; peakNode: null }

    function check(result, message) {
        if (!result)
            throw new Error(message);
    }
    function slider(item, node) {
        if (item.node === node && typeof item.setVolume === "function")
            return item.children.find(child => typeof child.committed === "function");
        for (const child of item.children) {
            const found = slider(child, node);
            if (found) return found;
        }
        return null;
    }
    Component.onCompleted: {
        Audio.sink = speaker;
        Audio.source = microphone;
        Audio.streams = [stream];
    }
    Timer {
        interval: 100
        running: true
        onTriggered: {
            try {
                const output = root.slider(orpheus, speaker);
                const input = root.slider(orpheus, microphone);
                const app = root.slider(orpheus, stream);
                root.check(output && input && app, "missing Orpheus slider");
                root.check(output.valueText === "120%" && input.valueText === "80%"
                    && app.valueText === "80%", "Orpheus displayed levels");
                root.check(Math.abs(kairos.outVol - 1.2) < 0.001
                    && Math.abs(frame.value - 1.2) < 0.001, "Kairos or FrameBars omitted boost");
                output.committed(0);
                root.check(speaker.audio.muted, "silence unmuted the output");
                output.moved(0.5);
                root.check(!speaker.audio.muted && speaker.audio.volume === 0.8,
                    "Orpheus wrote the raw output or kept it muted");
                root.check(frame.valueLabel === "120%", "FrameBars displayed level");
                kairos.setOut(0.6);
                frame.moved(0.7);
                input.committed(0.45);
                app.moved(0.35);
                root.check(!microphone.audio.muted && microphone.audio.volume === 0.45
                    && !stream.audio.muted && stream.audio.volume === 0.35,
                    "input or stream failed to update its own volume");
                const expected = [0, 0.5, 0.6, 0.7];
                root.check(Audio.writes.length === expected.length, "unexpected number of device writes");
                expected.forEach((value, index) => {
                    const [node, requested, limit] = Audio.writes[index];
                    root.check(node === speaker && requested === value && limit === 1, "device write " + index);
                });
                console.log("BAR-DEVICE-VOLUME-PASS");
            } catch (error) {
                console.error(error);
            }
            Qt.quit();
        }
    }
}
