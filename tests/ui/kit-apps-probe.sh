#!/usr/bin/env bash
# The kit's Tabs entries, Field glyph and bipolar Beam in both looks.
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
cp "$here/kit-apps-probe.qml" "$work/shell.qml"
QT_QPA_PLATFORM=offscreen XDG_CONFIG_HOME="$work/config" XDG_RUNTIME_DIR="$work/runtime" \
QML2_IMPORT_PATH="$work" timeout 20 qs -p "$work/shell.qml" >"$work/log" 2>&1 || true
if ! grep -q KIT-APPS-PROBE-PASS "$work/log" || grep -Eq "TypeError|ReferenceError" "$work/log"; then
    echo "kit-apps-probe: FAILED" >&2
    sed -n "1,80p" "$work/log" >&2
    exit 1
fi
echo "kit-apps-probe: keyed tabs, field glyph and bipolar beam passed"
