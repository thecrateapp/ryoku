#!/usr/bin/env bash
# The Welcome on the kit (step Tabs and Beam, PageHeader, PickCard) in the
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
cp -a "$repo/ryoku/shell/quickshell/welcome" "$work/welcome"
cp "$here/welcome-kit-probe.qml" "$work/probe.qml"
QT_QPA_PLATFORM=offscreen XDG_CONFIG_HOME="$work/config" XDG_RUNTIME_DIR="$work/runtime" \
RYOKU_I18N_DIR="$repo/ryoku/i18n/catalog" QML2_IMPORT_PATH="$work" QML_IMPORT_PATH="$work" \
    timeout 30 qs -p "$work/probe.qml" >"$work/log" 2>&1 || true
if ! grep -q WELCOME-KIT-PROBE-PASS "$work/log" || grep -Eq 'TypeError|ReferenceError' "$work/log"; then
    echo "welcome-kit-probe: FAILED" >&2
    sed -n '1,60p' "$work/log" >&2
    exit 1
fi
echo "welcome-kit-probe: step rail, page title and bar cards passed in both looks"
