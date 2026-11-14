#!/usr/bin/env bash
# shima-dock-kit-probe: what the Shima dock draws on its own (the design the
# Crate setup's dock uses under the QS Bar) on the kit and Tokens roles under
# crate, and as before in the stock look: the dock body as the one glass, the
# hover plates, the separator, the running and focused marks, the name label, the
# app menu and its rows, the windows sheet and its cards. The dock is a layer
# window, which needs a compositor, so the probe loads the IrisDock Item it
# hosts, offscreen, in an isolated session.
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
mkdir -p "$work/mods/Ryoku/Ui/Singletons" "$work/root" "$work/config/ryoku" "$work/runtime" "$work/home" "$work/cache" "$work/state"
chmod 700 "$work/runtime"
cat >"$work/config/ryoku/shell.json" <<'JSON'
{"language":"en","barStyle":"qsbar",
 "dock":{"enabled":true,"design":"shima","edge":"bottom","autohide":false,"magnify":false,"size":44,
         "pinned":["kitty","firefox","org.gnome.Nautilus"],"pinnedConfigured":true,
         "shima":{"launcher":true,"notch":true,"material":"inherit","shape":"auto"}}}
JSON
# The kit, linked entry by entry: Wm.qml reads Quickshell.WindowManager, which
# aborts the process under the offscreen platform (as in render.sh).
for entry in "$repo/ryoku/ui"/*; do
    [ "$(basename "$entry")" = Singletons ] || ln -s "$entry" "$work/mods/Ryoku/Ui/$(basename "$entry")"
done
for entry in "$repo/ryoku/ui/Singletons"/*; do
    [ "$(basename "$entry")" = Wm.qml ] || ln -s "$entry" "$work/mods/Ryoku/Ui/Singletons/$(basename "$entry")"
done
sed -e 's/WindowManager\.windowsets/[]/' -e 's/ToplevelManager\.toplevels/null/' \
    "$repo/ryoku/ui/Singletons/Wm.qml" >"$work/mods/Ryoku/Ui/Singletons/Wm.qml"
ln -s "$build/qml/Ryoku/Blobs" "$work/mods/Ryoku/Blobs"
# inir, mirrored as links with its LiveLayer swapped for one that draws in
# place: the real one maps a layer window of its own, which needs a compositor.
cp -as "$repo/ryoku/shell/quickshell/inir" "$work/mods/inir"
cp -rf --remove-destination "$here/fixtures/offscreen-inir/." "$work/mods/inir/"
ln -s "$repo/ryoku/shell/framebars" "$work/mods/Ryoku/FrameBars"
for entry in "$repo/ryoku/shell/quickshell/shell"/*; do
    [ "$(basename "$entry")" = shell.qml ] || ln -s "$entry" "$work/root/$(basename "$entry")"
done
cp "$here/shima-dock-kit-probe.qml" "$work/root/shell.qml"
env -u WAYLAND_DISPLAY -u DISPLAY -u DBUS_SESSION_BUS_ADDRESS -u HYPRLAND_INSTANCE_SIGNATURE \
    -u NIRI_SOCKET -u SWAYSOCK \
    QT_QPA_PLATFORM=offscreen HOME="$work/home" XDG_CONFIG_HOME="$work/config" \
    XDG_CACHE_HOME="$work/cache" XDG_STATE_HOME="$work/state" XDG_RUNTIME_DIR="$work/runtime" \
    RYOKU_I18N_DIR="$repo/ryoku/i18n/catalog" \
    QML_IMPORT_PATH="$work/mods:$repo/ryoku/shell/quickshell" QML2_IMPORT_PATH="$work/mods" \
    timeout 60 qs -p "$work/root/shell.qml" >"$work/log" 2>&1 || true
if [ -n "${PROBE_LOG:-}" ]; then cp "$work/log" "$PROBE_LOG"; fi
if ! grep -q SHIMA-DOCK-KIT-PROBE-PASS "$work/log" || grep -Eq 'SHIMA-DOCK-KIT-PROBE-FAIL' "$work/log" \
    || grep -E 'TypeError|ReferenceError' "$work/log" | grep -q 'iris/dock/'; then
    echo "shima-dock-kit-probe: FAILED" >&2
    grep -E 'SHIMA-DOCK-KIT-PROBE|TypeError|ReferenceError|ERROR|caused by' "$work/log" | head -40 >&2
    exit 1
fi
echo "shima-dock-kit-probe: the Shima dock draws from the kit and Tokens under crate; stock unchanged"
