import QtQuick
import QtQuick.Layouts
import Quickshell
import Ryoku.Ui
import Ryoku.Ui.Singletons
import stage
import stage.services
import stage.modules.common
import stage.modules.ii.editMode

// The Stage editor's chrome in both looks. Under crate: the toolbar, the
// catalogue panel, the widget and bar menus and the guide card are the one
// glass (Tokens.glass in a 1 px Tokens.line at Tokens.radius, no filled
// shadow); the toolbar's controls are kit Chips, IconButtons and the confirm
// Btn; the panel's header drops its lead bar and rule; panel rows take the
// pick wash in the 1 px pickEdge with Solar glyphs, the kit Sw and kit
// IconButton steppers; option runs are kit Chips; section labels are the
// tracked caption. In stock every one of those keeps its old value.
ShellRoot {
    id: probe
    property string look: "crate"
    property string asked: ""

    FloatingWindow {
        implicitWidth: 1600
        implicitHeight: 1000

        EditModeChromeContent {
            id: chrome
            width: 1100
            height: 700
            card: Qt.rect(100, 140, 900, 520)
            area: Qt.rect(0, 0, 1100, 700)
            onDrawerPageRequested: (section, page) => probe.asked = section
        }

        // The catalogue panel's plate and header: the panel itself reads the
        // dock's window list, which needs a compositor.
        EditDrawerPlate {
            id: drawer
            x: 1110
            width: 420
            height: 700

            EditDrawerHeader {
                id: drawerHeader
                x: 16
                y: 16
                width: 388
                canGoBack: true
                title: "Clocks"
            }
        }

        EditWidgetMenu {
            id: widgetMenu
            y: 710
        }

        EditBarMenu {
            id: barMenu
            x: 300
            y: 710
        }

        ColumnLayout {
            x: 600
            y: 710
            width: 380

            EditPanelSectionLabel {
                id: sectionLabel
                text: "Placement"
            }
            EditPanelRow {
                id: pickedRow
                Layout.fillWidth: true
                symbol: "tune"
                title: "Widget options"
                selected: true
                trailingKind: "chevron"
            }
            EditPanelRow {
                id: switchRow
                Layout.fillWidth: true
                symbol: "keep"
                title: "Pin position"
                trailingKind: "switch"
                switchChecked: true
            }
            EditPanelRow {
                id: stepRow
                Layout.fillWidth: true
                symbol: "aspect_ratio"
                title: "Size"
                trailingKind: "stepper"
                valueText: "100%"
            }
            EditOptionChips {
                id: chips
                label: "Corner"
                options: [{ "value": "round", "displayName": "Round", "icon": "circle" },
                          { "value": "square", "displayName": "Square", "icon": "square" }]
                currentValue: "round"
            }
            EditPanelNotice {
                id: notice
                text: "Locked by the theme."
            }
            EditMenuPageHeader {
                id: pageHeader
                title: "Desktop"
                actionSymbol: "open_in_new"
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
        if (item.contentItem && item.contentItem !== item && item.contentItem.parent === item)
            return find(item.contentItem, name);
        return null;
    }
    function get(item, name) {
        const hit = find(item, name);
        if (!hit) throw new Error(probe.look + ": no " + name);
        return hit;
    }
    function check(test, reason) { if (!test) throw new Error(probe.look + ": " + reason); }
    function same(a, b) { return Qt.color(a).toString() === Qt.color(b).toString(); }
    function clear(c) { return Qt.color(c).a === 0; }
    function glass(plate, what, stockFill) {
        check(same(plate.color, probe.look === "crate" ? Tokens.glass : stockFill), what + "'s fill, got " + plate.color);
        if (probe.look === "crate")
            check(plate.border.width === Tokens.border && same(plate.border.color, Tokens.line)
                && plate.radius === Tokens.radius, what + " is the glass in a hairline at Tokens.radius");
    }

    function verify(crate) {
        // the toolbar
        const bar = get(chrome, "editToolbar");
        check(same(bar.colBackground, crate ? Tokens.glass : Appearance.colors.colLayer0), "the toolbar's fill");
        check(same(bar.borderColor, crate ? Tokens.line : Appearance.colors.colOutline), "the toolbar's edge");
        for (const name of ["editKitMonitor", "editKitSections", "editKitSnap", "editKitUndo", "editKitRedo", "editKitDone"])
            check(get(chrome, name).visible === crate, name + " shows only under crate");
        check(get(chrome, "editKitDone").primary === true, "Done is the confirm Btn");
        check(get(chrome, "editKitSnap").glyph !== "", "snapping is a glyph IconButton");
        check(get(chrome, "editKitSection-widgets").text === Translation.tr("Widgets"), "a section chip per section");
        // (the panel itself is not opened: it reads the dock's window list)
        check(get(chrome, "editKitSection-style").on === false, "no section chip is on while the panel is shut");
        probe.asked = "";
        get(chrome, "editKitSection-style").clicked();
        check(probe.asked === "style", "a section chip opens its section, got " + probe.asked);

        // the catalogue panel
        glass(drawer, "the panel", Appearance.colors.colLayer0);
        check(get(drawerHeader, "editDrawerLeadBar").visible === !crate && get(drawerHeader, "editDrawerRule").visible === !crate,
            "the header's lead bar and rule show only in stock");
        check(get(drawerHeader, "editDrawerEyebrow").visible === crate, "the eyebrow is the kit caption under crate");
        check(get(drawerHeader, "editDrawerKitBack").visible === crate, "the way back is the kit's under crate");
        check(get(drawerHeader, "editDrawerBackButton").glyph === "arrow_back", "the way back is the arrow glyph");

        // the menus
        glass(get(widgetMenu, "editWidgetMenuCard"), "the widget menu", Appearance.m3colors.m3surfaceContainer);
        glass(barMenu, "the bar menu", Appearance.colors.colSurfaceContainer);

        // the panel rows
        const plate = get(pickedRow, "editRowPlate");
        check(same(plate.color, crate ? Tokens.pickFill : Appearance.colors.colSecondary), "the picked row's fill");
        check(plate.border.width === (crate ? Tokens.border : 0)
            && (!crate || same(plate.border.color, Tokens.pickEdge)), "the picked row's 1 px pickEdge");
        check(get(pickedRow, "editRowGlyph").visible === crate, "a row's icon is a Solar Glyph under crate");
        check(get(pickedRow, "editRowTrail").visible === crate, "a row's chevron is a Glyph under crate");
        check(get(switchRow, "editRowSwitch").visible === crate && get(switchRow, "editRowSwitch").on === true,
            "a switch row carries the kit Sw under crate");
        check(get(stepRow, "editRowStepDown").visible === crate && get(stepRow, "editRowStepUp").visible === crate,
            "the stepper is kit IconButtons under crate");

        // option chips, labels, notice, page header
        check(get(chips, "editKitChips").visible === crate && get(chips, "editStockChips").visible === !crate,
            "an option run is kit Chips under crate");
        if (crate)
            check(get(chips, "editKitChip-round").on === true && get(chips, "editKitChip-square").on === false,
                "the chosen option's chip is on");
        check(sectionLabel.font.weight === (crate ? Font.Normal : Font.Medium)
            && same(sectionLabel.color, crate ? (Tokens.labelAccent ? Tokens.caption : Tokens.inkSubtle)
                                              : Appearance.colors.colSubtext), "the section caption");
        check(same(notice.color, crate ? Tokens.tint5 : Appearance.colors.colSecondaryContainer), "the notice's fill");
        check(get(pageHeader, "editMenuKitBack").visible === crate
            && get(pageHeader, "editMenuKitAction").visible === crate, "the menu header's ways out are kit IconButtons");
    }

    Timer {
        id: crateCheck
        interval: 800
        onTriggered: {
            try {
                probe.verify(true);
                Tokens.controlsCrate = false;
                Tokens.accentMarks = false;
                Tokens.selectFill = true;
                probe.look = "stock";
                stockCheck.start();
            } catch (e) {
                console.log("STAGE-KIT-PROBE-FAIL " + e.message);
                Qt.quit();
            }
        }
    }
    Timer {
        id: stockCheck
        interval: 800
        onTriggered: {
            try {
                probe.verify(false);
                console.log("STAGE-KIT-PROBE-PASS");
            } catch (e) {
                console.log("STAGE-KIT-PROBE-FAIL " + e.message);
            }
            Qt.quit();
        }
    }
    Timer {
        interval: 300
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
