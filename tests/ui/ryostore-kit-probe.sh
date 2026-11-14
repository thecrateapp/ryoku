#!/usr/bin/env bash
# Ryostore on the kit (Beam, keyed Tabs, PickCard, Chip, Field, IconButton) in
# the crate and the stock look, against a plain config.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT
mkdir -p "$work/Ryoku" "$work/bin" "$work/config/ryoku" "$work/runtime"
chmod 700 "$work/runtime"
echo '{"language":"en"}' > "$work/config/ryoku/shell.json"
ln -s "$repo/ryoku/ui" "$work/Ryoku/Ui"
cp -a "$repo/ryoku/apps/ryostore/quickshell" "$work/ryostore"
cp "$here/ryostore-kit-probe.qml" "$work/probe.qml"
printf '%s\n' '#!/usr/bin/env bash' 'echo "{\"categories\":[],\"items\":[],\"offline\":false}"' > "$work/bin/ryostore"
chmod +x "$work/bin/ryostore"
PATH="$work/bin:$PATH" QT_QPA_PLATFORM=offscreen XDG_CONFIG_HOME="$work/config" XDG_RUNTIME_DIR="$work/runtime" \
RYOKU_I18N_DIR="$repo/ryoku/i18n/catalog" QML2_IMPORT_PATH="$work" QML_IMPORT_PATH="$work" \
    timeout 30 qs -p "$work/probe.qml" >"$work/log" 2>&1 || true
if ! grep -q RYOSTORE-KIT-PROBE-PASS "$work/log" || grep -Eq 'TypeError|ReferenceError' "$work/log"; then
    echo "ryostore-kit-probe: FAILED" >&2
    grep -v "AnimatedImage\|pipewire\|PulseAudio" "$work/log" | sed -n '1,60p' >&2
    exit 1
fi
echo "ryostore-kit-probe: beam, tabs, pick cards, tags, fields and links passed in both looks"
