#!/usr/bin/env bash
# Prewarm the real Controls board on Qt's offscreen display in both themes.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../.." && pwd)
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
unset WAYLAND_DISPLAY DISPLAY NIRI_SOCKET SWAYSOCK DBUS_SESSION_BUS_ADDRESS
mkdir -m 700 -p "$work"/{runtime,config/ryoku,home,cache,state,data,Ryoku}
export HOME="$work/home" XDG_RUNTIME_DIR="$work/runtime" XDG_CONFIG_HOME="$work/config"
export XDG_CACHE_HOME="$work/cache" XDG_STATE_HOME="$work/state" XDG_DATA_HOME="$work/data"
export DBUS_SYSTEM_BUS_ADDRESS="unix:path=$work/runtime/no-system-bus"
export QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software
export PIPEWIRE_REMOTE=missing-probe-server PULSE_SERVER="unix:$work/runtime/no-pulse"
export QML2_IMPORT_PATH="$work" RYOKU_I18N_DIR="$repo/ryoku/i18n/catalog"
ln -s "$repo/ryoku/ui" "$work/Ryoku/Ui"
ln -s "$repo/ryoku/shell/quickshell/shell" "$work/shell"
cp "$here/controls-prewarm-probe.qml" "$work/probe.qml"
for look in crate stock; do
    printf '{"themeStyle":{"controls":"%s"},"language":"en"}\n' "$look" > "$XDG_CONFIG_HOME/ryoku/shell.json"
    status=0
    CONTROLS_LOOK="$look" timeout 45 qs -p "$work/probe.qml" >"$work/log" 2>&1 || status=$?
    if [[ $status != 0 ]] || ! grep -q CONTROLS-PREWARM-PASS "$work/log" \
        || grep -Eq 'Binding loop detected|TypeError|ReferenceError' "$work/log"; then
        echo "controls-prewarm-probe: $look failed (qs exit $status)" >&2
        cat "$work/log" >&2
        exit 1
    fi
    echo "controls-prewarm-probe: $look passed"
done
