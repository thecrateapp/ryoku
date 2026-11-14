import QtQuick
import Quickshell
import Ryoku.Ui
import Ryoku.Ui.Singletons
import "modules/visualizer"
import "modules/visualizer/Singletons" as Viz

// The desktop spectrum's colours and its placement grip in both looks. Under
// crate the spectrum is one active signal in the mark, as crate-mark's
// equalizer draws it: the bars ramp holds the mark across every stop and the
// edge field walks the accent to the mark (sun, beamTail, mark), each stop
// re-lit on its own hue against the wallpaper behind it (the fixture's is
// bright, as light as the mark itself, so the relight has to act); a pinned
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

    // Each stop is its role re-lit: the same hue, moved off the picture's L*
    // by the relight's separation when the role sat too close to it.
    function relitList(got, roles, bgL, what) {
        check(got.length === roles.length, what + ": " + got.length + " stops, want " + roles.length);
        for (let i = 0; i < roles.length; i++) {
            const c = Qt.color(got[i]);
            const r = Qt.color(roles[i]);
            const clear = Math.abs(Ink.lstar(r) - bgL) >= 18;
            if (clear) {
                check(same(c, r), what + " stop " + i + " stands clear and stays " + r + ", got " + c);
                continue;
            }
            check(!same(c, r), what + " stop " + i + " is re-lit off " + r);
            check(Math.abs(c.hslHue - r.hslHue) < 0.01, what + " stop " + i + " keeps its hue");
            check(Math.abs(Ink.lstar(c) - bgL) >= 17, what + " stop " + i + " stands clear of the picture, L* "
                + Ink.lstar(c).toFixed(1) + " on " + bgL);
        }
    }

    function verify(crate) {
        check(!same(Tokens.sun, Tokens.mark), "the fixture palette keeps the accent and the mark apart");
        // the bars: one mark signal under crate, re-lit on its own hue so it
        // stands clear of the bright picture; the wallpaper-lit sweep in stock
        const l = aura.fieldLstar;
        const side = aura.fieldSide;
        check(Math.abs(l - 86) < 0.5 && Math.abs(Ink.lstar(Tokens.mark) - l) < 18,
            "the fixture wallpaper is bright enough to swallow the mark (L* " + l + ")");
        if (crate) {
            probe.relitList(bars.ramp, [0, 1, 2, 3, 4, 5, 6, 7].map(() => Tokens.mark), l, "the bars ramp");
            for (let i = 1; i < 8; i++)
                check(same(bars.ramp[i], bars.ramp[0]), "the bars ramp is one colour, stop " + i);
        } else {
            probe.sameList(bars.ramp, probe.stockRamp(bars), "the bars ramp");
        }
        // the edge field: sun, beamTail, mark under crate, each re-lit; lit
        // from the wallpaper in stock
        if (crate)
            probe.relitList(aura.auraTriad, [Tokens.sun, Tokens.beamTail, Tokens.mark], l, "the edge field's triad");
        else
            probe.sameList(aura.auraTriad, [Viz.Scheme.colorAt(0.12, l, side), Viz.Scheme.colorAt(0.50, l, side),
                Viz.Scheme.colorAt(0.88, l, side)], "the edge field's triad");
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
