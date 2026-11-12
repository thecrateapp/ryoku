#!/usr/bin/env bash
# Render the Controls panel from this checkout, with no package installed:
#   tests/visual/controls-bench/render.sh OUT_DIR
# writes OUT_DIR/controls.png. It rebuilds the Ryoku.Blobs plugin incrementally,
# then loads the kit (ryoku/ui), the plugin build and the shell tree
# (ryoku/shell/quickshell) ahead of the installed copies, and opens a floating
# window for BENCH_WAIT ms (default 4000). BENCH_CRATE=1 or 0 forces the crate
# or the stock look; unset, it follows the active theme.
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd "$here/../../.." && pwd)
out=${1:?usage: render.sh OUT_DIR}
mkdir -p "$out"
plugin="$repo/ryoku/shell/plugin"
build="${RYOKU_BLOBS_BUILD:-$plugin/build}"
cmake -S "$plugin" -B "$build" -G Ninja -DCMAKE_BUILD_TYPE=Release >/dev/null
cmake --build "$build" >/dev/null
mods=$(mktemp -d)
trap 'rm -r -- "$mods"' EXIT
mkdir -p "$mods/Ryoku"
ln -s "$repo/ryoku/ui" "$mods/Ryoku/Ui"
ln -s "$build/qml/Ryoku/Blobs" "$mods/Ryoku/Blobs"
rm -f "$out/controls.png"
BENCH_OUT="$out/controls.png" QML_IMPORT_PATH="$mods:$repo/ryoku/shell/quickshell" \
  timeout 60 quickshell -p "$here/shell.qml" >"$out/controls.log" 2>&1 || true
if [ -s "$out/controls.png" ]; then
  echo "wrote $out/controls.png"
else
  echo "render.sh: no image; see $out/controls.log" >&2
  grep -E "ERROR|caused by" "$out/controls.log" | head -8 >&2 || true
  exit 1
fi
