import QtQuick
import Quickshell
import Ryoku.Ui
import Ryoku.Ui.Singletons

// The kit Btn's danger variant. Under crate a danger button fills with the
// theme's error role and writes its label in the ink on that role; disarmed it
// is a plain button. Every button without danger draws exactly as before, and
// in the stock look a danger button draws as a plain one.
ShellRoot {
    id: probe
    property string look: "crate"

    FloatingWindow {
        implicitWidth: 400
        implicitHeight: 200
        Row {
            x: 40
            y: 40
            spacing: 8
            // offscreen the pointer rests at the window's origin: keep it off them
            Btn { id: plain; text: "Plain" }
            Btn { id: primary; text: "Record"; primary: true }
            Btn { id: danger; text: "Stop"; danger: true }
            Btn { id: dangerPrimary; text: "Stop"; danger: true; primary: true }
            Btn { id: disarmed; text: "Stop"; danger: true; armed: false }
            Btn { id: plainDisarmed; text: "Stop"; armed: false }
            Btn { id: primaryRef; text: "Stop"; primary: true }
        }
    }

    function label(btn) {
        for (const child of btn.children)
            if (child.text !== undefined && child.font !== undefined)
                return child;
        return null;
    }
    function same(a, b) { return Qt.colorEqual(a, b); }
    function looksAlike(a, b) {
        return same(a.color, b.color) && same(a.border.color, b.border.color)
            && same(probe.label(a).color, probe.label(b).color);
    }
    function check(test, reason) { if (!test) throw new Error(probe.look + ": " + reason); }

    function verify(crate) {
        const err = Tokens.role("error", Tokens.alert);
        const onErr = Tokens.role("onError", Tokens.paper);
        if (crate) {
            check(same(danger.color, err), "a danger button fills with the error role, got " + danger.color);
            check(same(danger.border.color, err), "its edge is the error role");
            check(same(probe.label(danger).color, onErr), "its label is the ink on the error role");
            check(same(dangerPrimary.color, err), "danger wins over primary");
            check(probe.looksAlike(disarmed, plainDisarmed), "a disarmed danger button is a plain disarmed one");
        } else {
            check(probe.looksAlike(danger, plain), "stock draws a danger button as a plain one");
            check(probe.looksAlike(dangerPrimary, primaryRef), "stock keeps a primary danger button primary");
        }
        check(!same(plain.color, err) && !same(primary.color, err), "the other buttons never take the error fill");
    }

    Timer {
        id: crateCheck
        interval: 400
        onTriggered: {
            probe.verify(true);
            Tokens.controlsCrate = false;
            probe.look = "stock";
            stockCheck.start();
        }
    }
    Timer {
        id: stockCheck
        interval: 400
        onTriggered: {
            probe.verify(false);
            console.log("BTN-DANGER-PROBE-PASS");
            Qt.quit();
        }
    }
    Timer {
        interval: 200
        running: true
        onTriggered: {
            // a palette whose accent and error differ (the default's are both red)
            Tokens.namedScheme = { primary: "#06b6d4", secondary: "#67e8f9", error: "#ef4444", onError: "#0a0a0f" };
            Tokens.controlsCrate = true;
            crateCheck.start();
        }
    }
}
