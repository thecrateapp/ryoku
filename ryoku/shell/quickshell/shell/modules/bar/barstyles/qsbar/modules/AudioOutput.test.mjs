import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import vm from "node:vm";

const source = await readFile(new URL("./AudioOutput.js", import.meta.url), "utf8");
const module = { exports: {} };
vm.runInNewContext(source.replace(/^\.pragma library\s*/, "") +
    "\nmodule.exports = { outputKind, outputGlyph, sinkGlyph };", { module, String });
const { outputKind, outputGlyph, sinkGlyph } = module.exports;

// PipeWire properties of real sinks (a Meteor Lake laptop with SoundWire
// speakers, a headphone jack and DisplayPort monitors), plus Bluetooth and
// network sinks as WirePlumber and PipeWire's modules publish them.
const cases = [
    ["laptop", { "node.name": "alsa_output.pci-0000_00_1f.3-platform-sof_sdw.HiFi__Speaker__sink",
        "node.description": "Meteor Lake-P HD Audio Controller Speaker", "device.bus": "pci",
        "device.icon-name": "audio-card-analog", "device.api": "alsa" }],
    ["headphones", { "node.name": "alsa_output.pci-0000_00_1f.3-platform-sof_sdw.HiFi__Headphones__sink",
        "node.description": "Meteor Lake-P HD Audio Controller Headphones", "device.bus": "pci",
        "device.icon-name": "audio-card-analog", "device.api": "alsa" }],
    ["monitor", { "node.name": "alsa_output.pci-0000_00_1f.3-platform-sof_sdw.HiFi__HDMI1__sink",
        "node.description": "Meteor Lake-P HD Audio Controller HDMI / DisplayPort 1 Output", "device.bus": "pci",
        "device.api": "alsa" }],
    ["monitor", { "node.name": "alsa_output.pci-0000_01_00.1.hdmi-stereo", "node.description": "GA104 High Definition Audio Controller Digital Stereo (HDMI)" }],
    ["bt-headphones", { "node.name": "bluez_output.AC_80_0A_11_22_33.1", "node.description": "ULT WEAR",
        "device.bus": "bluetooth", "device.form-factor": "headphone", "device.api": "bluez5" }],
    ["bt-headphones", { "node.name": "bluez_output.00_11_22_33_44_55.1", "device.bus": "bluetooth",
        "device.icon-name": "audio-headset-bluetooth" }],
    ["remote", { "node.name": "bluez_output.66_77_88_99_AA_BB.1", "node.description": "SoundCore 2",
        "device.bus": "bluetooth", "device.form-factor": "speaker", "device.api": "bluez5" }],
    ["remote", { "node.name": "raop_sink.Living-Room.local.192.168.1.20.7000", "node.description": "AirPlay Living Room" }],
    ["remote", { "node.name": "tunnel.studio.local.alsa_output.usb", "node.description": "Tunnel to studio" }],
    ["remote", { "node.name": "roc-sink", "node.description": "ROC Sink" }],
    ["headphones", { "node.name": "alsa_output.usb-SteelSeries_Arctis_7-00.analog-stereo", "device.bus": "usb",
        "device.form-factor": "headset" }],
    ["speaker", { "node.name": "alsa_output.usb-Focusrite_Scarlett_2i2-00.analog-stereo", "device.bus": "usb",
        "node.description": "Scarlett 2i2 USB Analog Stereo" }],
    ["speaker", { "node.name": "alsa_output.pci-0000_00_1f.3.analog-stereo", "device.bus": "pci",
        "node.description": "Built-in Audio Analog Stereo" }],
    ["speaker", {}],
    ["speaker", null],
];
for (const [want, props] of cases)
    assert.equal(outputKind(props), want, `${want}: ${props && (props["node.name"] || "{}")}`);

assert.deepEqual(
    ["bt-headphones", "remote", "headphones", "monitor", "laptop", "speaker"].map(outputGlyph),
    ["headphones-round-sound", "speaker-minimalistic", "headphones-round", "monitor", "laptop", "speaker"]);
assert.equal(outputGlyph("nonsense"), "speaker");

// sinkGlyph is the one answer for "the glyph of a sink": the bar's audio widget
// and the volume panel's device rows both draw it, so the bar shows the device
// picked in the panel. It reads the node's properties, and a name the kit does
// not draw (an older kit) falls back to the plain speaker for both.
const node = (props) => ({ name: props["node.name"], properties: props });
const sinks = Object.fromEntries(cases.filter(([, p]) => p && p["node.name"]).map(([, p]) => [p["node.name"], p]));
const glyphOf = (name) => sinkGlyph(node(sinks[name]), () => true);
assert.equal(glyphOf("alsa_output.pci-0000_00_1f.3-platform-sof_sdw.HiFi__Speaker__sink"), "laptop");
assert.equal(glyphOf("alsa_output.pci-0000_00_1f.3-platform-sof_sdw.HiFi__Headphones__sink"), "headphones-round");
assert.equal(glyphOf("alsa_output.pci-0000_01_00.1.hdmi-stereo"), "monitor");
assert.equal(glyphOf("bluez_output.AC_80_0A_11_22_33.1"), "headphones-round-sound");
assert.equal(glyphOf("bluez_output.66_77_88_99_AA_BB.1"), "speaker-minimalistic");
for (const [, props] of cases)
    assert.equal(sinkGlyph(props && node(props), () => true), outputGlyph(outputKind(props)));
assert.equal(sinkGlyph(null, () => true), "speaker");
assert.equal(sinkGlyph({ name: "x" }, () => true), "speaker");
const oldKit = (name) => !["laptop", "headphones-round-sound", "speaker-minimalistic"].includes(name);
assert.equal(sinkGlyph(node(sinks["bluez_output.AC_80_0A_11_22_33.1"]), oldKit), "speaker");
assert.equal(sinkGlyph(node(sinks["alsa_output.pci-0000_01_00.1.hdmi-stereo"]), oldKit), "monitor");
assert.equal(sinkGlyph(node(sinks["alsa_output.pci-0000_01_00.1.hdmi-stereo"])), "monitor");
console.log("AudioOutput: ok");
