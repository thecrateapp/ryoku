#!/usr/bin/env bash
# notification-glyph-probe: the notification card's last-resort thumbnail glyph
# (images on, no image and no app icon) is a kit Solar Glyph in a Tokens role
# under crate, and the Material notifications / priority_high glyph in stock.
# Loads the card offscreen in an isolated session, once per look.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
plugin="$repo/ryoku/shell/plugin"
build="${RYOKU_BLOBS_BUILD:-$plugin/build}"
if [ ! -f "$build/qml/Ryoku/Blobs/qmldir" ]; then
    cmake -S "$plugin" -B "$build" -G Ninja -DCMAKE_BUILD_TYPE=Release >/dev/null
    cmake --build "$build" >/dev/null
fi

run() {
    local look="$1" work
    work="$(mktemp -d)"
    trap 'rm -rf -- "$work"' RETURN
    mkdir -p "$work/mods/Ryoku" "$work/root" "$work/config/ryoku" "$work/runtime" "$work/home"
    chmod 700 "$work/runtime"
    echo '{"language":"en","notifications":{"show_images":true}}' >"$work/config/ryoku/shell.json"
    ln -s "${RYOKU_UI_SOURCE:-$repo/ryoku/ui}" "$work/mods/Ryoku/Ui"
    ln -s "$build/qml/Ryoku/Blobs" "$work/mods/Ryoku/Blobs"
    for entry in "$repo/ryoku/shell/quickshell/shell"/*; do
        [ "$(basename "$entry")" = shell.qml ] || ln -s "$entry" "$work/root/$(basename "$entry")"
    done
    cp "$here/notification-glyph-probe.qml" "$work/root/shell.qml"
    env -u WAYLAND_DISPLAY -u DISPLAY -u DBUS_SESSION_BUS_ADDRESS -u HYPRLAND_INSTANCE_SIGNATURE \
        PROBE_LOOK="$look" QT_QPA_PLATFORM=offscreen HOME="$work/home" XDG_CONFIG_HOME="$work/config" \
        XDG_CACHE_HOME="$work/cache" XDG_RUNTIME_DIR="$work/runtime" \
        RYOKU_I18N_DIR="$repo/ryoku/i18n/catalog" \
        QML_IMPORT_PATH="$work/mods:$repo/ryoku/shell/quickshell" QML2_IMPORT_PATH="$work/mods" \
        timeout 40 qs -p "$work/root/shell.qml" >"$work/log" 2>&1 || true
    if ! grep -q "NOTIFICATION-GLYPH-PROBE-PASS $look" "$work/log" \
        || grep -Eq 'TypeError|ReferenceError|NOTIFICATION-GLYPH-PROBE-FAIL' "$work/log"; then
        echo "notification-glyph-probe ($look): FAILED" >&2
        grep -E 'NOTIFICATION-GLYPH-PROBE|TypeError|ReferenceError|ERROR|caused by' "$work/log" | head -40 >&2
        return 1
    fi
}

run stock
run crate
echo "notification-glyph-probe: the fallback thumbnail is a kit Solar glyph in Tokens roles under crate; Material in stock"
