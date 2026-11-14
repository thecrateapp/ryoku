import QtQuick
import QtQuick.Layouts
import Quickshell
import Ryoku.Ui
import Ryoku.Ui.Singletons
import stage
import stage.services
import stage.modules.common
import stage.modules.common.widgets
import stage.modules.ii.editMode
import stage.modules.ii.background.widgets
import stage.modules.common.draw

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

        // The wallpaper framing controls over a stand-in screen.
        EditWallpaperFramingOverlay {
            id: framing
            x: 1110
            y: 0
            width: 420
            height: 300
            screenName: "probe"
        }

        // The sketch editor's draw tray and one of its tools (the note pane
        // itself reads the notes store, which an isolated session has none of).
        DrawToolButton {
            id: drawTool
            x: 600
            y: 640
            symbol: "undo"
        }
        DrawToolbar {
            id: drawTray
            x: 320
            y: 640
            palette: ["#111111", "#e2342a"]
            currentColor: "#111111"
            strokeWidth: 4
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

        // A widget's own edit chrome and the shared card. A whole widget
        // reads the window manager's workspaces, which needs a compositor, so
        // the probe loads the Items it draws them with.
        Item {
            id: cardWidget
            x: 1110
            y: 720
            width: 200
            height: 120

            WidgetCard {
                anchors.fill: parent
                radius: Tokens.controlsCrate ? Tokens.radius : Appearance.rounding.large
                color: WidgetColorScheme.cardBgColor
            }
            WidgetSelectionHalo {
                anchors.fill: parent
                anchors.margins: -8
            }
            WidgetSizeReadout {
                y: -30
                text: "120%"
            }
            WidgetEditGrip {
                objectName: "widgetResizeGrip"
                x: 170
                y: 90
                symbol: "open_in_full"
            }
            WidgetEditGrip {
                objectName: "widgetMenuGrip"
                x: 170
                y: 8
                symbol: "more_horiz"
                symbolSize: 15
            }
            WidgetButton {
                id: widgetButton
                x: 20
                y: 20
                width: 80
                height: 40
                symbol: "play_arrow"
                label: "Go"
            }
        }

        MissingWidgetPlaceholder {
            id: placeholder
            widgetId: "ext:clock"
            widgetX: 1350
            widgetY: 720
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
            Row {
                spacing: 8
                EditAddBadge { id: addBadge }
                EditRemoveBadge { id: removeBadge }
            }
            EditDockDesignPicker {
                id: designPicker
                Layout.fillWidth: true
                currentValue: "ryoku"
            }
            ColorPreviewButton {
                id: schemeCard
                Layout.preferredWidth: 120
                colorScheme: MaterialThemeLoader.schemeType
            }
            EditAlignBar {
                id: alignBar
                count: 3
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
        check(same(addBadge.color, crate ? Tokens.mark : Appearance.colors.colPrimary)
            && same(removeBadge.color, crate ? Tokens.alert : Appearance.m3colors.m3error)
            && addBadge.radius === (crate ? Tokens.radius : 8), "the add and remove badges");
        // the wallpaper framing coach and control plate: opaque popover plates
        for (const name of ["framingCoach", "framingDock"]) {
            const plate = get(framing, name);
            check(same(plate.color, crate ? Tokens.popover : Tokens.paper), name + "'s fill");
        }
        check(get(framing, "framingDock").radius === (crate ? Tokens.radius : Tokens.radius * 2), "the framing plate's corner");
        // the sketch tray
        const tray = get(drawTray, "drawTray");
        check(same(tray.color, crate ? Tokens.popover : Appearance.m3colors.m3surfaceContainer)
            && tray.border.width === (crate ? Tokens.border : 0), "the draw tray's plate");
        check(get(drawTray, "drawWidthBeam").visible === crate, "the thickness is the kit Beam under crate");
        check(get(drawTool, "drawToolGlyph").visible === crate, "a draw tool's icon is a Solar Glyph under crate");
        check(same(drawTool.colBackground, crate ? "transparent" : Appearance.m3colors.m3surfaceContainerHigh),
            "a draw tool has no plate under crate");
        // the dock design cards and the selection's align strip
        const chosen = get(designPicker, "dockDesign-ryoku");
        const other = get(designPicker, "dockDesign-python");
        check(same(chosen.color, crate ? Tokens.pickFill : Appearance.colors.colSecondaryContainer)
            && same(chosen.border.color, crate ? Tokens.pickEdge : Appearance.colors.colSecondary)
            && same(other.border.color, crate ? Tokens.line : Appearance.colors.colOutlineVariant),
            "the dock design cards");
        check(schemeCard.toggled === true, "the scheme card for the live scheme is chosen");
        check(same(schemeCard.colBackground, crate ? Tokens.pickFill : Tokens.bone)
            && same(schemeCard.borderColor, crate ? Tokens.pickEdge : Tokens.bone), "the chosen colour scheme card");
        const strip = get(alignBar, "alignBarPlate");
        check(same(strip.colBackground, crate ? Tokens.popover : Appearance.colors.colLayer0)
            && same(strip.borderColor, crate ? Tokens.line : Appearance.colors.colOutline), "the align strip's plate");
        check(get(alignBar, "alignKit-left").visible === crate, "the align buttons are kit IconButtons under crate");
        check(get(pageHeader, "editMenuKitBack").visible === crate
            && get(pageHeader, "editMenuKitAction").visible === crate, "the menu header's ways out are kit IconButtons");
    }

    function verifyWidgets(crate) {
        // the shared card: content on the desktop, the scheme's fill kept
        const card = get(cardWidget, "widgetCard");
        check(card.border.width === (crate ? Tokens.border : 0)
            && (!crate || same(card.border.color, Tokens.line)), "the card's hairline under crate only");
        // the edit chrome every widget carries
        const halo = get(cardWidget, "widgetSelectionHalo");
        check(same(halo.color, crate ? Tokens.pickFill : Qt.alpha(Appearance.colors.colPrimary, 0.08))
            && same(halo.border.color, crate ? Tokens.pickEdge : Appearance.colors.colPrimary)
            && halo.border.width === (crate ? Tokens.border : 2), "the selection halo");
        for (const name of ["widgetResizeGrip", "widgetMenuGrip"]) {
            const grip = get(cardWidget, name);
            check(same(grip.color, crate ? Tokens.popover : Appearance.colors.colSecondaryContainer)
                && grip.border.width === (crate ? Tokens.border : 0)
                && grip.radius === (crate ? Tokens.radius : 7), name + " is a popover knob under crate");
            check(get(grip, "widgetGripGlyph").visible === crate, name + "'s glyph is the kit's under crate");
        }
        const readout = get(cardWidget, "widgetResizeReadout");
        check(same(readout.color, crate ? Tokens.popover : Appearance.colors.colPrimary)
            && readout.radius === (crate ? Tokens.radius : Appearance.rounding.full), "the size readout");
        check(get(widgetButton, "widgetButtonGlyph").visible === crate, "a widget button's symbol is a Glyph under crate");
        check(same(placeholder.color, crate ? Tokens.glass : Qt.rgba(0, 0, 0, 0.55))
            && same(placeholder.warnInk, crate ? Tokens.alert : "#ffaaaa"), "the missing-widget placeholder");
    }

    // The widget faces migrated family by family: a whole widget cannot be
    // created without a compositor, so each is compiled (its imports, types
    // and bindings resolved) rather than instantiated.
    readonly property var faces: [
        "clock/CirclePointerClockWidget.qml", "clock/ConcentricClockWidget.qml",
        "clock/MonthClockWidget.qml", "clock/NothingDigitalClockWidget.qml",
        "clock/NothingWheelClockWidget.qml", "clock/ScallopDotClockWidget.qml",
        "clock/ScallopNumberClockWidget.qml", "clock/TripleRingClockWidget.qml",
        "clock/WearOSArcClock.qml", "clock/WearOSClockWidget.qml",
        "media/AndroidMediaWidget.qml", "media/CircularMediaWidget.qml", "media/CompactMediaWidget.qml",
        "media/PosterMediaWidget.qml", "media/DeckMediaWidget.qml",
        "bluetooth/DevicesBatteryList1x1Widget.qml", "bluetooth/DevicesBatteryListWidget.qml",
        "bluetooth/BluetoothFillCardsWidget.qml",
        "utility/CpuPillWidget.qml", "utility/DiskPillWidget.qml", "utility/RamPillWidget.qml",
        "utility/ResourceFillCardsWidget.qml", "utility/ResourceColumnsWidget.qml",
        // the catalogue panel itself (its plate and header are loaded above)
        // and the pages that read the dock or the window manager
        "../../editMode/EditModeDrawer.qml", "../../editMode/EditWallpaperRootPage.qml",
        "../../editMode/EditWallpaperScreenMap.qml", "../../editMode/EditWallpaperFramingOverlay.qml",
        "../../editMode/EditWallpaperPage.qml", "../../editMode/EditStylePresets.qml",
        "../../overlay/notes/NotesContent.qml", "../../overlay/notes/NotesSketchEditor.qml"
    ]
    // A player that can seek, for the media seek line.
    QtObject {
        id: fakePlayer
        property var player: ({ "canSeek": true })
        property color colAccent: Tokens.sun
        property color colTrack: Tokens.line
        property bool animate: false
        property bool isPlaying: true
        property bool hasLength: true
        property string positionText: "1:20"
        property real progress: 0.4
        property real sought: -1
        function seek(v) { fakePlayer.sought = v; }
    }
    function verifySeek(crate) {
        const base = "file://" + Quickshell.env("STAGE_WIDGETS") + "/";
        const component = Qt.createComponent(base + "media/MediaSeekBar.qml", Component.PreferSynchronous);
        check(component.status === Component.Ready, "the seek line compiles: " + component.errorString());
        const bar = component.createObject(cardWidget, { "source": fakePlayer, "width": 180 });
        check(bar !== null, "the seek line loads");
        const beam = get(bar, "mediaSeekBeam");
        check(beam.visible === crate, "the seek line is the kit Beam only under crate");
        if (crate) {
            check(beam.interactive === true && Math.abs(beam.value - 0.4) < 1e-6, "the Beam follows the track and seeks");
            beam.moved(0.7);
            check(Math.abs(fakePlayer.sought - 0.7) < 1e-6, "a Beam drag seeks the player");
        }
        bar.destroy();
    }
    // Every icon the catalogue, the widget menus and the bar menus name has a
    // Solar glyph under crate: none falls back to the font.
    function verifyIcons() {
        const missing = [];
        for (const w of WidgetsRegistry.builtinWidgets)
            if (w.icon && !GlyphCatalog.has(w.icon)) missing.push(w.icon);
        for (const c of BarComponentRegistry.allComponents)
            if (c.icon && !GlyphCatalog.has(c.icon)) missing.push(c.icon);
        check(missing.length === 0, "icons without a Solar glyph: " + Array.from(new Set(missing)).join(" "));
    }

    function verifyFaces() {
        const base = "file://" + Quickshell.env("STAGE_WIDGETS") + "/";
        for (const face of probe.faces) {
            const component = Qt.createComponent(base + face, Component.PreferSynchronous);
            check(component.status === Component.Ready, face + " compiles: " + component.errorString());
        }
    }

    Timer {
        id: crateCheck
        interval: 800
        onTriggered: {
            try {
                probe.verify(true);
                probe.verifyWidgets(true);
                probe.verifySeek(true);
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
                probe.verifyWidgets(false);
                probe.verifySeek(false);
                probe.verifyFaces();
                probe.verifyIcons();
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
