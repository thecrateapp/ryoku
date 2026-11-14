#!/usr/bin/env bash
# Render one app scene (scenes/app-*.qml) from this checkout in both looks:
#   tests/visual/surfaces/app-scene.sh SCENE OUT_DIR
# The scene's root links the checkout's kit (Ryoku.Ui) and the four Wave 4 apps
# under their names, so a scene imports "ryostore", "ryovm", "welcome" or
# "ryoshot" as a probe does, and the plugin kit as Ryoku.PluginKit. Each look reads its own config: crate is the Crate
# theme from hub-fixture/crate.json, stock a plain shell.json. A scene's
# scenes/SCENE.bin directory, when present, leads PATH with fake commands.
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd "$here/../../.." && pwd)
scene=${1:?usage: app-scene.sh SCENE OUT_DIR}
out=${2:?usage: app-scene.sh SCENE OUT_DIR}
mkdir -p "$out"
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
mkdir -p "$work/root/Ryoku"
ln -s "$repo/ryoku/ui" "$work/root/Ryoku/Ui"
ln -s "$repo/ryoku/shell/quickshell/plugins/kit" "$work/root/Ryoku/PluginKit"
ln -s "$repo/ryoku/apps/ryostore/quickshell" "$work/root/ryostore"
ln -s "$repo/ryoku/apps/ryovm/quickshell" "$work/root/ryovm"
ln -s "$repo/ryoku/shell/quickshell/welcome" "$work/root/welcome"
ln -s "$repo/ryoku/shell/quickshell/ryoshot" "$work/root/ryoshot"
cp "$here/scenes/$scene.qml" "$work/root/shell.qml"
path=$PATH
[ -d "$here/scenes/$scene.bin" ] && path="$here/scenes/$scene.bin:$PATH"
status=0
for look in crate stock; do
  cfg="$work/config-$look/ryoku"
  mkdir -p "$cfg"
  if [ "$look" = crate ]; then
    cp "$here/hub-fixture/crate.json" "$cfg/shell.json"
  else
    echo '{"language":"en","theme":{"motion":{"reduce":true}}}' > "$cfg/shell.json"
  fi
  echo '{"followWallpaper":false}' > "$cfg/theme.json"
  png="$out/$scene-$look.png"
  rm -f "$png"
  PATH="$path" XDG_CONFIG_HOME="$work/config-$look" RYOKU_I18N_DIR="$repo/ryoku/i18n/catalog" \
    BENCH_OUT="$png" BENCH_CRATE=$([ "$look" = crate ] && echo 1 || echo 0) \
    QML_IMPORT_PATH="$work/root" QML2_IMPORT_PATH="$work/root" \
    timeout 60 quickshell -p "$work/root/shell.qml" >"$out/$scene-$look.log" 2>&1 || true
  if [ -s "$png" ]; then echo "wrote $png"; else
    echo "app-scene.sh: no $look image; see $out/$scene-$look.log" >&2
    grep -E "ERROR|caused by" "$out/$scene-$look.log" | head -6 >&2 || true
    status=1
  fi
done
exit $status
