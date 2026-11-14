#!/usr/bin/env bash
# Load the QS Bar's crate media body offscreen with a stand-in panel.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT
mkdir -p "$work/Ryoku" "$work/config" "$work/runtime"
# Spanish runs the longest labels: every chip's text has to fit its chip.
mkdir -p "$work/config/ryoku"
echo '{"language":"es"}' > "$work/config/ryoku/shell.json"
export RYOKU_I18N_DIR="$repo/ryoku/i18n/catalog"
chmod 700 "$work/runtime"
ln -s "${RYOKU_UI_SOURCE:-$repo/ryoku/ui}" "$work/Ryoku/Ui"
# the body and its header in panels/, next to modules/ for the AudioOutput.js
# it imports (the output glyph)
qsbar="$repo/ryoku/shell/quickshell/shell/modules/bar/barstyles/qsbar"
mkdir -p "$work/panels" "$work/modules"
cp "$qsbar/panels/CrateMediaDetails.qml" "$qsbar/panels/CrateResourceHeader.qml" "$work/panels/"
cp "$qsbar/modules/AudioOutput.js" "$work/modules/"
cp "$here/media-details-probe.qml" "$work/shell.qml"
QT_QPA_PLATFORM=offscreen XDG_CONFIG_HOME="$work/config" XDG_RUNTIME_DIR="$work/runtime" \
QML2_IMPORT_PATH="$work" timeout 20 qs -p "$work/shell.qml" >"$work/log" 2>&1 || true
if ! grep -q MEDIA-DETAILS-PROBE-PASS "$work/log"; then
    echo "media-details-probe: FAILED" >&2
    sed -n '1,80p' "$work/log" >&2
    exit 1
fi
echo "media-details-probe: track, output, seek, transport, record, equalizer curve, switch, presets, idle state and close passed"
