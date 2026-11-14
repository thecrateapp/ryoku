import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import "modules/bar/barstyles/qsbar/panels"

// The QS Bar's image picker (top row) and media picker (bottom row) in each
// pickerStyle, tanzaku, hearthstone and carousel, over a desktop. Each is the
// Item its layer window hosts (a layer window needs a compositor), fed a
// stand-in picker whose thumbnails are the repo's wallpapers (PICKER_ART, or
// ryoku/assets/wallpapers under the working directory); the glass shows the
// desktop unfrosted here. The media carousel has a delete armed. The software
// renderer draws no shader effects, so the tanzaku strips (ClippingRectangle)
// and the carousel slices (a MultiEffect mask) show their frames without the
// photo, alike in both looks.
ShellRoot {
    id: scene

    readonly property string art: "file://" + (Quickshell.env("PICKER_ART") || (Quickshell.env("PWD") + "/ryoku/assets/wallpapers")) + "/"
    readonly property var files: ["wallhaven-3q2jqy.jpg", "lain-walk.jpg", "wallhaven-5yzd98.png", "wallhaven-211xrg.jpg",
        "wallhaven-1qxxkg.png", "138032536_p0.jpg", "wallhaven-5ykjq7.jpg", "Angel1.png", "wallhaven-212ldx.png"]
    readonly property var names: ["Kanagawa", "Tokyo Night", "Gruvbox", "Everforest", "Rose Pine", "Nord", "Catppuccin", "Osaka Jade", "Matte Black"]
    function entries(media) {
        const out = [];
        for (let i = 0; i < scene.files.length; i++)
            out.push({ idx: i, filePath: "/w/" + scene.files[i], thumbnailPath: scene.art.slice(7) + scene.files[i],
                       thumb: scene.art + scene.files[i], label: media ? "2026-11-1" + (i % 10) + "  1" + i + ":2" + i : scene.names[i],
                       dir: "/t/" + i, current: !media && i === 3 });
        return out;
    }

    // the bar's theme: the palette the bar draws with
    QtObject {
        id: theme
        readonly property color paper: Tokens.paper
        readonly property color ink: Tokens.ink
        readonly property color seal: Tokens.sun
        readonly property color sep: Qt.rgba(Tokens.ink.r, Tokens.ink.g, Tokens.ink.b, 0.18)
        readonly property color frameWeak: Tokens.paperLift
        readonly property color sectionInk: Tokens.caption
        readonly property string mono: Tokens.mono
        property bool imagePickerVisible: true
        property bool mediaBrowserVisible: true
        function evenW(v) { return Math.round(v / 2) * 2 }
    }

    component Strip: QtObject {
        property bool visible: true
        property bool active: true
        property bool ready: true
        property real reveal: 1
        property real dealT: 1
        readonly property bool dealSettled: true
        property int cardMotionDuration: 0
        property bool isThemeMode: true
        property bool isVideos: false
        property bool scanDone: true
        property bool loaded: true
        property bool layoutSettled: true
        property bool confirmDelete: false
        property string filterText: ""
        property int selFilt: 3
        property var filtered: []
        readonly property var sel: filtered[selFilt]
        property var selMeta: ({ author: "sainnhe", repo: "https://github.com/sainnhe/everforest", palette: "#e67e80,#a7c080,#dbbc7f,#7fbbb3,#d699b6,#83c092" })
        readonly property string currentLabel: sel ? sel.label : ""
        property int thumbEpoch: 0
        property string readyThumbUrl: ""
        readonly property int focusedW: 460
        readonly property int focusedH: 259
        readonly property int peekW: 104
        readonly property int stripW: 24
        readonly property int gap: 8
        readonly property int maxVisible: 5
        function stripWidthFor(d) { return d <= 0 ? focusedW : d === 1 ? peekW : stripW }
        readonly property color scrim: Qt.rgba(theme.paper.r, theme.paper.g, theme.paper.b, 0.8)
        readonly property color frameBg: theme.frameWeak
        readonly property color uiDim: Qt.rgba(theme.ink.r, theme.ink.g, theme.ink.b, 0.45)
        readonly property int cardW: 232
        readonly property int cardH: 330
        readonly property real focusScale: 1.24
        readonly property real spreadDeg: 6.0
        readonly property real stepX: 128
        readonly property real focusLift: 54
        readonly property color feltColor: Qt.rgba(0.035, 0.035, 0.05, 0.975)
        readonly property color frameDark: Qt.rgba(0.086, 0.086, 0.11, 1)
        readonly property color textLight: Qt.rgba(0.925, 0.925, 0.933, 1)
        readonly property color textDim: Qt.rgba(0.92, 0.92, 0.94, 0.55)
        function applySelected() {}
        function openSelected() {}
        function moveSel(d) {}
        function openRepo() {}
    }
    component Wheel: QtObject {
        property bool visible: true
        property bool active: true
        property bool ready: true
        property bool isThemeMode: true
        property bool isVideos: false
        property bool scanDone: true
        property bool loaded: true
        property bool layoutSettled: true
        property bool confirmDelete: false
        property string filterText: ""
        property int selectedIndex: 3
        property var imageArray: []
        property var labels: []
        property int thumbEpoch: 0
        property string readyThumbUrl: ""
        readonly property var sel: imageArray[selectedIndex] || null
        readonly property int expandedW: 768
        readonly property int expandedH: 432
        readonly property int sliceW: 108
        readonly property int sliceH: 390
        readonly property int sliceGap: -30
        readonly property int skew: 28
        readonly property color selBorder: theme.seal
        readonly property color unselBorder: Qt.rgba(theme.ink.r, theme.ink.g, theme.ink.b, 0.22)
        readonly property color dimColor: theme.paper
        readonly property color footerText: theme.seal
        readonly property color footerDim: Qt.rgba(footerText.r, footerText.g, footerText.b, 0.68)
        function itemMatches(i) { return true }
        function filteredPos(i) { return i }
        function selectedFiltPos() { return selectedIndex }
        function thumbUrlFor(img) { return img ? "file://" + img.thumbnailPath : "" }
        function currentLabel() { return labels[selectedIndex] || "" }
        function selectAdjacent(d) {}
        function applySelected() {}
        function openSelected() {}
    }

    Strip { id: themes; filtered: scene.entries(false); filterText: "e" }
    Strip { id: walls; filtered: scene.entries(false); isThemeMode: false; selFilt: 4 }
    Wheel { id: themeWheel; imageArray: scene.entries(false); labels: scene.names }
    Strip { id: shots; filtered: scene.entries(true); isThemeMode: false; selFilt: 2 }
    Strip { id: videos; filtered: scene.entries(true); isThemeMode: false; isVideos: true; selFilt: 5 }
    Wheel { id: clipWheel; imageArray: scene.entries(true); labels: scene.entries(true).map(e => e.label); isVideos: true; confirmDelete: true; selectedIndex: 1 }

    FloatingWindow {
        implicitWidth: sheet.width
        implicitHeight: sheet.height
        color: Tokens.paper

        Grid {
            id: sheet
            columns: 3
            spacing: 0

            Repeater {
                model: 6
                Item {
                    id: cell
                    required property int index
                    width: 1280
                    height: 760
                    clip: true
                    // the desktop under the picker
                    Image {
                        anchors.fill: parent
                        source: scene.art + scene.files[(cell.index + 6) % scene.files.length]
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: 1280
                    }
                    Loader {
                        anchors.fill: parent
                        sourceComponent: [tanzakuImages, hearthImages, wheelImages, tanzakuMedia, hearthMedia, wheelMedia][cell.index]
                    }
                }
            }
        }

        Component { id: tanzakuImages; ImageCarouselPanelView { picker: themes; root: theme } }
        Component { id: hearthImages; ImageCarouselHearthstoneView { picker: walls; root: theme } }
        Component { id: wheelImages; ImageCarouselCarouselView { picker: themeWheel; root: theme } }
        Component { id: tanzakuMedia; MediaBrowserPanelView { picker: shots; root: theme } }
        Component { id: hearthMedia; MediaBrowserHearthstoneView { picker: videos; root: theme } }
        Component { id: wheelMedia; MediaBrowserCarouselView { picker: clipWheel; root: theme } }

        Timer {
            interval: Number(Quickshell.env("BENCH_WAIT") || 4000)
            running: true
            onTriggered: sheet.grabToImage(r => { r.saveToFile(Quickshell.env("BENCH_OUT")); Qt.quit(); })
        }

        Component.onCompleted: {
            const look = Quickshell.env("BENCH_CRATE");
            if (look === "1" || look === "0")
                Tokens.controlsCrate = look === "1";
            // the Crate theme's switches (hub-fixture/crate.json), so the crate
            // look shows its mark, its hairline and its mono face
            if (look === "1") {
                Tokens.accentMarks = true;
                Tokens.selectFill = false;
                Tokens.labelAccent = true;
                Tokens.compact = true;
                Tokens.lineAlpha = 0.1;
                Tokens.mono = "JetBrainsMono Nerd Font";
            }
        }
    }
}
