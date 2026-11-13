import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import "pages" as Pages
import "pages/users" as Users

ShellRoot {
    id: probe
    readonly property bool crate: Quickshell.env("RYOKU_PROBE_MODE") === "crate"
    property int failures: 0
    Binding { target: Tokens; property: "outlineSelections"; value: Tokens.controlsCrate }

    function check(ok, message) {
        if (!ok) {
            failures++;
            console.log("HUB-CONTROLS-FAIL " + message);
        }
    }
    function named(root, name) {
        const found = [];
        function visit(item) {
            if (item.objectName === name)
                found.push(item);
            for (const child of item.children || [])
                visit(child);
        }
        visit(root);
        return found;
    }
    function meter(root, name, value) {
        const items = named(root, name);
        check(items.length === 1, name + " count " + items.length);
        if (items.length) {
            const beam = items[0];
            check(beam.visible === crate && !beam.interactive && !beam.activeFocusOnTab
                && Math.abs(beam.frac - value) < 0.001 && beam.width > 0, name + " progress " + beam.frac);
        }
    }
    function visibleText(root, value) {
        if (!root || !root.visible)
            return false;
        return root.text === value || (root.children || []).some(x => visibleText(x, value));
    }
    function plate(item, stockColor, stockBorder, name) {
        check(item && item.visible && item.width > 0 && item.height > 0, name + " opens");
        if (!item)
            return;
        check(item.color == (crate ? Tokens.popover : stockColor) && item.color.a === 1, name + " opaque surface");
        check(item.radius === Tokens.radius && item.border.width === (crate ? 1 : stockBorder), name + " corners and line");
    }
    function checkPickerCorners() {
        for (const picker of [appPicker, appSetPicker]) {
            picker.visible = true;
            const card = named(picker, "appPickerPlate")[0];
            check(card && card.visible && card.width > 0 && card.height > 0
                && card.radius === (crate ? Tokens.radius : Tokens.radius * 2), "application picker corners");
            picker.visible = false;
        }
        const popup = colorField.data.find(item => item.objectName === "colorPickerDialog");
        check(!!popup, "color picker exists");
        if (popup) {
            popup.open();
            check(popup.visible && popup.background.width > 0 && popup.background.height > 0
                && popup.background.radius === (crate ? Tokens.radius : 0), "color picker corners");
            popup.close();
        }
    }
    function checkDialogs() {
        // Standalone popups: there is no account service or submitted-signal handler.
        addPerson.openForCreate();
        changePassword.openFor("fixture");
        storageLimit.openFor("fixture", 1024);
        removePerson.openFor("fixture");
        for (const [dialog, eyebrow] of [[addPerson, "ADD PERSON"], [changePassword, "RESET PASSWORD"],
                [storageLimit, "HOME STORAGE"], [removePerson, "REMOVE PERSON"]]) {
            plate(dialog.background, Tokens.paper, Tokens.border, eyebrow);
            const label = named(dialog.contentItem, "dialogEyebrow")[0];
            check(dialog.modal && label && label.visible === !crate && label.text === I18n.tr(eyebrow), eyebrow + " heading");
            dialog.close();
            check(!dialog.visible, eyebrow + " closes");
        }
        const download = named(dictation, "dictationConfirmation")[0];
        const remove = named(addons, "addonRemoval")[0];
        const print = named(locks, "fingerprintDialog")[0];
        plate(download, Tokens.bone, 2, "download");
        plate(remove, Tokens.bone, 2, "remove");
        plate(print, Tokens.paperLift, Tokens.border, "fingerprints");
        check(visibleText(download, I18n.tr("CANCEL")) && visibleText(remove, I18n.tr("CANCEL")), "confirmations retain cancel");
        check(visibleText(print, I18n.tr("VERIFY")) === !crate, "fingerprint eyebrow");
        const dismiss = named(locks, "fingerprintDismiss")[0];
        check(dismiss && dismiss.visible === crate && (!crate || dismiss.width === 44), "fingerprint close");
        if (crate && dismiss) {
            dismiss.clicked();
            check(!print.visible, "fingerprint closes");
        }
    }
    function run() {
        check(Tokens.controlsCrate === crate, "theme loaded");
        checkPickerCorners();
        checkDialogs();
        meter(user, "storageQuota", 0.75);
        meter(update, "updateProgress", 0.4);
        meter(update, "updatePieceProgress", 0.6);
        meter(dictation, "dictationDownloadProgress", 0.5);
        const permissions = named(user, "permission");
        check(permissions.length === (crate ? 1 : 0), "permission skin");
        if (crate && permissions.length) {
            const chip = permissions[0];
            check(!chip.on && chip.enabled && chip.width > 0, "permission initial");
            chip.clicked();
            check(chip.on && user.selectedPermissions.length === 1, "one permission selection");
            check(chip.border.width === 1 && chip.color.a === 0 && chip.radius === Tokens.radius, "outline and radius");
            user.canManage = false;
            check(!chip.enabled, "read-only permission");
        }
        const edge = named(displays, "displayProfileEdge")[0];
        check(edge && edge.border.width === (crate ? 1 : 0) && (!crate || edge.border.color == Tokens.pickEdge), "matching display profile");
        const preview = named(controls, "controlsPreviewBlock");
        check(preview.length > 0 && (!crate || preview.some(b => b.border.color == Tokens.pickEdge)), "selected controls block");
        const provider = named(compositor, "currentProvider")[0];
        check(provider && provider.visible === crate && !provider.interactive && provider.on, "current provider badge");
        const groups = [[keybinds, "appCandidate"], [keybinds, "shellChip"], [keybinds, "promptChip"],
            [keybinds, "starshipPaletteChip"], [controls, "controlVisibility"], [profile, "profileVisibility"],
            [locks, "signInMode"], [animations, "curvePreset"], [imports, "importStatus"]];
        for (const [owner, role] of groups) {
            const choices = named(owner, role);
            check(crate ? choices.length > 0 : choices.length === 0, role + " skin, count " + choices.length);
        }
        if (crate) {
            const shells = named(keybinds, "shellChip");
            check(shells.some(x => x.on && x.enabled) && shells.some(x => !x.enabled), "shell chosen and unavailable");
            const modes = named(locks, "signInMode");
            check(modes.length === 5 && modes.some(x => x.on), "both authentication options");
            check(named(imports, "importStatus").every(x => !x.interactive), "inert status");
        }
        const glosses = named(rashin, "rashinSectionGloss");
        UiPreferences.showJapaneseGloss = false;
        check(glosses.length > 0 && glosses.every(x => x.text === ""), "Japanese gloss hidden");
        UiPreferences.showJapaneseGloss = true;
        check(glosses.every(x => x.text.length > 0), "Japanese gloss restored");
        const functions = named(rashin, "rashinSectionLabel");
        check(functions.length > 0 && functions.some(x => x.visible === crate && x.text.length > 0), "Rashin group labels");
        const settings = named(fastfetch, "fastfetchSectionLabel");
        check(settings.length === 2 && settings[0].visible === crate, "Fastfetch group labels");
        const tools = named(fastfetch, "compositionTool");
        check(tools.length === (crate ? 8 : 0), "four actions per Fastfetch row: " + tools.length);
        if (crate && tools.length === 8) {
            check(tools.every(b => b.children.some(g => g.drawn === true)), "all tool glyphs are in the Solar catalog");
            check(tools.every(b => b.width === 44 && b.height === 44 && b.glyph.length > 0), "tool dimensions and glyphs");
            const down = tools.find(b => b.glyph === "alt-arrow-down");
            down.clicked();
            check(fastfetch.model.rows[0].text === "Second", "one move");
            const eye = named(fastfetch, "compositionTool").find(b => b.glyph === "eye");
            eye.clicked();
            check(!fastfetch.model.rows[0].enabled, "one toggle");
            const bin = named(fastfetch, "compositionTool").find(b => b.glyph === "trash-bin-minimalistic");
            bin.clicked();
            check(fastfetch.model.rows.length === 1, "one removal");
            fastfetch.model = Object.assign({}, fastfetch.model, {renderer: "locked"});
            check(named(fastfetch, "compositionTool").every(b => !b.enabled), "locked composition");
        }
        update.run = Object.assign({}, update.run, {pieces: [{name: "probe", state: "running"}]});
        const piece = named(update, "updatePieceProgress")[0];
        check(piece && piece.indeterminate, "piece duration unknown");
        keybinds.tab = "shortcuts";
        const categories = named(keybinds, "keybindCategory");
        check(categories.some(b => b.active && b.border.width === (crate ? 1 : 0)), "selected shortcut category");
        if (crate) {
            Tokens.controlsCrate = false;
            check(named(user, "permission").length === 0, "stock replaces Crate chip");
            Tokens.controlsCrate = true;
            check(named(user, "permission").length === 1, "one Crate chip after switching back");
        }
        console.log((failures ? "HUB-CONTROLS-FAILED " : "HUB-CONTROLS-PASS ") + (crate ? "crate" : "stock"));
        Qt.quit();
    }

    FloatingWindow {
        id: win
        visible: true
        implicitWidth: 840
        implicitHeight: 760

        Users.UserCard {
            id: user
            width: parent.width
            userData: ({name: "probe", permissions: [], storage: {supported: true, usedBytes: 75, limitBytes: 100}})
            permissionDefs: [{id: "audio", label: "Audio"}]
            storageCaps: ({quota: true})
            canManage: true
            selfName: ""
            adminCount: 2
        }
        Pages.UpdateRun {
            id: update
            width: parent.width
            run: ({phase: "running", fillFraction: 0.4, label: "Updating", started: 1, now: 101, watch: {}, logLines: [],
                steps: [{key: "build", state: "running", label: "Build"}], piecesStep: "build",
                pieces: [{name: "probe", state: "running", progress: 0.6}], human: n => n + "s"})
        }
        ColorField { id: colorField; width: 180; value: "#0077AA" }
        AppPicker { id: appPicker; anchors.fill: parent; visible: false }
        AppSetPicker { id: appSetPicker; anchors.fill: parent; visible: false }
        Users.AddPersonDialog { id: addPerson }
        Users.PasswordDialog { id: changePassword }
        Users.StorageLimitDialog { id: storageLimit }
        Users.RemovePersonDialog { id: removePerson }
        Pages.AddonsPage { id: addons; anchors.fill: parent }
        Pages.DictationPage { id: dictation; anchors.fill: parent }
        Pages.DisplaysPage { id: displays; anchors.fill: parent }
        CompositorControl { id: compositor; width: 360 }
        Pages.KeybindsPage { id: keybinds; anchors.fill: parent }
        Pages.ControlsPage { id: controls; anchors.fill: parent }
        Pages.LockscreenPage { id: locks; anchors.fill: parent }
        Pages.ProfilePage { id: profile; anchors.fill: parent }
        Pages.ImportPage { id: imports; anchors.fill: parent }
        Pages.AnimationsPage { id: animations; anchors.fill: parent }
        Pages.RashinPage { id: rashin; anchors.fill: parent }
        Pages.FastfetchPage { id: fastfetch; anchors.fill: parent }
        Timer {
            interval: 400
            running: true
            onTriggered: {
                compositor.providers = [{id: "probe", name: "Probe", active: true}];
                displays.profiles = [{name: "probe", matches: true}];
                keybinds.tab = "apps";
                imports.importProbeReady = false;
                imports.step = "resolve";
                keybinds.roles = [{role: "terminal", fallback: "foot", label: "Terminal", candidates: [
                    {installed: true, cmd: "foot", label: "Foot"}, {installed: false, cmd: "other", label: "Other"}]}];
                keybinds.shellState = {current: "bash", choices: [{key: "bash", label: "Bash", installed: true},
                    {key: "zsh", label: "Zsh", installed: false}], zshPrompt: "stock"};
                profile.editing = true;
                fastfetch.model = Object.assign({}, fastfetch.model, {rows: [
                    {kind: "header", text: "First", enabled: true},
                    {kind: "header", text: "Second", enabled: true}
                ]});
                dictation.loaded = true;
                dictation.installed = true;
                dictation.presets = [{key: "demo", label: "Demo", detail: "Example", family: "local", group: "", size: "", cloud: false}];
                dictation.downloading = "demo";
                dictation.dlPercent = 50;
                dictation.pendingDownload = "demo";
                addons.confirmRemove = true;
                addons.confirmName = "Fixture";
                locks.foverlayMode = "verify";
                locks.foverlay = true;
                settle.start();
            }
        }
        Timer { id: settle; interval: 600; onTriggered: probe.run() }
    }
}
