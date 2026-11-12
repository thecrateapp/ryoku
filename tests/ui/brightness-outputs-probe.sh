#!/usr/bin/env bash
# Run QS against three nested Wayland outputs and private, delayed brightness devices.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
work="$(mktemp -d)"
compositors=()
cleanup() {
    for pid in "${compositors[@]}"; do kill "$pid" 2>/dev/null || true; done
    wait || true
    rm -rf -- "$work"
}
trap cleanup EXIT
export HOME="$work/home" XDG_RUNTIME_DIR="$work/runtime" XDG_CONFIG_HOME="$work/config"
export XDG_CACHE_HOME="$work/cache" XDG_DATA_HOME="$work/data" XDG_STATE_HOME="$work/state"
export QML_IMPORT_PATH="$work/imports" QT_QUICK_BACKEND=software PATH="$work/bin:$PATH"
unset WAYLAND_DISPLAY DISPLAY DBUS_SESSION_BUS_ADDRESS
bar=modules/bar/barstyles/qsbar
stage="$work/shell/$bar"
mkdir -p "$HOME" "$XDG_RUNTIME_DIR" "$XDG_CONFIG_HOME/ryoku" "$stage" "$work/bin" "$work/imports/Ryoku" \
    "$work/imports/shell/services"
chmod 700 "$XDG_RUNTIME_DIR"
ln -s "$repo/ryoku/ui" "$work/imports/Ryoku/Ui"
for group in modules panels; do
    cp -r "$repo/ryoku/shell/quickshell/shell/$bar/$group" "$stage/$group"
done
cp "$here/brightness-outputs-probe.qml" "$work/shell/shell.qml"
echo '{"themeStyle":{"controls":"crate"}}' > "$XDG_CONFIG_HOME/ryoku/shell.json"
printf 'module shell.services\nsingleton Perf 1.0 Perf.qml\n' > "$work/imports/shell/services/qmldir"
printf 'pragma Singleton\nimport QtQuick\nQtObject { readonly property int msaa: 0 }\n' > "$work/imports/shell/services/Perf.qml"

echo 23 > "$XDG_RUNTIME_DIR/wayland0"
echo 71 > "$XDG_RUNTIME_DIR/wayland1"
cat > "$work/bin/ryoku-brightness-output" <<'HELPER'
#!/usr/bin/env bash
set -euo pipefail
echo "$*" >> "$XDG_RUNTIME_DIR/commands"
case "$2" in wayland0|wayland1) ;; *) exit 1;; esac
device="$XDG_RUNTIME_DIR/$2"
[[ -f "$device" ]] || exit 1
case "$1" in
    get) ;;
    set) sleep .22; echo "$3" > "$device" ;;
    step)
        value=$(<"$device")
        if [[ "$3" == up ]]; then value=$((value+5)); else value=$((value-5)); fi
        echo "$value" > "$device"
        ;;
    *) exit 1 ;;
esac
cat "$device"
HELPER
chmod +x "$work/bin/ryoku-brightness-output"

start_weston() {
    local socket="$1"
    shift
    weston --socket="$socket" --shell=kiosk-shell.so --no-config --renderer=pixman "$@" \
        > "$work/$socket.log" 2>&1 &
    local pid=$!
    compositors=("$pid" "${compositors[@]}")
    for _ in {1..150}; do
        [[ -S "$XDG_RUNTIME_DIR/$socket" ]] && return 0
        kill -0 "$pid" 2>/dev/null || break
        sleep .02
    done
    cat "$work/$socket.log" >&2
    return 1
}
start_weston parent --backend=headless --width=1440 --height=400
start_weston display --backend=wayland --display=parent --output-count=3 --width=480 --height=350
if ! QT_QPA_PLATFORM=wayland WAYLAND_DISPLAY=display timeout 20 qs -p "$work/shell/shell.qml" > "$work/log" 2>&1 \
    || ! grep -q BRIGHTNESS-OUTPUTS-PROBE-PASS "$work/log"; then
    cat "$work/log" >&2
    exit 1
fi
# Optimistic UI values alone do not prove which connector received each write.
[[ $(<"$XDG_RUNTIME_DIR/wayland0") == 23 && $(<"$XDG_RUNTIME_DIR/wayland1") == 86 ]]
grep -Fxq 'get wayland2' "$XDG_RUNTIME_DIR/commands"
if grep -Eq '^(set|step) wayland2 |^set wayland1 19$|^step wayland1 down$' "$XDG_RUNTIME_DIR/commands"; then exit 1; fi
echo "brightness-outputs: indicators, wheel, panel routing, queued writes, unsupported output and reconnection passed"
