import { createRequire } from "node:module";
const require = createRequire(import.meta.url);
const { volumeArgs, nextWrite } = require("./sinkvolume.js");

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

// coalescing: a drag sends many values while wpctl runs; only the newest is
// written next, and nothing is written twice
eq(nextWrite({ busy: false, pending: null }), null, "idle with nothing pending writes nothing");
eq(nextWrite({ busy: true, pending: { id: 1, v: 0.4 } }), null, "a running write is never overlapped");
eq(nextWrite({ busy: false, pending: { id: 1, v: 0.4 } }), { id: 1, v: 0.4 }, "the newest pending value is written");

if (failed) {
    console.log(failed + " failed");
    process.exit(1);
}
