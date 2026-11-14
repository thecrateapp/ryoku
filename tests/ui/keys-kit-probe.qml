import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import "keys" as Keys
import "keys/phone" as Phone
import "keys/typing" as Typing
import "keys/devtools" as Dev
import "keys-hint" as Hint

// Kit and its first-boot hint on the kit, in the look PROBE_LOOK names. Under
// crate the Kit card is opaque panel grey on the shared corner; its head is the
// kit PageHeader, its tabs the kit Tabs (a tab switches), its close an
// IconButton, its search glyph a Glyph, its footer and heads TrackLabels, and
// the live rail entry takes the 1 px pick edge with no mark bar; the masthead
// and marginalia are gone. The hint cards are the crate glass with no lead
// rule and a kit close. The typing toolbar and a tool's choices are kit Chips,
// the test's progress a Beam, the phone settings an IconButton, a reached setup
// step and an action tile take the mark and the hairline. Stock keeps every
// one of its own drawings; the crate run also switches to stock live.
ShellRoot {
    id: probe

    property string look: Quickshell.env("PROBE_LOOK") || "crate"

    readonly property var categories: [
        { name: "Windows", binds: [
            { keys: ["Super", "Q"], desc: "Close window", hint: "Closes the focused window" },
            { keys: ["Super", "F"], desc: "Fullscreen", hint: "" }
        ] },
        { name: "Workspaces", binds: [
            { keys: ["Super", "1"], desc: "Go to workspace 1", hint: "" }
        ] }
    ]

    FloatingWindow {
        implicitWidth: 1340
        implicitHeight: 860
        Keys.Kit {
            id: kit
            anchors.fill: parent
            categories: probe.categories
            loaded: true
        }
    }

    FloatingWindow {
        implicitWidth: 900
        implicitHeight: 900
        Column {
            spacing: 12
            Hint.HintCards { id: hint }
            Phone.PhonePaneHeader { id: phoneHead; width: 600; client: fakeClient }
            Phone.PhoneSetupStep { id: step; width: 400; step: 1; current: true; title: "Pair" }
            Phone.PhoneActionTile { id: tile; width: 200; glyph: "keyboard"; label: "Type"; detail: "Send text" }
            Typing.TypingTestToolbar { id: toolbar; width: 600; store: fakeStore }
            Dev.ToolOption {
                id: option
                width: 400
                option: ({ id: "case", label: "Case", type: "choice",
                           choices: [{ value: "lower", label: "lower" }, { value: "upper", label: "UPPER" }] })
                value: "lower"
            }
            Keys.CategoryBlock { id: block; width: 600; name: "Windows"; binds: probe.categories[0].binds }
        }
    }

    QtObject {
        id: fakeClient
        property var activeDevice: ({ id: "a", name: "Pixel", type: "phone", reachable: true, charge: 80 })
        property var pairedDevices: [activeDevice, { id: "b", name: "Tab", type: "tablet", reachable: false }]
        function call() { return null; }
    }
    QtObject {
        id: fakeStore
        property bool punctuation: true
        property bool numbers: false
        property string mode: "time"
        property int timeLimit: 30
        property int wordLimit: 25
        property bool zenGuided: false
    }

    function find(item, name) {
        if (!item) return null;
        if (item.objectName === name) return item;
        for (const child of item.children) {
            const hit = find(child, name);
            if (hit) return hit;
        }
        return null;
    }
    function all(item, name, out) {
        if (!item) return out;
        if (item.objectName === name) out.push(item);
        for (const child of item.children) all(child, name, out);
        return out;
    }
    function check(test, reason) { if (!test) throw new Error(probe.look + ": " + reason); }
    function same(a, b) { return Qt.colorEqual(a, b); }

    function verifyKit(crate) {
        const card = find(kit, "kitCard");
        check(card !== null, "the Kit card exists");
        check(same(card.color, crate ? Tokens.popover : Tokens.paperLift) && card.color.a === 1,
            "the card is opaque " + (crate ? "panel grey" : "paperLift"));
        check(card.radius === (crate ? Tokens.radius : Tokens.radius * 1.5), "the card's corner");
        check(find(kit, "kitPageHeader").visible === crate, "the kit PageHeader only under crate");
        check(find(kit, "kitMasthead").visible === !crate, "the masthead (lead rule, seal) only in stock");
        check(find(kit, "kitMarginalia").visible === !crate, "the marginalia only in stock");
        check(find(kit, "kitClose").visible === crate, "the kit close button only under crate");
        check(find(kit, "kitCloseStock").opacity === (crate ? 0 : 1), "the stock close only in stock");
        check(find(kit, "kitSearchGlyph").visible === crate, "the search Glyph only under crate");
        const tabs = find(kit, "kitTabs");
        check(tabs.visible === crate && tabs.options.length === 5, "the kit Tabs under crate, a tab each");
        check(tabs.current === kit.tabs[kit.currentIndex].id, "the live tab is the current one");
        check(find(kit, "kitTabRow").visible === !crate, "the stock tab plates only in stock");
        const live = all(kit, "kitRailItem", []).filter(r => r.selected);
        check(live.length === 1, "one live rail entry");
        check(live[0].border.width === (crate ? Tokens.border : 0), "the live rail entry's pick edge under crate");
        check(!crate || same(live[0].border.color, Tokens.pickEdge), "the pick edge colour");
        const bars = all(kit, "kitRailBar", []).filter(b => b.visible);
        check(bars.length === (crate ? 0 : 1), "the 2 px mark bar only in stock");
        const footer = find(kit, "kitFooter");
        check(footer.font.family === (crate ? Tokens.mono : Tokens.ui), "the footer's face");
        check(footer.font.capitalization === (crate ? Font.AllUppercase : Font.MixedCase), "the footer's case");
    }

    function verifyParts(crate) {
        const cards = all(hint, "hintCard", []);
        check(cards.length === 2, "two hint cards");
        for (const c of cards) {
            check(same(c.color, crate ? Tokens.glass : Tokens.paperLift), "a hint card is the " + (crate ? "glass" : "raised paper"));
            check(c.radius === (crate ? Tokens.radius : Tokens.radius * 1.5), "a hint card's corner");
        }
        check(find(hint, "hintLead").visible === !crate, "the hint's lead rule only in stock");
        check(find(hint, "hintClose").visible === crate, "the hint's kit close only under crate");
        check(find(hint, "hintCloseStock").visible === !crate, "the hint's stock close only in stock");
        check(find(phoneHead, "phoneSettingsButton").visible === crate, "the phone settings IconButton under crate");
        const disc = find(step, "phoneStepDisc");
        check(same(disc.color, crate ? Tokens.mark : Tokens.bone), "a reached setup step's fill");
        check(crate ? tile.color.a === 0 : same(tile.color, Tokens.paperLift), "the action tile's plate");
        check(same(tile.border.color, crate ? Tokens.line : Tokens.lineSoft), "the action tile's edge");
        // the toolbar's options in this mode (zen's "guided" sits hidden)
        const chips = all(toolbar, "typingChip", []).filter(c => c.parent.visible);
        check(chips.length >= 5 && chips.every(c => c.visible === crate), "the typing toolbar's kit Chips under crate");
        check(chips.find(c => c.text === "punctuation").on === true, "a chip that is on");
        const choices = all(option, "toolChoiceChip", []);
        check(choices.length === (crate ? 2 : 0), "a tool's choices are kit Chips under crate");
        check(!crate || choices.find(c => c.text === "lower").on, "the chosen tool option is on");
        check(find(block, "categoryBullet").visible === !crate, "the category lead square only in stock");
        check(find(block, "categoryHead").font.family === (crate ? Tokens.mono
            : (Tokens.navCaps ? Tokens.navFont : Tokens.ui)), "the category head's face");
    }

    function verifyTyping(crate) {
        const beam = find(kit, "typingBeam");
        check(beam !== null, "the typing test loads");
        check(beam.visible === crate && !beam.interactive, "the test's progress is a read-only Beam under crate");
    }

    Timer {
        id: first
        interval: 1200
        onTriggered: {
            const crate = probe.look === "crate";
            probe.check(Tokens.controlsCrate === crate, "the theme loaded");
            probe.verifyKit(crate);
            probe.verifyParts(crate);
            if (crate) {
                probe.find(kit, "kitTabs").chose("commands");
                probe.check(kit.currentIndex === 1, "a kit tab switches");
            }
            kit.openTab("typing", "test");
            second.start();
        }
    }
    Timer {
        id: second
        interval: 1800
        onTriggered: {
            const crate = probe.look === "crate";
            probe.verifyTyping(crate);
            if (!crate) {
                console.log("KEYS-KIT-PROBE-PASS " + probe.look);
                Qt.quit();
                return;
            }
            Tokens.controlsCrate = false;
            live.start();
        }
    }
    Timer {
        id: live
        interval: 400
        onTriggered: {
            probe.look = "crate-then-stock";
            probe.verifyKit(false);
            probe.verifyParts(false);
            probe.verifyTyping(false);
            console.log("KEYS-KIT-PROBE-PASS crate");
            Qt.quit();
        }
    }
    Component.onCompleted: first.start()
}
