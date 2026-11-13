import assert from "node:assert/strict";
import test from "node:test";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const { bars } = require("./signal.js");

test("signal strength maps to the four bars the shell has always shown", () => {
  assert.equal(bars(100), 4);
  assert.equal(bars(76), 4);
  assert.equal(bars(75), 3);
  assert.equal(bars(51), 3);
  assert.equal(bars(50), 2);
  assert.equal(bars(26), 2);
  assert.equal(bars(25), 1);
  assert.equal(bars(1), 1);
  assert.equal(bars(0), 0);
});

test("a missing or malformed strength reads as no signal", () => {
  assert.equal(bars(undefined), 0);
  assert.equal(bars(null), 0);
  assert.equal(bars("x"), 0);
  assert.equal(bars(-5), 0);
  assert.equal(bars("80"), 4);
});
