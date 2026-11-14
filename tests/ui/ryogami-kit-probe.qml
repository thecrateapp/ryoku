import QtQuick
import Quickshell
import Ryoku.Ui.Singletons
import Ryoku.Ryogami

// The Ryogami picker on the kit, in the crate and the stock look: Theme takes its
// roles, faces, type ladder and corner from Tokens under crate (a previewed
// candidate palette still wins); FolioSlider draws the Beam, Switch is Sw,
// SectionLabel the tracked label, ResetChip, RiceChip, BrowserChip and
// FixedButton the kit Chip (a lone x the plateless close), the search panel's
// segments the kit Seg, the masthead's open library an underline; the stock
// look draws none of them.
ShellRoot {
    id: probe

    property int slid: 0
    property int released: 0
    property bool switched: false
    property int resets: 0
    property int browserTaps: 0
    property int buttonTaps: 0
    property int closes: 0

    FloatingWindow {
        implicitWidth: 1400
        implicitHeight: 900

        PickerState {
            id: pickerState
            view: LibraryView { collection: pickerState.collection }
            shown: true
            filterBarToggled: true
        }

        Column {
            x: 40; y: 220
            width: 600
            spacing: 14
            FolioSlider { id: slider; width: 400; from: 0; to: 2; value: 1.2; step: 0.1; onMoved: probe.slid++; onReleased: probe.released++ }
            Switch { id: sw; checked: false; onToggled: (v) => probe.switched = v }
            SectionLabel { id: section; width: 400; text: "Filters" }
            ResetChip { id: reset; onTriggered: probe.resets++ }
            RiceChip { id: riceStrong; label: "LIVE"; strong: true }
            RiceChip { id: ricePlain; label: "dark" }
            BrowserChip { id: plainChip; kind: "plain"; label: "Top"; active: true; onClicked: probe.browserTaps++ }
            BrowserChip { id: swatchChip; kind: "swatch"; swatchIndex: 2; swatchInner: "#c33" }
            FixedButton { id: held; label: "Current wallpaper"; active: true }
            FixedButton { id: idle; label: "Beginning"; onTriggered: probe.buttonTaps++ }
            FixedButton { id: risky; label: "Delete"; destructive: true; confirm: true }
            FixedButton { id: dismiss; label: "×"; onTriggered: probe.closes++ }
            ChoiceButtons { id: choice; options: [{ value: "a", label: "Alpha" }, { value: "b", label: "Beta" }]; value: "b" }
        }

        FilterBar { id: bar; anchors.fill: parent; state: pickerState }
        SearchPanel { id: search; anchors.fill: parent; state: pickerState }
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
    function findAll(item, name, out) {
        if (!item) return out;
        if (item.objectName === name) out.push(item);
        for (const child of item.children) findAll(child, name, out);
        return out;
    }
    function check(test, reason) { if (!test) throw new Error(reason); }
    function same(a, b) { return Qt.colorEqual(a, b); }
    function firstVisibleText(item) {
        for (const child of item.children)
            if (child instanceof Text && child.visible) return child;
        return null;
    }

    Timer {
        id: crateCheck
        interval: 700
        running: true
        onTriggered: {
            Tokens.controlsCrate = true;
            check(Theme.crate, "Theme follows controls crate");
            // roles, faces, ladder and corner from Tokens
            check(Theme.radius === Tokens.radius, "the shared 6 px corner, whatever the scale");
            check(same(Theme.surface, Tokens.popover) && same(Theme.background, Tokens.paper), "panels on popover, canvas on paper");
            check(same(Theme.surfaceText, Tokens.ink) && same(Theme.primary, Tokens.sun) && same(Theme.tertiary, Tokens.alert), "ink, accent and alert from Tokens");
            check(Theme.sans === Tokens.ui && Theme.display === Tokens.display && Theme.mono === Tokens.mono, "the desktop's faces and its mono");
            check(Math.abs(Theme.fontFine - Theme.fs(Tokens.fMicro)) < 0.01, "captions on the kit's 11 px label at the picker's scale");
            check(Math.abs(Theme.fontSection - Theme.fs(Tokens.fTitle)) < 0.01, "the folio title on the page title");
            Theme.previewPalette = { primary: "#123456" };
            check(same(Theme.primary, "#123456") && same(Theme.surface, Tokens.popover), "a previewed palette still wins, role by role");
            Theme.previewPalette = null;

            const beam = find(slider, "folioBeam");
            check(beam && beam.visible && !beam.interactive, "FolioSlider draws a non-interactive Beam");
            check(Math.abs(beam.value - 1.2) < 1e-6 && beam.to === 2 && beam.stepSize === 0.1, "the Beam shows the slider's range");
            check(!beam.hotHint, "no thumb at rest");
            slider.focused = true;
            check(beam.hotHint, "focus shows the thumb");
            slider.focused = false;

            const kitSw = find(sw, "folioSw");
            check(kitSw && kitSw.visible && kitSw.on === false, "Switch is the kit Sw");
            kitSw.toggled(true);
            check(probe.switched === true, "the Sw's toggle reaches the picker switch");
            sw.checked = true;
            check(kitSw.on, "the Sw follows checked");

            const label = find(section, "sectionLabel");
            check(label && label.visible && label.tone === "accent" && label.text === "Filters", "SectionLabel is the accent tracked label");
            check(label.font.family === Tokens.mono && label.font.capitalization === Font.AllUppercase, "mono, upper case");

            const resetKit = find(reset, "resetChip");
            check(resetKit && resetKit.visible && resetKit.radius === Tokens.radius, "ResetChip is a straight kit chip");
            resetKit.clicked();
            check(probe.resets === 1, "the chip resets");

            const strong = find(riceStrong, "riceChip");
            check(strong.visible && strong.on && !strong.interactive && same(strong.color, Tokens.mark), "a strong rice tag is filled with the mark");
            check(!find(ricePlain, "riceChip").on, "a plain rice tag is a hairline chip");

            const pc = find(plainChip, "browserChip");
            check(pc.visible && pc.on && same(pc.color, Tokens.mark), "an active browser chip is filled with the mark");
            pc.clicked();
            check(probe.browserTaps === 1, "the browser chip taps");
            check(!find(swatchChip, "browserChip").visible, "a swatch keeps its colour square");

            const heldChip = find(held, "fixedChip");
            check(heldChip.visible && heldChip.on && same(heldChip.color, Tokens.mark) && same(heldChip.border.color, Tokens.mark), "a held button is filled with the mark");
            const idleChip = find(idle, "fixedChip");
            check(!idleChip.on && same(idleChip.color, "transparent") && same(idleChip.border.color, Tokens.line), "an idle button is a hairline chip");
            idleChip.clicked();
            check(probe.buttonTaps === 1, "the chip's click runs the button");
            const riskyChip = find(risky, "fixedChip");
            check(same(riskyChip.labelInk, Tokens.alert), "a destructive button speaks in the alert");
            riskyChip.clicked();
            check(risky.armed && riskyChip.on, "a first press arms the destructive button");
            check(riskyChip.text.indexOf("Delete") > 0, "the armed chip asks to confirm");
            const close = find(dismiss, "fixedClose");
            check(close && close.visible && !find(dismiss, "fixedChip").visible && close.glyph === "close", "a lone x is the kit's close");
            close.clicked();
            check(probe.closes === 1, "the close button closes");
            const choices = findAll(choice, "fixedChip", []);
            check(choices.length === 2 && !choices[0].on && choices[1].on, "a choice row fills the chosen chip");

            pickerState.searchOpen = true;
            // the masthead shows whatever filterBarAlwaysVisible says
            if (!pickerState.filterBarShown)
                pickerState.filterBarToggled = !pickerState.filterBarToggled;

            armCheck.start();
        }
    }

    // the chip's fill animates (150 ms), so the armed colour is read a beat later
    Timer {
        id: armCheck
        interval: 400
        onTriggered: {
            check(same(find(risky, "fixedChip").color, Tokens.alert), "arming fills it with the alert");
            check(find(search, "searchModeSeg").visible && find(search, "miniSeg").visible, "the search panel's switches are kit Seg");
            const underline = find(bar, "collectionUnderline");
            check(underline && underline.visible && same(underline.color, Tokens.mark) && underline.height === 2, "the open library is underlined in the mark");
            Tokens.controlsCrate = false;
            stockCheck.start();
        }
    }

    Timer {
        id: stockCheck
        interval: 500
        onTriggered: {
            check(!Theme.crate, "stock look");
            check(Math.abs(Theme.radius - 6 * Theme.scale) < 1e-6, "stock corner scales with the picker");
            check(same(Theme.surface, Theme.wallPalette.surface), "stock panels keep the picker's own palette");
            check(Theme.display === "Fraunces" && Math.abs(Theme.fontFine - Theme.fs(9)) < 0.01, "stock faces and ladder");
            check(!find(slider, "folioBeam").visible, "stock slider draws its own track");
            check(!find(sw, "folioSw").visible, "stock switch draws its own track");
            check(!find(section, "sectionLabel").visible, "stock section label keeps its tick");
            check(!find(reset, "resetChip").visible, "stock reset is a link");
            check(!find(held, "fixedChip").visible && !find(dismiss, "fixedClose").visible, "stock buttons keep their plates");
            check(!find(plainChip, "browserChip").visible, "stock browser chip keeps its underline");
            check(!find(search, "searchModeSeg").visible && !find(search, "miniSeg").visible, "stock search switches keep their plates");
            check(!find(bar, "collectionUnderline").visible, "stock library tabs keep the plate");
            console.log("RYOGAMI-KIT-PROBE-PASS");
            Qt.quit();
        }
    }
}
