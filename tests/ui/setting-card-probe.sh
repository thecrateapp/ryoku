#!/usr/bin/env bash
# SettingCard's stock sheet and crate flat group, and folding in both.
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
cp "$here/setting-card-probe.qml" "$work/shell.qml"
QT_QPA_PLATFORM=offscreen XDG_CONFIG_HOME="$work/config" XDG_RUNTIME_DIR="$work/runtime" \
QML2_IMPORT_PATH="$work" timeout 20 qs -p "$work/shell.qml" >"$work/log" 2>&1 || true
if ! grep -q SETTING-CARD-PROBE-PASS "$work/log"; then
    echo "setting-card-probe: FAILED" >&2
    sed -n '1,80p' "$work/log" >&2
    exit 1
fi
echo "setting-card-probe: the stock sheet, the crate flat group and folding passed"
