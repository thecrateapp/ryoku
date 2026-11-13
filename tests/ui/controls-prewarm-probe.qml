import QtQuick
import QtTest as Test
import Quickshell
import Ryoku.Ui.Singletons
import shell.services
import shell.modules.sidebar as Sidebar

ShellRoot {
    id: fixture

    readonly property bool crate: Quickshell.env("CONTROLS_LOOK") === "crate"
    readonly property var readings: ["cpu", "cpuTemperature", "liveGraph", "memory", "gpu", "network", "disk", "battery"]

    function configure(visibleVitals, showMedia = false) {
        const sections = SidebarState.defaultSections.map(section => ({
            id: section.id,
            visible: section.id === "vitals" || (showMedia && section.id === "media")
        }));
        Config.controls = {
            sections: sections,
            hidden: ["identity"].concat(readings).filter(element => !visibleVitals.includes(element))
        };
    }
    function findHero(item) {
        if (item instanceof Sidebar.ControlsHero) return item;
        for (const child of item.children) {
            const result = findHero(child);
            if (result) return result;
        }
        return null;
    }
    function expect(predicate, reason) {
        const end = Date.now() + 5000;
        while (!predicate() && Date.now() < end) test.wait(15);
        if (!predicate()) throw Error(reason);
    }

    Window {
        id: window
        width: 688; height: 720; visible: false
        Test.TestCase { id: test; when: false }
        Loader {
            id: host
            width: parent.width
            height: item ? Math.min(window.height, item.implicitHeight) : 0
            active: false
            asynchronous: true
            sourceComponent: Sidebar.ControlsBoard {
                screen: null
                s: 1
                active: false
            }
        }
    }

    Timer {
        interval: 150
        running: true
        onTriggered: {
            try {
                fixture.expect(() => Tokens.controlsCrate === fixture.crate, "configured theme not applied");
                fixture.configure(["identity", "cpu", "liveGraph"], true);
                host.active = true;
                fixture.expect(() => host.status === Loader.Ready && !!fixture.findHero(host.item), "prewarm never completed");
                if (fixture.findHero(host.item).monitor.active) throw Error("hidden prewarm started sampling");
                window.visible = true;
                fixture.expect(() => host.item.implicitHeight > fixture.findHero(host.item).implicitHeight,
                               "two-section overview omitted the media section");
                fixture.configure(["identity", "cpu", "liveGraph"]);
                fixture.expect(() => !!fixture.findHero(host.item), "missing configured vitals");
                const hero = fixture.findHero(host.item);
                if (hero.active || hero.monitor.active) throw Error("prewarm started sampling");
                const identityHeight = fixture.crate ? 40 : Tokens.s7 + Tokens.s3;
                const readingsHeight = fixture.crate ? Tokens.s4 + 106 : Tokens.s3 + Tokens.s7 * 3;
                fixture.expect(() => hero.height === identityHeight + readingsHeight
                               && host.height === hero.height, "vitals or section height does not fit its contents");
                host.width = 480;
                fixture.expect(() => hero.width === host.width && hero.height === host.height, "section did not resize");
                fixture.configure(["identity", "cpu", "liveGraph", "memory"]);
                const openHero = fixture.findHero(host.item);
                host.item.active = true;
                fixture.expect(() => openHero.monitor.memoryAvailable && openHero.height
                               === identityHeight + readingsHeight + (fixture.crate ? Tokens.s4 + 28 : 0),
                               "memory meter failed to fit below the Crate graph or inside the stock row");
                host.item.active = false;
                fixture.expect(() => !openHero.monitor.active, "closing left the sampler running");
                fixture.configure(["identity"]);
                fixture.expect(() => host.height === identityHeight, "removed readings still occupy height");
                fixture.configure([]);
                fixture.expect(() => host.height === 0, "empty section still occupies height");
                console.log("CONTROLS-PREWARM-PASS");
            } catch (err) {
                console.error(err);
            }
            Qt.quit();
        }
    }
}
