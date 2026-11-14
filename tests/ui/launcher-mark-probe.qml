import QtQuick
import Quickshell
import "modules/bar/barstyles/qsbar" as QsBar
import "modules/bar/barstyles/qsbar/modules" as Modules
import "modules/bar/barstyles/qsbar/controlcenter/routes" as Routes

// The launcher marks: "crate" is a wordmark ("CRATE") and a glyph (the Crate
// logo, drawn as a vector because no font carries it), both right after
// "ryoku", and a rice's launcher payload choosing either passes the Theme's
// validators (the same ones the widgets cache goes through).
// LauncherMark is the one drawing the bar and the Identity picker share: the
// bar's LauncherWidget and the picker's crate tile both draw the vector.
ShellRoot {
    QsBar.Theme { id: theme }

    Item {
        width: 200
        height: 100
        Row {
            Modules.LauncherMark { id: crateIcon; root: theme; mode: "icon"; markId: "crate"; color: "#ff0000" }
            Modules.LauncherMark { id: archIcon; root: theme; mode: "icon"; markId: "arch"; color: "#ff0000" }
            Modules.LauncherMark { id: crateText; root: theme; mode: "text"; markId: "crate"; color: "#ff0000" }
        }
    }

    Modules.LauncherWidget { id: barLauncher; root: theme }
    Routes.IdentityRoute { id: identity; width: 800; height: 900; root: theme }

    function marks(item, out) {
        if (item.markId !== undefined && item.drawn !== undefined) out.push(item);
        for (const c of item.children) marks(c, out);
        return out;
    }

    function fail(msg) {
        console.error("LAUNCHER-MARK-PROBE-FAIL " + msg);
        Qt.quit();
    }

    Timer {
        interval: 900
        running: true
        onTriggered: {
            if (theme.launcherLogoTextOptions[1] !== "crate")
                return fail("wordmark options[1] = " + theme.launcherLogoTextOptions[1]);
            if (theme.launcherLogoIconOptions[1] !== "crate")
                return fail("glyph options[1] = " + theme.launcherLogoIconOptions[1]);
            theme.applyLauncherConfig({ launcher: { launcherLogoMode: "icon", launcherLogoText: "crate", launcherLogoIcon: "crate" } });
            if (theme.launcherLogoText !== "crate" || theme.launcherLogoIcon !== "crate")
                return fail("stored crate choice rejected: text=" + theme.launcherLogoText + " icon=" + theme.launcherLogoIcon);
            if (theme.launcherLogoTextLabel("crate") !== "CRATE")
                return fail("wordmark label = " + theme.launcherLogoTextLabel("crate"));
            if (!crateIcon.drawn)
                return fail("crate glyph is not drawn as a vector");
            if (crateIcon.width < 10 || crateIcon.height < 10)
                return fail("crate glyph size " + crateIcon.width + "x" + crateIcon.height);
            if (archIcon.drawn || archIcon.text !== String.fromCodePoint(0xE732))
                return fail("arch glyph changed: drawn=" + archIcon.drawn + " text=" + archIcon.text);
            if (crateText.drawn || crateText.text !== "CRATE")
                return fail("crate wordmark: drawn=" + crateText.drawn + " text=" + crateText.text);
            const bar = marks(barLauncher, []);
            if (bar.length !== 1 || !bar[0].drawn || bar[0].markId !== "crate")
                return fail("bar launcher does not draw the crate glyph");
            const tile = marks(identity, []).filter(m => m.markId === "crate");
            if (tile.length !== 1 || !tile[0].drawn)
                return fail("Identity picker has no drawn crate tile (" + tile.length + ")");
            console.log("LAUNCHER-MARK-PROBE-PASS");
            Qt.quit();
        }
    }
}
