#!/usr/bin/env bash
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../.." && pwd)
src="$repo/ryoku/shell/quickshell/shell"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

unset WAYLAND_DISPLAY DISPLAY NIRI_SOCKET SWAYSOCK DBUS_SESSION_BUS_ADDRESS
unset DBUS_STARTER_ADDRESS DBUS_STARTER_BUS_TYPE HYPRLAND_INSTANCE_SIGNATURE
export DBUS_SYSTEM_BUS_ADDRESS="unix:path=$work/runtime/no-system-bus"
mkdir -m 700 -p "$work"/{runtime,config,state,cache,data,Ryoku,shell/services}
export XDG_RUNTIME_DIR="$work/runtime" XDG_CONFIG_HOME="$work/config"
export XDG_STATE_HOME="$work/state" XDG_CACHE_HOME="$work/cache" XDG_DATA_HOME="$work/data"
export QT_QPA_PLATFORM=offscreen PIPEWIRE_REMOTE=missing-probe-server PULSE_SERVER="unix:$work/runtime/no-pulse"
ln -s "$repo/ryoku/ui" "$work/Ryoku/Ui"
for child in "$src/"*; do
    [[ ${child##*/} == services ]] || ln -s "$child" "$work/shell/"
done
ln -s "$repo/ryoku/shell/framebars" "$work/Ryoku/FrameBars"
for child in "$src/services/"*; do
    [[ ${child##*/} == Audio.qml ]] || ln -s "$child" "$work/shell/services/"
done
cat >"$work/shell/services/Audio.qml" <<'QML'
pragma Singleton
import QtQml
QtObject {
    property var sink: null
    property var source: null
    property var streams: []
    property var inputs: []
    property var outputs: []
    property var writes: []
    function alive(node) { return !!node }
    function streamIcon(node) { return "" }
    function streamName(node) { return "test stream" }
    function volumeOf(node) { return node ? node.audio.volume * node.boost : 0 }
    function setNodeVolume(node, value, limit) { writes.push([node, value, limit]) }
    function setSinkVolume(value, limit) { setNodeVolume(sink, value, limit) }
}
QML
cp "$here/bar-device-volume-probe.qml" "$work/shell/probe.qml"
QML2_IMPORT_PATH="$work:${QML2_IMPORT_PATH:-$HOME/.local/lib/qt6/qml}" \
    timeout 12 qs -p "$work/shell/probe.qml" >"$work/log" 2>&1 || { cat "$work/log" >&2; exit 1; }
if grep -Eq ' ERROR|TypeError|ReferenceError|is not a type|Type .* unavailable' "$work/log"; then
    cat "$work/log" >&2
    exit 1
fi
grep -q 'BAR-DEVICE-VOLUME-PASS' "$work/log" || { cat "$work/log" >&2; exit 1; }
echo "bar-device-volume-probe: output route, displayed boost, input and stream verified"
