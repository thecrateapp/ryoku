import QtQuick
import Quickshell
import Ryoku.Ui
import Ryoku.Ui.Singletons
import shell.services
import "modules/capture"

// The capture overlays' drawing in both looks. Under crate: the scrim is the
// theme's scrim role, the selection edge the 1 px pickEdge, the readouts opaque
// popover tags (Tokens.radius, a hairline, mono values) so they read over any
// content, the camera cue and flip are kit glyphs (Solar videocamera and
// flip-horizontal), the handles and rim take the mark, and the keypress
// placement tag is a TrackLabel. In stock every one of those keeps its old value.
ShellRoot {
    id: probe
    property string look: "crate"

    FloatingWindow {
        implicitWidth: 900
        implicitHeight: 600

        CaptureFrame {
            id: frame
            width: 800
            height: 500
            sel: "region"
            hasRect: true
            hlx: 100
            hly: 80
            hlw: 360
            hlh: 200
        }
        RegionDim {
            id: dim
            width: 800
            height: 500
            bx: 60
            by: 40
            bw: 300
            bh: 200
        }
        Item {
            x: 500
            y: 100
            width: 220
            height: 220
            CameraFace { id: face; anchors.fill: parent; rad: 40 }
            CameraHandles { id: handles; anchors.fill: parent; mode: "round" }
        }
        KeypressPlacement {
            id: place
            x: 100
            y: 400
            width: 200
            height: 60
            dark: true
            shown: true
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
    // compared at 8 bits a channel: a Text keeps its colour as a QRgb
    function same(a, b) { return Qt.color(a).toString() === Qt.color(b).toString(); }
    function scrim(a) { return Qt.rgba(Theme.scrim.r, Theme.scrim.g, Theme.scrim.b, a); }

    function verify(crate) {
        // the selection frame
        check(same(get(frame, "captureBand").color, crate ? scrim(0.45) : Qt.rgba(0, 0, 0, 0.45)), "the dim band");
        const edge = get(frame, "captureOutline");
        check(edge.border.width === (crate ? Tokens.border : 2), "the selection edge's weight, got " + edge.border.width);
        check(same(edge.border.color, crate ? Tokens.pickEdge : Theme.frameLine), "the selection edge's colour");
        const bare = get(frame, "captureSize");
        const tag = get(frame, "captureReadout");
        const val = get(frame, "captureReadoutText");
        check(bare.visible === !crate && tag.visible === crate, "a tag under crate, the bare readout in stock");
        check(bare.text === "360×200" && val.text === "360×200", "the readout's value");
        check(same(bare.color, Theme.outline) && bare.font.family === Theme.fontPrimary
            && bare.font.pixelSize === Theme.fontSm, "the stock readout keeps its face");
        if (crate) {
            check(same(tag.color, Tokens.popover) && tag.radius === Tokens.radius
                && tag.border.width === Tokens.border && same(tag.border.color, Tokens.line), "the readout tag is an opaque popover");
            check(val.font.family === Tokens.mono && same(val.color, Tokens.ink) && val.font.pixelSize === Tokens.fSmall,
                "the readout value is mono ink");
            check(tag.y >= frame.hly + frame.hlh && tag.x + tag.width <= frame.width, "the tag sits under the selection, on screen");
        }
        // the region-recording dim
        check(same(get(dim, "regionBand").color, crate ? scrim(0.45) : Qt.rgba(0, 0, 0, 0.45)), "the recording dim");
        // the camera bubble
        check(same(get(face, "cameraBackdrop").color, crate ? Tokens.popover : Theme.frameBg), "the camera backdrop");
        const cue = get(face, "cameraCue");
        check(cue.visible === crate && get(face, "cameraCueStock").visible === !crate, "the kit cue under crate");
        check(cue.name === "videocamera" && GlyphCatalog.has(cue.name), "the cue is Solar's videocamera");
        const rim = get(face, "cameraRim");
        check(rim.border.width === (crate ? Tokens.border : 2) && same(rim.border.color, crate ? Tokens.mark : Theme.primary), "the rim");
        // the camera handles
        for (const name of ["cameraRoundDot", "cameraGrip"]) {
            const h = get(handles, name);
            check(same(h.color, crate ? Tokens.popover : Theme.onSurface), name + " fill");
            check(h.border.width === (crate ? Tokens.border : 2) && same(h.border.color, crate ? Tokens.mark : Theme.primary), name + " edge");
        }
        check(get(handles, "cameraGrip").radius === (crate ? Tokens.radius : 3), "the grip's corner");
        for (const [mode, name] of [["round", "cameraRadius"], ["resize", "cameraSize"]]) {
            handles.mode = mode;
            const t = get(handles, name + "Tag");
            const x = get(handles, name + "Text");
            check(t.visible, name + " shows while " + mode);
            check(same(t.color, crate ? Tokens.popover : Qt.rgba(0, 0, 0, 0.72)) && t.radius === (crate ? Tokens.radius : 5), name + " tag");
            check(x.font.family === (crate ? Tokens.mono : Theme.mono) && x.font.pixelSize === (crate ? Tokens.fSmall : 11)
                && same(x.color, crate ? Tokens.ink : Theme.onSurface), name + " value");
        }
        handles.mode = "round";
        const flip = get(handles, "cameraFlip");
        check(flip.visible === crate && get(handles, "cameraFlipStock").visible === !crate, "the kit flip under crate");
        if (crate) {
            const btn = get(handles, "cameraFlipButton");
            check(btn.glyph === "flip-horizontal" && GlyphCatalog.has(btn.glyph), "the flip is Solar's flip-horizontal");
            check(btn.on === Camera.flipped, "the flip is on while mirrored");
            const drawn = btn.children.filter(c => c.drawn !== undefined);
            check(drawn.length === 1 && drawn[0].drawn, "the flip draws the Solar glyph, not its name, got " + drawn.map(c => c.drawn + ":" + c.name));
            check(same(flip.color, Tokens.popover) && flip.radius === Tokens.radius, "the flip's tile");
            const was = Camera.flipped;
            btn.clicked();
            check(Camera.flipped === !was && btn.on === !was, "the flip toggles the mirror");
            Camera.flipped = was;
        }
        // the keypress placement chrome
        const pe = get(place, "placeEdge");
        check(same(pe.border.color, crate ? Tokens.mark : Tokens.keycapOnDark)
            && pe.radius === (crate ? Tokens.radius : Tokens.radius + 6), "the placement edge");
        const pt = get(place, "placeTag");
        check(same(pt.color, crate ? Tokens.popover : Tokens.keycapLight)
            && pt.radius === (crate ? Tokens.radius : pt.height / 2), "the placement tag");
        const pl = get(place, "placeLabel");
        check(pl.tone !== undefined, "the placement caption is a TrackLabel");
        check(pl.font.family === (crate ? Tokens.mono : Tokens.ui) && pl.font.pixelSize === (crate ? Tokens.fMicro : 9)
            && same(pl.color, crate ? pl.toneInk : Tokens.keycapOnLight)
            && pl.font.capitalization === (crate ? Font.AllUppercase : Font.MixedCase),
            "the placement caption's face");
    }

    Timer {
        id: crateCheck
        interval: 500
        onTriggered: {
            try {
                probe.verify(true);
                Tokens.controlsCrate = false;
                probe.look = "stock";
                stockCheck.start();
            } catch (e) {
                console.log("CAPTURE-KIT-PROBE-FAIL " + e.message);
                Qt.quit();
            }
        }
    }
    Timer {
        id: stockCheck
        interval: 500
        onTriggered: {
            try {
                probe.verify(false);
                console.log("CAPTURE-KIT-PROBE-PASS");
            } catch (e) {
                console.log("CAPTURE-KIT-PROBE-FAIL " + e.message);
            }
            Qt.quit();
        }
    }
    Timer {
        interval: 200
        running: true
        onTriggered: {
            Tokens.controlsCrate = true;
            crateCheck.start();
        }
    }
}
