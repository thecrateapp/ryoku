// Row geometry for the kit's MeterRow and LevelRow: the crate-mark mock-up's
// columns (an 18 px icon, a 72 px caption, the Beam, a 40 px value, a 28 px
// chevron, 12 px apart), framework-free so the rows and a node test agree.
// Each column is { x, w }; an absent column has w 0 and takes no gap. A group of
// rows passes `labelWidth` (never below 72, never over 35 % of the row) so every
// row's beam starts together.

var ROW = { meter: 28, level: 28 };
var COL = { icon: 18, label: 72, value: 40, chevron: 28, gap: 12, name: 64, mute: 28 };

function labelWidth(o, s, width) {
    var asked = o && o.labelWidth > 0 ? Math.min(o.labelWidth, width * 0.35) : 0;
    return Math.max(COL.label * s, asked);
}

function levelColumns(width, o) {
    var s = (o && o.s) || 1;
    var gap = COL.gap * s;
    var iconW = o && o.icon ? COL.icon * s : 0;
    var chevW = o && o.chevron ? COL.chevron * s : 0;
    var labelW = labelWidth(o, s, width);
    var valueW = COL.value * s;
    var labelX = iconW > 0 ? iconW + gap : 0;
    var beamX = labelX + labelW + gap;
    var chevX = width - chevW;
    var valueX = chevX - (chevW > 0 ? gap : 0) - valueW;
    return {
        icon: { x: 0, w: iconW },
        label: { x: labelX, w: labelW },
        beam: { x: beamX, w: Math.max(0, valueX - gap - beamX) },
        value: { x: valueX, w: valueW },
        chevron: { x: chevX, w: chevW }
    };
}

function meterColumns(width, valueWidth, o) {
    var s = (o && o.s) || 1;
    var gap = COL.gap * s;
    var labelW = labelWidth(o, s, width);
    var valueW = Math.min(Math.max(0, valueWidth), width / 2);
    var valueX = width - valueW;
    var beamX = labelW + gap;
    return {
        label: { x: 0, w: labelW },
        beam: { x: beamX, w: Math.max(0, valueX - gap - beamX) },
        value: { x: valueX, w: valueW }
    };
}

// a stream (an app in the mixer): its name, the beam, and a mute button. A group
// passes `nameWidth` (its longest name) so the beams line up; it never drops
// below 64 px nor takes more than 35 % of the row.
function streamColumns(width, o) {
    var s = (o && o.s) || 1;
    var gap = COL.gap * s;
    var asked = o && o.nameWidth > 0 ? Math.min(o.nameWidth, width * 0.35) : 0;
    var nameW = Math.max(COL.name * s, asked);
    var muteW = COL.mute * s;
    var beamX = nameW + gap;
    var muteX = width - muteW;
    return {
        name: { x: 0, w: nameW },
        beam: { x: beamX, w: Math.max(0, muteX - gap - beamX) },
        mute: { x: muteX, w: muteW }
    };
}

if (typeof module !== "undefined" && module.exports)
    module.exports = { levelColumns, meterColumns, streamColumns, ROW, COL };
