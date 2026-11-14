import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import inir
import inir.services
import inir.modules.iris.dock as ShimaDock

// The Shima dock as the Crate setup shows it under the QS Bar: three pinned
// apps, kitty running two windows (one focused) and firefox one, and kitty's
// app menu open (SHIMA_SHEET=windows opens its windows sheet instead, and
// SHIMA_SHEET=label shows kitty's name label). A dark field with a few colour blocks sits behind it so the
// glass reads as glass; the compositor's blur is not part of a render.
ShellRoot {
    FloatingWindow {
        id: win
        implicitWidth: 1000
        implicitHeight: 600
        color: "black"

        Rectangle {
            id: sheet
            width: 1000
            height: 600
            color: Tokens.paper

            Rectangle { x: 120; y: 120; width: 320; height: 420; color: Tokens.sun; opacity: 0.55 }
            Rectangle { x: 520; y: 260; width: 360; height: 300; color: Tokens.ink; opacity: 0.35 }
            Rectangle { x: 0; y: 470; width: 1000; height: 8; color: Tokens.sunHi; opacity: 0.6 }
            // a light patch under the dock's right end: the floating icons and
            // their marks must read on a light wallpaper as well as a dark one
            Rectangle { x: 560; y: 500; width: 440; height: 100; color: Tokens.ink; opacity: 0.85 }

            ShimaDock.IrisDock {
                id: dock
                screen: GlobalStates.focusedScreen
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
        function all(item, name, out) {
            out = out || [];
            if (!item) return out;
            if (item.objectName === name) out.push(item);
            for (const child of item.children) all(child, name, out);
            return out;
        }

        // Revealed first (the user's dock may autohide), so the menu anchors on
        // the resting dock rather than on one still rising.
        Timer {
            interval: 400
            running: true
            onTriggered: GlobalStates.irisDockShown = true
        }
        Timer {
            interval: 400
            running: true
            onTriggered: TaskbarApps._apps = [
                { appId: "kitty", pinned: true, toplevels: [
                    { title: "~/code/crate", activated: true, nativeWindowId: 101 },
                    { title: "htop", activated: false, nativeWindowId: 102 }] },
                { appId: "firefox", pinned: true, toplevels: [
                    { title: "Crate", activated: false, nativeWindowId: 201 }] }
            ]
        }
        Timer {
            interval: 1500
            running: true
            onTriggered: {
                if (Quickshell.env("SHIMA_SHEET") === "label") {
                    let label = win.find(dock, "shimaLabelGlass");
                    while (label && typeof label.present !== "function") label = label.parent;
                    // a hover plate per slot: the launcher's, then one per entry
                    const at = 1 + dock.entries.findIndex(entry => entry.appId === "kitty");
                    label.present(win.all(dock, "shimaHoverPlate")[at].parent, "kitty", 2);
                } else {
                    GlobalStates.irisDockMenuRequest = { appId: "kitty",
                        mode: Quickshell.env("SHIMA_SHEET") === "windows" ? "windows" : "menu" };
                }
            }
        }
        Timer {
            interval: Number(Quickshell.env("BENCH_WAIT") || 3000)
            running: true
            onTriggered: sheet.grabToImage(r => { r.saveToFile(Quickshell.env("BENCH_OUT")); Qt.quit(); })
        }

        Component.onCompleted: {
            const look = Quickshell.env("BENCH_CRATE");
            if (look === "1" || look === "0")
                Tokens.controlsCrate = look === "1";
        }
    }
}
