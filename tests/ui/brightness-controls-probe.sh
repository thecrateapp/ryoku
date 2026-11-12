#!/usr/bin/env bash
# Exercise the Crate popup controls with Qt input events and a simulated level.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT
mkdir -p "$work/imports/Ryoku" "$work/config" "$work/runtime"
chmod 700 "$work/runtime"
ln -s "$repo/ryoku/ui" "$work/imports/Ryoku/Ui"
ln -s "$repo/ryoku/shell/quickshell/shell/modules/bar/barstyles/qsbar/panels" "$work/panels"
cp "$here/brightness-controls-probe.qml" "$work/shell.qml"
if ! env QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
    XDG_CONFIG_HOME="$work/config" XDG_RUNTIME_DIR="$work/runtime" \
    QML_IMPORT_PATH="$work/imports" timeout 15 qs -p "$work/shell.qml" >"$work/log" 2>&1 \
    || ! grep -q BRIGHTNESS-CONTROLS-PROBE-PASS "$work/log"; then
    cat "$work/log" >&2
    exit 1
fi
echo "brightness-controls: pointer, keyboard, step actions and close passed"
