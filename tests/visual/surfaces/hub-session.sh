#!/usr/bin/env bash
# Run a Hub scene in its own filesystem, network, display and command environment.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
scene=$(realpath "${1:?usage: hub-session.sh SCENE_QML LOOK OUT_DIR [BASE_TREE]}")
look=${2:?missing look}
out=$(realpath -m "${3:?missing output directory}")
repo=$(realpath "${4:-$here/../../..}")
case $look in stock|crate) ;; *) exit 2 ;; esac
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
mkdir -p "$out" "$work"/{app,bin,config/ryoku,config/quickshell/shell/modules/launcher,i18n,fonts}
cp -a "$repo/ryoku/hub/quickshell/." "$work/app/"
if [[ -n ${RYOKU_HUB_FIXTURE_APP_OVERLAY:-} ]]; then
    cp -a "$RYOKU_HUB_FIXTURE_APP_OVERLAY/." "$work/app/"
fi
cp "$scene" "$work/app/probe.qml"
for cmd in bash sh env nmcli rfkill systemctl ryoku ryoku-hub ryoku-host ryoku-shell ryogami ryostore \
    omarchy ryoku-rashin qs ryoku-cmd-record pacman paru flatpak hyprctl niri ryostore-install fprintd-list; do
    ln -s /fixture/commands "$work/bin/$cmd"
done
if [[ $look == crate ]]; then
    cp "$here/hub-fixture/crate.json" "$work/config/ryoku/shell.json"
else
    echo '{"language":"en","theme":{"motion":{"reduce":true}}}' > "$work/config/ryoku/shell.json"
fi
echo '{"followWallpaper":false}' > "$work/config/ryoku/theme.json"
echo '{}' > "$work/config/ryoku/brand.json"
echo '{"phase":"idle"}' > "$work/update.json"
cp -a "$repo/ryoku/shell/quickshell/reload-cover" "$work/config/quickshell/"
cp "$repo/ryoku/i18n/langs.json" "$repo/ryoku/i18n/catalog/en.json" "$work/i18n/"
if [[ -n ${RYOKU_HUB_FIXTURE_FONTS:-} ]]; then
    cp "$RYOKU_HUB_FIXTURE_FONTS"/*.woff2 "$work/fonts/"
fi
timeout 150 bwrap --unshare-all --die-with-parent --new-session --clearenv \
    --ro-bind /usr/lib /usr/lib --ro-bind /usr/share /usr/share \
    --symlink usr/lib /lib --symlink usr/lib /lib64 \
    --ro-bind /etc/fonts /etc/fonts --ro-bind /usr/share/zoneinfo/UTC /etc/localtime \
    --ro-bind /usr/bin/quickshell /tools/qs --ro-bind /usr/bin/bash /tools/bash \
    --ro-bind "$work/bin" /usr/bin --symlink usr/bin /bin \
    --ro-bind "$here/hub-fixture" /fixture --ro-bind "$repo/ryoku/wm/hyprland/schema.json" /provider.json \
    --ro-bind "$work/app" /app --ro-bind "$repo/ryoku/ui" /qml/Ryoku/Ui \
    --ro-bind "$repo/ryoku/shell/framebars" /qml/Ryoku/FrameBars \
    --ro-bind "$work/i18n" /i18n --bind "$out" /output \
    --proc /proc --dev /dev --tmpfs /tmp --perms 0700 --dir /run/fixture \
    --dir /home/fixture --bind "$work/config" /home/fixture/.config \
    --ro-bind "$repo/ryoku/shell/quickshell/shell/modules/launcher" /home/fixture/.config/quickshell/shell/modules/launcher \
    --ro-bind "$repo/ryoku/assets/brand" /home/fixture/.local/share/ryoku/assets/brand \
    --ro-bind "$work/update.json" /run/fixture/ryoku-update.json \
    --ro-bind "$repo/ryoku/assets/ryodecors" /home/fixture/Pictures/ryodecors \
    --ro-bind "$work/fonts" /home/fixture/.local/share/fonts \
    --setenv HOME /home/fixture --setenv XDG_RUNTIME_DIR /run/fixture --setenv LANG C.UTF-8 \
    --setenv PATH /bin --setenv BENCH_LOOK "$look" --setenv RYOKU_I18N_DIR /i18n \
    --setenv QML_IMPORT_PATH /qml:/app --setenv QT_QPA_PLATFORM offscreen --setenv QT_QUICK_BACKEND software \
    --chdir /app -- /tools/qs -p /app/probe.qml
