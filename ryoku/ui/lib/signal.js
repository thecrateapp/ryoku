// Signal strength (0..100) to the number of lit bars (0..4), with the thresholds
// the Wi-Fi page has always used, so the kit's SignalBars and a node test agree.

function bars(strength) {
    var v = Number(strength);
    if (!isFinite(v) || v <= 0)
        return 0;
    if (v > 75) return 4;
    if (v > 50) return 3;
    if (v > 25) return 2;
    return 1;
}

if (typeof module !== "undefined" && module.exports)
    module.exports = { bars };
