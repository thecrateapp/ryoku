#!/usr/bin/env bash
# Exercise the actual host, data collector, renderer and actions on a private display.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
bar="${1:-$repo/ryoku/shell/quickshell/shell/modules/bar/barstyles/qsbar}"
ui="$(realpath "${2:-$repo/ryoku/ui}")"
work="$(mktemp -d)"
weston_pid=""
cleanup() {
    if [[ -n "$weston_pid" ]]; then
        kill "$weston_pid" 2>/dev/null || true
        wait "$weston_pid" 2>/dev/null || true
    fi
    rm -rf -- "$work"
}
trap cleanup EXIT
export HOME="$work/home" XDG_RUNTIME_DIR="$work/runtime" XDG_CONFIG_HOME="$work/config"
export XDG_CACHE_HOME="$work/cache" XDG_DATA_HOME="$work/data" XDG_STATE_HOME="$work/state"
export QML_IMPORT_PATH="$work/imports" PATH="$work/bin:$PATH" QT_QUICK_BACKEND=software
unset DISPLAY WAYLAND_DISPLAY DBUS_SESSION_BUS_ADDRESS
mkdir -p "$HOME" "$XDG_RUNTIME_DIR" "$XDG_CONFIG_HOME/ryoku" "$work"/{bar,bin,imports/Ryoku,imports/shell/services}
chmod 700 "$XDG_RUNTIME_DIR"
if [[ -z "${RYOKU_I18N_DIR:-}" ]]; then
    export RYOKU_I18N_DIR="$work/i18n"
    mkdir -p "$RYOKU_I18N_DIR"
    ln -s "$repo/ryoku/i18n"/{langs.json,catalog/en.json,catalog/es.json} "$RYOKU_I18N_DIR/"
fi
ln -s "$ui" "$work/imports/Ryoku/Ui"
cp -r "$bar"/{modules,panels} "$work/bar/"
cp "$here/battery-panel-probe.qml" "$work/shell.qml"
echo '{"themeStyle":{"controls":"crate"},"language":"en"}' > "$XDG_CONFIG_HOME/ryoku/shell.json"
printf 'module shell.services\nsingleton Perf 1.0 Perf.qml\n' > "$work/imports/shell/services/qmldir"
printf 'pragma Singleton\nimport QtQuick\nQtObject { readonly property int msaa: 0 }\n' > "$work/imports/shell/services/Perf.qml"
# Replace only the command that gathers hardware data. QML still parses its stdout and dispatches real actions.
cat > "$work/bar/RyokuPower.js" <<'JS'
.pragma library
var batteryDataCmd = 'cat "$XDG_RUNTIME_DIR/reading"'
JS
echo 'BAT0|67|discharging|Time left|2h 30m|9.3|49 Wh|90%|175' > "$XDG_RUNTIME_DIR/reading"
cat > "$work/bin/ryoku-host" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$XDG_RUNTIME_DIR/launched"
STUB
chmod +x "$work/bin/ryoku-host"

weston --backend=headless --width=640 --height=480 --shell=kiosk-shell.so --no-config \
    --renderer=pixman --socket=battery-display > "$work/weston.log" 2>&1 &
weston_pid=$!
for _ in {1..150}; do
    [[ -S "$XDG_RUNTIME_DIR/battery-display" ]] && break
    kill -0 "$weston_pid" 2>/dev/null || { cat "$work/weston.log" >&2; exit 1; }
    sleep .02
done
if ! QT_QPA_PLATFORM=wayland WAYLAND_DISPLAY=battery-display timeout 20 qs -p "$work/shell.qml" > "$work/log" 2>&1 \
    || ! grep -q BATTERY-PANEL-PROBE-PASS "$work/log"; then
    cat "$work/log" >&2
    exit 1
fi
[[ $(wc -l < "$XDG_RUNTIME_DIR/launched") -eq 1 ]]
grep -Fxq "app --label btop -- bash -c kitty 'btop'" "$XDG_RUNTIME_DIR/launched"
echo 'battery-panel: charge levels, telemetry, theme switching, keyboard dismissal and btop passed'
