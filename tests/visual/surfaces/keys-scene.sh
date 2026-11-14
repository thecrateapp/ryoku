#!/usr/bin/env bash
# Render Kit and its first-boot hint (scenes/keys.qml) from this checkout in
# both looks, with no package installed:
#   tests/visual/surfaces/keys-scene.sh SCENE OUT_DIR
# The scene's root holds copies of quickshell/keys and quickshell/keys-hint and
# the checkout's kit linked entry by entry: Wm.qml reads Quickshell.WindowManager,
# which aborts the process under the offscreen platform, so the scene gets a copy
# with those two Wayland reads emptied. Each look runs offscreen in its own
# scratch HOME and XDG dirs with no session bus or compositor in reach (Kit's
# phone tab calls `qs ipc`, which then finds nothing): crate reads
# hub-fixture/crate.json, stock a plain shell.json. Writes OUT_DIR/SCENE-crate.png
# and OUT_DIR/SCENE-stock.png.
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd "$here/../../.." && pwd)
scene=${1:?usage: keys-scene.sh SCENE OUT_DIR}
out=${2:?usage: keys-scene.sh SCENE OUT_DIR}
[ -f "$here/scenes/$scene.qml" ] || { echo "keys-scene.sh: no scene $scene" >&2; exit 2; }
mkdir -p "$out"
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT

mkdir -p "$work/root/Ryoku/Ui/Singletons"
for entry in "$repo/ryoku/ui"/*; do
  [ "$(basename "$entry")" = Singletons ] || ln -s "$entry" "$work/root/Ryoku/Ui/$(basename "$entry")"
done
for entry in "$repo/ryoku/ui/Singletons"/*; do
  [ "$(basename "$entry")" = Wm.qml ] || ln -s "$entry" "$work/root/Ryoku/Ui/Singletons/$(basename "$entry")"
done
sed -e 's/WindowManager\.windowsets/[]/' -e 's/ToplevelManager\.toplevels/null/' \
  "$repo/ryoku/ui/Singletons/Wm.qml" >"$work/root/Ryoku/Ui/Singletons/Wm.qml"
cp -a "$repo/ryoku/shell/quickshell/keys" "$work/root/keys"
cp -a "$repo/ryoku/shell/quickshell/keys-hint" "$work/root/keys-hint"
cp "$here/scenes/$scene.qml" "$work/root/shell.qml"

status=0
for look in crate stock; do
  home="$work/home-$look"
  mkdir -p "$home/.config/ryoku" "$home/.cache" "$home/.local/share" "$home/.local/state" "$home/run"
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
  else
    echo '{"language":"en","theme":{"motion":{"reduce":true}}}' > "$home/.config/ryoku/shell.json"
  fi
  echo '{"followWallpaper":false}' > "$home/.config/ryoku/theme.json"
  png="$out/$scene-$look.png"
  rm -f "$png"
  env -u WAYLAND_DISPLAY -u DISPLAY -u DBUS_SESSION_BUS_ADDRESS -u HYPRLAND_INSTANCE_SIGNATURE -u RYOKU_SHELL_DIR \
    FONTCONFIG_FILE="$home/fonts.conf" HOME="$home" XDG_CONFIG_HOME="$home/.config" XDG_CACHE_HOME="$home/.cache" \
    XDG_DATA_HOME="$home/.local/share" XDG_STATE_HOME="$home/.local/state" XDG_RUNTIME_DIR="$home/run" \
    QT_QPA_PLATFORM=offscreen RYOKU_I18N_DIR="$repo/ryoku/i18n/catalog" \
    BENCH_OUT="$png" BENCH_CRATE=$([ "$look" = crate ] && echo 1 || echo 0) \
    QML_IMPORT_PATH="$work/root" QML2_IMPORT_PATH="$work/root" \
    timeout 60 quickshell -p "$work/root/shell.qml" >"$out/$scene-$look.log" 2>&1 || true
  if [ -s "$png" ]; then echo "wrote $png"; else
    echo "keys-scene.sh: no $look image; see $out/$scene-$look.log" >&2
    grep -E "ERROR|caused by" "$out/$scene-$look.log" | head -6 >&2 || true
    status=1
  fi
done
exit $status
