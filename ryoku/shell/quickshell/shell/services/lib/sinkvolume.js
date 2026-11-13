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

// Past 100 % a device route is capped at 1.0 (the SOF speaker route clamps
// anything above back within ~200 ms), so the route stays at 100 % and the rest
// rides the node's master Props volume, a linear gain the route resync leaves
// alone. The UI scale is cubic like wpctl's, so the master is v cubed.
function volumePlan(v, limit) {
    var value = Number(v);
    if (!isFinite(value))
        return null;
    var top = Math.min(CEILING, limit > 0 ? limit : CEILING);
    value = Math.max(0, Math.min(top, value));
    var route = Math.min(1, value);
    var master = value > 1 ? value * value * value : 1;
    return { route: route.toFixed(3), master: master.toFixed(4) };
}

// One sh -c line for a write. `boost` is the factor already riding the master
// (1 when none). The master goes first and only when it changes: a master write
// makes WirePlumber resync the node from the saved route, which would undo a
// route written just before it. The id must be a plain number, since it lands
// in a shell line.
function volumeCommand(id, v, limit, boost) {
    if (!/^[0-9]+$/.test(String(id)))
        return null;
    var plan = volumePlan(v, limit);
    if (!plan)
        return null;
    var b = boost > 0 ? boost : 1;
    var route = "wpctl set-volume " + id + " " + plan.route;
    if (plan.master === (b * b * b).toFixed(4))
        return ["sh", "-c", route];
    return ["sh", "-c", "pw-cli set-param " + id + " Props '{ volume: " + plan.master + " }' >/dev/null && sleep 0.15 && " + route];
}

// A drag sends many values while one wpctl call runs: keep only the newest and
// write it once the running call ends. Returns the write to start, or null.
function nextWrite(state) {
    if (!state || state.busy || !state.pending)
        return null;
    return state.pending;
}

if (typeof module !== "undefined" && module.exports)
    module.exports = { volumeArgs, nextWrite, volumePlan, volumeCommand };
