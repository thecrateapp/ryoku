#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT
mkdir -p "$work/home" "$work/Ryoku" "$work/bin" "$work/config/ryoku"
mkdir -m 700 "$work/runtime"
ln -s "$repo/ryoku/ui" "$work/Ryoku/Ui"
cp -a "$repo/ryoku/hub/quickshell" "$work/hub"
cp "$here/hub-header-probe.qml" "$work/hub/probe.qml"
echo '{}' > "$work/config/ryoku/shell.json"
for tool in ryoku ryoku-hub ryoku-shell; do
    printf '#!/bin/sh\nexit 0\n' > "$work/bin/$tool"
    chmod +x "$work/bin/$tool"
done
if ! env -u WAYLAND_DISPLAY -u DISPLAY -u NIRI_SOCKET -u SWAYSOCK -u DBUS_SESSION_BUS_ADDRESS \
    HOME="$work/home" DBUS_SYSTEM_BUS_ADDRESS="unix:path=$work/runtime/no-system-bus" \
    PATH="$work/bin:$PATH" XDG_RUNTIME_DIR="$work/runtime" XDG_CONFIG_HOME="$work/config" \
    XDG_CACHE_HOME="$work/cache" XDG_STATE_HOME="$work/state" XDG_DATA_HOME="$work/data" \
    QT_QPA_PLATFORM=offscreen QML2_IMPORT_PATH="$work" RYOKU_I18N_DIR="$repo/ryoku/i18n/catalog" \
    timeout 15 qs -p "$work/hub/probe.qml" > "$work/log" 2>&1 || ! grep -q HUB-HEADER-PROBE-PASS "$work/log"; then
    cat "$work/log" >&2
    exit 1
fi
echo "hub-header-probe: stock, Crate, register, action and Japanese gloss passed"
