#!/usr/bin/env bash
# visualizer-kit-probe: the desktop spectrum's colours (the bars ramp, the edge
# field's triad, the fallbacks behind a pinned colour) and the Stage Editor's
# placement grip, on Tokens roles under crate and as before in the stock look.
# The visualiser's layer window needs a compositor, so the probe loads the Items
# it hosts (VisualizerView, VisualizerGrip), offscreen, in an isolated session
# with a cyan palette, so the accent and its highlight differ, over a bright
# wallpaper, so the crate mark has to be re-lit to keep its contrast.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
plugin="$repo/ryoku/shell/plugin"
build="${RYOKU_BLOBS_BUILD:-$plugin/build}"
if [ ! -f "$build/qml/Ryoku/Blobs/qmldir" ]; then
    cmake -S "$plugin" -B "$build" -G Ninja -DCMAKE_BUILD_TYPE=Release >/dev/null
    cmake --build "$build" >/dev/null
fi
work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT
mkdir -p "$work/mods/Ryoku" "$work/root" "$work/config/ryoku" "$work/runtime" "$work/home"
chmod 700 "$work/runtime"
echo '{"language":"en"}' >"$work/config/ryoku/shell.json"
mkdir -p "$work/cache/ryoku"
echo '{"primary":"#06b6d4","secondary":"#67e8f9","surface":"#0a0a0f","onSurface":"#f1f5f9"}' >"$work/cache/ryoku/colors.json"
# a bright picture (L* 86, the mark's own lightness), so the relight has to act
echo '{"lstar":86}' >"$work/cache/ryoku/wallpaper-tone.json"
ln -s "$repo/ryoku/ui" "$work/mods/Ryoku/Ui"
ln -s "$build/qml/Ryoku/Blobs" "$work/mods/Ryoku/Blobs"
for entry in "$repo/ryoku/shell/quickshell/shell"/*; do
    [ "$(basename "$entry")" = shell.qml ] || ln -s "$entry" "$work/root/$(basename "$entry")"
done
cp "$here/visualizer-kit-probe.qml" "$work/root/shell.qml"
env -u WAYLAND_DISPLAY -u DISPLAY -u DBUS_SESSION_BUS_ADDRESS -u HYPRLAND_INSTANCE_SIGNATURE \
    QT_QPA_PLATFORM=offscreen HOME="$work/home" XDG_CONFIG_HOME="$work/config" \
    XDG_CACHE_HOME="$work/cache" XDG_RUNTIME_DIR="$work/runtime" \
    RYOKU_I18N_DIR="$repo/ryoku/i18n/catalog" \
    QML_IMPORT_PATH="$work/mods:$repo/ryoku/shell/quickshell" QML2_IMPORT_PATH="$work/mods" \
    timeout 40 qs -p "$work/root/shell.qml" >"$work/log" 2>&1 || true
if ! grep -q VISUALIZER-KIT-PROBE-PASS "$work/log" || grep -Eq 'TypeError|ReferenceError|VISUALIZER-KIT-PROBE-FAIL' "$work/log"; then
    echo "visualizer-kit-probe: FAILED" >&2
    grep -E 'VISUALIZER-KIT-PROBE|TypeError|ReferenceError|ERROR|caused by' "$work/log" | head -40 >&2
    exit 1
fi
echo "visualizer-kit-probe: the spectrum and its grip draw from Tokens under crate; stock unchanged"
