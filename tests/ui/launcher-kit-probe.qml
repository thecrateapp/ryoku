import QtQuick
import Quickshell
import Ryoku.Ui
import Ryoku.Ui.Singletons
import "modules/launcher/shared/Singletons"
import "modules/launcher/shared/lib/results.js" as Results
import "modules/launcher/variants/hero" as Hero
import "modules/launcher/shared" as Shared

// The hero launcher's drawing in both looks. Under crate: the card is the one
// glass (Tokens.glass in a hairline at Tokens.radius, no filled shadow); the
// search is the kit Field with the search glyph, kept in step with the query;
// the modes are kit Chips, the live one filled with the mark; the lead result,
// the picked ledger row, the focused shelf action and the focused window tile
// take the pick wash and the 1 px pickEdge at Tokens.radius; the ledger drops
// its rank numerals and grid rules; captions are tracked mono labels. In stock
// every one of those keeps its old value.
ShellRoot {
    id: probe
    property string look: "crate"

    readonly property var actions: [
        { id: "new-window", name: "New Window", enabled: true },
        { id: "private", name: "Private Window", enabled: true }
    ]
    readonly property var rows: [
        { resultKey: "apps:firefox", providerId: "apps", type: "App", title: "Firefox", icon: "",
          subtitle: "Web browser", primaryAction: { id: "open", name: "Open" },
          secondaryActions: probe.actions },
        { resultKey: "apps:files", providerId: "apps", type: "App", title: "Files", icon: "",
          subtitle: "File manager", primaryAction: { id: "open", name: "Open" }, secondaryActions: [] },
        { resultKey: "find:notes", providerId: "find", type: "File", title: "notes.md", icon: "",
          subtitle: "~/notes.md", primaryAction: { id: "open", name: "Open" }, secondaryActions: [] }
    ]

    FloatingWindow {
        implicitWidth: 900
        implicitHeight: 900

        Hero.LauncherCard {
            id: card
            width: 720
            height: 600
            s: 1
            longRadius: 16
            shortRadius: 3

            Hero.HeroShutter {
                id: hero
                width: 720
                height: 126
                s: 1
                compressed: true
                activeMode: "all"
            }
            Hero.ResultDrawer {
                id: drawer
                y: 126
                width: 720
                s: 1
                open: true
                animationsEnabled: false
                maxHeight: 460
                results: probe.rows
                selectedResult: probe.rows[0]
                selectedResultKey: probe.rows[0].resultKey
                shelfOpen: true
                secondaryActions: probe.actions
                packedLayout: Results.packActions(probe.actions)
                focusedActionId: "new-window"
            }
        }

        Shared.CategoryTabs {
            id: tabs
            y: 720
            width: 720
            s: 1
        }

        Row {
            y: 620
            spacing: 8
            Hero.WindowTile {
                id: tilePicked
                s: 1
                title: "Firefox - notes"
                cls: "firefox"
                workspace: "2"
                picked: true
            }
            Hero.WindowTile {
                id: tileIdle
                s: 1
                title: "Firefox - mail"
                cls: "firefox"
                workspace: "3"
            }
        }
    }

    function find(item, name) {
        if (!item) return null;
        if (item.objectName === name) return item;
        for (const child of item.children) {
            const hit = find(child, name);
            if (hit) return hit;
        }
        if (item.contentItem && item.contentItem !== item && item.contentItem.parent === item)
            return find(item.contentItem, name);
        return null;
    }
    function get(item, name) {
        const hit = find(item, name);
        if (!hit) throw new Error(probe.look + ": no " + name);
        return hit;
    }
    function check(test, reason) { if (!test) throw new Error(probe.look + ": " + reason); }
    // compared at 8 bits a channel: a Text keeps its colour as a QRgb
    function same(a, b) { return Qt.color(a).toString() === Qt.color(b).toString(); }
    function clear(c) { return Qt.color(c).a === 0; }

    function verify(crate) {
        // the card: one glass under crate, the drawer plate and its shadow in stock
        const shadow = get(card, "launcherCardShadow");
        const plate = get(card, "launcherCardPlate");
        check(shadow.visible === !crate, "the filled shadow shows only in stock");
        check(same(plate.color, crate ? Tokens.glass : Theme.drawer), "the card's fill, got " + plate.color);
        check(plate.border.width === 1 && same(plate.border.color, crate ? Tokens.line : Theme.frame), "the card's edge");
        check(plate.topLeftRadius === (crate ? Tokens.radius : 16) && plate.topRightRadius === (crate ? Tokens.radius : 3)
            && plate.bottomLeftRadius === (crate ? Tokens.radius : 3) && plate.bottomRightRadius === (crate ? Tokens.radius : 16),
            "the card's corners");

        // the search field
        const kit = get(hero, "heroKitField");
        const line = get(hero, "heroQueryLine");
        check(kit.visible === crate && line.visible === !crate, "the kit Field under crate, the query line in stock");
        check(kit.glyph === "search" && kit.clearOnEscape === false, "the kit Field leads with the search glyph and keeps Escape");
        check(kit.preeditText !== undefined && typeof kit.keyPressed === "function", "the kit Field reports keys and composition");
        hero.query = "fire";
        check(kit.text === "fire", "the kit Field follows the query");
        kit.edited("fox");
        check(hero.query === "fox", "an edit in the kit Field is the query, got " + hero.query);
        hero.query = "";

        // the modes
        check(get(hero, "heroModeChips").visible === crate && get(hero, "heroModeKeys").visible === !crate,
            "kit Chips under crate, the mode keys in stock");
        const all = get(hero, "heroMode-all");
        const img = get(hero, "heroMode-image");
        check(all.on === true && img.on === false && all.text === I18n.tr("ALL"), "the live mode is the chip that is on");

        // the header captions
        const greet = get(hero, "heroDate");
        check(greet.font.family === (crate ? Tokens.mono : Theme.mono)
            && greet.font.pixelSize === (crate ? Tokens.fMicro : 9), "the date caption's face");

        // the drawer: transparent over the glass under crate, a hairline under the header
        const back = get(drawer, "drawerBackdrop");
        check(crate ? clear(back.color) : same(back.color, Theme.drawer), "the drawer's backdrop");
        check(same(get(drawer, "drawerRule").color, crate ? Tokens.line : Theme.frame), "the header rule");

        // the lead result
        const lead = get(drawer, "heroLead");
        check(same(lead.color, crate ? Tokens.pickFill : Theme.leadContainer), "the lead's fill");
        check(lead.border.width === (crate ? Tokens.border : 2)
            && same(lead.border.color, crate ? Tokens.pickEdge : Theme.bright), "the lead's edge");
        check(lead.radius === (crate ? Tokens.radius : 0), "the lead's corner");
        const leadTitle = get(get(drawer, "lead-incoming"), "leadTitle");
        check(same(leadTitle.color, crate ? Tokens.pickInk : Theme.onLead)
            && leadTitle.font.family === (crate ? Tokens.ui : Theme.font), "the lead's title");

        // the ledger
        const pick = get(drawer, "resultPick");
        check(same(pick.color, crate ? Tokens.pickFill : Theme.pickRow), "the picked row's fill");
        check(pick.border.width === 1 && same(pick.border.color, crate ? Tokens.pickEdge : Theme.pickEdge), "the picked row's 1 px edge");
        check(pick.radius === (crate ? Tokens.radius : 0), "the picked row's corner");
        check(get(drawer, "resultRank").visible === !crate, "the rank numerals show only in stock");
        check(get(drawer, "resultRule").visible === !crate, "the ledger rules show only in stock");
        const title = get(drawer, "resultTitle");
        check(title.font.pixelSize === (crate ? Tokens.fBody : 11), "the row title's size");
        const sub = get(drawer, "resultSub");
        check(sub.font.family === (crate ? Tokens.mono : Theme.mono)
            && (crate ? sub.font.pixelSize === Tokens.fMicro : Math.abs(sub.font.pixelSize - 7.5) <= 0.5),
            "the row's type caption");

        // the action shelf
        const focused = get(drawer, "action-new-window");
        const idle = get(drawer, "action-private");
        check(same(focused.color, crate ? Tokens.pickFill : Theme.drawerRaised)
            && same(focused.border.color, crate ? Tokens.pickEdge : Theme.frame)
            && focused.radius === (crate ? Tokens.radius : 0), "the focused action");
        check(same(idle.border.color, crate ? Tokens.line : Theme.hair), "an idle action's edge");

        // the window rail tiles
        check(same(tilePicked.color, crate ? Tokens.glass : Theme.leadContainer), "the focused tile's fill");
        check(tilePicked.border.width === (crate ? Tokens.border : 2)
            && same(tilePicked.border.color, crate ? Tokens.pickEdge : Theme.bright), "the focused tile's edge");
        check(tilePicked.radius === (crate ? Tokens.radius : 5), "the tile's corner");
        check(crate ? same(get(tilePicked, "windowTileWash").color, Tokens.pickFill)
                    : !get(tilePicked, "windowTileWash").visible, "the focused tile's wash");
        check(same(tileIdle.color, crate ? Tokens.glass : Theme.drawerRaised)
            && same(tileIdle.border.color, crate ? Tokens.line : Theme.hair), "an idle tile");
        const plateIcon = get(tilePicked, "windowTileIcon");
        check(crate ? clear(plateIcon.color) : same(plateIcon.color, Qt.rgba(0, 0, 0, 0.18)), "the tile's icon plate");
    }

    function verifyTabs(crate) {
        // the "/" action categories: the kit's Tabs under crate
        const kitTabs = get(tabs, "categoryKitTabs");
        check(kitTabs.visible === crate && get(tabs, "categoryTabs").visible === !crate, "kit Tabs under crate, the stock bar in stock");
        check(kitTabs.current === tabs.activeCategory, "the live tab is the active category");
        kitTabs.chose(tabs.categories[2]);
        check(tabs.activeIndex === 2, "a tab picked on the kit Tabs is the active category");
        tabs.activeIndex = 0;
    }

    Timer {
        id: crateCheck
        interval: 600
        onTriggered: {
            try {
                probe.verify(true);
                probe.verifyTabs(true);
                Tokens.controlsCrate = false;
                Tokens.accentMarks = false;
                Tokens.selectFill = true;
                probe.look = "stock";
                stockCheck.start();
            } catch (e) {
                console.log("LAUNCHER-KIT-PROBE-FAIL " + e.message);
                Qt.quit();
            }
        }
    }
    Timer {
        id: stockCheck
        interval: 600
        onTriggered: {
            try {
                probe.verify(false);
                probe.verifyTabs(false);
                console.log("LAUNCHER-KIT-PROBE-PASS");
            } catch (e) {
                console.log("LAUNCHER-KIT-PROBE-FAIL " + e.message);
            }
            Qt.quit();
        }
    }
    Timer {
        interval: 200
        running: true
        onTriggered: {
            // the Crate theme's switches
            Tokens.controlsCrate = true;
            Tokens.accentMarks = true;
            Tokens.selectFill = false;
            crateCheck.start();
        }
    }
}
