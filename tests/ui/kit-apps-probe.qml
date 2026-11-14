import QtQuick
import Quickshell
import Ryoku.Ui
import Ryoku.Ui.Singletons

// The kit pieces the apps grew, in both looks: Tabs takes {key, label, note}
// entries (the key selects and is emitted, the note is drawn) while plain labels
// behave as before; Field draws a leading glyph and names its input; a bipolar
// Beam fills from its middle toward the head.
ShellRoot {
    id: probe
    property string lastKey: ""
    property string lastLabel: ""
    property string look: "crate"

    FloatingWindow {
        implicitWidth: 640
        implicitHeight: 260
        Column {
            x: 60; y: 60
            spacing: 12
            Tabs {
                id: keyed
                options: [{ key: "all", label: "All" }, { key: "games", label: "Games", note: "42" }]
                current: "games"
                onChose: key => probe.lastKey = key
            }
            Tabs { id: plain; options: ["Shortcuts", "Apps"]; current: "Apps"; onChose: label => probe.lastLabel = label }
            Field { id: search; width: 240; glyph: "search"; inputObjectName: "probeSearchInput" }
            Field { id: bare; width: 240 }
            Beam { id: low; width: 200; from: -100; to: 100; value: -50; bipolar: true; interactive: false }
            Beam { id: high; width: 200; from: -100; to: 100; value: 50; bipolar: true; interactive: false }
            Beam { id: flat; width: 200; value: 0.5; interactive: false }
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
    function plates(tabs) { return tabs.children.filter(c => c.modelData !== undefined); }
    function texts(item, out) {
        for (const child of item.children) {
            if (child.text !== undefined && child.font !== undefined) out.push(child);
            texts(child, out);
        }
        return out;
    }
    function check(test, reason) { if (!test) throw new Error(probe.look + ": " + reason); }

    function verify() {
        const kp = plates(keyed);
        check(kp.length === 2 && kp[1].on && !kp[0].on, "a keyed entry is current by its key");
        const labels = texts(kp[1], []).filter(t => t.visible).map(t => t.text);
        check(labels.indexOf("GAMES") >= 0 && labels.indexOf("42") >= 0, "the entry reads its label and note, got " + labels);
        check(texts(kp[0], []).filter(t => t.visible && t.text === "").length === 0, "an entry without a note draws none");
        const pp = plates(plain);
        check(pp[1].on && pp[1].key === "Apps", "a plain label is its own key");
        check(texts(pp[1], []).filter(t => t.visible).map(t => t.text).indexOf("APPS") >= 0, "plain label text");
        check(search.children.some(c => c.name === "search" && c.visible), "the search field shows its glyph");
        check(!bare.children.some(c => c.name !== undefined && c.visible), "a field without a glyph draws none");
        const input = find(search, "probeSearchInput");
        check(input !== null && input.x > 20, "the input is named and starts after the glyph");
        check(low.fillFrom === 0.25 && low.fillTo === 0.5 && low.mirrored, "below the middle fills from the head to the middle");
        check(high.fillFrom === 0.5 && high.fillTo === 0.75 && !high.mirrored, "above the middle fills from the middle to the head");
        check(flat.fillFrom === 0 && flat.fillTo === 0.5 && !flat.mirrored, "a plain beam fills from its start");
    }

    Timer {
        id: crateCheck
        interval: 400
        onTriggered: {
            probe.verify();
            const kp = probe.plates(keyed);
            kp[0].data.find(c => String(c).startsWith("QQuickTapHandler")).tapped(undefined, Qt.LeftButton);
            Tokens.controlsCrate = false;
            probe.look = "stock";
            stockCheck.start();
        }
    }
    Timer {
        id: stockCheck
        interval: 400
        onTriggered: {
            probe.verify();
            probe.check(probe.lastKey === "all", "a tap emits the entry's key, got " + probe.lastKey);
            console.log("KIT-APPS-PROBE-PASS");
            Qt.quit();
        }
    }
    Timer {
        interval: 150
        running: true
        onTriggered: {
            Tokens.controlsCrate = true;
            crateCheck.start();
        }
    }
}
