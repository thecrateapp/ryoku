// Writes ../lib/glyphs.js, the kit's glyph catalogue, from solar-kit.json plus a
// few glyphs Solar does not draw. Re-run after changing either:
//   node ryoku/ui/tools/build-glyphs.mjs
//
// solar-kit.json holds Solar's Outline icons (480 Design, CC BY 4.0,
// https://creativecommons.org/licenses/by/4.0/), the weight Crate's own UI uses,
// exported from @solar-icons/react 2.3 with crate-for-ryoku's icons/solar_export.mjs:
//   node icons/solar_export.mjs <node_modules> <this dir>/solar-kit.json outline $(cat solar-kit.names)
// solar-kit.names lists the exported glyphs; add a name there, re-export, re-run.
// Outline glyphs are filled shapes, drawn as Solar ships them. Solar has no
// struck-through microphone or Bluetooth, so those two are its glyph with a
// 1.5 px round-capped diagonal.
import { readFileSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import path from "node:path";

const here = path.dirname(fileURLToPath(import.meta.url));
const src = JSON.parse(readFileSync(path.join(here, "solar-kit.json"), "utf8"));

const SVG_OPEN = '<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">';
const SLASH = '<path d="M3 3L21 21" stroke="currentColor" stroke-linecap="round"></path>';
const struck = (markup) => markup.replace(/<\/svg>$/, `${SLASH}</svg>`);

// Solar's react markup carries a styled root; keep only the viewBox and fill
const icons = {};
for (const [name, markup] of Object.entries(src.icons))
  icons[name] = markup.replace(/^<svg[^>]*>/, SVG_OPEN);

icons["microphone-2-off"] = struck(icons["microphone-2"]);
icons["bluetooth-off"] = struck(icons["bluetooth"]);
icons["bluetooth-square-off"] = struck(icons["bluetooth-square"]);

// Solar has no DIMM. Draw the module and its contacts at the same 24-unit scale.
icons["memory-stick"] = SVG_OPEN
  + '<g stroke="currentColor" stroke-linecap="round" stroke-linejoin="round">'
  + '<rect x="2" y="6" width="20" height="10" rx="1.5"/>'
  + '<path d="M6 9.5h4v3H6zm8 0h4v3h-4zM5 16v2m3-2v2m3-2v2m4-2v2m3-2v2"/>'
  + '</g></svg>';

for (const name of Object.keys(icons))
  icons[name] = icons[name].replace(/^<svg /, '<svg stroke-width="1.5" ');

// Material Symbols names the shell already passes, mapped to the catalogue
const alias = {
  lock: "lock", dark_mode: "moon", bedtime: "moon-stars", light_mode: "sun",
  logout: "logout-2", restart_alt: "restart", power_settings_new: "power",
  coffee: "cup-hot", notifications_off: "bell-off", mic: "microphone-2", mic_off: "microphone-2-off",
  sports_esports: "gamepad-minimalistic", settings: "settings", tune: "tuning-2", close: "close",
  arrow_back: "alt-arrow-left", expand_more: "alt-arrow-down", extension: "widget",
  vpn_lock: "shield-network", wifi: "wi-fi", wifi_off: "wi-fi-off",
  bluetooth: "bluetooth", bluetooth_disabled: "bluetooth-off",
  volume_up: "volume-loud", volume_down: "volume-small", volume_mute: "volume", volume_off: "volume-cross",
  brightness_low: "sun", brightness_medium: "sun", brightness_high: "sun",
  keyboard: "keyboard", play_arrow: "play", pause: "pause", skip_next: "skip-next",
  skip_previous: "skip-previous", shuffle: "shuffle", repeat: "repeat", repeat_one: "repeat-one-minimalistic",
  star: "star", delete: "trash-bin-minimalistic", push_pin: "pin", content_copy: "copy", search: "magnifier",
  notifications: "bell", music_note: "music-note-2", calendar_today: "calendar", chevron_right: "alt-arrow-right",
  expand_less: "alt-arrow-up", check_circle: "check-circle", add_circle: "add-circle", desktop_windows: "display",
  open_in_new: "square-arrow-right-up", speaker: "speaker", headphones: "headphones-round", monitor: "monitor",
  signal_wifi_4_bar: "wi-fi", network_wifi_3_bar: "wi-fi-high", network_wifi_2_bar: "wi-fi-low",
  network_wifi_1_bar: "wi-fi-low", signal_wifi_0_bar: "wi-fi-none", signal_wifi_off: "wi-fi-off", arrow_forward: "alt-arrow-right",
  north_east: "arrow-right-up", display_settings: "display", memory: "cpu", gamepad: "gamepad",
  mouse: "mouse-minimalistic", phone: "smartphone", watch: "watch-round", content_paste: "clipboard-text", refresh: "refresh", add: "add-circle", verified: "shield-check", verified_off: "shield",
  // Kit's phone tab (KDE Connect)
  phonelink_ring: "phone-calling-rounded", screen_share: "screen-share", videocam: "videocamera",
  android: "widget", progress_activity: "refresh", notifications_active: "bell-ring",
  upload_file: "file-send", folder_shared: "folder-path-connect", vibration: "smartphone-vibration",
  "audio-headphones": "headphones-round", "audio-headset": "headphones-round", "audio-card": "speaker",
  "input-mouse": "mouse-minimalistic", "input-gaming": "gamepad", bluetooth_connected: "bluetooth-wave", next: "skip-next", previous: "skip-previous", prev: "skip-previous",
  // weather (services/lib/weather.js symbolFor, and the dashboard's readouts)
  clear_day: "sun", clear_night: "moon", partly_cloudy_day: "cloud-sun", partly_cloudy_night: "cloudy-moon",
  cloud: "cloud", foggy: "fog", rainy: "cloud-rain", weather_snowy: "cloud-snowfall", thunderstorm: "cloud-storm",
  humidity_percentage: "waterdrops", thermostat: "temperature", air: "wind",
  // freedesktop icon names (the OSD, MPRIS and notification sources use these)
  "audio-volume-high": "volume-loud", "audio-volume-medium": "volume", "audio-volume-low": "volume-small",
  "audio-volume-muted": "volume-cross",
  "microphone-sensitivity-high": "microphone-2", "microphone-sensitivity-medium": "microphone-2",
  "microphone-sensitivity-low": "microphone-2", "microphone-sensitivity-muted": "microphone-2-off",
  "brightness-high": "sun", "brightness-medium": "sun", "brightness-low": "sun",
  "input-keyboard": "keyboard", "media-playback-start": "play", "media-playback-pause": "pause",
  "media-skip-forward": "skip-next", "media-skip-backward": "skip-previous",
  "media-playlist-shuffle": "shuffle", "media-playlist-repeat": "repeat",
  "media-playlist-repeat-song": "repeat-one-minimalistic", "window-close": "close", "edit-copy": "copy",
  "edit-delete": "trash-bin-minimalistic", "system-search": "magnifier",
  // the Ask bar, its tools and the Rashin chat
  route: "routing", edit: "pen", arrow_upward: "arrow-up", deployed_code: "box", draft: "file",
  cognition: "brain", terminal: "code-square", description: "document-text", build: "sledgehammer",
  public: "global", error: "danger-circle", visibility_off: "eye-closed", download: "download-minimalistic",
  folder_zip: "folder-zip", inventory_2: "archive", delete_sweep: "broom", dashboard: "widget-2",
};

const out = `// Generated by tools/build-glyphs.mjs; do not edit by hand. The kit's glyph
// catalogue: Solar Outline icons by 480 Design (CC BY 4.0), the weight Crate's
// UI uses. A name is a catalogue name ("volume-loud") or a
// Material Symbols name the shell already uses ("volume_up").

var ICONS = ${JSON.stringify(icons, null, 4)};

var ALIAS = ${JSON.stringify(alias, null, 4)};

function resolve(name) {
    var n = String(name || "");
    if (ICONS.hasOwnProperty(n))
        return n;
    return ALIAS.hasOwnProperty(n) ? ALIAS[n] : "";
}

function has(name) {
    return resolve(name) !== "";
}

// The glyph's SVG with its strokes and fills in one colour: "#rrggbb", or
// "#aarrggbb" as QML writes a colour with alpha. SVG reads eight hex digits as
// #rrggbbaa (or not at all), so the alpha moves to the root's opacity.
function svg(name, color) {
    var key = resolve(name);
    var c = String(color);
    if (!key || !/^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(c))
        return "";
    var markup = ICONS[key];
    if (c.length === 9) {
        var alpha = parseInt(c.slice(1, 3), 16) / 255;
        c = "#" + c.slice(3);
        markup = markup.replace(/^<svg /, '<svg opacity="' + (Math.round(alpha * 1000) / 1000) + '" ');
    }
    return markup.replace(/currentColor/g, c);
}

// A data URL an Image can load; "" when the glyph or the colour is unknown.
function dataUri(name, color) {
    var markup = svg(name, color);
    return markup ? "data:image/svg+xml;utf8," + encodeURIComponent(markup) : "";
}

if (typeof module !== "undefined" && module.exports)
    module.exports = { resolve, has, svg, dataUri, ICONS, ALIAS };
`;
writeFileSync(path.join(here, "..", "lib", "glyphs.js"), out);
console.log(`wrote ${Object.keys(icons).length} glyphs, ${Object.keys(alias).length} aliases`);
