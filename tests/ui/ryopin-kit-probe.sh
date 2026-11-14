#!/usr/bin/env bash
# ryopin-kit-probe: a pinned card on the kit and Tokens roles under crate (an
# opaque popover card, the action strip as the one glass in the gutter above it,
# kit IconButtons with Solar glyphs) and as before in the stock look. A pin is a
# layer window, which needs a compositor, so the probe loads the PinCard Item it
# hosts, offscreen, in an isolated session.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT
mkdir -p "$work/mods/Ryoku" "$work/root" "$work/config/ryoku" "$work/runtime" "$work/home" "$work/cache"
chmod 700 "$work/runtime"
echo '{"language":"en"}' >"$work/config/ryoku/shell.json"
ln -s "$repo/ryoku/ui" "$work/mods/Ryoku/Ui"
cp -a "$repo/ryoku/shell/quickshell/ryopin" "$work/root/ryopin"
cp "$here/ryopin-kit-probe.qml" "$work/root/shell.qml"
magick -size 320x200 gradient:'#406080-#203040' "$work/shot.png"
env -u WAYLAND_DISPLAY -u DISPLAY -u DBUS_SESSION_BUS_ADDRESS -u HYPRLAND_INSTANCE_SIGNATURE \
    QT_QPA_PLATFORM=offscreen HOME="$work/home" XDG_CONFIG_HOME="$work/config" \
    XDG_CACHE_HOME="$work/cache" XDG_RUNTIME_DIR="$work/runtime" \
    RYOKU_I18N_DIR="$repo/ryoku/i18n/catalog" PIN_SHOT="$work/shot.png" \
    QML_IMPORT_PATH="$work/mods" QML2_IMPORT_PATH="$work/mods" \
    timeout 40 qs -p "$work/root/shell.qml" >"$work/log" 2>&1 || true
if ! grep -q RYOPIN-KIT-PROBE-PASS "$work/log" || grep -Eq 'TypeError|ReferenceError|RYOPIN-KIT-PROBE-FAIL' "$work/log"; then
    echo "ryopin-kit-probe: FAILED" >&2
    grep -E 'RYOPIN-KIT-PROBE|TypeError|ReferenceError|ERROR|caused by' "$work/log" | head -40 >&2
    exit 1
fi
echo "ryopin-kit-probe: the pinned card draws from the kit and Tokens under crate; stock unchanged"
