import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import inir
import inir.services
import inir.modules.iris.style
import inir.modules.iris.dock as ShimaDock

// The Shima dock, standing alone as it does under the QS Bar, in both looks.
// Under crate its body, its name label and its menu are the one glass with a
// 1 px line at the shared corner, its hover plates take that corner and the ink
// hover wash, its running marks take the mark, its separator the line, and the
// app menu and the windows sheet draw kit captions, Solar glyphs, kit
// IconButtons and the pick wash and edge on the focused window. Stock keeps
// every iRiS role it had: no glass of its own, the body left to a chassis.
ShellRoot {
    id: probe
    property string look: "crate"
    property int step: 0

    FloatingWindow {
        implicitWidth: 1200
        implicitHeight: 760
        color: "black"
        ShimaDock.IrisDock { id: dock; screen: GlobalStates.focusedScreen }
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
    function shown(item) {
        for (let p = item; p; p = p.parent)
            if (!p.visible) return false;
        return true;
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
    function same(a, b) { return Qt.colorEqual(a, b); }
    function check(test, reason) {
        if (!test) {
            console.log("SHIMA-DOCK-KIT-PROBE-FAIL " + probe.look + ": " + reason);
            Qt.exit(1);
            throw new Error(reason);
        }
    }

    // Two running apps: kitty with two windows, the first focused, and firefox.
    function fakeApps() {
        TaskbarApps._apps = [
            { appId: "kitty", pinned: true, toplevels: [
                { title: "~/code", activated: true, nativeWindowId: 101 },
                { title: "htop", activated: false, nativeWindowId: 102 }] },
            { appId: "firefox", pinned: true, toplevels: [
                { title: "Crate", activated: false, nativeWindowId: 201 }] }
        ];
    }

    // The name label shows on a hover dwell; present it for a slot directly.
    function presentLabel() {
        let label = find(dock, "shimaLabelGlass");
        while (label && typeof label.present !== "function") label = label.parent;
        check(label !== null, "the name label is found");
        label.present(all(dock, "shimaHoverPlate")[1].parent, "kitty", 2);
    }

    function verifyBar(crate) {
        check(dock.crate === crate, "the dock's crate switch follows the theme");
        const glass = find(dock, "shimaDockGlass");
        check(glass !== null, "the dock body has a glass layer");
        check(glass.visible === crate, "the dock draws its own glass only under crate");
        if (crate) {
            check(same(glass.color, Tokens.glass), "the dock body is the one glass");
            check(glass.border.width === 1 && same(glass.border.color, Tokens.line), "the dock body's 1 px line");
            check(glass.radius === Tokens.radius, "the dock body's corner, got " + glass.radius);
        }

        const plates = all(dock, "shimaHoverPlate");
        check(plates.length >= 4, "a hover plate per slot, got " + plates.length);
        for (const plate of plates) {
            check(plate.radius === (crate ? Tokens.radius : IrisStyle.iconRadius(plate.width)), "a hover plate's corner, got " + plate.radius);
            check(plate.color.a === 0, "a hover plate rests clear");
        }

        const sep = find(dock, "shimaSeparator");
        check(sep !== null, "the launcher separator is drawn");
        check(same(sep.color, crate ? Tokens.line : IrisStyle.borderStrong), "the separator's ink");

        const marks = all(dock, "shimaRunMark").filter(shown);
        check(marks.length === 3, "a mark per running window, got " + marks.length);
        const inks = marks.map(m => m.color);
        if (crate) {
            check(inks.every(c => same(c, Tokens.mark) || same(c, Tokens.markHover)), "every running mark is the mark");
            check(inks.filter(c => same(c, Tokens.mark)).length === 2, "the focused app's marks in the mark");
            check(inks.filter(c => same(c, Tokens.markHover)).length === 1, "another running app's mark at 40 %");
            check(same(dock.crateDot(true, false, false), Tokens.alert), "an urgent app's mark is the alert");
        } else {
            check(inks.every(c => same(c, IrisStyle.text) || same(c, IrisStyle.textSecondary) || same(c, IrisStyle.textTertiary)),
                "stock marks keep the iRiS inks");
        }

        const launcher = find(dock, "shimaLauncherGlyph");
        check(launcher.visible === crate, "the launcher's Solar glyph only under crate");
        if (crate) check(launcher.drawn && launcher.name === "widget", "the launcher draws the Solar widget glyph");

        const badge = find(dock, "shimaCrateBadge");
        check(badge !== null && !badge.visible, "no badge without notifications");
        if (crate) check(same(badge.color, Tokens.mark) && badge.radius <= Tokens.radius, "the crate badge fills with the mark");

        const label = find(dock, "shimaLabelGlass");
        check(label.visible === crate, "the name label draws its glass only under crate");
        if (crate) {
            check(same(label.color, Tokens.glass) && same(label.border.color, Tokens.line), "the name label is the one glass");
            check(label.radius === Tokens.radius, "the name label's corner");
        }
        const count = find(dock, "shimaLabelCount");
        check(shown(count) && same(count.color, crate ? Tokens.mark : IrisStyle.secondaryAccent), "the window count's ink");
        const name = find(dock, "shimaLabelName");
        check(crate ? name.font.family === Tokens.mono && same(name.color, Tokens.ink)
            : same(name.color, IrisStyle.text) && name.font.pixelSize === IrisStyle.typeLabel, "the name label's type");
    }

    function verifyMenu(crate) {
        const menu = find(dock, "shimaMenu");
        check(menu !== null && menu.open && menu.progress > 0.9, "the app menu opens");
        check(menu.fieldBacked === !crate, "the menu body is the chassis' only in stock");
        check(same(menu.color, crate ? Tokens.glass : IrisStyle.bodySurface), "the menu body's fill");
        if (crate) {
            check(menu.radius === Tokens.radius && menu.material === "solid", "the menu is a solid glass at the shared corner");
            const top = find(dock, "shimaDockGlass").mapToItem(menu.parent, 0, 0).y;
            check(menu.y + menu.height <= top - Tokens.s2 + 0.5, "the menu's glass stands clear of the dock's by the kit gap");
        }
        const edge = find(dock, "shimaMenuEdge");
        check(edge.visible === crate, "the menu's line only under crate");
        if (crate) check(same(edge.border.color, Tokens.line) && edge.border.width === 1, "the menu's 1 px line");

        const title = find(dock, "shimaMenuTitle");
        check(shown(title) === crate, "the menu head is a kit caption only under crate");
        const rows = all(dock, "shimaMenuRow").filter(shown);
        check(rows.length >= 6, "the window rows and the actions, got " + rows.length);
        let picked = 0;
        for (const row of rows) {
            const g = find(row, "shimaMenuGlyph");
            check(g.visible === crate, "row " + row.label + ": the Solar glyph only under crate");
            if (crate) {
                check(g.drawn, "row " + row.label + " draws a Solar glyph for " + row.glyph);
                check(find(row, "shimaMenuLabel").font.family === Tokens.mono, "row " + row.label + " speaks mono");
                check(row.buttonRadius === Tokens.radius, "row " + row.label + " takes the shared corner");
            }
            const pick = find(row, "shimaMenuPick");
            if (pick.visible) {
                picked++;
                check(same(pick.border.color, Tokens.pickEdge) && pick.border.width === 1 && same(pick.color, Tokens.pickFill),
                    "the focused window's row takes the pick wash and edge");
            }
        }
        check(picked === (crate ? 1 : 0), "one picked row (the focused window) under crate, got " + picked);
    }

    function verifySheet(crate) {
        const plates = all(dock, "shimaCardPlate").filter(shown);
        check(plates.length === 2, "a card per kitty window, got " + plates.length);
        const focused = plates.filter(p => crate ? same(p.border.color, Tokens.pickEdge) : p.border.width > 0);
        check(focused.length === 1, "one focused card, got " + focused.length);
        for (const plate of plates) {
            if (crate) {
                check(plate.radius === Tokens.radius && plate.border.width === 1, "a card's corner and line");
                check(same(find(plate, "shimaCardWindow").color, Tokens.paperLift), "a card's window silhouette");
            } else {
                check(same(plate.border.color, IrisStyle.accent), "stock cards ring in the iRiS accent");
            }
        }
        check(same(focused[0].color, crate ? Tokens.pickFill : IrisStyle.fillQuiet), "the focused card's wash");
        const add = find(dock, "shimaSheetAdd");
        check(shown(add) === crate, "the sheet's new-window button is the kit's only under crate");
        if (crate) check(glyphOf(add).drawn, "the new-window button draws its Solar glyph");
        check(all(dock, "shimaCardClose").length === 2, "a kit close per card");
        const title = find(dock, "shimaCardTitle");
        check(crate ? title.font.family === Tokens.ui : same(title.color, IrisStyle.text) || same(title.color, IrisStyle.subtext), "a card's title type");
    }

    Timer {
        id: steps
        interval: 900
        repeat: true
        onTriggered: {
            const crate = probe.look === "crate";
            switch (probe.step++) {
            case 0:
                probe.fakeApps();
                probe.presentLabel();
                break;
            case 1:
                probe.verifyBar(crate);
                GlobalStates.irisDockMenuRequest = { appId: "kitty", mode: "menu" };
                break;
            case 2:
                probe.verifyMenu(crate);
                dock.closeMenu();
                break;
            case 3:
                GlobalStates.irisDockMenuRequest = { appId: "kitty", mode: "windows" };
                break;
            case 4:
                probe.verifySheet(crate);
                dock.closeMenu();
                break;
            case 5:
                if (crate) {
                    Tokens.controlsCrate = false;
                    probe.look = "stock";
                    probe.step = 1;
                } else {
                    console.log("SHIMA-DOCK-KIT-PROBE-PASS");
                    Qt.quit();
                }
                break;
            }
        }
    }
    Timer {
        interval: 600
        running: true
        onTriggered: {
            Tokens.controlsCrate = true;
            steps.start();
        }
    }
}
