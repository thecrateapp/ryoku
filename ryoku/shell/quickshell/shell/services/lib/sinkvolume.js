// Device volume through WirePlumber. A volume written straight to a device
// node's Props (what Quickshell's PwNodeAudio does) is overwritten about 250 ms
// later by WirePlumber, which resyncs the node from the device route it saved:
// the slider jumps back to the old level and a boost past 100 % falls back to
// the route's 1.0. `wpctl set-volume` goes through WirePlumber's mixer, which
// updates the route itself, so the level holds. App streams have no route and
// keep the direct write.

var CEILING = 1.5;

// wpctl arguments that set node `id` to `v`, clamped to [0, limit] (and never
// past 150 %); null when there is nothing valid to write
function volumeArgs(id, v, limit) {
    if (id === undefined || id === null || id === "")
        return null;
    var value = Number(v);
    if (!isFinite(value))
        return null;
    var top = Math.min(CEILING, limit > 0 ? limit : CEILING);
    value = Math.max(0, Math.min(top, value));
    return ["set-volume", String(id), value.toFixed(3)];
}

// A drag sends many values while one wpctl call runs: keep only the newest and
// write it once the running call ends. Returns the write to start, or null.
function nextWrite(state) {
    if (!state || state.busy || !state.pending)
        return null;
    return state.pending;
}

if (typeof module !== "undefined" && module.exports)
    module.exports = { volumeArgs, nextWrite };
