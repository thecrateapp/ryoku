import assert from "node:assert/strict";
import test from "node:test";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const { span, fraction, markFraction, mainFraction, overFraction, valueAt, snap } = require("./beam.js");

const near = (a, b) => assert.ok(Math.abs(a - b) < 1e-9, `${a} != ${b}`);

test("without a limit the track spans from..to", () => {
  const r = { from: 0, to: 100, limit: 0 };
  assert.equal(span(r), 100);
  near(fraction(r, 25), 0.25);
  near(markFraction(r), 1);
});

test("the value is clamped to the track", () => {
  const r = { from: 0, to: 1, limit: 0 };
  assert.equal(fraction(r, -2), 0);
  assert.equal(fraction(r, 5), 1);
});

test("a limit above to extends the track and places the 100 % mark", () => {
  const r = { from: 0, to: 1, limit: 1.5 };
  near(markFraction(r), 1 / 1.5);
  near(mainFraction(r, 1.2), 1 / 1.5);
  near(overFraction(r, 1.2), 0.2 / 1.5);
  near(overFraction(r, 0.8), 0);
  near(fraction(r, 1.2), 1.2 / 1.5);
});

test("a press maps x to a value over the whole track, snapped to the step", () => {
  const r = { from: 0, to: 100, limit: 0, step: 5 };
  assert.equal(valueAt(r, 50, 200), 25);
  assert.equal(valueAt(r, 51, 200), 25);
  assert.equal(valueAt(r, -10, 200), 0);
  assert.equal(valueAt(r, 999, 200), 100);
  const boost = { from: 0, to: 1, limit: 1.5, step: 0 };
  near(valueAt(boost, 200, 200), 1.5);
});

test("a zero-width or empty track yields the start", () => {
  assert.equal(valueAt({ from: 3, to: 3, limit: 0 }, 10, 100), 3);
  assert.equal(valueAt({ from: 0, to: 1, limit: 0 }, 10, 0), 0);
  assert.equal(fraction({ from: 3, to: 3, limit: 0 }, 3), 0);
});

test("snap rounds to the step from the start and leaves a zero step alone", () => {
  assert.equal(snap(7.4, 0, 5), 5);
  assert.equal(snap(7.6, 0, 5), 10);
  near(snap(0.333, 0, 0), 0.333);
});

test("bounce runs to the far end at half a cycle and back, easing at both ends", () => {
  const { bounce } = require("./beam.js");
  near(bounce(0), 0);
  near(bounce(0.25), 0.5);
  near(bounce(0.5), 1);
  near(bounce(0.75), 0.5);
  near(bounce(1), 0);
  // eased: barely moving near the ends, fastest in the middle (ease-in-out sine legs)
  assert.ok(bounce(0.01) < 0.002);
  assert.ok(bounce(0.26) - bounce(0.24) > bounce(0.02) - bounce(0));
});

test("bounce stays inside 0..1 for any phase, including past one cycle", () => {
  for (let p = -2; p <= 3; p += 0.013) {
    const v = require("./beam.js").bounce(p);
    assert.ok(v >= 0 && v <= 1, `bounce(${p}) = ${v}`);
  }
});
