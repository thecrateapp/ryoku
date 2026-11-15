import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import Ryoku.Ryogami

// The Ryogami card labels, the card frame and the masthead in the crate and the
// stock look. Under crate the current card's tags and name stand upright in the
// mono's tracked caps (never italic, never slanted with the card), the applied
// wallpaper is a tag filled with the mark and the lead bar is gone, the card
// field draws a 1 px edge in the mark at the shared corner, and the masthead is
// the shell's glass in a hairline at Tokens.radius with mono caps tabs, a field
// box for search, the pick edge in its menus and the theme strip on the same
// glass, its second line in the mono caps too. The stock look keeps every one of
// its own values.
ShellRoot {
    id: probe

    FloatingWindow {
        id: win
        implicitWidth: 1400
        implicitHeight: 900

        PickerState {
            id: pickerState
            view: LibraryView { collection: pickerState.collection }
            shown: true
            filterBarToggled: true
        }

        Item {
            id: stage
            anchors.fill: parent

            CardLabel {
                id: card
                x: 300; y: 320
                width: 700; height: 360
                sx: 48
                type: "static"
                name: "crate-groove.webp"
                badges: 1 | 32
            }
            CardLabel {
                id: scene
                x: 300; y: 720
                width: 400; height: 120
                type: "we"
                name: "scene"
                badges: 0
            }
            MenuRow { id: picked; x: 40; y: 300; width: 220; label: "Colour"; selected: true }
            MenuRow { id: plain; x: 40; y: 340; width: 220; label: "Name" }
        }

        FilterBar { id: bar; anchors.fill: parent; state: pickerState }
        ThemeBar { id: strip; anchors.fill: parent; state: pickerState }
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
    function findAll(item, name, out) {
        if (!item) return out;
        if (item.objectName === name) out.push(item);
        for (const child of item.children) findAll(child, name, out);
        return out;
    }
    function check(test, reason) { if (!test) throw new Error(reason); }
    // a colour a Text or Rectangle stores is 8 bit per channel, the role it came from is not
    function same(a, b) { return Qt.colorEqual(a, b) || String(Qt.color(a)) === String(Qt.color(b)); }
    // the horizontal drift of an item's left edge from its top to its bottom on screen
    function slant(item) {
        const top = item.mapToItem(stage, 0, 0);
        const bottom = item.mapToItem(stage, 0, item.height);
        return bottom.x - top.x;
    }
    function caps(text) {
        return text.font.capitalization === Font.AllUppercase && !text.font.italic;
    }

    Timer {
        interval: 700
        running: true
        onTriggered: {
            Tokens.controlsCrate = true;
            pickerState.themeBarOpen = true;
            // the masthead shows whatever filterBarAlwaysVisible says
            if (!pickerState.filterBarShown)
                pickerState.filterBarToggled = !pickerState.filterBarToggled;
            crateCheck.start();
        }
    }

    Timer {
        id: crateCheck
        interval: 600
        onTriggered: {
            check(Theme.crate, "Theme follows controls crate");

            const frame = Theme.cardFrame;
            check(frame.currentEdge === 1 && frame.cornerRadius === Tokens.radius, "crate: a 1 px current edge at the shared corner");
            check(same(Theme.cardEdge, Tokens.mark), "crate: the current edge in the mark");

            const typeText = find(find(card, "cardTypeTag"), "cardTagText");
            check(typeText.text === "Still" && caps(typeText), "crate: the type reads STILL in caps, not italic");
            check(typeText.font.family === Tokens.mono && typeText.font.family === Theme.mono, "crate: the type tag is the mono");
            check(Math.abs(typeText.font.letterSpacing - Tokens.trackLabel) < 0.05, "crate: the type tag is tracked");
            check(same(typeText.color, Tokens.inkMuted), "crate: the type tag in muted ink");
            check(find(find(scene, "cardTypeTag"), "cardTagText").text === "Scene", "crate: a scene reads SCENE");
            const tag = find(card, "cardTypeTag");
            check(tag.radius === Tokens.radius && same(tag.color, Tokens.glass) && same(tag.border.color, Tokens.line), "crate: the tag is glass in a hairline at the shared corner");

            const name = find(card, "cardNameText");
            check(name.text === "crate-groove.webp" && caps(name), "crate: the name in caps, not italic");
            check(name.font.family === Tokens.mono && Math.abs(name.font.pixelSize - Theme.fontMicro) < 1, "crate: the name is the mono's small label");
            check(same(name.color, Tokens.inkMuted), "crate: the name in muted ink");
            check(Math.abs(slant(name)) < 0.5, "crate: the name stands upright on the skewed card (" + slant(name) + ")");
            check(Math.abs(slant(find(card, "cardTags"))) < 0.5, "crate: the tags stand upright on the skewed card");
            check(slant(find(card, "cardNameBand")) < -2, "crate: the band still follows the card's slant");

            const live = find(card, "cardLiveTag");
            check(live.visible && same(live.color, Tokens.mark) && same(find(live, "cardTagText").color, Tokens.paper), "crate: the applied wallpaper is a tag filled with the mark");
            const fav = find(card, "cardFavTag");
            check(fav.visible && fav.height === tag.height && live.height === tag.height && fav.width === fav.height, "crate: the corner tags share one height");
            check(!find(card, "cardLeadBar").visible, "crate: no lead bar");
            check(same(find(card, "cardNameBand").color, Tokens.glass), "crate: the name band is the glass");

            const slab = find(bar, "mastheadSlab");
            check(slab.radius === Tokens.radius, "crate: masthead radius is Tokens.radius");
            check(same(slab.color, Tokens.glass) && slab.border.width === 1 && same(slab.border.color, Tokens.line), "crate: masthead is one glass in a hairline");
            const tabs = findAll(bar, "collectionTabLabel", []).filter(t => t.visible);
            check(tabs.length >= 4, "the four library tabs are drawn");
            for (const t of tabs)
                check(t.font.family === Tokens.mono && caps(t) && Math.abs(t.font.letterSpacing - Tokens.trackLabel) < 0.05, "crate: tab " + t.text + " is mono tracked caps");
            const segs = findAll(bar, "typeSegmentLabel", []).concat(findAll(bar, "barButtonLabel", []));
            check(segs.length >= 4, "the second line's labels are drawn");
            for (const t of segs)
                check(t.font.family === Tokens.mono && caps(t), "crate: control " + t.text + " is mono caps");
            const underline = find(bar, "collectionUnderline");
            check(underline.visible && same(underline.color, Tokens.mark), "crate: the open tab keeps its underline in the mark");
            const box = find(bar, "searchBox");
            check(box.visible && box.radius === Tokens.radius && same(box.border.color, Tokens.line), "crate: search is a hairline field at the shared corner");
            check(same(find(bar, "barMenuPanel").color, Tokens.glass), "crate: dropdowns are the masthead's glass");

            const pickPlate = find(picked, "menuRowPlate");
            check(pickPlate.border.width === 1 && same(pickPlate.border.color, Tokens.pickEdge), "crate: a chosen menu row takes the 1 px pick edge");
            check(find(plain, "menuRowPlate").border.width === 0, "crate: an idle menu row has no edge");

            const panel = find(strip, "themeBarPanel");
            check(panel.radius === Tokens.radius && same(panel.color, Tokens.glass) && same(panel.border.color, Tokens.line), "crate: the theme strip is the glass in a hairline");

            Tokens.controlsCrate = false;
            stockCheck.start();
        }
    }

    Timer {
        id: stockCheck
        interval: 600
        onTriggered: {
            check(!Theme.crate, "stock look");
            const frame = Theme.cardFrame;
            check(frame.currentEdge === 3 && frame.cornerRadius === -1, "stock: the 3 px edge and the layout's own corners");
            check(same(Theme.cardEdge, Theme.primary), "stock: the edge in the accent");

            const typeText = find(find(card, "cardTypeTag"), "cardTagText");
            check(typeText.text === "PIC" && typeText.font.family === Theme.sans && typeText.font.capitalization === Font.MixedCase, "stock: the PIC badge keeps its face");
            check(typeText.font.weight === Font.DemiBold && same(typeText.color, Theme.withAlpha(Theme.surfaceText, 0.92)), "stock: the badge keeps its weight and ink");
            const tag = find(card, "cardTypeTag");
            check(same(tag.color, Theme.withAlpha(Theme.background, 0.72)) && same(tag.border.color, Theme.withAlpha(Theme.outline, 0.40)), "stock: the badge keeps its plate");
            const name = find(card, "cardNameText");
            check(name.font.family === Theme.sans && name.font.capitalization === Font.MixedCase && Math.abs(name.font.pixelSize - Theme.fontBody) < 1, "stock: the name keeps its face and size");
            check(same(name.color, Theme.surfaceText) && name.font.weight === Font.DemiBold, "stock: the name keeps its ink and weight");
            check(slant(name) < -1, "stock: the words slant with the card, as before");
            check(!find(card, "cardLiveTag").visible && find(card, "cardLeadBar").visible, "stock: the applied wallpaper keeps its lead bar");
            check(same(find(card, "cardNameBand").color, Theme.withAlpha(Theme.background, 0.62)), "stock: the band keeps its scrim");

            const slab = find(bar, "mastheadSlab");
            check(Math.abs(slab.radius - 6 * Theme.scale) < 1e-6 && same(slab.color, Theme.withAlpha(Theme.surface, 0.95)), "stock: the masthead keeps its slab");
            check(same(slab.border.color, Theme.withAlpha(Theme.outline, 0.5)), "stock: the masthead keeps its edge");
            for (const t of findAll(bar, "collectionTabLabel", []))
                check(t.font.family === Theme.sans && t.font.capitalization === Font.MixedCase && Math.abs(t.font.pixelSize - Theme.fs(14)) < 1, "stock: tab " + t.text + " keeps its face");
            check(!find(bar, "collectionUnderline").visible, "stock: the tabs keep the plate");
            for (const t of findAll(bar, "typeSegmentLabel", []).concat(findAll(bar, "barButtonLabel", [])))
                check(t.font.family === Theme.sans && t.font.capitalization === Font.MixedCase && Math.abs(t.font.pixelSize - Theme.fs(12.5)) < 1, "stock: control " + t.text + " keeps its face");
            check(!find(bar, "searchBox").visible, "stock: search keeps its rule");
            check(same(find(bar, "barMenuPanel").color, Theme.withAlpha(Theme.surface, 0.985)), "stock: dropdowns keep their panel");
            check(find(picked, "menuRowPlate").border.width === 0, "stock: a chosen menu row keeps its tick, no edge");
            check(same(find(strip, "themeBarPanel").color, Theme.withAlpha(Theme.surface, 0.97)), "stock: the theme strip keeps its panel");
            console.log("RYOGAMI-CARD-PROBE-PASS");
            Qt.quit();
        }
    }
}
