#!/usr/bin/env bash
# audio-output-glyph-probe: under crate the bar's audio widget draws the same
# glyph as the volume panel's picked device row and the media panel's output
# line, for a laptop speaker, wired headphones, an HDMI monitor and Bluetooth
# headphones, with the current kit and with a kit from before the newer glyphs;
# the stock look keeps graphic_eq.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
qsbar="$repo/ryoku/shell/quickshell/shell/modules/bar/barstyles/qsbar"

run() {
    local kit="$1" work
    work="$(mktemp -d)"
    trap 'rm -rf -- "$work"' RETURN
    mkdir -p "$work/imports/shell/services" "$work/imports/Ryoku" "$work/config/ryoku" \
        "$work/runtime" "$work/home" "$work/state" "$work/cache"
    chmod 700 "$work/runtime"
    if [ "$kit" = old ]; then
        # a kit from before the newer glyphs: both must fall back to the same one
        cp -r "$repo/ryoku/ui" "$work/imports/Ryoku/Ui"
        python3 -c 'import re, sys
p = sys.argv[1]; s = open(p).read()
for n in ("headphones-round-sound", "speaker-minimalistic", "laptop"):
    s = re.sub(r"\n    \"%s\": \"[^\n]*\"," % re.escape(n), "", s)
open(p, "w").write(s)' "$work/imports/Ryoku/Ui/lib/glyphs.js"
    else
        ln -s "$repo/ryoku/ui" "$work/imports/Ryoku/Ui"
    fi
    ln -s "$qsbar/modules" "$work/modules"
    ln -s "$qsbar/panels" "$work/panels"
    printf 'module shell.services\nsingleton Audio 1.0 Audio.qml\n' >"$work/imports/shell/services/qmldir"
    cat >"$work/imports/shell/services/Audio.qml" <<'QML'
pragma Singleton
import QtQml
QtObject {
    property var sink: null
    property var outputs: []
    readonly property real sinkVolume: sink && sink.audio ? (sink.audio.volume || 0) : 0
    function alive(n) { return !!n }
    function volumeOf(n) { return n ? n.audio.volume : 0 }
    function setSinkVolume(v, limit) {}
    function setOutput(n) { sink = n }
    function nodeLabel(n) { return n ? (n.properties["node.description"] || n.name) : "" }
    function isBluez(n) { return !!n && (n.properties["device.api"] || "") === "bluez5" }
}
QML
    echo '{}' >"$work/config/ryoku/shell.json"
    cp "$here/audio-output-glyph-probe.qml" "$work/shell.qml"
    env -u WAYLAND_DISPLAY -u DISPLAY -u DBUS_SESSION_BUS_ADDRESS -u HYPRLAND_INSTANCE_SIGNATURE \
        PROBE_KIT="$kit" RYOKU_I18N_DIR="$repo/ryoku/i18n/catalog" QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
        PIPEWIRE_REMOTE=missing-probe-server \
        HOME="$work/home" XDG_CONFIG_HOME="$work/config" XDG_CACHE_HOME="$work/cache" \
        XDG_STATE_HOME="$work/state" XDG_RUNTIME_DIR="$work/runtime" \
        QML2_IMPORT_PATH="$work/imports" QML_IMPORT_PATH="$work/imports" \
        timeout 20 qs -p "$work/shell.qml" >"$work/log" 2>&1 || true
    if ! grep -q "AUDIO-OUTPUT-GLYPH-PROBE-PASS $kit" "$work/log" \
            || grep -Eq 'AUDIO-OUTPUT-GLYPH-PROBE-FAIL|TypeError|ReferenceError|is not a type' "$work/log"; then
        echo "audio-output-glyph-probe ($kit kit): FAILED" >&2
        sed -n '1,80p' "$work/log" >&2
        return 1
    fi
}

run new
run old
echo "audio-output-glyph-probe: the bar's audio glyph is the picked device row's and the media panel's under crate, with the current and an older kit; stock keeps graphic_eq"
