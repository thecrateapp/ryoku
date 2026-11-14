#!/usr/bin/env bash
# Render ryopin's pinned cards (scenes/ryopin.qml) from this checkout in both
# looks, with no package installed:
#   tests/visual/surfaces/ryopin-scene.sh SCENE OUT_DIR
# A pin is a layer window, which needs a compositor, so the scene hosts the
# PinCard Items it draws. The scene's root holds a copy of quickshell/ryopin and
# the checkout's kit linked entry by entry, with Wm.qml's two Wayland reads
# emptied as keys-scene.sh does. The pinned shot is a crop of a bundled
# wallpaper, the desktop behind it another. Each look runs offscreen in its own
# scratch HOME and XDG dirs with no session bus or compositor in reach: crate
# reads hub-fixture/crate.json, stock a plain shell.json. Writes
# OUT_DIR/SCENE-crate.png and OUT_DIR/SCENE-stock.png.
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd "$here/../../.." && pwd)
scene=${1:?usage: ryopin-scene.sh SCENE OUT_DIR}
out=${2:?usage: ryopin-scene.sh SCENE OUT_DIR}
[ -f "$here/scenes/$scene.qml" ] || { echo "ryopin-scene.sh: no scene $scene" >&2; exit 2; }
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
cp -a "$repo/ryoku/shell/quickshell/ryopin" "$work/root/ryopin"
walls="$repo/ryoku/assets/wallpapers"
magick "$walls/cornelius-dammrich-2003-mainshot-crop-hd-04.jpg" -resize 1200x640^ -gravity center -extent 1200x640 "$work/backdrop.png"
magick "$walls/138032536_p0.jpg" -resize 960x -gravity center -crop 960x620+0+0 +repage "$work/shot.png"
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
    PIN_SHOT="$work/shot.png" PIN_BACKDROP="$work/backdrop.png" BENCH_OUT="$png" BENCH_CRATE=$([ "$look" = crate ] && echo 1 || echo 0) \
    QML_IMPORT_PATH="$work/root" QML2_IMPORT_PATH="$work/root" \
    timeout 60 quickshell -p "$work/root/shell.qml" >"$out/$scene-$look.log" 2>&1 || true
  if [ -s "$png" ]; then echo "wrote $png"; else
    echo "ryopin-scene.sh: no $look image; see $out/$scene-$look.log" >&2
    grep -E "ERROR|caused by" "$out/$scene-$look.log" | head -6 >&2 || true
    status=1
  fi
done
exit $status
