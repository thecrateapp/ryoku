import QtQuick
import Quickshell
import Quickshell.Io
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons
import "Singletons"

ShellRoot {
    id: probe
    readonly property bool crate: Quickshell.env("BENCH_LOOK") === "crate"
    property int step: 0

    FloatingWindow {
        visible: true
        implicitWidth: 1400
        implicitHeight: 880
        HubGlass { id: glass; anchors.fill: parent }
        Hub { id: hub; anchors.fill: parent }

        Column {
            Kit.Tabs { id: tabs; options: ["One", "Two"]; current: "One"; onChose: value => current = value }
            Kit.Seg { id: segments; options: ["One", "Two"]; current: "One"; onChose: value => current = value }
            Kit.Chips { id: chips; options: ["One", "Two"]; current: "One"; onChose: value => current = value }
            Kit.Multi { id: multi; options: ["One", "Two"]; chosen: ["One"]; onToggled: value => chosen = [value] }
        }
    }

    FileView {
        id: perfFile
        path: Quickshell.env("HOME") + "/.config/ryoku/performance.json"
        printErrors: false
    }

    function named(item, name) {
        if (item.objectName === name) return item;
        for (const child of item.children) {
            const match = named(child, name);
            if (match) return match;
        }
        return null;
    }

    function choice(item, key) {
        if (item instanceof Kit.Chip && item.modelData === key) return item;
        for (const child of item.children) {
            const found = choice(child, key);
            if (found) return found;
        }
        return null;
    }

    function check(test, reason) {
        if (!test) throw Error(reason);
    }

    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            try {
                if (!hub.wmLoaded || !ProviderSchema.ready || Tokens.controlsCrate !== probe.crate) return;
                if (!probe.step) {
                    const entry = Qt.createComponent(Qt.resolvedUrl("shell.qml"));
                    probe.check(entry.status === Component.Ready, "Hub window entry: " + entry.errorString());
                    hub.navigate("global");
                    ++probe.step;
                    return;
                }
                const key = probe.step === 1 ? "global" : "updates";
                const edge = probe.named(hub, "routeEdge-" + key);
                const other = probe.named(hub, "routeEdge-profile");
                const updates = probe.named(hub, "updatesShortcut");
                const files = probe.named(hub, "settingsFilesShortcut");
                probe.check(hub.section === key && edge.visible, "selected route missing");
                probe.check(hub.radius === (probe.crate ? Tokens.radius : 0)
                    && Qt.colorEqual(hub.color, probe.crate ? Tokens.glass : Tokens.paper), "window surface");
                probe.check(edge.border.width === (probe.crate ? 1 : 0) && other.border.width === 0, "route selection");
                probe.check(!probe.crate || Qt.colorEqual(edge.border.color, Tokens.pickEdge), "route outline color");
                probe.check(updates.visible === probe.crate, "Updates shortcut style");
                if (probe.step === 1) {
                    probe.check(Tokens.outlineSelections === probe.crate, "Hub selection policy");
                    for (const group of [tabs, segments, chips, multi]) {
                        const one = probe.choice(group, "One");
                        if (!probe.crate) {
                            probe.check(!one || !one.outlined, "stock option styling");
                            continue;
                        }
                        const two = probe.choice(group, "Two");
                        probe.check(one && two && one.outlined && one.border.width === 1
                            && Qt.colorEqual(one.border.color, Tokens.pickEdge), "selected option edge");
                        two.clicked();
                        probe.check(!one.on && two.on, "group selection callback");
                    }
                    probe.check(files.visible === probe.crate, "Files shortcut style");
                    if (probe.crate) {
                        files.clicked();
                        probe.check(files.on, "Files did not open");
                        files.clicked();
                        probe.check(!files.on, "Files did not close");
                        updates.clicked();
                    } else {
                        hub.navigate("updates");
                    }
                    ++probe.step;
                    return;
                }
                probe.check(updates.on, "Updates did not follow navigation");
                if (probe.step === 2) {
                    probe.check(probe.crate ? glass.blurRegion && glass.blurRegion.radius === Tokens.radius
                        && glass.blurRegion.width === hub.width : glass.blurRegion === null, "rounded blur region");
                    perfFile.setText('{"disableBlur":true}');
                    ++probe.step;
                    return;
                }
                if (glass.allowBlur) return;
                probe.check(glass.blurRegion === null && hub.color.a === 1, "opaque fallback with blur disabled");
                console.log("HUB-CHROME-PASS", Quickshell.env("BENCH_LOOK"));
            } catch (error) {
                console.error(error);
            }
            stop();
            Qt.quit();
        }
    }
}
