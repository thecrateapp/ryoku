import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import "welcome" as Welcome

// The Welcome on the kit, in both looks: an opaque surface; under crate the
// step rail is the kit's keyed Tabs over a Beam of the way through, a tab
// moves to its step, the page title is the kit PageHeader and a picked bar card
// draws through PickCard; stock keeps its own rail, title and card.
ShellRoot {
    id: probe
    property string look: "crate"

    FloatingWindow {
        implicitWidth: 1180
        implicitHeight: 760
        Welcome.Welcome { id: app; anchors.fill: parent; step: 1 }
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
        const beam = find(app, "welcomeStepBeam");
        check(Math.abs(beam.value - app.step / 4) < 0.001 && !beam.interactive, "the beam reads the way through");
        const header = find(app, "welcomePageHeader");
        check(header !== null && header.visible === crate && header.title.length > 0, "the page title is the kit PageHeader under crate");
        const pick = find(app, "welcomeBarPick");
        check(pick !== null && pick.visible === crate, "bar cards draw through PickCard under crate");
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
