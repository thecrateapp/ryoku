import QtQuick
import Quickshell
import Ryoku.Ui.Singletons

// Drives the QS Bar's crate media body with a stand-in panel: the track and
// its output read out, the seek beam follows the position and seeks, the
// transport reaches the player, the record turns only while playing, the
// equalizer curve has a node per band that rises with its gain and nudges it,
// the switch and the preset chips drive the equalizer, and without a player
// the panel says so and hides the controls.
ShellRoot {
    QtObject {
        id: panel
        property bool visible: true
        property bool active: true
        property bool playing: true
        property string playerName: "Crate"
        property string trackTitle: "Pronto"
        property string trackArtist: "Repion"
        property string trackAlbum: "Ciudad lenta"
        property url artSource: ""
        property string outputLabel: "Speakers"
        property bool outputHeadphones: false
        property real shownPos: 84
        property real curLen: 222
        property bool canSeek: true
        property bool canPrevious: true
        property bool canNext: true
        property bool canTogglePlaying: true
        property var levels: [0.2, 0.5, 0.8, 0.4]
        property int bands: 4
        property real energy: 0.3
        property bool eqOn: true
        property string eqPreset: "Bass"
        property var eqPresets: ["Flat", "Bass", "Treble", "Vocal", "Pop", "Rock", "Jazz", "Classic"]
        property var eqBandLabels: ["31", "63", "125", "250", "500", "1k", "2k", "4k", "8k", "16k"]
        property int eqRange: 12
        property var eqGains: [6, 5, 3, 1, 0, -1, 0, 1, 2, 2]
        property real sought: -1
        property string calls: ""
        function fmtTime(s) { const m = Math.floor(s / 60), x = Math.floor(s % 60); return m + ":" + (x < 10 ? "0" : "") + x }
        function seekTo(f) { sought = f }
        function previous() { calls += "prev " }
        function next() { calls += "next " }
        function togglePlaying() { playing = !playing; calls += "toggle " }
        function eqPresetLabel(p) { return p }
        function setEqOn(v) { eqOn = v }
        function setEqBand(i, db) { const g = eqGains.slice(); g[i] = db; eqGains = g }
        function applyEqPreset(p) { eqPreset = p }
    }

    Item {
        width: 408
        height: 900
        CrateMediaDetails {
            id: details
            width: 408
            panel: panel
            property bool closed: false
            onCloseRequested: closed = true
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

    Timer {
        interval: 150
        running: true
        onTriggered: {
            Tokens.controlsCrate = true;
            if (find(details, "mediaTitle").text !== "Pronto" || find(details, "mediaArtist").text !== "Repion")
                throw new Error("The track must read out");
            if (find(details, "mediaOutput").text.indexOf("Speakers") < 0)
                throw new Error("The output device must read out");
            const seek = find(details, "mediaSeek");
            if (Math.abs(seek.value - 84 / 222) > 0.001 || !seek.interactive)
                throw new Error("The seek beam follows the position, value " + seek.value);
            seek.committed(0.5);
            if (panel.sought !== 0.5)
                throw new Error("Committing the beam must seek");
            find(details, "mediaPrevious").clicked();
            find(details, "mediaNext").clicked();
            find(details, "mediaPlay").clicked();
            if (panel.calls !== "prev next toggle ")
                throw new Error("The transport must reach the player: " + panel.calls);
            if (find(details, "mediaRecord").spinning)
                throw new Error("The record stops while paused");
            panel.playing = true;
            if (!find(details, "mediaRecord").spinning)
                throw new Error("The record turns while playing");
            const n0 = find(details, "eqNode-0"), n5 = find(details, "eqNode-5");
            if (!n0 || !n5 || !find(details, "eqNode-9"))
                throw new Error("The curve needs a node per band");
            if (!(n0.y < n5.y))
                throw new Error("A boosted band sits above a cut one");
            n5.nudge(1);
            if (panel.eqGains[5] !== 0)
                throw new Error("A node nudges its band, got " + panel.eqGains[5]);
            find(details, "eqSwitch").toggled(false);
            if (panel.eqOn)
                throw new Error("The switch turns the equalizer off");
            const presets = find(details, "eqPresets");
            if (!presets || presets.options.length !== 8 || presets.current !== "Bass")
                throw new Error("The presets list with the current one on");
            presets.chose("Rock");
            if (panel.eqPreset !== "Rock")
                throw new Error("A preset chip applies its curve");
            panel.active = false;
            if (find(details, "mediaTitle").text === "Pronto" || seek.visible || find(details, "mediaTransport").visible)
                throw new Error("Without a player the panel says so and hides the controls");
            find(details, "closeMedia").clicked();
            if (!details.closed)
                throw new Error("Close must ask to close");
            console.log("MEDIA-DETAILS-PROBE-PASS");
            Qt.quit();
        }
    }
}
