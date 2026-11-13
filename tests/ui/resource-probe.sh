#!/usr/bin/env bash
# Exercise the actual QS Bar resource widgets with controlled telemetry.
set -euo pipefail
case "${1:-}" in
    memory|storage) resource=$1 ;;
    *) echo 'Usage: resource-probe.sh memory|storage [qsbar-dir] [kit-dir]' >&2; exit 2 ;;
esac

here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../.." && pwd)
bar=$(realpath "${2:-$repo/ryoku/shell/quickshell/shell/modules/bar/barstyles/qsbar}")
kit=$(realpath "${3:-$repo/ryoku/ui}")
work=$(mktemp -d)
weston_pid=""
cleanup() {
    if [[ -n "$weston_pid" ]]; then
        kill "$weston_pid" 2>/dev/null || true
        wait "$weston_pid" 2>/dev/null || true
    fi
    rm -rf -- "$work"
}
trap cleanup EXIT
export HOME="$work/home" XDG_CONFIG_HOME="$work/config" XDG_CACHE_HOME="$work/cache"
export XDG_RUNTIME_DIR="$work/runtime" XDG_DATA_HOME="$work/data" XDG_STATE_HOME="$work/state"
export QML_IMPORT_PATH="$work/imports" QT_QUICK_BACKEND=software
unset DISPLAY WAYLAND_DISPLAY DBUS_SESSION_BUS_ADDRESS
mkdir -p "$HOME" "$XDG_CONFIG_HOME/ryoku" "$XDG_RUNTIME_DIR" "$work/bar" "$work/imports/Ryoku" "$work/imports/shell/services"
chmod 700 "$XDG_RUNTIME_DIR"
ln -s "$bar/panels" "$bar/modules" "$work/bar/"
ln -s "$kit" "$work/imports/Ryoku/Ui"
printf 'module shell.services\nsingleton Perf 1.0 Perf.qml\n' > "$work/imports/shell/services/qmldir"
printf 'pragma Singleton\nimport QtQuick\nQtObject { readonly property int msaa: 0; readonly property bool ambientMotion: false }\n' > "$work/imports/shell/services/Perf.qml"
echo '{"themeStyle":{"controls":"crate"},"language":"en"}' > "$XDG_CONFIG_HOME/ryoku/shell.json"
cp "$here/$resource-resource-probe.qml" "$work/shell.qml"
weston --backend=headless --width=720 --height=540 --shell=kiosk-shell.so --no-config \
    --renderer=pixman --socket=resource-display > "$work/weston.log" 2>&1 &
weston_pid=$!
for _ in {1..150}; do
    [[ -S "$XDG_RUNTIME_DIR/resource-display" ]] && break
    kill -0 "$weston_pid" 2>/dev/null || { cat "$work/weston.log" >&2; exit 1; }
    sleep .02
done
if ! QT_QPA_PLATFORM=wayland WAYLAND_DISPLAY=resource-display timeout 20 qs -p "$work/shell.qml" > "$work/log" 2>&1 ||
    ! grep -Fq "${resource^^}-RESOURCE-PROBE-PASS" "$work/log"; then
    cat "$work/log" >&2
    exit 1
fi
echo "$resource resource probe passed"
