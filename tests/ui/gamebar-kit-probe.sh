#!/usr/bin/env bash
# gamebar-kit-probe: the Game Bar's strip and cards on the kit and Tokens under
# crate, and unchanged in the stock look. Offscreen, in its own runtime, home and
# config, with the live session's Wayland, X11, D-Bus and Hyprland unset.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT
mkdir -p "$work/mods/Ryoku/Ui/Singletons" "$work/mods/root" "$work/runtime" "$work/home" "$work/config/ryoku"
chmod 700 "$work/runtime"
echo '{"language":"en"}' >"$work/config/ryoku/shell.json"
# The kit, linked entry by entry: Wm.qml reads Quickshell.WindowManager, which
# aborts the process offscreen, so the probe gets a copy with those reads emptied.
for entry in "$repo/ryoku/ui"/*; do
    [ "$(basename "$entry")" = Singletons ] || ln -s "$entry" "$work/mods/Ryoku/Ui/$(basename "$entry")"
done
for entry in "$repo/ryoku/ui/Singletons"/*; do
    [ "$(basename "$entry")" = Wm.qml ] || ln -s "$entry" "$work/mods/Ryoku/Ui/Singletons/$(basename "$entry")"
done
sed -e 's/WindowManager\.windowsets/[]/' -e 's/ToplevelManager\.toplevels/null/' \
    "$repo/ryoku/ui/Singletons/Wm.qml" >"$work/mods/Ryoku/Ui/Singletons/Wm.qml"
for entry in "$repo/ryoku/shell/quickshell/shell"/*; do
    [ "$(basename "$entry")" = shell.qml ] || ln -s "$entry" "$work/mods/root/$(basename "$entry")"
done
cp "$here/gamebar-kit-probe.qml" "$work/mods/root/shell.qml"
env -u WAYLAND_DISPLAY -u DISPLAY -u DBUS_SESSION_BUS_ADDRESS -u HYPRLAND_INSTANCE_SIGNATURE -u NIRI_SOCKET \
    -u QML2_IMPORT_PATH \
    QT_QPA_PLATFORM=offscreen HOME="$work/home" XDG_CONFIG_HOME="$work/config" XDG_CACHE_HOME="$work/cache" \
    XDG_STATE_HOME="$work/state" XDG_DATA_HOME="$work/data" XDG_RUNTIME_DIR="$work/runtime" \
    RYOKU_I18N_DIR="$repo/ryoku/i18n/catalog" QML_IMPORT_PATH="$work/mods:$repo/ryoku/shell/quickshell" \
    timeout 40 qs -p "$work/mods/root/shell.qml" >"$work/log" 2>&1 || true
if ! grep -q GAMEBAR-KIT-PROBE-PASS "$work/log" || grep -Eq 'TypeError|ReferenceError|Error: (crate|stock):' "$work/log"; then
    echo "gamebar-kit-probe: FAILED" >&2
    grep -vE 'Socket error|pipewire|Mpris' "$work/log" | sed -n '1,60p' >&2
    exit 1
fi
echo "gamebar-kit-probe: the strip and cards draw on the kit and Tokens under crate, stock unchanged"
