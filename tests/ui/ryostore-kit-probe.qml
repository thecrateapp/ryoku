import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import "ryostore" as Ryo

// Ryostore on the kit, in both looks: the install progress is a Beam under crate
// (its sweep when the total is unknown) and the stock track otherwise; provider
// strips are the kit's keyed Tabs; cards and tiles draw through PickCard; the
// hero tags are read-only Chips; the search fields are the kit Field; detail
// links are plateless IconButtons with Solar glyphs; the window is opaque.
ShellRoot {
    id: probe
    property string look: "crate"
    property string picked: "-"
    property string edited: "-"
    property int cleared: 0

    FloatingWindow {
        implicitWidth: 1180
        implicitHeight: 760
        Item {
            id: stage
            x: 60; y: 60
            width: 1100; height: 680
            Ryo.App { id: app; width: 1100; height: 680; visible: false }
            Ryo.InstallProgress { id: known; width: 300; stage: "download"; done: 30; total: 100; active: true }
            Ryo.InstallProgress { id: unknown; y: 60; width: 300; stage: "extract"; done: 0; total: 0; active: true }
            Ryo.ProviderTabs {
                id: providers
                y: 120; width: 800
                providers: [{ key: "games", label: "GAMES", note: "4" }, "Arc"]
                active: "games"
                allLabel: "ALL"
                onPicked: key => probe.picked = key
            }
            Ryo.ProductCard {
                id: card
                y: 180; width: 260; height: 220
                item: ({ id: "neon", category: "rices", name: "Neon", summary: "Cyan on near black" })
                selected: true
            }
            Ryo.AppsTile {
                id: tile
                x: 280; y: 180; width: 320; height: 96
                item: ({ id: "org.example.Alpha", category: "flatpak", name: "Alpha", summary: "Graphs", installed: true })
                selected: true
            }
            Ryo.CategorySearch {
                id: search
                x: 280; y: 300; width: 300
                onEdited: value => probe.edited = value
                onCleared: probe.cleared++
            }
            Ryo.AppsHero {
                id: hero
                x: 620; y: 180; width: 460; height: 200
                items: [{ id: "org.example.Alpha", category: "flatpak", name: "Alpha", summary: "Graphs", installed: true, verificationStatus: "verified", tags: ["network"] }]
            }
        }
        Ryo.ProductDetail {
            id: detail
            anchors.fill: parent
            open: true
            originRect: Qt.rect(60, 420, 220, 180)
            item: ({ id: "paper", category: "rices", name: "Paper", summary: "Warm", installed: true,
                     upstream: "https://example.org/paper", discord: "https://example.org/chat" })
        }
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
    function all(item, test, out) {
        if (!item) return out;
        if (test(item)) out.push(item);
        for (const child of item.children) all(child, test, out);
        return out;
    }
    function check(test, reason) { if (!test) throw new Error(probe.look + ": " + reason); }

    function verify(crate) {
        check(Qt.colorEqual(app.color, crate ? Tokens.popover : Tokens.paper) && app.color.a === 1, "an opaque window surface");
        for (const progress of [known, unknown]) {
            const beam = find(progress, "ryostore-install-beam");
            check(beam.visible === crate, "the Beam shows only under crate");
            check(all(progress, i => i.objectName === "" && i.color !== undefined && i.height === 3, []).every(t => t.visible === !crate), "the stock track shows only in stock");
        }
        check(!find(known, "ryostore-install-beam").indeterminate && find(known, "ryostore-install-beam").value === 0.3, "a known total fills the Beam");
        check(find(unknown, "ryostore-install-beam").indeterminate, "an unknown total sweeps");
        const kit = find(providers, "ryostore-provider-kit-tabs");
        check(kit.visible === crate, "provider strip is the kit Tabs under crate");
        check(kit.options.length === 3 && kit.options[0].key === "" && kit.options[1].note === "4" && kit.options[2].key === "Arc",
              "the strip's entries become keyed tabs");
        check(kit.current === "games", "the active provider is the current tab");
        check(find(providers, "ryostore-provider-games").visible === !crate, "stock plates show only in stock");
        const pick = find(card, "ryostore-card-pick");
        check(pick.visible === crate && pick.picked, "the product card draws through PickCard under crate");
        check(find(card, "ryostore-card-frame").visible === !crate, "the stock frame shows only in stock");
        check(find(pick, "ryostore-cover-metadata") !== null === crate, "the card content sits in the PickCard under crate");
        const tilePick = find(tile, "ryostore-tile-pick");
        check(tilePick.visible === crate && tilePick.picked, "the app tile draws through PickCard under crate");
        const tags = all(hero, i => i.objectName === "ryostore-hero-tag" && i.visible, []);
        check(crate ? tags.length >= 2 && tags.every(t => !t.interactive) : tags.length === 0, "hero tags are read-only kit chips under crate");
        const input = find(search, "ryostore-category-search-field");
        check(input !== null && input.visible, "the category search names its input");
        check(crate === (input.parent.glyph === "search"), "the category search is the kit Field under crate");
        const links = all(detail, i => i.objectName === "ryostore-link-button", []);
        check(links.length === 2 && links.every(l => l.visible === crate), "links are kit IconButtons under crate");
        check(!crate || (links[0].glyph === "link-round" && links[1].glyph === "chat-round-dots"), "links use Solar glyphs");
    }

    Timer {
        id: crateCheck
        interval: 600
        onTriggered: {
            probe.verify(true);
            providers.picked("Arc");
            const input = probe.find(search, "ryostore-category-search-field");
            input.text = "moss";
            input.textEdited();
            probe.check(probe.edited === "moss", "the kit field reports edits");
            input.parent.escaped();
            probe.check(probe.cleared === 1 && input.text === "", "escape clears the kit field");
            Tokens.controlsCrate = false;
            probe.look = "stock";
            stockCheck.start();
        }
    }
    Timer {
        id: stockCheck
        interval: 600
        onTriggered: {
            probe.verify(false);
            probe.check(probe.picked === "Arc", "a picked tab reports its key");
            console.log("RYOSTORE-KIT-PROBE-PASS");
            Qt.quit();
        }
    }
    Timer {
        interval: 200
        running: true
        onTriggered: {
            Tokens.controlsCrate = true;
            crateCheck.start();
        }
    }
}
