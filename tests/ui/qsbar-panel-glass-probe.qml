import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import "modules/bar/barstyles/qsbar" as QsBar

// Under crate every QS Bar panel is the one glass (Tokens.glass, the popover at
// 68 %), like Controls (Super+Esc), whatever opacity the user gives the bar
// itself: with the bar's frost off the panels painted the bar's 94 % and read
// more opaque than Controls. In stock the panels keep the bar's fill.
ShellRoot {
    QsBar.Theme { id: theme }

    Timer {
        interval: 900
        running: true
        onTriggered: {
            const crate = Quickshell.env("PROBE_LOOK") === "crate";
            const same = (a, b) => Math.abs(a.r - b.r) < 0.003 && Math.abs(a.g - b.g) < 0.003 && Math.abs(a.b - b.b) < 0.003 && Math.abs(a.a - b.a) < 0.003;
            let err = "";
            if (Tokens.controlsCrate !== crate) err = "look not read";
            else if (theme.barFrostEnabled) err = "the fixture's bar frost should be off";
            else if (crate && !same(theme.panelFill, Tokens.glass)) err = "crate: panelFill " + theme.panelFill + " is not Tokens.glass " + Tokens.glass;
            else if (crate && Math.abs(theme.bg.a - 0.94) > 0.003) err = "crate: the bar itself lost the user's opacity " + theme.bg.a;
            else if (!crate && !same(theme.panelFill, theme.bg)) err = "stock: panelFill is not the bar's bg";
            console.log(err ? "QSBAR-PANEL-GLASS-PROBE-FAIL " + err : "QSBAR-PANEL-GLASS-PROBE-PASS " + (crate ? "crate" : "stock"));
            Qt.quit();
        }
    }
}
