import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import "ryopin" as Ryopin
import "ryopin/Singletons" as PinState

// A pinned card in both looks. Under crate the image is content on an opaque
// popover card (the shared corner, a 1 px line, no drop shadow) and the action
// strip is chrome: the one glass, set in the gutter above the card rather than
// over the image, holding the kit's IconButtons with Solar glyphs. Stock keeps
// its doubled corner, its shadow and the bare glyph strip over the image.
ShellRoot {
    id: probe
    property string look: "crate"
    property var asked: []

    FloatingWindow {
        implicitWidth: 700
        implicitHeight: 500
        Ryopin.PinCard {
            id: card
            x: 60; y: 80
            width: 480; height: 300
            path: Quickshell.env("PIN_SHOT")
            showStrip: true
            onEditRequested: probe.asked.push("edit")
            onCopyRequested: probe.asked.push("copy")
            onLinkRequested: probe.asked.push("link")
            onCloseRequested: probe.asked.push("close")
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
    function all(item, name, out) {
        out = out || [];
        if (!item) return out;
        if (item.objectName === name) out.push(item);
        for (const child of item.children) all(child, name, out);
        return out;
    }
    function glyphOf(item) {
        if (!item) return null;
        if (item.drawn !== undefined && item.name !== undefined) return item;
        for (const child of item.children) {
            const hit = glyphOf(child);
            if (hit) return hit;
        }
        return null;
    }
    function check(test, reason) {
        if (!test) {
            console.log("RYOPIN-KIT-PROBE-FAIL " + probe.look + ": " + reason);
            Qt.exit(1);
            throw new Error(reason);
        }
    }

    function verify(crate) {
        check(card.natW > 0, "the pinned image loads");
        const frame = find(card, "ryopinFrame");
        check(frame !== null, "the card's frame is named");
        check(frame.radius === (crate ? Tokens.radius : Tokens.radius * 2), "the card's corner, got " + frame.radius);
        check(Qt.colorEqual(frame.color, crate ? Tokens.popover : Tokens.paperLift), "the card's ground");
        check(Qt.colorEqual(frame.border.color, crate ? Tokens.line : Tokens.lineSoft) && frame.border.width === 1, "the card's edge");
        check(find(card, "ryopinShadow").visible === !crate, "a drop shadow only in stock");
        const plate = find(card, "ryopinStripPlate");
        check(plate !== null, "the strip has a plate");
        check(PinState.Theme.gutter === (crate ? plate.height + 2 * Tokens.s1 : 28), "the surface gutter, got " + PinState.Theme.gutter);
        const strip = find(card, "ryopinStrip");
        const top = strip.mapToItem(card, 0, 0);
        if (crate) {
            check(plate.visible, "the strip sits on a plate under crate");
            check(Qt.colorEqual(plate.color, Tokens.glass), "the strip plate is the one glass");
            check(Qt.colorEqual(plate.border.color, Tokens.line) && plate.border.width === 1, "the plate's 1 px line");
            check(plate.radius === Tokens.radius, "the plate's corner");
            const p = plate.mapToItem(card, 0, 0);
            check(p.y + plate.height <= 0 && p.y >= -PinState.Theme.gutter, "the glass sits in the gutter above the card, not over the image (y " + p.y + ")");
            check(Math.abs(p.x + plate.width - card.width) < 1, "the strip keeps to the card's right edge");
        } else {
            check(!plate.visible, "no plate in stock");
            check(top.y === 8 && Math.abs(top.x + strip.width - (card.width - 8)) < 1, "stock strip inside the card's top right");
        }

        const kits = all(card, "ryopinKitButton");
        const stock = all(card, "ryopinStockGlyph");
        check(kits.length === 4 && stock.length === 4, "four actions");
        const want = ["pen", "copy", "link", "close"];
        for (let i = 0; i < 4; i++) {
            check(kits[i].visible === crate, "action " + i + " is the kit IconButton only under crate");
            check(stock[i].visible === !crate, "action " + i + " keeps its stock glyph only in stock");
            check(kits[i].glyph === want[i], "action " + i + " glyph " + kits[i].glyph);
            if (crate) {
                const g = glyphOf(kits[i]);
                check(g && g.drawn, "action " + i + " draws the Solar " + want[i]);
                check(Qt.colorEqual(kits[i].ink, Tokens.inkSecondary), "action " + i + " rests in the secondary ink");
                check(Qt.colorEqual(kits[i].parent.color, "transparent"), "no plate under action " + i);
            }
        }
    }

    Timer {
        id: crateCheck
        interval: 600
        onTriggered: {
            probe.verify(true);
            for (const k of probe.all(card, "ryopinKitButton")) k.clicked();
            probe.check(probe.asked.join(",") === "edit,copy,link,close", "kit clicks reach the pin's actions: " + probe.asked.join(","));
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
            console.log("RYOPIN-KIT-PROBE-PASS");
            Qt.quit();
        }
    }
    Timer {
        interval: 300
        running: true
        onTriggered: {
            Tokens.controlsCrate = true;
            crateCheck.start();
        }
    }
}
