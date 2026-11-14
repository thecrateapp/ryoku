import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import "phone" as Phone

// Every icon name Kit's phone tab uses draws as a kit (Solar) glyph under
// crate, and as the Material Symbols text in the stock look.
ShellRoot {
    id: probe
    readonly property bool wantCrate: Quickshell.env("PROBE_LOOK") === "crate"
    readonly property var names: ["android", "phonelink_ring", "tablet", "smartphone", "expand_less", "expand_more",
        "screen_share", "videocam", "mic", "progress_activity", "alarm", "notifications_active", "upload_file",
        "content_paste", "link", "folder_shared", "vibration", "keyboard"]

    Item {
        Repeater {
            id: rep
            model: probe.names
            Phone.PhoneGlyph { required property string modelData; name: modelData }
        }
    }

    function glyphOf(item) {
        for (const c of item.children) if (c.objectName === "phoneGlyph") return c;
        return null;
    }

    Timer {
        interval: 600
        running: true
        onTriggered: {
            let err = "";
            if (Tokens.controlsCrate !== probe.wantCrate) err = "look not read";
            for (let i = 0; i < rep.count && !err; i++) {
                const g = glyphOf(rep.itemAt(i));
                if (probe.wantCrate && !g.drawn) err = "crate: no kit glyph for " + probe.names[i];
                if (!probe.wantCrate && (g.visible || g.drawn)) err = "stock: " + probe.names[i] + " is not the Material text";
            }
            console.log(err ? "KEYS-PHONE-GLYPHS-PROBE-FAIL " + err : "KEYS-PHONE-GLYPHS-PROBE-PASS " + (probe.wantCrate ? "crate" : "stock"));
            Qt.quit();
        }
    }
}
