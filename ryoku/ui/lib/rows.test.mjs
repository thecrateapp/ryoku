import assert from "node:assert/strict";
import test from "node:test";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const { levelColumns, meterColumns, ROW } = require("./rows.js");

test("a level row lays out icon, caption, beam, value and chevron with 12 px gaps", () => {
  const c = levelColumns(656, { icon: true, chevron: true });
  assert.deepEqual(c.icon, { x: 0, w: 18 });
  assert.deepEqual(c.label, { x: 30, w: 72 });
  assert.deepEqual(c.beam, { x: 114, w: 656 - 114 - 12 - 40 - 12 - 28 });
  assert.deepEqual(c.value, { x: 656 - 28 - 12 - 40, w: 40 });
  assert.deepEqual(c.chevron, { x: 656 - 28, w: 28 });
});

test("a level row without icon or chevron gives their room to the beam", () => {
  const c = levelColumns(400, { icon: false, chevron: false });
  assert.equal(c.icon.w, 0);
  assert.equal(c.label.x, 0);
  assert.equal(c.beam.x, 84);
  assert.equal(c.chevron.w, 0);
  assert.equal(c.value.x + c.value.w, 400);
  assert.equal(c.beam.x + c.beam.w + 12, c.value.x);
});

test("columns scale with s", () => {
  const c = levelColumns(1312, { icon: true, chevron: true, s: 2 });
  assert.deepEqual(c.icon, { x: 0, w: 36 });
  assert.deepEqual(c.label, { x: 60, w: 144 });
  assert.equal(c.chevron.w, 56);
});

test("the beam never goes negative on a narrow row", () => {
  const c = levelColumns(100, { icon: true, chevron: true });
  assert.equal(c.beam.w, 0);
});

test("a meter row sizes the value to its text, capped at half the row", () => {
  const c = meterColumns(656, 140);
  assert.deepEqual(c.label, { x: 0, w: 72 });
  assert.deepEqual(c.value, { x: 656 - 140, w: 140 });
  assert.deepEqual(c.beam, { x: 84, w: 656 - 140 - 12 - 84 });
  assert.equal(meterColumns(400, 390).value.w, 200);
});

test("row heights follow the mock-up", () => {
  assert.equal(ROW.meter, 28);
  assert.equal(ROW.level, 28);
});

test("a group can widen the caption column so every row's beam starts together", () => {
  const level = levelColumns(656, { icon: true, chevron: true, labelWidth: 84 });
  assert.deepEqual(level.label, { x: 30, w: 84 });
  assert.equal(level.beam.x, 126);
  const meter = meterColumns(656, 100, { labelWidth: 84 });
  assert.equal(meter.beam.x, 96);
  assert.equal(levelColumns(656, { labelWidth: 40 }).label.w, 72);
});

test("a stream row lays out a 64 px name, the beam and a 28 px mute button", () => {
  const { streamColumns } = require("./rows.js");
  const c = streamColumns(300);
  assert.deepEqual(c.name, { x: 0, w: 64 });
  assert.deepEqual(c.beam, { x: 76, w: 300 - 76 - 12 - 28 });
  assert.deepEqual(c.mute, { x: 272, w: 28 });
  assert.equal(streamColumns(600, { s: 2 }).name.w, 128);
  assert.equal(streamColumns(60).beam.w, 0);
});

test("a group of streams can widen the name column, up to 35 % of the row", () => {
  const { streamColumns } = require("./rows.js");
  assert.equal(streamColumns(600, { nameWidth: 120 }).name.w, 120);
  assert.equal(streamColumns(600, { nameWidth: 400 }).name.w, 210);
  assert.equal(streamColumns(600, { nameWidth: 20 }).name.w, 64);
  assert.equal(streamColumns(600, { nameWidth: 120 }).beam.x, 132);
});
