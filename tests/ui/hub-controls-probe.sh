#!/usr/bin/env bash
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../.." && pwd)
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
unset WAYLAND_DISPLAY DISPLAY NIRI_SOCKET SWAYSOCK DBUS_SESSION_BUS_ADDRESS HYPRLAND_INSTANCE_SIGNATURE
export HOME="$work/home" XDG_RUNTIME_DIR="$work/runtime" XDG_CONFIG_HOME="$work/config"
export XDG_CACHE_HOME="$work/cache" XDG_STATE_HOME="$work/state" XDG_DATA_HOME="$work/data"
export DBUS_SYSTEM_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/no-system-bus"
mkdir -pm 700 "$HOME" "$XDG_RUNTIME_DIR" "$work/config/ryoku" "$work/Ryoku" "$work/bin"
ln -s "$repo/ryoku/ui" "$work/Ryoku/Ui"
cp -a "$repo/ryoku/hub/quickshell" "$work/hub"
cp "$here/hub-controls-probe.qml" "$work/hub/probe.qml"
for tool in ryoku ryoku-hub ryoku-shell ryoku-host ryostore ryoku-rashin fastfetch fprintd-list pactl wpctl bluetoothctl nmcli; do
    printf '#!/bin/sh\nexit 0\n' >"$work/bin/$tool"
    chmod 755 "$work/bin/$tool"
done
export PATH="$work/bin:$PATH" QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software QML2_IMPORT_PATH="$work"
for mode in stock crate; do
    printf '{"themeStyle":{"controls":"%s"},"language":"en"}\n' "$mode" >"$XDG_CONFIG_HOME/ryoku/shell.json"
    RYOKU_PROBE_MODE="$mode" timeout 30 qs -p "$work/hub/probe.qml" >"$work/$mode.log" 2>&1 || true
    if ! grep -q "HUB-CONTROLS-PASS $mode" "$work/$mode.log" || grep -Eq 'TypeError|ReferenceError|Binding loop detected|Cannot override FINAL property|Cannot assign to non-existent property' "$work/$mode.log"; then
        grep -E 'HUB-CONTROLS|TypeError|ReferenceError|Binding loop|Cannot (override|assign)|ERROR' "$work/$mode.log" | head -90
        exit 1
    fi
done
echo "hub-controls-probe: Crate and stock controls passed in a window"
