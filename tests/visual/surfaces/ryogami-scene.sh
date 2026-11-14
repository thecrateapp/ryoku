#!/usr/bin/env bash
# Render one Ryogami picker scene (scenes/ryogami-*.qml) from this checkout in
# both looks, with no package installed and no daemon running:
#   tests/visual/surfaces/ryogami-scene.sh SCENE OUT_DIR
# Builds the picker module (RYOGAMI_PICKER_BUILD, default the gitignored
# picker/build), dumps the daemon's settings schema from its Go source, and
# serves it from ryogami-fake-daemon.py on a scratch runtime dir, so the chrome
# and the settings folio render with every key at its default. Each look runs
# in its own scratch HOME and XDG dirs: crate reads hub-fixture/crate.json and
# a colors.json in the Crate palette, stock a plain shell.json and no colors.json
# (the picker's own fallback palette). Writes OUT_DIR/SCENE-crate.png and
# OUT_DIR/SCENE-stock.png.
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd "$here/../../.." && pwd)
scene=${1:?usage: ryogami-scene.sh SCENE OUT_DIR}
out=${2:?usage: ryogami-scene.sh SCENE OUT_DIR}
[ -f "$here/scenes/$scene.qml" ] || { echo "ryogami-scene.sh: no scene $scene" >&2; exit 2; }
mkdir -p "$out"
picker="$repo/ryoku/shell/ryogami/picker"
build="${RYOGAMI_PICKER_BUILD:-$picker/build}"
cmake -S "$picker" -B "$build" -G Ninja -DCMAKE_BUILD_TYPE=Release >/dev/null
cmake --build "$build" -j "${RYOGAMI_PICKER_JOBS:-4}" >/dev/null

work=$(mktemp -d)
daemon_pid=""
cleanup() {
  [ -n "$daemon_pid" ] && kill "$daemon_pid" 2>/dev/null || true
  rm -rf -- "$work"
}
trap cleanup EXIT

# The schema, read from the daemon's Go source in a scratch copy: no daemon runs.
cp -a "$repo/ryoku/shell/ryogami/daemon" "$work/daemon"
cat >"$work/daemon/zz_schema_dump_test.go" <<'EOF'
package main

import (
	"encoding/json"
	"os"
	"testing"
)

func TestSchemaDump(t *testing.T) {
	b, err := json.Marshal(map[string]interface{}{"revision": settingsRevision, "keys": settingsSchema,
		"availability": map[string]bool{}, "caps": map[string]bool{}})
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(os.Getenv("SCHEMA_OUT"), b, 0o644); err != nil {
		t.Fatal(err)
	}
}
EOF
(cd "$work/daemon" && SCHEMA_OUT="$work/schema.json" go test -run TestSchemaDump -count=1 . >/dev/null)

# The kit, linked entry by entry: Wm.qml reads Quickshell.WindowManager, which
# aborts the process under the offscreen platform, so the scene gets a copy with
# those two Wayland reads emptied. Nothing in the checkout changes.
mkdir -p "$work/qml/Ryoku/Ui/Singletons"
for entry in "$repo/ryoku/ui"/*; do
  [ "$(basename "$entry")" = Singletons ] || ln -s "$entry" "$work/qml/Ryoku/Ui/$(basename "$entry")"
done
for entry in "$repo/ryoku/ui/Singletons"/*; do
  [ "$(basename "$entry")" = Wm.qml ] || ln -s "$entry" "$work/qml/Ryoku/Ui/Singletons/$(basename "$entry")"
done
sed -e 's/WindowManager\.windowsets/[]/' -e 's/ToplevelManager\.toplevels/null/' \
  "$repo/ryoku/ui/Singletons/Wm.qml" >"$work/qml/Ryoku/Ui/Singletons/Wm.qml"
ln -s "$build/qml/Ryoku/Ryogami" "$work/qml/Ryoku/Ryogami"
mkdir -p "$work/root"
cp "$here/scenes/$scene.qml" "$work/root/shell.qml"
# scenes/ryogami.bin leads PATH with stubs, so a dialog that shells out on open
# (ryoku-hub rice files, rice preflight) never reaches the real commands
path="$here/scenes/ryogami.bin:$PATH"

status=0
for look in crate stock; do
  home="$work/home-$look"
  mkdir -p "$home/.config/ryoku" "$home/.cache/ryoku" "$home/.local/share" "$home/.local/state" "$home/run"
  chmod 700 "$home/run"
  # fontconfig keeps finding the user's own fonts (a theme's display face lives
  # there) from the scratch HOME, its cache in the scratch dir
  cat >"$home/fonts.conf" <<FONTS
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
<fontconfig>
  <include ignore_missing="yes">/etc/fonts/fonts.conf</include>
  <dir>$HOME/.local/share/fonts</dir>
  <cachedir>$home/fc-cache</cachedir>
</fontconfig>
FONTS
  if [ "$look" = crate ]; then
    cp "$here/hub-fixture/crate.json" "$home/.config/ryoku/shell.json"
    python3 - "$here/hub-fixture/crate.json" "$home/.cache/ryoku/colors.json" <<'EOF'
import json, sys
palette = json.load(open(sys.argv[1]))["themePalette"]
palette["background"] = palette["surface"]
json.dump(palette, open(sys.argv[2], "w"))
EOF
  else
    echo '{"language":"en","theme":{"motion":{"reduce":true}}}' > "$home/.config/ryoku/shell.json"
  fi
  echo '{"followWallpaper":false}' > "$home/.config/ryoku/theme.json"
  python3 "$here/ryogami-fake-daemon.py" "$home/run/ryogami.sock" "$work/schema.json" &
  daemon_pid=$!
  for _ in $(seq 50); do [ -S "$home/run/ryogami.sock" ] && break; sleep 0.1; done
  png="$out/$scene-$look.png"
  rm -f "$png"
  PATH="$path" FONTCONFIG_FILE="$home/fonts.conf" HOME="$home" XDG_CONFIG_HOME="$home/.config" XDG_CACHE_HOME="$home/.cache" \
    XDG_DATA_HOME="$home/.local/share" XDG_STATE_HOME="$home/.local/state" XDG_RUNTIME_DIR="$home/run" \
    QT_QPA_PLATFORM=offscreen RYOKU_I18N_DIR="$repo/ryoku/i18n/catalog" \
    BENCH_OUT="$png" BENCH_CRATE=$([ "$look" = crate ] && echo 1 || echo 0) \
    QML_IMPORT_PATH="$work/qml" QML2_IMPORT_PATH="$work/qml" \
    timeout 60 quickshell -p "$work/root/shell.qml" >"$out/$scene-$look.log" 2>&1 || true
  kill "$daemon_pid" 2>/dev/null || true
  wait "$daemon_pid" 2>/dev/null || true
  daemon_pid=""
  if [ -s "$png" ]; then echo "wrote $png"; else
    echo "ryogami-scene.sh: no $look image; see $out/$scene-$look.log" >&2
    grep -E "ERROR|caused by" "$out/$scene-$look.log" | head -6 >&2 || true
    status=1
  fi
done
exit $status
