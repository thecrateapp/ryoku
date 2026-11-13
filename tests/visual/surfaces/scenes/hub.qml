import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import "Singletons"

ShellRoot {
    id: scene
    readonly property string look: Quickshell.env("BENCH_LOOK")
    property var routes: []
    property var host: null
    property int current: -1
    property int settled: 0
    property double deadline: Date.now() + 20000

    Window {
        visible: true
        width: 1400
        height: 880
        Rectangle {
            id: backdrop
            anchors.fill: parent
            // An identical dark backdrop makes the glass readable without a compositor.
            color: "#0a0a0f"
            Hub { id: hub; anchors.fill: parent }
        }
    }

    function pageHost(item) {
        if (item.front !== undefined && item.shown !== undefined && item.swap !== undefined) return item;
        for (const child of item.children) {
            const result = pageHost(child);
            if (result) return result;
        }
        return null;
    }

    // Freeze the Profile signal GIF and the visible Profile/Launcher clocks for image comparisons.
    function setCaptureClock(item) {
        if (item instanceof AnimatedImage) {
            item.playing = false;
            item.currentFrame = 0;
        }
        if (item.clockTime !== undefined || item.clockStr !== undefined)
            item.now = new Date("2026-11-13T10:30:00Z");
        for (const child of item.children) setCaptureClock(child);
    }

    function next() {
        ++current;
        if (current === routes.length) {
            console.log("HUB-CAPTURE-DONE", look, routes.length);
            Qt.quit();
            return;
        }
        const key = routes[current];
        if (!hub.sectionAvailable(key)) throw Error("Fixture cannot navigate to " + key);
        hub.navigate(key);
        deadline = Date.now() + 15000;
        settled = 0;
        poll.start();
    }

    Timer {
        id: poll
        interval: 60
        repeat: true
        running: true
        onTriggered: {
            try {
                if (Date.now() > scene.deadline) throw Error("Timed out at " + hub.section);
                if (scene.current < 0) {
                    if (!ProviderSchema.ready || !hub.wmLoaded || Tokens.controlsCrate !== (scene.look === "crate")) return;
                    const caps = {};
                    for (const group of hub.groups)
                        for (const item of group.items) {
                            scene.routes.push(item.key);
                            if (item.needs && item.needs.cap) caps[item.needs.cap] = true;
                            for (const row of hub.effectiveRows(item.key))
                                if (row.caps) caps[row.caps] = true;
                        }
                    Settings.applyWm(JSON.stringify({provider: "hyprland"}));
                    Settings.apply(JSON.stringify({caps: caps, showJapaneseGloss: true}));
                    Updates.apply(JSON.stringify({release: "1.0.9", channelRelease: "1.0.9", channel: "main"}));
                    scene.host = scene.pageHost(hub);
                    if (!scene.host) throw Error("Missing Hub page host");
                    scene.next();
                    return;
                }
                const key = scene.routes[scene.current], host = scene.host, loader = host.front;
                if (hub.section !== key || host.shown !== key || host.parking
                    || loader.status !== Loader.Ready || String(loader.source) !== String(hub.pageFile(key))
                    || loader.x !== 0 || loader.opacity !== 1 || !loader.item
                    || loader.item.width <= 0 || loader.item.height <= 0) {
                    scene.settled = 0;
                    return;
                }
                // Let delegates polish and the rail settle after the real route transition.
                if (key === "profile" || key === "launcher") scene.setCaptureClock(loader.item);
                if (++scene.settled < 3) return;
                poll.stop();
                const path = "/output/hub-" + scene.look + "-" + key + ".png";
                if (!backdrop.grabToImage(result => {
                    if (!result.saveToFile(path)) {
                        console.error("Failed to save " + path);
                        Qt.quit();
                        return;
                    }
                    console.log("HUB-CAPTURE", key, loader.source, loader.item.width, loader.item.height);
                    Qt.callLater(scene.next);
                })) throw Error("Cannot capture " + key);
            } catch (error) {
                console.error(error);
                Qt.quit();
            }
        }
    }
}
