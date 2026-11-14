import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import shell.services
import "modules/ask"
import "services" as Services

// Loads the Ask bar's surface and the pinned bubble's pieces in one look
// (PROBE_LOOK stock or crate) and checks how they draw. AskBar and AskBubble
// map layer-shell windows, which offscreen Quickshell cannot load, so the probe
// drives what they hold: AskSurface (field, header, modes, drawers, answer,
// chat, tools, web) and AskBubbleDisc, AskBubbleCard and AskDismissTarget.
ShellRoot {
    id: shell

    readonly property bool crate: Quickshell.env("PROBE_LOOK") === "crate"
    property int step: 0
    property var failures: []

    Services.AskSession { id: session }

    // a window, so the transcript and file lists lay out their delegates
    FloatingWindow {
        implicitWidth: 1600
        implicitHeight: 1400
        color: Tokens.popover

        AskSurface {
            id: surface
            width: 720
            s: 1
            screen: Quickshell.screens[0]
            session: session
            active: true
            maximumHeight: 900
        }

        AskChat {
            id: chat
            x: 760
            width: 420
            s: 1
            active: true
            maximumHeight: 520
        }

        AskBubbleDisc { id: disc; x: 760; y: 560; width: 56; height: 56; s: 1; shown: true; unread: true }
        AskBubbleCard { id: card; x: 840; y: 560; width: 300; height: 120; s: 1 }
        AskDismissTarget { id: dismiss; x: 1160; y: 560; s: 1; armed: true; overDismiss: true }
        AskHandoffCard { id: handoff; x: 760; y: 700; width: 420; s: 1; question: "What is Ryoku?"; answer: "A desktop." }
        AskFilePicker { id: picker; x: 760; y: 820; width: 420; s: 1 }
    }

    function fail(message) {
        failures = failures.concat([message]);
        console.log("ASK-KIT-PROBE-FAIL " + message);
    }
    function expect(condition, message) {
        if (!condition)
            fail(message);
    }

    function walk(item, visit) {
        if (!item)
            return;
        visit(item);
        for (let i = 0; i < item.children.length; i++)
            walk(item.children[i], visit);
    }
    function find(item, name) {
        let hit = null;
        walk(item, it => { if (!hit && it.objectName === name) hit = it; });
        return hit;
    }
    function findAll(item, name) {
        const out = [];
        walk(item, it => { if (it.objectName === name) out.push(it); });
        return out;
    }
    function shown(item) {
        return item !== null && item.visible && item.opacity > 0;
    }
    function same(a, b) {
        return Qt.colorEqual(a, b);
    }
    // Visible Material Symbols text: a font icon the kit's Solar glyphs replace.
    function fontIcons(item) {
        const out = [];
        walk(item, it => {
            if (it.visible && it.font !== undefined && it.text !== undefined && it.font.family === "Material Symbols Rounded"
                    && String(it.text).length > 0)
                out.push(String(it.text));
        });
        return out;
    }
    // Visible kit glyphs that fell back to the font.
    function undrawnGlyphs(item) {
        const out = [];
        walk(item, it => {
            if (it.visible && it.drawn !== undefined && it.fallbackFont !== undefined && !it.drawn && String(it.name).length > 0)
                out.push(String(it.name));
        });
        return out;
    }
    // Visible fills or edges in bone, the stock look's pick and press colour.
    function boneSurfaces(item) {
        const out = [];
        walk(item, it => {
            if (!it.visible || it.border === undefined || it.radius === undefined)
                return;
            if ((it.color.a > 0 && same(it.color, Tokens.bone)) || (it.border.width > 0 && same(it.border.color, Tokens.bone)))
                out.push(it.objectName || String(it));
        });
        return out;
    }
    function everything() {
        return [surface, chat, disc, card, dismiss, handoff, picker];
    }

    function convoRow(fields) {
        const row = {
            kind: "msg", key: String(Needle.convo.count), role: "", body: "", thought: "", open: false, live: false,
            cont: false, failed: false, imagesJson: "[]", toolId: "", title: "", tkind: "", status: "", input: "",
            output: "", diffsJson: "[]", auto: false, permJson: "", askId: "", question: "", answer: ""
        };
        for (const key in fields)
            row[key] = fields[key];
        Needle.convo.append(row);
    }

    Component.onCompleted: {
        Tokens.controlsCrate = crate;
        if (crate) {
            Tokens.accentMarks = true;
            Tokens.labelAccent = true;
            Tokens.focusAccent = true;
            Tokens.selectFill = false;
        }
        session.phase = "done";
        session.askedQuestion = "What is the Crate accent?";
        session.answerText = "The Crate accent is a warm red.";
        session.answerActions = [{ kind: "color", value: "#e2342a", label: "#e2342a" }];
        Stash.queueModel.append({ kind: "download", arg: "https://example.org/v", mode: "auto", name: "ambient-set.webm",
            title: "", state: "running", pct: 42, msg: "", saved: false, fmt: "", key: "" });
    }

    Timer {
        interval: 250
        running: true
        repeat: true
        onTriggered: {
            shell.step++;
            if (shell.step === 1) {
                // after the chat surface opened (opening re-projects an empty
                // transcript), and the picker opens as the Tools mode opens it
                shell.convoRow({ role: "user", body: "Which kernel am I on?" });
                shell.convoRow({ kind: "tool", toolId: "t1", title: "uname -r", tkind: "execute", status: "running" });
                shell.convoRow({ role: "agent", body: "You are on **7.3.4-1-cachyos**." });
                picker.open = true;
            } else if (shell.step === 2)
                shell.checkAsk();
            else if (shell.step === 3) {
                session.phase = "working";
                session.working = "Thinking";
            } else if (shell.step === 4) {
                picker.toggle(picker.home + "/clip.mp4");
                shell.checkWorking();
                surface.toggleModel();
            } else if (shell.step === 6) {
                Needle.quickLane = { route: "agent", routes: [
                    { id: "agent", label: "Agent", sub: "the full agent" },
                    { id: "fast", label: "Fast", sub: "a quick model" }] };
            } else if (shell.step === 8) {
                shell.checkDrawer();
                surface.closeDrawers();
                surface.mode = "tools";
            } else if (shell.step === 10) {
                shell.checkTools();
                shell.checkChat();
                shell.checkBubble();
                shell.checkWhole();
                if (shell.failures.length === 0)
                    console.log("ASK-KIT-PROBE-PASS " + Quickshell.env("PROBE_LOOK"));
                Qt.quit();
            }
        }
    }

    function checkAsk() {
        expect(same(surface.color, crate ? Tokens.glass : Tokens.paper), "the bar fills with " + (crate ? "the glass" : "paper"));
        expect(same(surface.border.color, crate ? Tokens.line : Tokens.lineStrong), "the bar's edge");
        expect(surface.casts === !crate, "the bar casts its shadow only in the stock look");
        expect(shown(find(surface, "askHead")) === crate, "the tracked head replaces the // eyebrow under crate only");
        expect(shown(find(surface, "askHistoryButton")) === crate && shown(find(surface, "askModelButton")) === crate,
            "the header buttons are kit IconButtons under crate only");
        expect(shown(find(surface, "askModeSeg")) === crate, "the modes are a kit Seg under crate only");
        expect(shown(find(surface, "askRouteGlyph")) === crate, "the route pill's glyph is the kit's under crate only");
        const chips = findAll(surface, "askActionChip").filter(shown);
        expect(chips.length === (crate ? 5 : 0), "the answer's actions are kit Chips under crate only: " + chips.length);
        if (crate) {
            expect(chips.some(c => c.swatched && same(c.swatch, "#e2342a")), "a colour action shows its swatch");
            expect(chips[0].on && !chips[1].on, "the selected action is the one chip on");
            const field = find(surface, "askWorkBeam").parent;
            expect(same(field.color, "transparent"), "the field is a hairline on the glass");
        }
    }

    function checkWorking() {
        expect(shown(find(surface, "askWorkBeam")) === crate, "a kit Beam runs along the working field under crate only");
        expect(shown(find(surface, "askBorderBeam")) === !crate, "the border beam is the stock look's");
    }

    function checkDrawer() {
        const rows = findAll(surface, "askDrawerRow").filter(shown);
        expect(rows.length === 2, "the model drawer lists both routes: " + rows.length);
        const picks = findAll(surface, "askDrawerPick").filter(shown);
        expect(picks.length === (crate ? 1 : 0), "the route in use carries the pick dot under crate only");
        if (crate && rows.length === 2) {
            expect(same(rows[0].border.color, Tokens.pickEdge) && same(rows[0].color, Tokens.pickFill),
                "the active row takes the pick wash and edge");
            expect(same(rows[1].border.color, "transparent"), "a quiet row has no edge");
        }
        if (!crate && rows.length === 2)
            expect(same(rows[0].color, Tokens.bone), "the stock cursor row fills with bone");
    }

    function checkTools() {
        const commands = findAll(surface, "askToolsCommand").filter(shown);
        expect(commands.length === (crate ? 7 : 0), "the commands are kit PickRows under crate only: " + commands.length);
        expect(shown(find(surface, "askToolsModeSeg")) === crate, "the download mode is a kit Seg under crate only");
        expect(shown(find(surface, "askToolsEngineSwitch")) === crate, "the engine toggle is a kit Sw under crate only");
        const jobBeam = find(surface, "askToolsJobBeam");
        expect(shown(jobBeam) === crate, "a running job's progress is a kit Beam under crate only");
        if (crate)
            expect(Math.abs(jobBeam.value - 0.42) < 0.001 && !jobBeam.interactive, "the job Beam reads the job's percent");
        expect(shown(find(surface, "askToolsJobCancel")) === crate, "a job's cancel is a kit IconButton under crate only");
    }

    function checkChat() {
        expect(shown(find(chat, "askChatSend")) === crate, "the composer sends through a kit IconButton under crate only");
        expect(shown(find(chat, "askChatTerminal")) === crate && shown(find(chat, "askChatNew")) === crate,
            "the chat's actions are kit Btns under crate only");
        expect(findAll(chat, "askChatToolBeam").filter(shown).length === (crate ? 1 : 0),
            "a running tool call shows a kit Beam under crate only");
        const model = find(chat, "askChatModel");
        expect(same(model.color, crate ? "transparent" : Tokens.tint5), "the model button's fill");
        expect(shown(find(handoff, "askHandoffCaption")) === crate, "the handoff caption is a kit TrackLabel under crate only");
        expect(shown(find(picker, "askPickerConfirm")) === crate && shown(find(picker, "askPickerCount")) === crate,
            "the file picker's actions and count come from the kit under crate only");
        const fileRows = findAll(picker, "askPickerRow").filter(shown);
        expect(crate ? fileRows.length >= 3 : fileRows.length === 0, "the files are kit PickRows under crate only: " + fileRows.length);
        if (crate) {
            const clip = fileRows.filter(r => r.title === "clip.mp4")[0];
            expect(clip && clip.picked, "a chosen file is the picked row");
        }
    }

    function checkBubble() {
        expect(same(card.color, crate ? Tokens.glass : Tokens.paper), "the bubble's card fills with " + (crate ? "the glass" : "paper"));
        expect(same(find(disc, "askBubbleDisc").color, crate ? Tokens.glass : Tokens.bone), "the bubble's disc");
        expect(shown(find(disc, "askBubbleShadow")) === !crate, "the bubble casts its shadow only in the stock look");
        expect(same(find(disc, "askBubbleUnread").color, crate ? Tokens.mark : Tokens.ink), "the unread dot");
        expect(dismiss.radius === (crate ? Tokens.radius : dismiss.height / 2), "the remove target's corner");
        expect(same(dismiss.border.color, crate ? Tokens.alert : Tokens.bone), "the remove target lights when the bubble is over it");
        expect(shown(find(dismiss, "askDismissGlyph")) === crate, "the remove target's glyph is the kit's under crate only");
    }

    function checkWhole() {
        let icons = [], undrawn = [], bone = [];
        for (const part of everything()) {
            icons = icons.concat(fontIcons(part));
            undrawn = undrawn.concat(undrawnGlyphs(part));
            bone = bone.concat(boneSurfaces(part));
        }
        if (crate) {
            expect(icons.length === 0, "no Material Symbols font icons under crate: " + icons.join(", "));
            expect(undrawn.length === 0, "every kit glyph is in the Solar catalogue: " + undrawn.join(", "));
            expect(bone.length === 0, "no stock bone fills or edges under crate: " + bone.join(", "));
        } else {
            expect(icons.indexOf("memory") >= 0 && icons.indexOf("download") >= 0 && icons.indexOf("arrow_upward") >= 0,
                "the stock look keeps its font icons: " + icons.join(", "));
        }
    }
}
