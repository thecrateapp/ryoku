#!/usr/bin/env bash
# Render the Ryoku.Ui kit gallery from this checkout in both looks:
#   tests/visual/kit-gallery/render.sh OUT_DIR
# writes OUT_DIR/kit-stock.png and OUT_DIR/kit-crate.png (controls "crate").
# It opens a floating window for about two seconds per look.
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd "$here/../../.." && pwd)
out=${1:?usage: render.sh OUT_DIR}
mkdir -p "$out"
mods=$(mktemp -d)
trap 'rm -r -- "$mods"' EXIT
mkdir -p "$mods/Ryoku"
ln -s "$repo/ryoku/ui" "$mods/Ryoku/Ui"
for look in stock crate; do
  KIT_CRATE=$([ "$look" = crate ] && echo 1 || echo 0) KIT_OUT="$out/kit-$look.png" \
    QML_IMPORT_PATH="$mods" timeout 30 quickshell -p "$here/shell.qml" >/dev/null 2>&1 || true
  [ -s "$out/kit-$look.png" ] && echo "wrote $out/kit-$look.png"
done
