#!/usr/bin/env bash
# btn-danger-probe: the kit Btn's danger variant fills with the error role under
# crate and leaves every other button, and the stock look, as they were.
# Offscreen, in its own runtime, home and config, with the live session unset.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT
mkdir -p "$work/Ryoku" "$work/config/ryoku" "$work/runtime" "$work/home"
chmod 700 "$work/runtime"
echo '{"language":"en"}' >"$work/config/ryoku/shell.json"
ln -s "$repo/ryoku/ui" "$work/Ryoku/Ui"
cp "$here/btn-danger-probe.qml" "$work/probe.qml"
env -u WAYLAND_DISPLAY -u DISPLAY -u DBUS_SESSION_BUS_ADDRESS -u HYPRLAND_INSTANCE_SIGNATURE -u NIRI_SOCKET \
    -u QML2_IMPORT_PATH \
    QT_QPA_PLATFORM=offscreen HOME="$work/home" XDG_CONFIG_HOME="$work/config" XDG_CACHE_HOME="$work/cache" \
    XDG_STATE_HOME="$work/state" XDG_RUNTIME_DIR="$work/runtime" \
    RYOKU_I18N_DIR="$repo/ryoku/i18n/catalog" QML_IMPORT_PATH="$work" \
    timeout 30 qs -p "$work/probe.qml" >"$work/log" 2>&1 || true
if ! grep -q BTN-DANGER-PROBE-PASS "$work/log" || grep -Eq 'TypeError|ReferenceError|Error: (crate|stock):' "$work/log"; then
    echo "btn-danger-probe: FAILED" >&2
    sed -n '1,40p' "$work/log" >&2
    exit 1
fi
echo "btn-danger-probe: danger fills with the error role under crate; other buttons and stock unchanged"
