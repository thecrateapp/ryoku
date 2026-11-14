import QtQuick
import Quickshell
import Ryoku.Ui
import Ryoku.Ui.Singletons
import shell.services
import "modules/notifications"

// The notification card's last-resort thumbnail: with images on and neither an
// image nor an app icon, the card draws a glyph. Under crate it is a kit Glyph
// (Solar bell, danger-circle for a critical card) drawn from the catalogue in a
// Tokens role; in stock it stays the Material Symbols notifications /
// priority_high glyph in the theme's onSurfaceVariant.
ShellRoot {
    id: probe
    property string look: Quickshell.env("PROBE_LOOK") || "crate"

    FloatingWindow {
        implicitWidth: 820
        implicitHeight: 300

        Row {
            spacing: 20
            NotificationCard {
                id: normal
                width: 370
                notif: ({ id: 1, appName: "Probe", summary: "Normal", body: "Body", urgency: 1,
                          image: "", appIcon: "", actions: [] })
            }
            NotificationCard {
                id: critical
                width: 370
                notif: ({ id: 2, appName: "Probe", summary: "Critical", body: "Body", urgency: 2,
                          image: "", appIcon: "", actions: [] })
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
    function fail(msg) {
        console.log("NOTIFICATION-GLYPH-PROBE-FAIL " + probe.look + ": " + msg);
        Qt.quit();
    }
    function same(a, b) { return Qt.colorEqual(a, b); }

    function check(card, crateName, materialName, crateColor) {
        const glyph = find(card, "notifFallbackGlyph");
        const material = find(card, "notifFallbackMaterial");
        if (!glyph || !material)
            return "the fallback needs a kit Glyph and the stock Material icon";
        if (probe.look === "crate") {
            if (!glyph.visible || material.visible)
                return "crate draws the kit Glyph, not the Material icon";
            if (glyph.name !== crateName || !glyph.drawn)
                return "crate draws Solar " + crateName + " from the catalogue, got " + glyph.name + " drawn " + glyph.drawn;
            if (!same(glyph.color, crateColor))
                return "the glyph takes its Tokens role, got " + glyph.color;
        } else {
            if (glyph.visible || !material.visible)
                return "stock keeps the Material icon";
            if (material.text !== materialName)
                return "stock keeps Material " + materialName + ", got " + material.text;
            if (!same(material.color, Theme.onSurfaceVariant))
                return "stock keeps onSurfaceVariant, got " + material.color;
        }
        return "";
    }

    Timer {
        interval: 50
        repeat: true
        running: true
        property int tries: 0
        onTriggered: {
            Tokens.controlsCrate = probe.look === "crate";
            // shell.json loads asynchronously; wait for show_images to land
            if (!normal.imagesEnabled) {
                if (++tries > 80) { stop(); probe.fail("show_images never turned on"); }
                return;
            }
            stop();
            let msg = probe.check(normal, "bell", "notifications", Tokens.inkSecondary);
            if (!msg) msg = probe.check(critical, "danger-circle", "priority_high", Tokens.mark);
            if (msg) { probe.fail(msg); return; }
            console.log("NOTIFICATION-GLYPH-PROBE-PASS " + probe.look);
            Qt.quit();
        }
    }
}
