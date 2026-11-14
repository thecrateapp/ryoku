#!/usr/bin/env bash
# keys-phone-glyphs-probe: Kit's phone tab icons are kit glyphs under crate and
# Material text in the stock look. Offscreen, in its own session.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"

run() {
    local look="$1" work
    work="$(mktemp -d)"
    trap 'rm -rf -- "$work"' RETURN
    mkdir -p "$work/Ryoku" "$work/config/ryoku" "$work/runtime" "$work/shell"
    chmod 700 "$work/runtime"
    ln -s "$repo/ryoku/ui" "$work/Ryoku/Ui"
    ln -s "$repo/ryoku/shell/quickshell/keys/phone" "$work/shell/phone"
    cp "$here/keys-phone-glyphs-probe.qml" "$work/shell/shell.qml"
    if [ "$look" = crate ]; then
        echo '{"themeStyle":{"controls":"crate"}}' >"$work/config/ryoku/shell.json"
    else
        echo '{}' >"$work/config/ryoku/shell.json"
    fi
    env -u WAYLAND_DISPLAY -u DISPLAY -u DBUS_SESSION_BUS_ADDRESS -u HYPRLAND_INSTANCE_SIGNATURE \
        -u QML2_IMPORT_PATH -u QML_IMPORT_PATH \
        PROBE_LOOK="$look" RYOKU_I18N_DIR="$repo/ryoku/i18n/catalog" QT_QPA_PLATFORM=offscreen \
        HOME="$work" XDG_CONFIG_HOME="$work/config" XDG_CACHE_HOME="$work/cache" XDG_STATE_HOME="$work/state" \
        XDG_RUNTIME_DIR="$work/runtime" QML2_IMPORT_PATH="$work" QML_IMPORT_PATH="$work" \
        timeout 20 qs -p "$work/shell/shell.qml" >"$work/log" 2>&1 || true
    if ! grep -q "KEYS-PHONE-GLYPHS-PROBE-PASS $look" "$work/log"; then
        echo "keys-phone-glyphs-probe ($look): FAILED" >&2
        sed -n '1,60p' "$work/log" >&2
        return 1
    fi
}

run crate
run stock
echo "keys-phone-glyphs-probe: every phone-tab icon is a kit glyph under crate and Material text in stock"
