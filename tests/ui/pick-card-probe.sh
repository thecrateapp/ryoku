#!/usr/bin/env bash
# PickCard's crate pick grammar and the stock gallery tile.
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
cp "$here/pick-card-probe.qml" "$work/shell.qml"
QT_QPA_PLATFORM=offscreen XDG_CONFIG_HOME="$work/config" XDG_RUNTIME_DIR="$work/runtime" \
QML2_IMPORT_PATH="$work" timeout 20 qs -p "$work/shell.qml" >"$work/log" 2>&1 || true
if ! grep -q PICK-CARD-PROBE-PASS "$work/log"; then
    echo "pick-card-probe: FAILED" >&2
    sed -n '1,80p' "$work/log" >&2
    exit 1
fi
echo "pick-card-probe: crate pick grammar, stock gallery tile and caller content passed"
