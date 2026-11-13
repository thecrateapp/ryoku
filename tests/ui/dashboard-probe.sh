#!/usr/bin/env bash
# Load the QS Bar's crate dashboard body offscreen with a stand-in panel.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT
mkdir -p "$work/Ryoku" "$work/config/ryoku" "$work/runtime"
echo '{}' > "$work/config/ryoku/shell.json"
export RYOKU_I18N_DIR="$repo/ryoku/i18n/catalog"
chmod 700 "$work/runtime"
ln -s "${RYOKU_UI_SOURCE:-$repo/ryoku/ui}" "$work/Ryoku/Ui"
panels="$repo/ryoku/shell/quickshell/shell/modules/bar/barstyles/qsbar/panels"
cp "$panels/CrateDashboardDetails.qml" "$panels/CrateResourceHeader.qml" "$work/"
cp "$here/dashboard-probe.qml" "$work/shell.qml"
QT_QPA_PLATFORM=offscreen XDG_CONFIG_HOME="$work/config" XDG_RUNTIME_DIR="$work/runtime" \
QML2_IMPORT_PATH="$work" timeout 20 qs -p "$work/shell.qml" >"$work/log" 2>&1 || true
if ! grep -q DASHBOARD-PROBE-PASS "$work/log"; then
    echo "dashboard-probe: FAILED" >&2
    sed -n '1,80p' "$work/log" >&2
    exit 1
fi
echo "dashboard-probe: month grid, today and picked day, month navigation, weather states, hourly curve and close passed"
