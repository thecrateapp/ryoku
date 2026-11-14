import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import "reload-cover" as Reload

// The reload cover in both looks. Under a theme with controls "crate" and a
// coverMark, the media draws the theme's mark at emblem size (96 px) in the
// theme's ink, in place of Ryoku's wordmark, failure included; the status is
// the kit's tracked label with its Japanese gloss (再読込, 起動中, 失敗), an
// indeterminate Beam only while the cover holds, and the failure line in the
// theme's error role. Without the style the cover is Ryoku's, as before.
ShellRoot {
    id: probe
    readonly property bool wantCrate: Quickshell.env("PROBE_LOOK") === "crate"
    readonly property string fixture: Quickshell.env("PROBE_MARK")

    Item {
        width: 1280
        height: 720
        Reload.ReloadMedia {
            id: media
            anchors.fill: parent
            descriptor: ({ path: "", name: "", kind: "default", bytes: 0 })
            themeMark: Tokens.controlsCrate ? Tokens.coverMark : ""
            markTint: Tokens.ink
        }
        Reload.CoverStatus { id: reload; anchors.fill: parent; mode: "reload"; phase: "hold"; logoHeight: media.defaultLogoHeight }
        Reload.CoverStatus { id: closing; anchors.fill: parent; mode: "reload"; phase: "closing"; logoHeight: media.defaultLogoHeight }
        Reload.CoverStatus { id: boot; anchors.fill: parent; mode: "boot"; phase: "hold"; logoHeight: media.defaultLogoHeight }
        Reload.CoverStatus { id: failed; anchors.fill: parent; mode: "reload"; phase: "failed"; logoHeight: media.defaultLogoHeight }
    }

    function fail(msg) {
        console.error("RELOAD-COVER-PROBE-FAIL " + msg);
        return false;
    }
    function part(status, name) {
        const find = item => {
            if (item.objectName === name) return item;
            for (const c of item.children) { const f = find(c); if (f) return f; }
            return null;
        };
        return find(status);
    }

    function checkCrate() {
        if (!Tokens.controlsCrate) return fail("crate style not read");
        if (Tokens.coverMark !== probe.fixture) return fail("Tokens.coverMark = " + Tokens.coverMark);
        if (media.defaultLogoHeight !== 96) return fail("mark height " + media.defaultLogoHeight);
        const mark = part(media, "themeMark");
        if (!mark || mark.status !== Image.Ready || !mark.parent.visible) return fail("theme mark not shown");
        if (mark.height !== 96 || Math.abs(mark.width - 80) > 1) return fail("theme mark " + mark.width + "x" + mark.height + ", want 80x96");
        if (part(media, "wordmark").visible) return fail("Ryoku wordmark still shown");
        media.forceDefault = true;
        if (!mark.parent.visible) return fail("a failure brings Ryoku's wordmark back");
        media.forceDefault = false;
        const glosses = [[reload, "再読込"], [boot, "起動中"], [failed, "失敗"]];
        for (const [s, g] of glosses) {
            const gloss = part(s, "coverGloss");
            if (!gloss || !gloss.visible || gloss.text !== g) return fail(s.mode + "/" + s.phase + " gloss " + (gloss && gloss.text));
        }
        const label = part(reload, "coverLabel");
        if (label.text !== "SHELL RELOADING" || label.font.family !== Tokens.mono) return fail("reload label " + label.text + " " + label.font.family);
        if (!part(reload, "coverBeam").visible || !part(reload, "coverBeam").indeterminate) return fail("no waiting Beam while holding");
        if (part(closing, "coverBeam").visible) return fail("Beam shown while the iris closes");
        if (part(failed, "coverBeam").visible) return fail("Beam shown on failure");
        const err = part(failed, "coverLabel");
        if (!Qt.colorEqual(err.color, Tokens.role("error", Tokens.alert))) return fail("failure colour " + err.color);
        if (err.text !== "RELOAD FAILED") return fail("failure text " + err.text);
        if (part(boot, "coverLabel").text !== "LOADING DESKTOP") return fail("boot text");
        return true;
    }

    function checkStock() {
        if (Tokens.controlsCrate) return fail("stock run reads a crate style");
        if (part(media, "themeMark")) return fail("stock cover draws a theme mark");
        if (!part(media, "wordmark").visible) return fail("stock wordmark hidden");
        const label = part(reload, "coverLabel");
        if (!Qt.colorEqual(label.color, "#d8e8f5") || label.font.family !== "JetBrainsMono Nerd Font" || label.font.pixelSize !== 11)
            return fail("stock label changed: " + label.color + " " + label.font.family + " " + label.font.pixelSize);
        if (part(reload, "coverGloss")) return fail("stock cover has a gloss");
        if (part(reload, "coverBeam")) return fail("stock cover has a Beam");
        const err = part(failed, "coverLabel");
        if (!Qt.colorEqual(err.color, "#ff735d") || err.font.pixelSize !== 14) return fail("stock failure changed");
        return true;
    }

    Timer {
        interval: 1500
        running: true
        onTriggered: {
            if (probe.wantCrate ? checkCrate() : checkStock())
                console.log("RELOAD-COVER-PROBE-PASS " + (probe.wantCrate ? "crate" : "stock"));
            Qt.quit();
        }
    }
}
