#!/usr/bin/env bash
# Load the QS Bar's crate notification list offscreen with a stand-in panel.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT
mkdir -p "$work/Ryoku" "$work/config" "$work/runtime"
chmod 700 "$work/runtime"
ln -s "${RYOKU_UI_SOURCE:-$repo/ryoku/ui}" "$work/Ryoku/Ui"
cp "$repo/ryoku/shell/quickshell/shell/modules/bar/barstyles/qsbar/panels/CrateNotificationList.qml" "$work/"
cp "$repo/ryoku/shell/quickshell/shell/modules/bar/barstyles/qsbar/panels/CrateResourceHeader.qml" "$work/"
cp "$here/notification-list-probe.qml" "$work/shell.qml"
QT_QPA_PLATFORM=offscreen XDG_CONFIG_HOME="$work/config" XDG_RUNTIME_DIR="$work/runtime" \
QML2_IMPORT_PATH="$work" timeout 20 qs -p "$work/shell.qml" >"$work/log" 2>&1 || true
if ! grep -q NOTIFICATION-LIST-PROBE-PASS "$work/log"; then
    echo "notification-list-probe: FAILED" >&2
    sed -n '1,80p' "$work/log" >&2
    exit 1
fi
echo "notification-list-probe: count, cards, open, dismiss, clear all, scroll cap, empty state and close passed"
