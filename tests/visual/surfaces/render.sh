#!/usr/bin/env bash
# Render one shell surface from this checkout, with no package installed:
#   tests/visual/surfaces/render.sh SCENE OUT_DIR
# loads scenes/SCENE.qml against the checkout's kit (ryoku/ui), the Ryoku.Blobs
# build and shell tree (ryoku/shell/quickshell), in the crate and the stock look,
# and writes OUT_DIR/SCENE-crate.png and OUT_DIR/SCENE-stock.png. A scene is a
# ShellRoot whose `sheet` item is grabbed after BENCH_WAIT ms (default 1500). It
# runs from a scratch config root that links every entry of the shell's root but
# its shell.qml, since Quickshell refuses relative imports outside the config
# root: a scene imports "modules/<name>" as the shell does.
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd "$here/../../.." && pwd)
scene=${1:?usage: render.sh SCENE OUT_DIR}
out=${2:?usage: render.sh SCENE OUT_DIR}
[ -f "$here/scenes/$scene.qml" ] || { echo "render.sh: no scene $scene" >&2; exit 2; }
mkdir -p "$out"
plugin="$repo/ryoku/shell/plugin"
build="${RYOKU_BLOBS_BUILD:-$plugin/build}"
cmake -S "$plugin" -B "$build" -G Ninja -DCMAKE_BUILD_TYPE=Release >/dev/null
cmake --build "$build" >/dev/null
mods=$(mktemp -d)
trap 'rm -r -- "$mods"' EXIT
mkdir -p "$mods/Ryoku" "$mods/root"
ln -s "$repo/ryoku/ui" "$mods/Ryoku/Ui"
for entry in "$repo/ryoku/shell/quickshell/shell"/*; do
  [ "$(basename "$entry")" = shell.qml ] || ln -s "$entry" "$mods/root/$(basename "$entry")"
done
cp "$here/scenes/$scene.qml" "$mods/root/shell.qml"
ln -s "$build/qml/Ryoku/Blobs" "$mods/Ryoku/Blobs"
status=0
for look in crate stock; do
  png="$out/$scene-$look.png"
  rm -f "$png"
  BENCH_OUT="$png" BENCH_CRATE=$([ "$look" = crate ] && echo 1 || echo 0) \
    QML_IMPORT_PATH="$mods:$repo/ryoku/shell/quickshell" \
    timeout 60 quickshell -p "$mods/root/shell.qml" >"$out/$scene-$look.log" 2>&1 || true
  if [ -s "$png" ]; then echo "wrote $png"; else
    echo "render.sh: no $look image; see $out/$scene-$look.log" >&2
    grep -E "ERROR|caused by" "$out/$scene-$look.log" | head -6 >&2 || true
    status=1
  fi
done
exit $status
