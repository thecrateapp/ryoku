pragma Singleton

import QtQuick
import shell.services
import Ryoku.Ui as Kit
import Ryoku.Ui.Singletons as Ui
import "../../../components"

// The Game Bar overlay follows Ryoku's rounding, type scale and
// matugen roles, so it tracks the wallpaper instead of a fixed palette.
// Under a theme style's controls "crate" every role, corner and face comes from
// the kit's Tokens instead: the strip and the cards are the shared glass with
// a hairline edge and the 6 px corner, and the controls drawn on them are the
// kit's own (see the Game Bar components).
QtObject {
    id: root

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    readonly property bool crate: Ui.Tokens.controlsCrate

    readonly property color bar: root.crate ? Ui.Tokens.glass : Theme.surfaceContainer
    readonly property color panel: root.crate ? Ui.Tokens.glass : Theme.surfaceContainerLow
    // under crate a card has one frame: no second plate inside it
    readonly property color content: root.crate ? "transparent" : Theme.surfaceContainer
    // a tint laid over imagery (the lyric view over the cover): the card's fill
    readonly property color wash: root.crate ? Ui.Tokens.popover : Theme.surfaceContainer
    readonly property color raised: root.crate ? Ui.Tokens.tint5 : Theme.surfaceContainerHigh
    readonly property color raisedHover: root.crate ? Ui.Tokens.tint10 : Theme.surfaceContainerHighest
    readonly property color border: root.crate ? Ui.Tokens.line : Theme.outlineVariant
    readonly property color fg: root.crate ? Ui.Tokens.ink : Theme.onSurface
    readonly property color onLayer: root.crate ? Ui.Tokens.inkSecondary : Theme.onSurfaceVariant
    readonly property color subtext: root.crate ? Ui.Tokens.inkSubtle : Theme.outline
    readonly property color toggled: root.crate ? Ui.Tokens.mark : Theme.secondaryContainer
    readonly property color toggledInk: root.crate ? Ui.Tokens.paper : Theme.onSecondaryContainer
    readonly property color accent: root.crate ? Ui.Tokens.sun : Theme.primary
    readonly property color accentInk: root.crate ? Ui.Tokens.paper : Theme.onPrimary
    readonly property color danger: root.crate ? Ui.Tokens.alert : Theme.error
    readonly property color onDanger: root.crate ? Ui.Tokens.paper : Theme.onError
    // a second series in a reading (GPU next to CPU)
    readonly property color second: root.crate ? Ui.Tokens.sunHi : Theme.tertiary

    readonly property color hover: root.crate ? Ui.Tokens.tint5 : root.alpha(Theme.onSurface, 0.06)

    // Hub -> Game Bar -> Corner rounding owns the base; the smaller radii keep
    // their distance from it so the strip, frame and chips stay in proportion.
    // Under crate every corner is the shared one.
    readonly property int radiusWindow: root.crate ? Ui.Tokens.radius : Config.gamebar.radius
    readonly property int radiusVeryLarge: root.crate ? Ui.Tokens.radius : Config.gamebar.radius + 8
    readonly property int radiusNormal: root.crate ? Ui.Tokens.radius : Config.gamebar.radius + 3
    readonly property int radiusSmall: root.crate ? Ui.Tokens.radius : Math.max(0, Config.gamebar.radius - 2)
    readonly property int radiusVerySmall: root.crate ? Ui.Tokens.radius : Math.max(0, Config.gamebar.radius - 6)

    // The overlay's type scale, multiplied by the bar's own scale. Under crate
    // it is crate-mark's: 11 px labels, 12 px values, 13 px body.
    readonly property int smallest: root.crate ? 11 : 10
    readonly property int smaller: 12
    readonly property int smallie: root.crate ? 12 : 13
    readonly property int small: root.crate ? 13 : 15
    readonly property int huge: 22
    readonly property int battery: root.crate ? 13 : 18
    readonly property int initial: 17
    readonly property int symbol: 20
    readonly property int stripSymbol: 21

    readonly property string face: root.crate ? Ui.Tokens.ui : Theme.fontPrimary
    // readings (the clock, levels, counts): the mono face under crate
    readonly property string numeric: root.crate ? Ui.Tokens.mono : Theme.fontPrimary

    // The overlay's icon names, as the kit's Solar catalogue names them. Only
    // Discord's mark (a brand) keeps the Game Bar's own icon under crate.
    readonly property var solarNames: ({
        "pin": "pin",
        "close": "close",
        "mic": "mic",
        "mic-off": "mic_off",
        "headphones": "headphones",
        "music": "music_note",
        "play": "play",
        "cpu": "cpu",
        "archive": "memory-stick",
        "monitor": "monitor",
        "music_note": "music_note",
        "volume_up": "volume_up",
        "skip_previous": "skip_previous",
        "skip_next": "skip_next",
        "play_arrow": "play_arrow",
        "pause": "pause",
        "screenshot_region": "crop-minimalistic",
        "region": "crop-minimalistic",
        "window": "window-frame",
        "screens": "full-screen",
        "speed": "speedometer-middle",
        "monitoring": "graph-up",
        "checklist": "checklist-minimalistic",
        "photo_library": "gallery",
        "grid_view": "widget-2",
        "lyrics": "playlist-minimalistic",
        "headset_mic": "headphones-round-sound",
        "headphones-off": "headphones-round-off",
        "grip": "menu-dots-vertical"
    })

    function solar(name) {
        const key = root.solarNames[name] || "";
        return key.length > 0 && Kit.GlyphCatalog.has(key) ? key : "";
    }

    // The Game Bar's own line icons, for a kit IconButton's path where Solar has
    // no glyph (the 24-unit paths GlyphIcon strokes).
    readonly property GlyphIcon lines: GlyphIcon {}

    function linePath(name) {
        const g = root.lines.glyphs[name];
        return g && !g.fill ? g.d : "";
    }

    // a line icon drawn solid (Discord's mark): a kit IconButton strokes its
    // path, so the button carries it as a GlyphIcon in its ink instead
    function lineFilled(name) {
        const g = root.lines.glyphs[name];
        return !!g && g.fill === true;
    }

    // the battery glyph for a charge, from the catalogue
    function batteryGlyph(pct, charging) {
        if (charging)
            return "battery-charge";
        return pct >= 70 ? "battery-full" : pct >= 30 ? "battery-half" : "battery-low";
    }
}
