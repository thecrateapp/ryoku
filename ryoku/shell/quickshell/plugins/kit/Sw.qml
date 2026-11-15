import QtQuick
import Ryoku.Ui as Kit

// The kit's switch, re-exported: a plugin may import only Ryoku.PluginKit (R4), so
// a boolean setting (the crate-mark equalizer's on/off) uses the same control the
// shell draws. `on` is the state; `toggled(v)` asks for the new one.
Kit.Sw {}
