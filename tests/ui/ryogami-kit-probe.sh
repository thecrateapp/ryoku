#!/usr/bin/env bash
# The Ryogami picker on the kit, in the crate and the stock look. Builds the
# picker module (RYOGAMI_PICKER_BUILD, default the gitignored picker/build) and
# loads it against this checkout's kit from scratch config, cache and runtime
# dirs; no daemon runs, so every setting sits at its default. Wm.qml reads
# Quickshell.WindowManager, which aborts under the offscreen platform, so the
# probe's kit links every entry but takes a copy of it with those reads emptied.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
picker="$repo/ryoku/shell/ryogami/picker"
build="${RYOGAMI_PICKER_BUILD:-$picker/build}"
cmake -S "$picker" -B "$build" -G Ninja -DCMAKE_BUILD_TYPE=Release >/dev/null 2>&1
cmake --build "$build" -j "${RYOGAMI_PICKER_JOBS:-4}" >/dev/null
work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT
mkdir -p "$work/qml/Ryoku/Ui/Singletons" "$work/config/ryoku" "$work/cache" "$work/data" "$work/state" "$work/runtime"
chmod 700 "$work/runtime"
for entry in "$repo/ryoku/ui"/*; do
    [ "$(basename "$entry")" = Singletons ] || ln -s "$entry" "$work/qml/Ryoku/Ui/$(basename "$entry")"
done
for entry in "$repo/ryoku/ui/Singletons"/*; do
    [ "$(basename "$entry")" = Wm.qml ] || ln -s "$entry" "$work/qml/Ryoku/Ui/Singletons/$(basename "$entry")"
done
sed -e 's/WindowManager\.windowsets/[]/' -e 's/ToplevelManager\.toplevels/null/' \
    "$repo/ryoku/ui/Singletons/Wm.qml" >"$work/qml/Ryoku/Ui/Singletons/Wm.qml"
ln -s "$build/qml/Ryoku/Ryogami" "$work/qml/Ryoku/Ryogami"
echo '{"language":"en"}' > "$work/config/ryoku/shell.json"
cp "$here/ryogami-kit-probe.qml" "$work/shell.qml"
QT_QPA_PLATFORM=offscreen XDG_CONFIG_HOME="$work/config" XDG_CACHE_HOME="$work/cache" \
XDG_DATA_HOME="$work/data" XDG_STATE_HOME="$work/state" XDG_RUNTIME_DIR="$work/runtime" \
RYOKU_I18N_DIR="$repo/ryoku/i18n/catalog" QML2_IMPORT_PATH="$work/qml" QML_IMPORT_PATH="$work/qml" \
    timeout 40 qs -p "$work/shell.qml" >"$work/log" 2>&1 || true
if ! grep -q RYOGAMI-KIT-PROBE-PASS "$work/log" || grep -Eq 'TypeError|ReferenceError' "$work/log"; then
    echo "ryogami-kit-probe: FAILED" >&2
    grep -Ev 'propagateSizeHints|window masks' "$work/log" | sed -n '1,60p' >&2
    exit 1
fi
echo "ryogami-kit-probe: theme roles, Beam, Sw, label, chips, close, Seg and tabs passed in both looks"
