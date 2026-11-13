import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import "pages" as Pages
import "pages/users" as Users

// These four account actions open the real popup via the Users tab. The other
// three pages own inline dialogs. Never submit an action from the fixture.
ShellRoot {
    id: scene
    readonly property string look: Quickshell.env("BENCH_LOOK")
    readonly property var states: ["users-password", "users-storage-limit", "users-add", "users-remove",
        "addons-remove", "dictation-model", "fingerprint-verify"]
    readonly property var tabStates: [password, quota, add, remove]
    property int index: 0

    Binding { target: Tokens; property: "outlineSelections"; value: Tokens.controlsCrate }

    Window {
        id: window
        width: 900; height: 760
        visible: true
        color: Tokens.paper
        Loader {
            id: host
            anchors.fill: parent
            anchors.margins: 20
            sourceComponent: scene.index < 4 ? people : [addons, dictation, fingerprint][scene.index - 4]
        }
    }
    Component { id: people; Users.UsersTab {} }
    Component { id: addons; Pages.AddonsPage {} }
    Component { id: dictation; Pages.DictationPage {} }
    Component { id: fingerprint; Pages.LockscreenPage {} }

    function find(item, predicate) {
        if (predicate(item)) return item;
        for (const child of item.children || []) {
            const match = find(child, predicate);
            if (match) return match;
        }
        return null;
    }
    function password(card) { card.passwordRequested("studio"); }
    function quota(card) { card.limitRequested("studio", 96 * 1073741824); }
    function add() {
        const button = find(host.item, item => item.text === "ADD PERSON" && item.act !== undefined && item.visible);
        if (!button || !button.armed) throw Error("Add person action unavailable");
        button.act();
    }
    function remove(card) { card.removeRequested("studio"); }

    function prepare() {
        const page = host.item;
        if (!page || Tokens.controlsCrate !== (look === "crate")) throw Error("Page or look is unavailable");
        if (index < 4) {
            page.loadError = "";
            page.listLoaded = true;
            page.capsLoaded = true;
            page.selfName = "operator";
            page.permissionDefs = [{id: "devices", label: "Devices"}, {id: "audio", label: "Audio"}];
            page.storageCaps = {quota: true};
            const storage = {supported: true, usedBytes: 52 * 1073741824, limitBytes: 96 * 1073741824};
            page.users = [
                {name: "studio", fullName: "Studio editor", role: "standard", permissions: ["audio"], storage: storage},
                {name: "operator", fullName: "System operator", role: "admin", permissions: [], storage: storage}
            ];
            const card = find(page, item => item.userData && item.userData.name === "studio" && item.visible);
            if (!card) throw Error("Fixture user unavailable");
            tabStates[index](card);
        } else if (index === 4) {
            page.loaded = true;
            page.plugins = [{id: "studio-clock", manifest: {name: "Studio clock", version: "1.0", summary: "A second clock for the studio."},
                placement: {enabled: true, host: "topbarGlyph"}}];
            page.requestPluginRemove("studio-clock", "Studio clock");
        } else if (index === 5) {
            page.loaded = true;
            page.installed = true;
            page.presets = [{key: "whisper-fast", label: "Whisper Small", detail: "Local speech recognition",
                language: "Multilingual", speed: "Balanced", family: "local", group: "whisper",
                size: "465 MiB", keyKind: "", present: false, cloud: false}];
            page.pendingDownload = "whisper-fast";
        } else {
            page.foverlayMode = "verify";
            page.fstatus = "verify-match";
            page.foverlay = true;
        }
    }

    function dialog() {
        if (index < 4) {
            const title = ["New password for studio", "Storage limit for studio", "A separate Ryoku account", "Remove studio?"][index];
            // Popups live in the Qt Quick Controls overlay, outside the page subtree.
            const titleItem = find(window.contentItem, item => item.visible && item.text === title);
            for (let parent = titleItem; parent; parent = parent.parent)
                if (parent.contentItem && parent.background && parent.visible) return parent;
            return null;
        }
        const name = ["addonRemoval", "dictationConfirmation", "fingerprintDialog"][index - 4];
        return find(host.item, item => item.visible && item.objectName === name);
    }

    function fail(error) {
        console.error("HUB-DIALOGS-FAIL", states[index], error);
        Qt.quit();
    }
    Timer {
        id: open
        running: true
        interval: 400
        onTriggered: {
            try { scene.prepare(); capture.start(); }
            catch (error) { scene.fail(error); }
        }
    }
    Timer {
        id: capture
        interval: 240
        onTriggered: {
            try {
                const target = scene.dialog();
                if (!target || target.width < 200 || target.height < 100) throw Error("Dialog is absent or empty");
                const frame = target.mapToItem(window.contentItem, 0, 0);
                if (frame.x < 0 || frame.y < 0 || frame.x + target.width > window.width + 1
                    || frame.y + target.height > window.height + 1) throw Error("Dialog is outside the viewport");
                const name = scene.states[scene.index];
                // Grab the window content, including Qt Quick Controls' overlay.
                window.contentItem.grabToImage(result => {
                    if (!result.saveToFile("/output/hub-" + scene.look + "-dialog-" + name + ".png")) {
                        scene.fail("PNG write failed");
                        return;
                    }
                    console.log("HUB-DIALOG", name, target.width, target.height, scene.look);
                    if (scene.index + 1 === scene.states.length) {
                        console.log("HUB-DIALOGS-DONE", scene.look);
                        Qt.quit();
                        return;
                    }
                    // Destroying the old tab closes its Popup before the next grab.
                    host.active = false;
                    scene.index++;
                    host.active = true;
                    open.start();
                });
            } catch (error) { scene.fail(error); }
        }
    }
}
