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
icons["headphones-round-off"] = struck(icons["headphones-round"]);
icons["bluetooth-square-off"] = struck(icons["bluetooth-square"]);
// Solar has no unpin: the dock menus' "Unpin" is its pin, struck.
icons["magnet-off"] = struck(icons["magnet"]);
icons["pin-off"] = struck(icons["pin"]);
icons["smartphone-off"] = struck(icons["smartphone"]);
icons["music-note-off"] = struck(icons["music-note-2"]);
icons["hourglass-off"] = struck(icons["hourglass"]);

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
// Solar has no unpin: the dock menus' "Unpin" is its pin, struck.
  // the Shima dock's app menu and windows sheet (keep/keep_off are the Stage's)
  select_window: "window-frame", picture_in_picture: "window-frame",
  view_carousel: "layers-minimalistic", dock_to_bottom: "square-bottom-down", bubble_chart: "square-top-up",
  // the Stage editor's toolbar, panel rows and widget grips
  widgets: "widget", wallpaper: "gallery", palette: "palette", dock: "panel-bottom",
  grid_guides: "magnet", grid_off: "magnet-off", undo: "undo-left", redo: "undo-right", done: "check",
  open_in_full: "maximize-square", aspect_ratio: "maximize-square", fit_screen: "full-screen",
  more_horiz: "menu-dots", remove: "minus-circle", keep: "pin", keep_off: "pin-off",  // desktop widget, catalogue and Stage editor icons (Solar Outline stand-ins)
  add_to_home_screen: "home-add", ads_click: "cursor", album: "album",
  align_horizontal_center: "align-horizontal-center", align_horizontal_left: "align-left",
  align_horizontal_right: "align-right", align_justify_space_even: "align-horizontal-spacing",
  align_space_even: "align-horizontal-spacing", align_vertical_bottom: "align-bottom",
  align_vertical_center: "align-vertical-center", align_vertical_top: "align-top", apps: "widget-4",
  apps_outage: "danger-square", arrow_selector_tool: "cursor", attach_file: "paperclip",
  auto_awesome: "stars", battery_android_6: "battery-full-minimalistic",
  battery_charging_full: "battery-charge", battery_full: "battery-full", block: "forbidden-circle",
  blur_circular: "circle-dot-dashed", blur_on: "circle-dashed", bookmark: "bookmark",
  bookmark_remove: "bookmark-minus", bookmarks: "bookmark-square", calendar_month: "calendar-minimalistic",
  calendar_view_day: "calendar-date", cast: "screencast", category: "widget-3",
  center_focus_strong: "target", checklist: "checklist", circle: "record", colorize: "pipette",
  content_cut: "scissors", content_paste_go: "clipboard-paste", create_new_folder: "add-folder",
  crop: "crop", crop_free: "full-screen", crop_square: "crop-minimalistic", date_range: "calendar-mark",
  deployed_code_update: "archive-up", desktop: "monitor", dock_to_bottom: "panel-bottom",
  dock_to_left: "panel-left", do_not_disturb_on: "minus-circle", donut_large: "donut",
  drag_indicator: "grip-vertical", drive_file_move: "move-to-folder", earbuds: "headphones-round-sound",
  event: "calendar-mark", fiber_manual_record: "record", filter_center_focus: "target",
  filter_drama: "cloud", fingerprint: "face-scan-circle", flag: "flag", flip: "flip-horizontal",
  fluid_med: "dropper", folder_copy: "folder-2", format_color_fill: "paint-roller",
  format_list_numbered: "list", format_quote: "quote", fullscreen: "full-screen", gradient: "colour-tuning",
  graphic_eq: "soundwave", grid_view: "grid-2x2", hard_drive: "server-square", height: "move-vertical",
  horizontal_distribute: "align-horizontal-spacing", hourglass_top: "hourglass",
  image: "gallery-minimalistic", info: "info-circle", interests: "widget-3", label: "tag",
  lan: "server-path", landscape: "gallery-wide", layers: "layers", lightmode: "sun",
  linear_scale: "slider-horizontal", line_curve: "graph", line_weight: "hamburger-menu", link_off: "unlink",
  live_tv: "tv", lockscreen: "lock-keyhole", mail: "letter", memory_alt: "cpu-bolt",
  monitor_heart: "heart-pulse", more_vert: "menu-dots-vertical", motion_photos_on: "play-circle",
  movie: "clapperboard", navigation: "map-arrow-up", near_me: "map-arrow-right",
  nest_clock_farsight_analog: "clock-circle", neurology: "brain", note_stack: "notes", opacity: "waterdrop", open_with: "move",
  panorama: "panorama", photo_size_select_small: "gallery-round", play_circle: "play-circle", radar: "radar",
  radio_button_checked: "record-circle", remove_circle_outline: "minus-circle",
  reset_wrench: "refresh-circle", rotate_left: "undo-left-round", rotate_right: "undo-right-round",
  rounded_corner: "maximize-square-minimalistic", running_with_errors: "danger-triangle",
  schedule: "clock-circle", screen: "display", screen_record: "videocamera-record",
  shadow: "layers-minimalistic", shield_lock: "shield-keyhole", smart_display: "play-stream",
  space_bar: "keyboard", splitscreen: "table-rows-split", sports_soccer: "football", stacks: "layers",
  storefront: "shop", straighten: "ruler", style: "palette-2", sunny: "sun",
  swap_horiz: "transfer-horizontal", swap_vert: "transfer-vertical", swipe: "move-horizontal",
  swipe_vertical: "move-vertical", sync_problem: "danger-circle", system_update_alt: "download-minimalistic",
  timer: "stopwatch", vertical_align_center: "align-vertical-center", vertical_align_top: "align-top",
  vertical_distribute: "align-vertical-spacing", vertical_split: "sidebar", view_agenda: "layout-list",
  view_carousel: "posts-carousel-horizontal", view_column: "table-columns-split", view_module: "grid-3x2",
  view_week: "table-columns-split", visibility: "eye", water_drop: "waterdrop", water_full: "cup",
  weather_mix: "cloud-snowfall", width: "move-horizontal", workspaces: "widget-5",
  zoom_in: "magnifier-zoom-in", zoom_out_map: "maximize",
  // the wallpaper framing coach and its snap marker
  pan_tool: "move", face: "face-scan-circle", center_focus_weak: "target",
  // the EasyEffects widget's effect chips
  auto_fix_high: "magic-wand", compress: "minimize-square", diamond: "stars-minimalistic", door_front: "exit",
  equalizer: "slider-vertical", expand: "maximize", filter_alt: "filter", grain: "circle-dot-dashed",
  monitoring: "graph-up", noise_control_off: "soundwave-circle", piano: "music-library",
  record_voice_over: "microphone-large", spatial_audio: "headphones-round-sound", surround_sound: "speaker",
  voice_over_off: "microphone-2-off", voice_selection_off: "microphone-2-off",
  // the desktop shortcuts' menus
  dashboard_customize: "widget-add", file_copy: "copy", folder_open: "folder-open", language: "global", url: "link",
  // the timers' and the mail widget's
  hourglass_disabled: "hourglass-off", hourglass_empty: "hourglass-line", keyboard_arrow_down: "alt-arrow-down",
  login: "login-2", save: "diskette",
  // the icons the widget faces draw
  animation: "clapperboard-play", battery_std: "battery-half", bolt: "bolt", bookmark_add: "bookmark-plus",
  calendar_view_week: "calendar-minimalistic", check_box_outline_blank: "stop",
  chevron_left: "alt-arrow-left", device_thermostat: "temperature", devices: "devices", directory: "folder",
  done_all: "check-read", event_available: "calendar-mark", extension_off: "forbidden-circle",
  group: "users-group-rounded", hourglass_bottom: "hourglass", inbox: "inbox", location_on: "map-point",
  mobile: "smartphone", mobile_off: "smartphone-off", music_off: "music-note-off", percent: "sale",
  phone_android: "smartphone", phonelink_off: "smartphone-off", photo_library: "gallery", sync: "refresh",
  task_alt: "check-circle",
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
