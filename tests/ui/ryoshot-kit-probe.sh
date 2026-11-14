#!/usr/bin/env bash
# Ryoshot on the kit (Beam sliders, kit IconButtons, the shared corner) in the
# crate and the stock look, against a plain config.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT
mkdir -p "$work/Ryoku" "$work/config/ryoku" "$work/runtime"
chmod 700 "$work/runtime"
echo '{"language":"en"}' > "$work/config/ryoku/shell.json"
ln -s "$repo/ryoku/ui" "$work/Ryoku/Ui"
cp -a "$repo/ryoku/shell/quickshell/ryoshot" "$work/ryoshot"
cp "$here/ryoshot-kit-probe.qml" "$work/probe.qml"
QT_QPA_PLATFORM=offscreen XDG_CONFIG_HOME="$work/config" XDG_RUNTIME_DIR="$work/runtime" \
RYOKU_I18N_DIR="$repo/ryoku/i18n/catalog" QML2_IMPORT_PATH="$work" QML_IMPORT_PATH="$work" \
    timeout 30 qs -p "$work/probe.qml" >"$work/log" 2>&1 || true
if ! grep -q RYOSHOT-KIT-PROBE-PASS "$work/log" || grep -Eq 'TypeError|ReferenceError' "$work/log"; then
    echo "ryoshot-kit-probe: FAILED" >&2
    sed -n '1,60p' "$work/log" >&2
    exit 1
fi
echo "ryoshot-kit-probe: beam sliders, kit buttons and corners passed in both looks"
