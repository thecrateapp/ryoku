.pragma library

// What the default sink plays through, from its PipeWire properties, so the
// bar's audio glyph can show it: Bluetooth headphones, a remote speaker
// (Bluetooth speaker, AirPlay, a network tunnel, ROC or Snapcast), wired or
// USB headphones, a monitor or TV over HDMI or DisplayPort, the laptop's own
// speakers, or any other speaker.

function prop(props, key) {
    var v = props ? props[key] : undefined
    return v === undefined || v === null ? "" : String(v)
}

function outputKind(props) {
    var name = prop(props, "node.name").toLowerCase()
    var desc = prop(props, "node.description").toLowerCase()
    var bus = prop(props, "device.bus").toLowerCase()
    var form = prop(props, "device.form-factor").toLowerCase()
    var icon = prop(props, "device.icon-name").toLowerCase()
    var text = name + " " + desc
    var headish = /^(headphone|headset|hands-?free)$/.test(form) || /headphone|headset/.test(icon)

    if (bus === "bluetooth" || name.indexOf("bluez_output") === 0)
        return headish ? "bt-headphones" : "remote"
    if (/^(raop_sink|tunnel|roc-sink|snapcast)/.test(name) || prop(props, "device.api") === "raop")
        return "remote"
    if (/hdmi|displayport/.test(text))
        return "monitor"
    if (headish || /headphone|headset/.test(text))
        return "headphones"
    if ((bus === "pci" || form === "internal") && /speaker/.test(text))
        return "laptop"
    return "speaker"
}

var GLYPHS = {
    "bt-headphones": "headphones-round-sound",
    "remote": "speaker-minimalistic",
    "headphones": "headphones-round",
    "monitor": "monitor",
    "laptop": "laptop",
    "speaker": "speaker"
}

// the kit (Solar) glyph for a kind
function outputGlyph(kind) {
    return GLYPHS[kind] || "speaker"
}
