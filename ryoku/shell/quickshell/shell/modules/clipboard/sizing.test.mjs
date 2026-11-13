import assert from "node:assert/strict";
import test from "node:test";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const { sized } = require("./sizing.js");

test("an unset size takes the look's own", () => {
  assert.equal(sized(undefined, 65, 50, true), 50);
  assert.equal(sized(undefined, 65, 50, false), 65);
  assert.equal(sized(null, 12, 6, true), 6);
});

test("a stock value saved by the Hub reads as untouched under crate", () => {
  assert.equal(sized(65, 65, 50, true), 50);
  assert.equal(sized(9, 9, 6, true), 6);
  assert.equal(sized(65, 65, 50, false), 65);
});

test("a value the user changed wins in either look", () => {
  assert.equal(sized(80, 65, 50, true), 80);
  assert.equal(sized("70", 65, 50, false), 70);
  assert.equal(sized(0, 12, 6, true), 0);
});

test("garbage falls back to the look's own", () => {
  assert.equal(sized("wide", 65, 50, true), 50);
  assert.equal(sized("", 42, 40, false), 42);
});
