import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import shell.services
import "modules/gamebar"
import "modules/gamebar/cards"
import "modules/gamebar/look"

// The Game Bar on the kit, in both looks. Under crate the strip and the cards are
// the shared glass with a hairline and the 6 px corner; every control drawn on
// them is a kit component (IconButton, Btn, Tabs, Seg, MeterRow, InfoRow,
// LevelRow, StreamRow, the caption a TrackLabel) and every colour a Tokens role.
// In the stock look none of the kit controls shows and the overlay keeps its
// Material roles and the Hub's corner.
ShellRoot {
    id: probe

    property string look: "crate"
    property var picked: []
    property int snaps: 0

    FloatingWindow {
        implicitWidth: 1500
        implicitHeight: 900

        QtObject {
            id: host
            property bool live: true
            property bool suppressed: true
            readonly property var catalogue: [
                { id: "capture", label: "Capture", symbol: "screenshot_region" },
                { id: "performance", label: "Performance", symbol: "speed" },
                { id: "media", label: "Media", symbol: "music_note" },
                { id: "voice", label: "Voice", symbol: "headset_mic", glyph: "discord", minimal: true }
            ]
            function entry(id) {
                for (let i = 0; i < host.catalogue.length; i++)
                    if (host.catalogue[i].id === id)
                        return host.catalogue[i];
                return {};
            }
            function symbolFor(id) { return host.entry(id).symbol || ""; }
            function glyphFor(id) { return host.entry(id).glyph || ""; }
            function beginDrag(id) {}
            function dragBy(id, dx, dy) {}
            function endDrag(id) {}
            function beginResize(id) {}
            function resizeBy(id, dx, dy) {}
            function endResize(id) {}
            function shoot(mode) {}
            function startRecording() {}
        }

        Item {
            id: stage
            anchors.fill: parent

            GameBarStrip {
                id: strip
                cards: host.catalogue
                activeIds: ["performance"]
                snapping: true
                onPicked: id => probe.picked = probe.picked.concat([id])
                onSnapToggled: probe.snaps++
            }
            CaptureCard { id: capture; y: 80; s: 1; host: host; cardId: "capture"; width: 350; height: 240 }
            PerformanceCard { id: performance; x: 360; y: 80; s: 1; host: host; cardId: "performance"; width: 340; height: 356 }
            ResourcesCard { id: resources; x: 710; y: 80; s: 1; host: host; cardId: "resources"; width: 350; height: 200 }
            AudioCard { id: audio; x: 1070; y: 80; s: 1; host: host; cardId: "audio"; width: 350; height: 282 }
            GalleryCard { id: gallery; y: 450; s: 1; host: host; cardId: "gallery"; width: 350; height: 290 }
            MediaCard { id: media; x: 360; y: 450; s: 1; host: host; cardId: "media"; width: 358; height: 235 }
            VoiceCard { id: voice; x: 720; y: 450; s: 1; host: host; cardId: "voice"; width: 358; height: 336 }
            TasksCard { id: tasks; x: 1090; y: 450; s: 1; host: host; cardId: "tasks"; width: 350; height: 270 }
        }
    }

    function all(item, name, out) {
        out = out || [];
        if (!item)
            return out;
        if (item.objectName === name)
            out.push(item);
        for (const child of item.children)
            probe.all(child, name, out);
        return out;
    }
    function find(item, name) {
        const hits = probe.all(item, name);
        return hits.length > 0 ? hits[0] : null;
    }
    // shown: the item and every ancestor up to the stage are visible
    function shown(item) {
        for (let it = item; it && it !== stage; it = it.parent)
            if (!it.visible)
                return false;
        return !!item;
    }
    function check(test, reason) {
        if (!test)
            throw new Error(probe.look + ": " + reason);
    }
    function same(a, b) {
        return Qt.colorEqual(a, b);
    }
    // the card's frame: the Rectangle the GameBarCard fills
    function frameOf(card) {
        for (const child of card.children)
            if (child.border !== undefined && child.radius !== undefined)
                return child;
        return null;
    }

    function verify(crate) {
        const L = GameBarLook;
        // roles: every colour and corner from Tokens under crate, Theme otherwise
        check(L.crate === crate, "GameBarLook follows controlsCrate");
        // every icon the overlay names draws a Solar glyph under crate (only
        // Discord's mark is a brand and keeps its own)
        if (crate)
            for (const n in L.solarNames)
                check(L.solar(n).length > 0, "a Solar glyph for " + n);
        check(same(L.panel, crate ? Tokens.glass : Theme.surfaceContainerLow), "the card fill");
        check(same(L.bar, crate ? Tokens.glass : Theme.surfaceContainer), "the strip fill");
        check(same(L.border, crate ? Tokens.line : Theme.outlineVariant), "the hairline");
        check(same(L.fg, crate ? Tokens.ink : Theme.onSurface), "the ink");
        check(same(L.subtext, crate ? Tokens.inkSubtle : Theme.outline), "the subtle ink");
        check(same(L.accent, crate ? Tokens.sun : Theme.primary), "the accent");
        check(same(L.danger, crate ? Tokens.alert : Theme.error), "the alert");
        check(L.radiusWindow === (crate ? Tokens.radius : Config.gamebar.radius), "the window corner");
        check(L.radiusSmall === (crate ? Tokens.radius : Math.max(0, Config.gamebar.radius - 2)), "the small corner");
        check(crate ? L.content.a === 0 : same(L.content, Theme.surfaceContainer), "no second plate inside a card under crate");

        // the frame and the strip
        const frame = probe.frameOf(capture);
        check(frame && same(frame.color, L.panel) && same(frame.border.color, L.border) && frame.border.width === 1,
            "the card frame is the panel fill with a 1 px hairline");
        check(frame.radius === L.radiusWindow, "the card frame takes the window corner");
        check(same(strip.color, L.bar) && strip.radius === L.radiusWindow, "the strip fill and corner");

        // the kit controls show under crate only
        const kitButtons = probe.all(strip, "gameBarStripButton");
        check(kitButtons.length === host.catalogue.length, "a kit button per widget");
        check(kitButtons.every(b => probe.shown(b) === crate), "the strip's kit buttons show under crate only");
        check(!crate || kitButtons[1].on && !kitButtons[0].on, "the active widget's button is on");
        check(!crate || kitButtons[2].glyph === "music_note", "a widget with a Solar glyph draws it");
        check(!crate || kitButtons[0].glyph === "crop-minimalistic", "the capture widget draws its Solar glyph");
        check(!crate || kitButtons[3].glyph === "" && kitButtons[3].path === "",
            "Discord keeps its own solid mark, carried inside the kit button");
        check(probe.shown(probe.find(strip, "gameBarSnapButton")) === crate, "the snap toggle is a kit button");
        check(probe.shown(probe.find(strip, "gameBarBatteryGlyph")) === (crate && Battery.present), "the battery is a kit glyph");

        const titleButtons = probe.all(capture, "gameBarKitButton");
        check(titleButtons.length >= 2 && titleButtons.every(b => probe.shown(b) === crate), "pin and close are kit buttons");
        const title = probe.find(capture, "gameBarCardTitle");
        check(title.crate === crate && (!crate || title.font.capitalization === Font.AllUppercase && title.font.family === Tokens.mono),
            "the card head is the kit caption under crate");
        // the card's 16 px panel padding under crate: the head's glyph and the
        // body start on the same edge; stock keeps its 6 px head and 14 px body
        const head = probe.find(capture, "gameBarTitleBar");
        const body = probe.find(capture, "gameBarBody");
        const sc = capture.s;
        const headX = head.mapToItem(capture, 0, 0).x, bodyX = body.mapToItem(capture, 0, 0).x;
        const edgeX = probe.find(capture, "gameBarCardFrame").mapToItem(capture, 0, 0).x;
        check(crate ? Math.abs(headX - edgeX - 16 * sc) < 0.5 && Math.abs(bodyX - edgeX - 16 * sc) < 0.5
                    : Math.abs(headX - edgeX - 6 * sc) < 0.5 && Math.abs(bodyX - edgeX - 14 * sc) < 0.5,
            "the card's padding (head " + (headX - edgeX) + ", body " + (bodyX - edgeX) + ")");

        check(probe.all(performance, "gameBarInfoRow").filter(r => probe.shown(r)).length === (crate ? 3 : 0), "the readings are InfoRows");
        check(probe.all(performance, "gameBarMeterRow").filter(r => probe.shown(r)).length === (crate ? 4 : 0), "the meters are MeterRows");
        check(probe.shown(probe.find(performance, "gameBarSparkHead")) === false || crate, "the graph's head dot is crate's");
        check(probe.shown(probe.find(resources, "gameBarKitTabs")) === crate, "the resource tabs are the kit's Tabs");
        check(probe.shown(probe.find(audio, "gameBarOutputRow")) === crate
            && probe.shown(probe.find(audio, "gameBarInputRow")) === crate, "the faders are LevelRows");
        check(probe.shown(probe.find(gallery, "gameBarGallerySeg")) === crate, "the gallery's modes are a Seg");
        check(probe.all(capture, "gameBarActionTile").every(t => crate ? t.color.a === 0 && t.border.width === 1 : t.border.width === 0),
            "a capture tile is a hairline tile under crate, a raised fill otherwise");
        const btns = probe.all(gallery, "gameBarKitButton").concat(probe.all(capture, "gameBarKitButton"));
        check(btns.some(b => b.text !== undefined && probe.shown(b) === crate), "text buttons are the kit's Btn");
        // two in the full card; the pinned overlay's pair hides with it
        check(probe.all(voice, "gameBarVoiceButton").filter(b => probe.shown(b)).length === (crate ? 2 : 0),
            "mute and deafen are kit buttons");
        check(probe.all(media, "gameBarTransportButton").filter(b => probe.shown(b)).length === (crate ? 3 : 0),
            "the transport is kit buttons");
    }

    function exercise() {
        // the kit controls reach the Game Bar's own signals
        const buttons = probe.all(strip, "gameBarStripButton");
        buttons[2].clicked();
        probe.find(strip, "gameBarSnapButton").clicked();
        check(probe.picked.join() === "media" && probe.snaps === 1, "the strip's kit buttons pick and snap");
        const tabs = probe.find(resources, "gameBarKitTabs");
        tabs.chose("2");
        check(GameBarStore.resourceTab === 2, "a kit tab picks its resource");
        probe.find(gallery, "gameBarGallerySeg").chose("clips");
        check(gallery.mode === "clips", "the Seg switches the gallery");
    }

    Timer {
        id: crateCheck
        interval: 600
        onTriggered: {
            probe.verify(true);
            probe.exercise();
            Tokens.controlsCrate = false;
            probe.look = "stock";
            stockCheck.start();
        }
    }
    Timer {
        id: stockCheck
        interval: 600
        onTriggered: {
            probe.verify(false);
            console.log("GAMEBAR-KIT-PROBE-PASS");
            Qt.quit();
        }
    }
    Timer {
        interval: 300
        running: true
        onTriggered: {
            DiscordVoice.status = "authenticated";
            DiscordVoice.channel = { name: "Raid night" };
            Tokens.controlsCrate = true;
            crateCheck.start();
        }
    }
}
