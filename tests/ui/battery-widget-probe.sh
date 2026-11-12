#!/usr/bin/env bash
# Exercise the bar indicator in both control styles against a changing device.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
modules="$(realpath "${1:-$repo/ryoku/shell/quickshell/shell/modules/bar/barstyles/qsbar/modules}")"
kit="$(realpath "${2:-$repo/ryoku/ui}")"
work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT
mkdir -p "$work/imports/shell/services" "$work/imports/Ryoku" "$work/config" "$work/runtime"
chmod 700 "$work/runtime"
ln -s "$modules" "$work/modules"
ln -s "$kit" "$work/imports/Ryoku/Ui"
printf 'module shell.services\nsingleton Perf 1.0 Perf.qml\n' > "$work/imports/shell/services/qmldir"
printf 'pragma Singleton\nimport QtQuick\nQtObject { readonly property bool ambientMotion: false }\n' > "$work/imports/shell/services/Perf.qml"
cp "$here/battery-widget-probe.qml" "$work/shell.qml"
if ! env QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software QML_IMPORT_PATH="$work/imports" \
    XDG_CONFIG_HOME="$work/config" XDG_CACHE_HOME="$work/cache" XDG_RUNTIME_DIR="$work/runtime" \
    timeout 15 qs -p "$work/shell.qml" >"$work/log" 2>&1 || ! grep -q BATTERY-WIDGET-PROBE-PASS "$work/log"; then
    cat "$work/log" >&2
    exit 1
fi
echo "battery-widget: Solar levels, charging, full, low warning, tooltip, click, icon-only and stock passed"
