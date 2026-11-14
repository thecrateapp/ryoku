#!/usr/bin/env bash
# The plugin kit (Ryoku.PluginKit) on the shell kit in the crate and the stock
# look, both loaded from this checkout against a plain config.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT
mkdir -p "$work/Ryoku" "$work/config/ryoku" "$work/runtime"
chmod 700 "$work/runtime"
echo '{"language":"en"}' > "$work/config/ryoku/shell.json"
ln -s "$repo/ryoku/ui" "$work/Ryoku/Ui"
ln -s "$repo/ryoku/shell/quickshell/plugins/kit" "$work/Ryoku/PluginKit"
cp "$here/pluginkit-kit-probe.qml" "$work/shell.qml"
QT_QPA_PLATFORM=offscreen XDG_CONFIG_HOME="$work/config" XDG_RUNTIME_DIR="$work/runtime" \
RYOKU_I18N_DIR="$repo/ryoku/i18n/catalog" QML2_IMPORT_PATH="$work" QML_IMPORT_PATH="$work" \
    timeout 30 qs -p "$work/shell.qml" >"$work/log" 2>&1 || true
if ! grep -q PLUGINKIT-KIT-PROBE-PASS "$work/log" || grep -Eq 'TypeError|ReferenceError' "$work/log"; then
    echo "pluginkit-kit-probe: FAILED" >&2
    sed -n '1,60p' "$work/log" >&2
    exit 1
fi
echo "pluginkit-kit-probe: plugin Theme, labels, ticks, card and the kit re-exports passed in both looks"
