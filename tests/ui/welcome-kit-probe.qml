import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import "welcome" as Welcome

// The Welcome on the kit, in both looks: an opaque surface; under crate the
// step rail is the kit's keyed Tabs alone (no progress beam), a tab
// moves to its step, the page title is the kit PageHeader and a picked bar card
// draws through PickCard, and cards and the live bar frame drop their corner
// ticks and lead bar; stock keeps its own rail, title, cards and marginalia.
ShellRoot {
    id: probe
    property string look: "crate"

    FloatingWindow {
        implicitWidth: 1180
        implicitHeight: 760
        Welcome.Welcome { id: app; anchors.fill: parent; step: 1 }
        Welcome.PageMake { id: make; opacity: 0; width: 1100; height: 560 }
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
    function tabsOf(rail) {
        for (const child of rail.children)
            if (child.options !== undefined) return child;
        return null;
    }
    function check(test, reason) { if (!test) throw new Error(probe.look + ": " + reason); }

    function verify(crate) {
        check(Qt.colorEqual(app.color, crate ? Tokens.popover : Tokens.paper) && app.color.a === 1, "an opaque surface");
        const rail = find(app, "welcomeStepRail");
        check(rail.visible === crate, "the kit rail shows only under crate");
        const tabs = probe.tabsOf(rail);
        check(tabs.options.length === 5 && tabs.options[1].key === "1" && tabs.current === String(app.step), "a tab per step, the current one live");
        check(find(app, "welcomeStepBeam") === null, "no progress beam under the step tabs");
        const header = find(app, "welcomePageHeader");
        check(header !== null && header.visible === crate && header.title.length > 0, "the page title is the kit PageHeader under crate");
        const pick = find(app, "welcomeBarPick");
        check(pick !== null && pick.visible === crate, "bar cards draw through PickCard under crate");
        const ticks = all(app, "welcomeTicks", []).concat(all(make, "welcomeTicks", []));
        check(ticks.length >= 2 && ticks.every(t => t.visible === !crate), "corner ticks only in stock");
        check(find(make, "welcomeStoreLead").visible === !crate, "the store card's lead bar only in stock");
    }

    Timer {
        id: crateCheck
        interval: 900
        onTriggered: {
            probe.verify(true);
            probe.tabsOf(probe.find(app, "welcomeStepRail")).chose("3");
            probe.check(app.step === 3, "a tab moves to its step");
            app.step = 1;
            Tokens.controlsCrate = false;
            probe.look = "stock";
            stockCheck.start();
        }
    }
    Timer {
        id: stockCheck
        interval: 900
        onTriggered: {
            probe.verify(false);
            console.log("WELCOME-KIT-PROBE-PASS");
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
