#!/usr/bin/env bash
# beam-bounce-probe: an indeterminate Beam with bounce scans both ways inside its track.
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
cp "$here/beam-bounce-probe.qml" "$work/shell.qml"
QT_QPA_PLATFORM=offscreen XDG_CONFIG_HOME="$work/config" XDG_RUNTIME_DIR="$work/runtime" \
QML2_IMPORT_PATH="$work" timeout 20 qs -p "$work/shell.qml" >"$work/log" 2>&1 || true
if ! grep -q BEAM-BOUNCE-PROBE-PASS "$work/log"; then
    echo "beam-bounce-probe: FAILED" >&2
    sed -n '1,80p' "$work/log" >&2
    exit 1
fi
echo "beam-bounce-probe: every indeterminate Beam scans to both ends and back inside its track, head leading"
