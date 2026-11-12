// Beam maths: the crate-mark slider and progress track, framework-free so the kit's
// Beam and a node test derive the same numbers. A range is { from, to, limit, step }:
// `to` is the 100 % mark; a `limit` above `to` extends the track past it (volume
// boost), and the part of the value beyond `to` is the over segment.

function top(r) {
    return r.limit > r.to ? r.limit : r.to;
}

function span(r) {
    return top(r) - r.from;
}

function clamp(v, a, b) {
    return Math.max(a, Math.min(b, v));
}

// where a value sits on the whole track, 0..1
function fraction(r, v) {
    var s = span(r);
    if (!(s > 0))
        return 0;
    return (clamp(v, r.from, top(r)) - r.from) / s;
}

// where the 100 % mark sits; 1 when there is no limit
function markFraction(r) {
    var s = span(r);
    return s > 0 ? (r.to - r.from) / s : 1;
}

// the filled part up to the mark, and the over segment beyond it
function mainFraction(r, v) {
    return fraction(r, Math.min(v, r.to));
}

function overFraction(r, v) {
    var s = span(r);
    if (!(s > 0) || !(v > r.to))
        return 0;
    return (Math.min(v, top(r)) - r.to) / s;
}

function snap(v, from, step) {
    if (!(step > 0))
        return v;
    return from + Math.round((v - from) / step) * step;
}

// the value under x on a track `width` wide
function valueAt(r, x, width) {
    var s = span(r);
    if (!(s > 0) || !(width > 0))
        return r.from;
    var v = r.from + clamp(x / width, 0, 1) * s;
    return clamp(snap(v, r.from, r.step || 0), r.from, top(r));
}

if (typeof module !== "undefined" && module.exports)
    module.exports = { span, fraction, markFraction, mainFraction, overFraction, valueAt, snap };
