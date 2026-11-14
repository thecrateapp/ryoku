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
# The Hub renders every routed page into hub-LOOK-SECTION.png; an app-* scene
# renders one of the Wave 4 apps through app-scene.sh; a ryogami scene renders the
# picker through ryogami-scene.sh (BENCH_OPEN picks the open surface); the keys
# scene renders Kit and its hint through keys-scene.sh; the ryopin scene renders
# pinned cards through ryopin-scene.sh. A scenes/SCENE.bin directory, when
# present, leads PATH with fake commands, as it does for the app scenes.
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(cd "$here/../../.." && pwd)
scene=${1:?usage: render.sh SCENE OUT_DIR}
out=${2:?usage: render.sh SCENE OUT_DIR}
[ -f "$here/scenes/$scene.qml" ] || { echo "render.sh: no scene $scene" >&2; exit 2; }
mkdir -p "$out"
case $scene in
  shell-states) exec "$here/shell-states.sh" "$out" ;;
  app-*) exec "$here/app-scene.sh" "$scene" "$out" ;;
  ryogami*) exec "$here/ryogami-scene.sh" "$scene" "$out" ;;
  keys) exec "$here/keys-scene.sh" "$scene" "$out" ;;
  ryopin) exec "$here/ryopin-scene.sh" "$scene" "$out" ;;
  hub|hub-states|hub-dialogs)
    case $scene in
      hub) marker=HUB-CAPTURE-DONE ;;
      hub-states) marker=HUB-STATES-DONE ;;
      hub-dialogs) marker=HUB-DIALOGS-DONE ;;
    esac
    for look in crate stock; do
      log="$out/$scene-$look.log"
      if ! "$here/hub-session.sh" "$here/scenes/$scene.qml" "$look" "$out" >"$log" 2>&1 \
          || ! grep -q "$marker" "$log" || grep -Eq 'TypeError|ReferenceError|Binding loop detected' "$log"; then
        tail -30 "$log" >&2
        exit 1
      fi
      grep "$marker" "$log"
    done
    exit 0
    ;;
esac
plugin="$repo/ryoku/shell/plugin"
build="${RYOKU_BLOBS_BUILD:-$plugin/build}"
cmake -S "$plugin" -B "$build" -G Ninja -DCMAKE_BUILD_TYPE=Release >/dev/null
cmake --build "$build" >/dev/null
mods=$(mktemp -d)
trap 'rm -r -- "$mods"' EXIT
mkdir -p "$mods/Ryoku" "$mods/root"
# The kit, linked entry by entry: Wm.qml reads Quickshell.WindowManager, which
# aborts the process under the offscreen platform, so a scene that reaches Wm
# (the Game Bar's cards do) gets a copy with those two Wayland reads emptied.
mkdir -p "$mods/Ryoku/Ui/Singletons"
for entry in "$repo/ryoku/ui"/*; do
  [ "$(basename "$entry")" = Singletons ] || ln -s "$entry" "$mods/Ryoku/Ui/$(basename "$entry")"
done
for entry in "$repo/ryoku/ui/Singletons"/*; do
  [ "$(basename "$entry")" = Wm.qml ] || ln -s "$entry" "$mods/Ryoku/Ui/Singletons/$(basename "$entry")"
done
sed -e 's/WindowManager\.windowsets/[]/' -e 's/ToplevelManager\.toplevels/null/' \
  "$repo/ryoku/ui/Singletons/Wm.qml" >"$mods/Ryoku/Ui/Singletons/Wm.qml"
for entry in "$repo/ryoku/shell/quickshell/shell"/*; do
  [ "$(basename "$entry")" = shell.qml ] || ln -s "$entry" "$mods/root/$(basename "$entry")"
done
cp "$here/scenes/$scene.qml" "$mods/root/shell.qml"
# A scene that imports inir (the Shima dock) gets inir mirrored as links with the
# offscreen stand-ins of tests/ui/fixtures/offscreen-inir (its LiveLayer and
# desktop menu map layer windows of their own, which cannot load offscreen). Its
# morphing body (the menus) clips through Quickshell's ClippingRectangle, a
# ShaderEffect the software scene graph of an offscreen render never draws, so
# the render draws that body as a plain Rectangle of the same fill and corner.
if grep -q '^import inir' "$here/scenes/$scene.qml"; then
  cp -as "$repo/ryoku/shell/quickshell/inir" "$mods/inir"
  cp -rf --remove-destination "$repo/tests/ui/fixtures/offscreen-inir/." "$mods/inir/"
  morph="$mods/inir/modules/iris/components/IrisMorphSurface.qml"
  sed 's/^    ClippingRectangle {$/    Rectangle {/' "$repo/ryoku/shell/quickshell/inir/modules/iris/components/IrisMorphSurface.qml" >"$morph.new"
  mv -f "$morph.new" "$morph"
fi
ln -s "$build/qml/Ryoku/Blobs" "$mods/Ryoku/Blobs"
path=$PATH
[ -d "$here/scenes/$scene.bin" ] && path="$here/scenes/$scene.bin:$PATH"
status=0
for look in crate stock; do
  png="$out/$scene-$look.png"
  rm -f "$png"
  PATH="$path" BENCH_OUT="$png" BENCH_CRATE=$([ "$look" = crate ] && echo 1 || echo 0) \
    QML_IMPORT_PATH="$mods:$repo/ryoku/shell/quickshell" \
    timeout 60 quickshell -p "$mods/root/shell.qml" >"$out/$scene-$look.log" 2>&1 || true
  if [ -s "$png" ]; then echo "wrote $png"; else
    echo "render.sh: no $look image; see $out/$scene-$look.log" >&2
    grep -E "ERROR|caused by" "$out/$scene-$look.log" | head -6 >&2 || true
    status=1
  fi
done
exit $status
