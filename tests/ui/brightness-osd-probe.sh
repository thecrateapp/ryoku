#!/usr/bin/env bash
# Check explicit key feedback and native backlight frames on independent OSD sources.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
work="$(mktemp -d)"
pid=
weston_pid=
cleanup() {
    if [[ $? != 0 ]]; then cat "$work/log" >&2; fi
    if [[ -n $pid ]]; then kill "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true; fi
    if [[ -n $weston_pid ]]; then kill "$weston_pid" 2>/dev/null || true; wait "$weston_pid" 2>/dev/null || true; fi
    rm -rf -- "$work"
}
trap cleanup EXIT
mkdir -p "$work/imports/Ryoku" "$work/config" "$work/runtime" "$work/imports/shell/services"
chmod 700 "$work/runtime"
ln -s "$repo/ryoku/ui" "$work/imports/Ryoku/Ui"
services="$work/imports/shell/services"
ln -s "$repo/ryoku/shell/quickshell/shell/services/OsdFeed.qml" "$services/OsdFeed.qml"
cat > "$services/qmldir" <<'QML'
module shell.services
singleton OsdFeed OsdFeed.qml
singleton Config Config.qml
singleton KeyboardLayout KeyboardLayout.qml
singleton Motion Motion.qml
QML
printf 'pragma Singleton\nimport QtQuick\nQtObject { property var qsbar: ({}) }\n' > "$services/Config.qml"
printf 'pragma Singleton\nimport QtQuick\nQtObject { property string variant: "" }\n' > "$services/KeyboardLayout.qml"
printf 'pragma Singleton\nimport QtQuick\nQtObject { property int osdHide: 4000 }\n' > "$services/Motion.qml"
mkdir -p "$work/osd"
ln -s "$repo/ryoku/shell/quickshell/shell/modules/osd/OsdSource.qml" "$work/osd/OsdSource.qml"
cp "$here/brightness-osd-probe.qml" "$work/shell.qml"
export QT_QPA_PLATFORM=wayland QT_QUICK_BACKEND=software
export XDG_CACHE_HOME="$work/cache" XDG_RUNTIME_DIR="$work/runtime" XDG_CONFIG_HOME="$work/config" QML_IMPORT_PATH="$work/imports"
export QML2_IMPORT_PATH="$work/imports"
export WAYLAND_DISPLAY=osd-probe
weston --socket="$WAYLAND_DISPLAY" --shell=kiosk-shell.so --no-config --backend=headless --renderer=pixman >"$work/weston.log" 2>&1 &
weston_pid=$!
for _ in {1..40}; do
    [[ ! -S $work/runtime/$WAYLAND_DISPLAY ]] || break
    sleep .05
done
qs -p "$work/shell.qml" >"$work/log" 2>&1 &
pid=$!
call() { qs -p "$work/shell.qml" ipc call -- "$@"; }
for _ in {1..70}; do
    if [[ $(call probe state 2>/dev/null || true) == "off0 off0 off0" ]]; then break; fi
    if ! kill -0 "$pid" 2>/dev/null; then cat "$work/log" >&2; exit 1; fi
    sleep .1
done
expect() {
    local actual
    actual=$(call probe state)
    [[ $actual == "$1" ]] || { echo "expected [$1], got [$actual]" >&2; exit 1; }
}
expect "off0 off0 off0"
[[ $(call osd show volume) == "competitor/volume" ]]
call brightnessOsd show DP-3 41
expect "off0 on41 off0"
call brightnessOsd show DP-5 72
expect "off0 on41 on72"
call brightnessOsd show DP-5 101
# The first frame is retained socket state, even when its sequence is non-zero.
call probe watched DP-3 7 99
call probe watched "" 8 99
expect "off0 on41 on72"
# Once the legacy hardware source is armed, its events reach its recorded connector.
sleep 1
call probe watched eDP-2 9 62
[[ $(call probe state) == "on62 "* ]] || exit 1
call brightnessOsd show DP-5 55
[[ $(call probe state) == "on62 "*" on55" ]] || exit 1
echo 'brightness-osd: explicit and native events routed to their own outputs'
