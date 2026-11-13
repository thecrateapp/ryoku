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
        if (item.modelData === key && item.on !== undefined) return item;
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
                    // the Hub selects options exactly as every other surface does:
                    // no Hub-only variant, a selected option filled with the mark
                    for (const group of [tabs, segments, chips, multi]) {
                        const one = probe.choice(group, "One");
                        const two = probe.choice(group, "Two");
                        probe.check(one && two && one.on && !two.on, "selection follows the shared kit");
                        if (probe.crate && group !== tabs)
                            probe.check(Qt.colorEqual(one.color, Tokens.mark), "a selected option is filled with the mark");
                        if (typeof two.clicked === "function") two.clicked();
                        else if (group === multi) group.toggled("Two");
                        else group.chose("Two");
                        probe.check(two.on, "group selection callback");
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
