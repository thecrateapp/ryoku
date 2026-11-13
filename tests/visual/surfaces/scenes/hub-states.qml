import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import "pages" as Pages
import "pages/users" as Users

// These states need data or a scroll that an initial Hub route won't supply.
// Each grab is the production component with the same records in both looks.
ShellRoot {
    id: scene
    Binding { target: Tokens; property: "outlineSelections"; value: Tokens.controlsCrate }
    readonly property string look: Quickshell.env("BENCH_LOOK")
    readonly property var names: ["update-run", "user-quota", "dictation-download", "fastfetch-tools", "rashin-functions"]
    property int index: 0

    Window {
        visible: true
        width: 920
        height: scene.index === 0 ? 310 : scene.index === 1 ? 520 : 670
        Rectangle {
            id: sheet
            anchors.fill: parent
            color: Tokens.paper
            Loader {
                id: host
                anchors.fill: parent
                anchors.margins: 24
                sourceComponent: [updates, users, dictation, fastfetch, rashin][scene.index]
            }
        }
    }

    Component {
        id: updates
        Pages.UpdateRun {
            run: ({
                phase: "running", label: "Building packages", watch: {}, unresponsive: false, firstBuild: false,
                started: 1000, now: 101000, beat: 101000, fillFraction: 0.62, piecesStep: "build",
                steps: [{key: "build", label: "Build packages", state: "running", began: 15000}],
                pieces: [{label: "ryoku-ui", state: "ok", took: 6000},
                    {label: "ryoku-shell", state: "running", began: 35000, progress: 0.43, typical: 90000}],
                errorMsg: "", activity: "", logLines: [], human: ms => Math.round(ms / 1000) + "s"
            })
        }
    }
    Component {
        id: users
        Users.UserCard {
            userData: ({name: "studio", fullName: "Studio editor", role: "user", permissions: ["audio"],
                storage: {supported: true, usedBytes: 52 * 1073741824, limitBytes: 96 * 1073741824}})
            permissionDefs: [{id: "audio", label: "Audio"}, {id: "video", label: "Video"}]
            storageCaps: ({quota: true})
            selfName: "operator"
            canManage: true
            adminCount: 1
        }
    }
    Component { id: dictation; Pages.DictationPage {} }
    Component { id: fastfetch; Pages.FastfetchPage {} }
    Component { id: rashin; Pages.RashinPage {} }

    function find(item, predicate) {
        if (predicate(item)) return item;
        for (const child of item.children || []) {
            const hit = find(child, predicate);
            if (hit) return hit;
        }
        return null;
    }
    function scrollTo(item) {
        for (let p = item.parent; p; p = p.parent) {
            if (p.contentY === undefined || !p.contentItem) continue;
            const y = item.mapToItem(p.contentItem, 0, 0).y - 60;
            p.contentY = Math.max(p.originY, Math.min(p.originY + p.contentHeight - p.height, y));
            break;
        }
    }
    Timer {
        id: prepare
        running: true
        interval: 350
        onTriggered: {
            const page = host.item;
            if (!page || Tokens.controlsCrate !== (scene.look === "crate")) {
                console.error("HUB-STATES-FAIL missing page or look", scene.index);
                Qt.quit();
                return;
            }
            if (scene.index === 2) {
                page.loaded = true;
                page.installed = true;
                page.presets = [{key: "whisper-fast", label: "Whisper Small", group: "whisper", family: "local",
                    detail: "Speech recognition", keyKind: "", language: "Multilingual", speed: "Balanced",
                    size: "465 MiB", present: false, cloud: false}];
                page.downloading = "whisper-fast";
                page.dlStage = "download";
                page.dlPercent = 64;
            } else if (scene.index === 3) {
                page.model = Object.assign({}, page.model, {rows: [
                    {kind: "header", label: "Header", text: "Studio workstation", enabled: true},
                    {kind: "module", label: "Operating system", key: "OS", module: "os", enabled: true},
                    {kind: "module", label: "Memory", key: "Memory", module: "memory", enabled: false}]});
                page.committed = page.model;
            }
            position.start();
        }
    }
    Timer {
        id: position
        interval: 200
        onTriggered: {
            const match = [
                x => x.objectName === "updatePieceProgress" && Math.abs(x.frac - 0.43) < 0.001, x => x.objectName === "storageQuota",
                x => x.objectName === "dictationDownloadProgress", x => x.solar === "alt-arrow-up",
                x => x.title === "FUNCTIONS" && x.kanji !== undefined][scene.index];
            const control = scene.find(host.item, match);
            if (!control || control.width <= 0 || (scene.index < 3 && control.visible !== (scene.look === "crate"))) {
                console.error("HUB-STATES-FAIL missing control", scene.names[scene.index], control, control ? control.width : 0, control ? control.visible : false);
                Qt.quit();
                return;
            }
            if (scene.index >= 2) scene.scrollTo(control);
            capture.start();
        }
    }
    Timer {
        id: capture
        interval: 150
        onTriggered: {
            const name = scene.names[scene.index];
            sheet.grabToImage(result => {
                if (!result.saveToFile("/output/hub-" + scene.look + "-" + name + ".png")) {
                    console.error("HUB-STATES-FAIL", name);
                    Qt.quit();
                    return;
                }
                console.log("HUB-STATE", name, scene.look);
                if (scene.index === scene.names.length - 1) {
                    console.log("HUB-STATES-DONE", scene.look);
                    Qt.quit();
                } else {
                    scene.index++;
                    prepare.start();
                }
            });
        }
    }
}
