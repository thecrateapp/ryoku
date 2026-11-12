import QtQuick
import Quickshell
import Quickshell.Io
import shell.services
import "osd"

ShellRoot {
    // In the full shell, Python owns this target before the OSDs are loaded.
    IpcHandler {
        target: "osd"
        function show(kind: string): string { return "competitor/" + kind; }
    }
    Loader {
        id: sources
        active: false
        sourceComponent: Item {
            readonly property var outputs: [laptop, first, second]
            OsdSource { id: laptop; kind: "brightness"; outputName: "eDP-2" }
            OsdSource { id: first; kind: "brightness"; outputName: "DP-3" }
            OsdSource { id: second; kind: "brightness"; outputName: "DP-5" }
        }
    }
    Timer { interval: 0; running: true; onTriggered: sources.active = true }
    IpcHandler {
        target: "probe"
        function state(): string {
            return sources.item?.outputs?.map(s =>
                (s.flashing ? "on" : "off") + Math.round(100 * s.value)).join(" ") ?? "";
        }
        function watched(output: string, seq: int, pct: int): void {
            OsdFeed.apply(JSON.stringify({brightness: {output, seq, value: pct / 100}}));
        }
    }
}
