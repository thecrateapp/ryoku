import assert from "node:assert/strict";
import test from "node:test";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const { resolve, has, svg, dataUri, ICONS, ALIAS } = require("./glyphs.js");

test("a Material name resolves to its catalogue glyph", () => {
  assert.equal(resolve("volume_up"), "volume-loud");
  assert.equal(resolve("expand_more"), "alt-arrow-down");
  assert.equal(resolve("volume-loud"), "volume-loud");
  assert.equal(resolve("no_such_glyph"), "");
  assert.equal(has("lock"), true);
  assert.equal(has("lan"), false);
});

test("every alias points at a glyph that exists", () => {
  for (const [from, to] of Object.entries(ALIAS))
    assert.ok(ICONS[to], `${from} -> ${to} is missing`);
});

test("the Controls panel's glyphs are all covered", () => {
  const used = ["lock", "dark_mode", "logout", "restart_alt", "power_settings_new", "bedtime",
    "light_mode", "coffee", "notifications_off", "mic", "mic_off", "sports_esports", "settings",
    "arrow_back", "extension", "tune", "close", "vpn_lock", "wifi", "wifi_off", "bluetooth",
    "bluetooth_disabled", "expand_more", "volume_up", "volume_down", "volume_mute", "volume_off",
    "brightness_low", "brightness_medium", "brightness_high"];
  for (const name of used)
    assert.ok(has(name), `${name} has no glyph`);
});

test("svg paints Solar's Outline glyph, filled, in the asked colour", () => {
  const out = svg("lock", "#67e8f9");
  assert.ok(out.startsWith("<svg "));
  assert.ok(out.includes('fill="#67e8f9"'));
  assert.ok(!out.includes('opacity="0.5"'), "Outline has no faded secondary layer");
  assert.ok(!out.includes("currentColor"));
  assert.ok(!out.includes("var(--"));
  assert.ok(!out.includes("class="));
});

test("svg refuses an unknown glyph or a colour that is not a hex", () => {
  assert.equal(svg("no_such_glyph", "#ffffff"), "");
  assert.equal(svg("lock", "red"), "");
  assert.equal(svg("lock", "#fff\"/><script"), "");
});

test("an off glyph is its on glyph struck through", () => {
  assert.ok(svg("mic_off", "#ffffff").includes('d="M3 3L21 21"'));
  assert.ok(!svg("mic", "#ffffff").includes('d="M3 3L21 21"'));
});

test("dataUri is an encoded SVG data URL an Image can load", () => {
  const uri = dataUri("sun", "#abe2ee");
  assert.ok(uri.startsWith("data:image/svg+xml;utf8,"));
  assert.ok(!uri.includes("#"));
  assert.ok(decodeURIComponent(uri.slice(24)).includes('fill="#abe2ee"'));
  assert.equal(dataUri("no_such_glyph", "#abe2ee"), "");
});

test("a colour with alpha (#aarrggbb, as QML writes it) becomes an opaque stroke and an svg opacity", () => {
  const out = svg("lock", "#80ff8800");
  assert.ok(out.includes('fill="#ff8800"'), out.slice(0, 200));
  assert.ok(!out.includes("#80ff8800"));
  assert.ok(/^<svg [^>]*opacity="0\.502"/.test(out));
  assert.ok(!/^<svg [^>]*opacity=/.test(svg("lock", "#ff8800")));
});


test("the freedesktop icon names the OSD emits resolve too", () => {
  assert.equal(resolve("audio-volume-high"), "volume-loud");
  assert.equal(resolve("audio-volume-medium"), "volume");
  assert.equal(resolve("audio-volume-low"), "volume-small");
  assert.equal(resolve("audio-volume-muted"), "volume-cross");
  assert.equal(resolve("microphone-sensitivity-high"), "microphone-2");
  assert.equal(resolve("microphone-sensitivity-muted"), "microphone-2-off");
  assert.equal(resolve("brightness-low"), "sun");
  assert.equal(resolve("input-keyboard"), "keyboard");
});

test("the memory module and drives render distinct glyphs in the widget foreground", () => {
  const names = ["memory-stick", "ssd-square", "ssd-round"];
  const glyphs = names.map(name => svg(name, "#19aacc"));
  for (const glyph of glyphs) {
    assert.ok(glyph.includes("#19aacc"));
    assert.ok(!glyph.includes("currentColor"));
  }
  assert.equal(new Set(glyphs).size, names.length);
  assert.notEqual(glyphs[0], svg("memory", "#19aacc"));
});

test("the freedesktop device icons Bluetooth reports resolve", () => {
  assert.equal(resolve("audio-headphones"), "headphones-round");
  assert.equal(resolve("audio-headset"), "headphones-round");
  assert.equal(resolve("audio-card"), "speaker");
  assert.equal(resolve("input-mouse"), "mouse-minimalistic");
  assert.equal(resolve("input-gaming"), "gamepad");
  assert.equal(resolve("phone"), "smartphone");
  assert.equal(resolve("bluetooth_connected"), "bluetooth-wave");
});

test("every weather symbol the shell draws has a Solar glyph", () => {
  const wx = require("../../shell/quickshell/shell/services/lib/weather.js");
  // every WMO code Open-Meteo reports, by day and by night
  const codes = [0, 1, 2, 3, 45, 48, 51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 71, 73, 75, 77, 80, 81, 82, 85, 86, 95, 96, 99];
  for (const code of codes)
    for (const day of [true, false]) {
      const name = wx.symbolFor(code, day);
      assert.ok(has(name), `code ${code} (${day ? "day" : "night"}) draws ${name}, which has no glyph`);
    }
  for (const name of ["humidity_percentage", "thermostat", "air"])
    assert.ok(has(name), `${name} has no glyph`);
});
