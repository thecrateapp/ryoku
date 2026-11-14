#!/usr/bin/env bash
# capture-kit-probe: what the capture overlays draw (the selection frame, the
# region-recording dim, the camera bubble and its handles, the keypress
# placement chrome) on the kit and Tokens roles under crate, and as before in
# the stock look. The overlays are layer windows, which need a compositor, so
# the probe loads the Items they host, offscreen, in an isolated session.
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
ln -s "$repo/ryoku/ui" "$work/mods/Ryoku/Ui"
ln -s "$build/qml/Ryoku/Blobs" "$work/mods/Ryoku/Blobs"
for entry in "$repo/ryoku/shell/quickshell/shell"/*; do
    [ "$(basename "$entry")" = shell.qml ] || ln -s "$entry" "$work/root/$(basename "$entry")"
done
cp "$here/capture-kit-probe.qml" "$work/root/shell.qml"
env -u WAYLAND_DISPLAY -u DISPLAY -u DBUS_SESSION_BUS_ADDRESS -u HYPRLAND_INSTANCE_SIGNATURE \
    QT_QPA_PLATFORM=offscreen HOME="$work/home" XDG_CONFIG_HOME="$work/config" \
    XDG_CACHE_HOME="$work/cache" XDG_RUNTIME_DIR="$work/runtime" \
    RYOKU_I18N_DIR="$repo/ryoku/i18n/catalog" \
    QML_IMPORT_PATH="$work/mods:$repo/ryoku/shell/quickshell" QML2_IMPORT_PATH="$work/mods" \
    timeout 40 qs -p "$work/root/shell.qml" >"$work/log" 2>&1 || true
if ! grep -q CAPTURE-KIT-PROBE-PASS "$work/log" || grep -Eq 'TypeError|ReferenceError|CAPTURE-KIT-PROBE-FAIL' "$work/log"; then
    echo "capture-kit-probe: FAILED" >&2
    grep -E 'CAPTURE-KIT-PROBE|TypeError|ReferenceError|ERROR|caused by' "$work/log" | head -40 >&2
    exit 1
fi
echo "capture-kit-probe: the capture overlays draw from the kit and Tokens under crate; stock unchanged"
