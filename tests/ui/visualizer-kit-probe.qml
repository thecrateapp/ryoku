import QtQuick
import Quickshell
import Ryoku.Ui
import Ryoku.Ui.Singletons
import "modules/visualizer"
import "modules/visualizer/Singletons" as Viz

// The desktop spectrum's colours and its placement grip in both looks. Under
// crate the spectrum is one active signal in the mark, as crate-mark's
// equalizer draws it: the bars ramp holds the mark across every stop and the
// edge field walks the accent to the mark (sun, beamTail, mark); a pinned
// colour or gradient is still painted exactly as chosen. The grip's handles are
// popover knobs with a 1 px mark edge, filled with the mark while held, on a
// hairline stem. The fallbacks behind a pinned colour are Tokens roles in both
// looks (never painted: each is read only once its hex is valid). In stock the
// ramp, the triad and the grip keep their wallpaper-lit and accent values.
ShellRoot {
    id: probe
    property string look: "crate"

    FloatingWindow {
        implicitWidth: 960
        implicitHeight: 540

        VisualizerView {
            id: bars
            width: 960
            height: 540
            index: 0
            instanceId: "probe-bars"
            cfg: Viz.VizItem { data: ({ id: "probe-bars", style: "bars" }) }
        }
        VisualizerView {
            id: aura
            width: 960
            height: 540
            index: 1
            instanceId: "probe-aura"
            cfg: Viz.VizItem { data: ({ id: "probe-aura", style: "aura" }) }
        }
        VisualizerView {
            id: pinned
            width: 960
            height: 540
            index: 2
            instanceId: "probe-pinned"
            cfg: Viz.VizItem { data: ({ id: "probe-pinned", style: "bars", color: "#ff8800" }) }
        }
        VisualizerView {
            id: pinnedAura
            width: 960
            height: 540
            index: 3
            instanceId: "probe-pinned-aura"
            cfg: Viz.VizItem { data: ({ id: "probe-pinned-aura", style: "aura", color: "#ff8800" }) }
        }
        Item {
            width: 960
            height: 540
            VisualizerGrip {
                id: grip
                instanceId: Viz.Config.idAt(0)
                composing: true
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
        return null;
    }
    function get(item, name) {
        const hit = find(item, name);
        if (!hit) throw new Error(probe.look + ": no " + name);
        return hit;
    }
    function check(test, reason) { if (!test) throw new Error(probe.look + ": " + reason); }
    function same(a, b) { return Qt.color(a).toString() === Qt.color(b).toString(); }

    // The stock ramp, as the wallpaper-lit sweep computes it.
    function stockRamp(v) {
        const out = [];
        for (let i = 0; i < 8; i++) {
            const t = i / 7;
            const l = Viz.Scheme.lstarAt(v.nx + t * v.nw * 0.875, v.ny, v.nw / 8, v.nh);
            out.push(Viz.Scheme.colorAt(t, l, v.fieldSide));
        }
        return out;
    }
    function pinnedRamp(base) {
        const out = [];
        for (let k = 0; k < 8; k++) {
            const f = 1 + (k / 7 - 0.5) * 0.36;
            out.push(f >= 1 ? Qt.lighter(base, f) : Qt.darker(base, 1 / f));
        }
        return out;
    }
    function sameList(a, b, what) {
        check(a.length === b.length, what + ": " + a.length + " stops, want " + b.length);
        for (let i = 0; i < a.length; i++)
            check(same(a[i], b[i]), what + " stop " + i + ": " + Qt.color(a[i]) + ", want " + Qt.color(b[i]));
    }

    function verify(crate) {
        check(!same(Tokens.sun, Tokens.mark), "the fixture palette keeps the accent and the mark apart");
        // the bars: one mark signal under crate, the wallpaper-lit sweep in stock
        const want = crate ? [0, 1, 2, 3, 4, 5, 6, 7].map(() => Tokens.mark) : probe.stockRamp(bars);
        probe.sameList(bars.ramp, want, "the bars ramp");
        // the edge field: sun, beamTail, mark under crate; lit from the wallpaper in stock
        const l = aura.fieldLstar;
        const side = aura.fieldSide;
        probe.sameList(aura.auraTriad, crate ? [Tokens.sun, Tokens.beamTail, Tokens.mark]
            : [Viz.Scheme.colorAt(0.12, l, side), Viz.Scheme.colorAt(0.50, l, side), Viz.Scheme.colorAt(0.88, l, side)],
            "the edge field's triad");
        // a pinned colour is the user's: painted exactly as chosen in both looks
        probe.sameList(pinned.ramp, probe.pinnedRamp(Qt.color("#ff8800")), "the pinned ramp");
        const base = Qt.color("#ff8800");
        probe.sameList(pinnedAura.auraTriad, [Qt.darker(base, 1.25), base, Qt.lighter(base, 1.25)], "the pinned triad");
        // the fallbacks behind an unpinned colour are Tokens roles, not literals
        const c = bars.cfg;
        check(!c.hasCustomColor && !c.hasColor2 && !c.hasAuraTriad, "the bars pin nothing");
        check(same(c.customColor, Tokens.sun) && same(c.color2Value, Tokens.sunHi)
            && same(c.auraColor2, Tokens.beamTail) && same(c.auraColor3, Tokens.sunHi),
            "the colour fallbacks are Tokens roles");
        // the placement grip
        const size = get(grip, "vizGripSize");
        const stem = get(grip, "vizGripStem");
        const turn = get(grip, "vizGripTurn");
        check(size.radius === Tokens.radius && turn.radius === turn.width / 2, "the handles' corners");
        check(same(grip.knob(false), crate ? Tokens.popover : Qt.alpha(Tokens.sun, 0.45)), "an idle handle's fill");
        check(same(grip.knob(true), crate ? Tokens.mark : Tokens.sun), "a held handle's fill");
        for (const h of [size, turn]) {
            check(h.border.width === Tokens.border, h.objectName + " edge weight");
            // `over` is read from the pointer, which an offscreen window never
            // moves, so the handle may sit lit or idle: it must be one of the two.
            check(same(h.color, grip.knob(false)) || same(h.color, grip.knob(true)), h.objectName + " fill, got " + h.color);
            check(same(h.border.color, crate ? Tokens.mark : Tokens.sun), h.objectName + " edge, got " + h.border.color);
        }
        check(stem.width === Tokens.border, "the stem is a hairline");
        check(same(stem.color, crate ? Tokens.lineStrong : Qt.alpha(Tokens.sun, 0.55)), "the stem's colour, got " + stem.color);
    }

    Timer {
        id: crateCheck
        interval: 600
        onTriggered: {
            try {
                probe.verify(true);
                Tokens.controlsCrate = false;
                Tokens.accentMarks = false;
                probe.look = "stock";
                stockCheck.start();
            } catch (e) {
                console.log("VISUALIZER-KIT-PROBE-FAIL " + e.message);
                Qt.quit();
            }
        }
    }
    Timer {
        id: stockCheck
        interval: 600
        onTriggered: {
            try {
                // stock with the mark off is ink: still apart from the accent
                probe.verify(false);
                console.log("VISUALIZER-KIT-PROBE-PASS");
            } catch (e) {
                console.log("VISUALIZER-KIT-PROBE-FAIL " + e.message);
            }
            Qt.quit();
        }
    }
    Timer {
        interval: 300
        running: true
        onTriggered: {
            // the Crate theme's switches (hub-fixture/crate.json)
            Tokens.controlsCrate = true;
            Tokens.accentMarks = true;
            Tokens.lineAlpha = 0.1;
            crateCheck.start();
        }
    }
}
