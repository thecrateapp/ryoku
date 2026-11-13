import { createRequire } from "node:module";
const require = createRequire(import.meta.url);
const { volumeArgs, nextWrite, volumePlan, volumeCommand } = require("./sinkvolume.js");

let failed = 0;
function eq(actual, expected, message) {
    const a = JSON.stringify(actual), e = JSON.stringify(expected);
    if (a === e) console.log("PASS " + message);
    else { failed++; console.log("FAIL " + message + "\n  expected " + e + "\n  got      " + a); }
}

eq(volumeArgs(106, 0.5, 1), ["set-volume", "106", "0.500"],
    "a device volume goes to wpctl by node id, three decimals");
eq(volumeArgs(106, 1.4, 1.5), ["set-volume", "106", "1.400"],
    "boost lets a device pass 100 %");
eq(volumeArgs(106, 1.4, 1), ["set-volume", "106", "1.000"],
    "without boost the 100 % cap holds");
eq(volumeArgs(106, -0.2, 1), ["set-volume", "106", "0.000"],
    "a negative volume is silence");
eq(volumeArgs(106, 0.5), ["set-volume", "106", "0.500"],
    "no limit means the 150 % ceiling");
eq(volumeArgs(106, 2, undefined), ["set-volume", "106", "1.500"],
    "nothing ever passes 150 %");
eq(volumeArgs(undefined, 0.5, 1), null, "no node, no write");
eq(volumeArgs(106, NaN, 1), null, "a non-number is not written");

// boost past 100 %: the device route stops at 1.0, so the rest rides the
// node's master volume as a linear gain (the cube of the cubic UI scale)
eq(volumePlan(0.5, 1.5), { route: "0.500", master: "1.0000" }, "under 100 % the route carries it all, master back to unity");
eq(volumePlan(1, 1.5), { route: "1.000", master: "1.0000" }, "exactly 100 % is unity master");
eq(volumePlan(1.2, 1.5), { route: "1.000", master: "1.7280" }, "120 % keeps the route at 100 % and adds 1.2 cubed");
eq(volumePlan(1.5, 1.5), { route: "1.000", master: "3.3750" }, "150 % is +10.6 dB of master");
eq(volumePlan(1.4, 1), { route: "1.000", master: "1.0000" }, "without boost nothing passes 100 %");
eq(volumePlan(NaN, 1.5), null, "a non-number plans nothing");
// the master goes first: a master write makes WirePlumber resync the node from
// the saved route, which would undo a route written just before it
eq(volumeCommand(106, 1.2, 1.5, 1), ["sh", "-c", "pw-cli set-param 106 Props '{ volume: 1.7280 }' >/dev/null && sleep 0.15 && wpctl set-volume 106 1.000"],
    "a boost writes the master, then the route");
eq(volumeCommand(106, 0.5, 1, 1), ["sh", "-c", "wpctl set-volume 106 0.500"],
    "an unchanged master is not rewritten, so a drag stays one wpctl call");
eq(volumeCommand(106, 0.5, 1, 1.2), ["sh", "-c", "pw-cli set-param 106 Props '{ volume: 1.0000 }' >/dev/null && sleep 0.15 && wpctl set-volume 106 0.500"],
    "leaving a boost puts the master back to unity first");
eq(volumeCommand(106, 1.2, 1.5, 1.2), ["sh", "-c", "wpctl set-volume 106 1.000"],
    "the same boost again only touches the route");
eq(volumeCommand("106; rm -rf /", 0.5, 1, 1), null, "only a numeric id reaches the shell line");

// coalescing: a drag sends many values while wpctl runs; only the newest is
// written next, and nothing is written twice
eq(nextWrite({ busy: false, pending: null }), null, "idle with nothing pending writes nothing");
eq(nextWrite({ busy: true, pending: { id: 1, v: 0.4 } }), null, "a running write is never overlapped");
eq(nextWrite({ busy: false, pending: { id: 1, v: 0.4 } }), { id: 1, v: 0.4 }, "the newest pending value is written");

if (failed) {
    console.log(failed + " failed");
    process.exit(1);
}
