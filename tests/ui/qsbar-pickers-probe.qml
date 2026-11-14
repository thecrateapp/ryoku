import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import "modules/bar/barstyles/qsbar/panels"

// The QS Bar's image and media pickers (pickerStyle tanzaku, hearthstone and
// carousel), each drawn by the Item its layer window hosts, fed a stand-in
// picker. Under crate: the scrim (tanzaku, hearthstone) and the carousel's
// caption plate are the one glass; strips, cards and slices sit in popover at
// Tokens.radius with a hairline edge, the focused one in the 1 px pickEdge; the
// sumi-e brush stroke under the focus does not show; the header, count, hint,
// current badge and delete prompt are tracked kit labels, the filter is the kit
// Field with the search glyph and the theme's author is a kit Btn; type and ink
// come from Tokens. In stock every one of those keeps its old value.
ShellRoot {
    id: probe
    property string look: "crate"

    QtObject {
        id: fakeRoot
        property color paper: "#101014"
        property color ink: "#e4e0da"
        property color seal: "#e2342a"
        property color sep: "#33302c"
        property color frameWeak: "#1a1a1e"
        property color sectionInk: "#c9c2b8"
        property string mono: "monospace"
        property bool imagePickerVisible: true
        property bool mediaBrowserVisible: true
        function evenW(v) { return Math.round(v / 2) * 2 }
    }

    // the tanzaku and hearthstone pickers read the same state
    QtObject {
        id: strip
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
        property string filterText: "to"
        property int selFilt: 1
        property var filtered: [
            { idx: 0, filePath: "/t/a.jpg", thumb: "", thumbnailPath: "", label: "Kanagawa", dir: "/t/a", current: false },
            { idx: 1, filePath: "/t/b.jpg", thumb: "", thumbnailPath: "", label: "Tokyo Night", dir: "/t/b", current: true },
            { idx: 2, filePath: "/t/c.jpg", thumb: "", thumbnailPath: "", label: "Gruvbox", dir: "/t/c", current: false }
        ]
        readonly property var sel: filtered[selFilt]
        property var selMeta: ({ author: "folke", repo: "https://github.com/folke/tokyonight", palette: "#f7768e,#9ece6a,#e0af68" })
        property string currentLabel: "Tokyo Night"
        property int thumbEpoch: 0
        property string readyThumbUrl: ""
        property int opened: 0
        // tanzaku geometry and stock colours
        readonly property int focusedW: 460
        readonly property int focusedH: 259
        readonly property int peekW: 104
        readonly property int stripW: 24
        readonly property int gap: 8
        readonly property int maxVisible: 5
        function stripWidthFor(d) { return d <= 0 ? focusedW : d === 1 ? peekW : stripW }
        readonly property color scrim: Qt.rgba(fakeRoot.paper.r, fakeRoot.paper.g, fakeRoot.paper.b, 0.8)
        readonly property color frameBg: fakeRoot.frameWeak
        readonly property color uiDim: Qt.rgba(fakeRoot.ink.r, fakeRoot.ink.g, fakeRoot.ink.b, 0.45)
        // hearthstone geometry and stock colours
        readonly property int cardW: 232
        readonly property int cardH: 330
        readonly property real focusScale: 1.24
        readonly property real spreadDeg: 6.0
        readonly property real stepX: 128
        readonly property real focusLift: 54
        readonly property color feltColor: Qt.rgba(0.035, 0.035, 0.05, 0.975)
        readonly property color frameDark: "#16161c"
        readonly property color textLight: "#ECECEE"
        readonly property color textDim: Qt.rgba(0.92, 0.92, 0.94, 0.55)
        function applySelected() {}
        function openSelected() {}
        function moveSel(d) {}
        function openRepo() { opened++ }
    }

    // the carousel pickers
    QtObject {
        id: wheel
        property bool visible: true
        property bool active: true
        property bool ready: true
        property bool isThemeMode: true
        property bool isVideos: false
        property bool scanDone: true
        property bool loaded: true
        property bool layoutSettled: true
        property bool confirmDelete: false
        property string filterText: "to"
        property int selectedIndex: 1
        property var imageArray: [
            { filePath: "/t/kanagawa-tones.jpg", thumbnailPath: "" },
            { filePath: "/t/tokyo-night.jpg", thumbnailPath: "" },
            { filePath: "/t/gruvbox-stone.jpg", thumbnailPath: "" }
        ]
        property int thumbEpoch: 0
        property string readyThumbUrl: ""
        readonly property int expandedW: 768
        readonly property int expandedH: 432
        readonly property int sliceW: 108
        readonly property int sliceH: 390
        readonly property int sliceGap: -30
        readonly property int skew: 28
        readonly property color selBorder: fakeRoot.seal
        readonly property color unselBorder: Qt.rgba(fakeRoot.ink.r, fakeRoot.ink.g, fakeRoot.ink.b, 0.22)
        readonly property color dimColor: fakeRoot.paper
        readonly property color footerText: fakeRoot.seal
        readonly property color footerDim: Qt.rgba(footerText.r, footerText.g, footerText.b, 0.68)
        function itemMatches(i) { return true }
        function filteredPos(i) { return i }
        function selectedFiltPos() { return selectedIndex }
        function thumbUrlFor(img) { return "" }
        function currentLabel() { return "Tokyo Night" }
        function selectAdjacent(d) {}
        function applySelected() {}
        function openSelected() {}
    }

    // the media pickers: videos, one armed for delete
    QtObject {
        id: mediaStrip
        property bool visible: true
        property bool active: true
        property bool ready: true
        property real reveal: 1
        property real dealT: 1
        property bool isVideos: true
        property bool loaded: true
        property bool layoutSettled: true
        property bool confirmDelete: true
        property string filterText: ""
        property int selFilt: 0
        property var filtered: strip.filtered
        readonly property var sel: filtered[selFilt]
        property string currentLabel: "2026-11-14  10:20"
        property int thumbEpoch: 0
        readonly property int focusedW: 460
        readonly property int focusedH: 259
        readonly property int peekW: 104
        readonly property int stripW: 24
        readonly property int gap: 8
        readonly property int maxVisible: 5
        function stripWidthFor(d) { return d <= 0 ? focusedW : d === 1 ? peekW : stripW }
        readonly property color scrim: strip.scrim
        readonly property color frameBg: strip.frameBg
        readonly property color uiDim: strip.uiDim
        readonly property int cardW: 232
        readonly property int cardH: 330
        readonly property real focusScale: 1.24
        readonly property real spreadDeg: 6.0
        readonly property real stepX: 128
        readonly property real focusLift: 54
        readonly property color feltColor: strip.feltColor
        readonly property color frameDark: strip.frameDark
        readonly property color textLight: strip.textLight
        readonly property color textDim: strip.textDim
        function openSelected() {}
        function moveSel(d) {}
        function deleteFocused() {}
        function copyFocused() {}
    }
    QtObject {
        id: mediaWheel
        property bool visible: true
        property bool active: true
        property bool ready: true
        property bool isVideos: true
        property bool loaded: true
        property bool layoutSettled: true
        property bool confirmDelete: true
        property string filterText: ""
        property int selectedIndex: 0
        property var imageArray: wheel.imageArray
        property int thumbEpoch: 0
        readonly property int expandedW: 768
        readonly property int expandedH: 432
        readonly property int sliceW: 108
        readonly property int sliceH: 390
        readonly property int sliceGap: -30
        readonly property int skew: 28
        readonly property color selBorder: wheel.selBorder
        readonly property color unselBorder: wheel.unselBorder
        readonly property color dimColor: wheel.dimColor
        readonly property color footerText: wheel.footerText
        readonly property color footerDim: wheel.footerDim
        function itemMatches(i) { return true }
        function filteredPos(i) { return i }
        function selectedFiltPos() { return selectedIndex }
        function currentLabel() { return "2026-11-14  10:20" }
        function selectAdjacent(d) {}
        function openSelected() {}
        function deleteFocused() {}
        function copyFocused() {}
    }

    FloatingWindow {
        implicitWidth: 1400
        implicitHeight: 900

        ImageCarouselPanelView { id: imgTanzaku; width: 1400; height: 900; picker: strip; root: fakeRoot }
        ImageCarouselHearthstoneView { id: imgHearth; width: 1400; height: 900; picker: strip; root: fakeRoot }
        ImageCarouselCarouselView { id: imgWheel; width: 1400; height: 900; picker: wheel; root: fakeRoot }
        MediaBrowserPanelView { id: medTanzaku; width: 1400; height: 900; picker: mediaStrip; root: fakeRoot }
        MediaBrowserHearthstoneView { id: medHearth; width: 1400; height: 900; picker: mediaStrip; root: fakeRoot }
        MediaBrowserCarouselView { id: medWheel; width: 1400; height: 900; picker: mediaWheel; root: fakeRoot }
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
        if (!hit) throw new Error(probe.look + ": " + item + " has no " + name);
        return hit;
    }
    function check(test, reason) { if (!test) throw new Error(probe.look + ": " + reason); }
    // compared at 8 bits a channel: a Text keeps its colour as a QRgb
    function same(a, b) { return Qt.color(a).toString() === Qt.color(b).toString(); }
    // a kit look (crate) and the stock one, both drawn, only one shown
    function swap(view, kit, stock, crate, what) {
        check(get(view, kit).visible === crate && get(view, stock).visible === !crate,
            what + ": the kit item under crate, the stock item otherwise");
    }

    // the caption every layout shares: on the kit under crate, the stock one otherwise
    function verifyCaptions(view, crate, what, titleStock, titleSize, armed) {
        swap(view, "pickerTitleKit", "pickerTitle", crate, what + " title");
        const title = get(view, crate ? "pickerTitleKit" : "pickerTitle");
        check(same(title.color, crate ? Tokens.ink : titleStock), what + " title ink, got " + title.color);
        check(title.font.family === (crate ? Tokens.ui : fakeRoot.mono)
            && title.font.pixelSize === (crate ? Tokens.fValue : titleSize), what + " title face");
        if (armed) {
            swap(view, "pickerConfirmKit", "pickerConfirm", crate, what + " delete prompt");
            check(same(get(view, "pickerConfirmKit").color, Tokens.alert), what + " the delete prompt is in the alert ink");
            check(!get(view, "pickerHintKit").visible && !get(view, "pickerHint").visible, what + " the prompt replaces the hint");
        } else {
            swap(view, "pickerHintKit", "pickerHint", crate, what + " hint");
            check(get(view, "pickerHintKit").tone === "subtle", what + " hint is a subtle label");
        }
    }
    function verifyFilter(view, crate, what) {
        swap(view, "pickerFilterKit", "pickerFilter", crate, what + " filter");
        const field = get(view, "pickerFilterKit");
        check(field.glyph === "search" && field.readOnly && field.text === "to" && !field.enabled,
            what + " filter is a read-only kit Field with the search glyph, fed the typed text");
    }
    function verifyImageMeta(view, crate, what) {
        swap(view, "pickerCurrentKit", "pickerCurrent", crate, what + " current badge");
        swap(view, "pickerAuthorKit", "pickerAuthor", crate, what + " author");
        const author = get(view, "pickerAuthorKit");
        check(author.outline === true && author.text === I18n.tr("by %1").arg("folke"), what + " author is an outlined kit Btn");
        const before = strip.opened;
        author.act();
        check(strip.opened === before + 1, what + " the author button opens the repo");
        const sw = get(view, "pickerSwatch-0");
        check(sw.radius === Tokens.radius / 3 && same(sw.border.color, Tokens.lineStrong) && same(sw.color, "#f7768e"),
            what + " the palette is the kit's colour sample");
    }

    function verifyTanzaku(view, crate, what, image) {
        const scrim = get(view, "pickerScrim");
        check(same(scrim.color, crate ? Tokens.glass : strip.scrim), what + " scrim, got " + scrim.color);
        swap(view, "pickerHeadKit", "pickerHead", crate, what + " header");
        check(get(view, "pickerHeadKit").tone === "accent", what + " header is the accent label");
        check(get(view, "pickerStroke").visible === !crate, what + " the brush stroke shows only in stock");
        const focused = get(view, "pickerFrame-" + (image ? 1 : 0));
        const idle = get(view, "pickerFrame-" + (image ? 0 : 1));
        check(focused.radius === (crate ? Tokens.radius : 8) && idle.radius === focused.radius, what + " frame corner");
        check(same(focused.color, crate ? Tokens.popover : strip.frameBg), what + " frame fill");
        check(focused.border.width === 1 && same(focused.border.color, crate ? Tokens.pickEdge : fakeRoot.seal),
            what + " focused frame edge, got " + focused.border.color);
        check(same(idle.border.color, crate ? Tokens.line : fakeRoot.sep), what + " idle frame edge");
        verifyCaptions(view, crate, what, fakeRoot.ink, 22, !image);
    }

    function verifyHearth(view, crate, what, image) {
        const scrim = get(view, "pickerScrim");
        check(same(scrim.color, crate ? Tokens.glass : strip.feltColor), what + " felt, got " + scrim.color);
        swap(view, "pickerHeadKit", "pickerHead", crate, what + " header");
        const focused = get(view, "pickerCard-" + (image ? 1 : 0));
        const idle = get(view, "pickerCard-" + (image ? 0 : 1));
        check(same(focused.matColor, crate ? Tokens.popover : strip.frameDark), what + " card mat");
        check(focused.outerRadius === (crate ? Tokens.radius : 18), what + " card corner");
        check(same(focused.edgeColor, crate ? Tokens.pickEdge : fakeRoot.seal)
            && focused.edgeWidth === (crate ? Tokens.border : 2), what + " focused card edge");
        check(crate ? same(idle.edgeColor, Tokens.line) && idle.edgeWidth === Tokens.border
                    : idle.edgeWidth === 0, what + " idle card edge");
        const name = get(idle, "pickerCardName");
        check(same(name.color, crate ? Tokens.ink : strip.textLight), what + " card name ink");
        check(same(get(idle, "pickerCardDim").color, crate ? Tokens.paper : "black"), what + " card dim wash");
        verifyCaptions(view, crate, what, strip.textLight, image ? 26 : 24, !image);
    }

    function verifyWheel(view, crate, what, picker) {
        const plate = get(view, "pickerFooterPlate");
        check(plate.visible === crate, what + " the caption plate shows only under crate");
        check(same(plate.color, Tokens.glass) && plate.radius === Tokens.radius
            && plate.border.width === Tokens.border && same(plate.border.color, Tokens.line), what + " caption plate is the glass");
        const sel = get(view, "pickerSlice-" + picker.selectedIndex);
        const idle = get(view, "pickerSlice-" + (picker.selectedIndex === 0 ? 1 : 0));
        check(same(sel.edgeColor, crate ? Tokens.pickEdge : picker.selBorder)
            && sel.edgeWidth === (crate ? Tokens.border : 3), what + " picked slice edge");
        check(same(idle.edgeColor, crate ? Tokens.line : picker.unselBorder), what + " idle slice edge");
        check(!get(view, "pickerMessagePlate").visible, what + " no message plate while the slices show");
        verifyCaptions(view, crate, what, picker.footerText, 30, picker.confirmDelete);
    }

    // the layer windows cannot load offscreen (no PanelWindow backend), but each
    // must fail on that alone: any other error (a syntax slip, a missing view)
    // would take the QS Bar's picker down with it
    function verifyWindows() {
        for (const name of ["ImageCarouselPanel", "ImageCarouselHearthstone", "ImageCarouselCarousel",
                            "MediaBrowserPanel", "MediaBrowserHearthstone", "MediaBrowserCarousel"]) {
            const c = Qt.createComponent("modules/bar/barstyles/qsbar/panels/" + name + ".qml");
            const errors = c.errorString().split("\n").filter(e => e.length > 0 && !e.includes("No PanelWindow backend loaded"));
            check(errors.length === 0, name + " does not compile: " + errors.join(" | "));
        }
    }

    function verify(crate) {
        verifyTanzaku(imgTanzaku, crate, "tanzaku images", true);
        verifyFilter(imgTanzaku, crate, "tanzaku images");
        verifyImageMeta(imgTanzaku, crate, "tanzaku images");
        check(get(imgTanzaku, "pickerDot-1").visible && !get(imgTanzaku, "pickerDot-0").visible, "the current dot marks the theme in use");
        check(get(get(imgTanzaku, "pickerDot-1"), "pickerDotHalo").visible === crate, "the current dot has its halo under crate");

        verifyHearth(imgHearth, crate, "hearthstone images", true);
        verifyFilter(imgHearth, crate, "hearthstone images");
        verifyImageMeta(imgHearth, crate, "hearthstone images");

        verifyWheel(imgWheel, crate, "carousel images", wheel);
        verifyFilter(imgWheel, crate, "carousel images");

        verifyTanzaku(medTanzaku, crate, "tanzaku media", false);
        verifyHearth(medHearth, crate, "hearthstone media", false);
        verifyWheel(medWheel, crate, "carousel media", mediaWheel);
    }

    Timer {
        id: crateCheck
        interval: 600
        onTriggered: {
            try {
                probe.verifyWindows();
                probe.verify(true);
                Tokens.controlsCrate = false;
                Tokens.accentMarks = false;
                Tokens.selectFill = true;
                probe.look = "stock";
                stockCheck.start();
            } catch (e) {
                console.log("QSBAR-PICKERS-PROBE-FAIL " + e.message);
                Qt.quit();
            }
        }
    }
    Timer {
        id: stockCheck
        interval: 600
        onTriggered: {
            try {
                probe.verify(false);
                console.log("QSBAR-PICKERS-PROBE-PASS");
            } catch (e) {
                console.log("QSBAR-PICKERS-PROBE-FAIL " + e.message);
            }
            Qt.quit();
        }
    }
    Timer {
        interval: 200
        running: true
        onTriggered: {
            // the Crate theme's switches
            Tokens.controlsCrate = true;
            Tokens.accentMarks = true;
            Tokens.selectFill = false;
            crateCheck.start();
        }
    }
}
