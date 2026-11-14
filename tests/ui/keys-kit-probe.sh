#!/usr/bin/env bash
# Kit (qs -c keys) and its first-boot hint on the kit: the crate look from the
# Crate theme fixture, then a live switch to stock, and the stock look from a
# plain config. Offscreen, with its own runtime, home, config, state and cache,
# so nothing reaches the live session (Kit's phone tab calls `qs ipc`). Wm.qml
# reads Quickshell.WindowManager, which aborts under the offscreen platform, so
# the probe's kit links every entry but takes a copy of it with those reads
# emptied (Kit's command catalogue follows Wm).
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"

run() {
    local look="$1" work
    work="$(mktemp -d)"
    trap 'rm -rf -- "$work"' RETURN
    mkdir -p "$work/Ryoku/Ui/Singletons" "$work/config/ryoku" "$work/runtime" "$work/state" "$work/cache"
    chmod 700 "$work/runtime"
    for entry in "$repo/ryoku/ui"/*; do
        [ "$(basename "$entry")" = Singletons ] || ln -s "$entry" "$work/Ryoku/Ui/$(basename "$entry")"
    done
    for entry in "$repo/ryoku/ui/Singletons"/*; do
        [ "$(basename "$entry")" = Wm.qml ] || ln -s "$entry" "$work/Ryoku/Ui/Singletons/$(basename "$entry")"
    done
    sed -e 's/WindowManager\.windowsets/[]/' -e 's/ToplevelManager\.toplevels/null/' \
        "$repo/ryoku/ui/Singletons/Wm.qml" >"$work/Ryoku/Ui/Singletons/Wm.qml"
    cp -a "$repo/ryoku/shell/quickshell/keys" "$work/keys"
    cp -a "$repo/ryoku/shell/quickshell/keys-hint" "$work/keys-hint"
    cp "$here/keys-kit-probe.qml" "$work/probe.qml"
    if [ "$look" = crate ]; then
        cp "$repo/tests/visual/surfaces/hub-fixture/crate.json" "$work/config/ryoku/shell.json"
    else
        echo '{"language":"en","theme":{"motion":{"reduce":true}}}' > "$work/config/ryoku/shell.json"
    fi
    echo '{"followWallpaper":false}' > "$work/config/ryoku/theme.json"
    env -u WAYLAND_DISPLAY -u DISPLAY -u DBUS_SESSION_BUS_ADDRESS -u HYPRLAND_INSTANCE_SIGNATURE \
        -u RYOKU_SHELL_DIR \
        PROBE_LOOK="$look" QT_QPA_PLATFORM=offscreen HOME="$work" XDG_CONFIG_HOME="$work/config" \
        XDG_STATE_HOME="$work/state" XDG_CACHE_HOME="$work/cache" XDG_RUNTIME_DIR="$work/runtime" \
        RYOKU_I18N_DIR="$repo/ryoku/i18n/catalog" QML2_IMPORT_PATH="$work" QML_IMPORT_PATH="$work" \
        timeout 40 qs -p "$work/probe.qml" >"$work/log" 2>&1 || true
    if ! grep -q "KEYS-KIT-PROBE-PASS $look" "$work/log" || grep -Eq 'TypeError|ReferenceError' "$work/log"; then
        echo "keys-kit-probe ($look): FAILED" >&2
        grep -vE 'qmlscanner|^\s*$' "$work/log" | tail -30 >&2 || true
        return 1
    fi
}

run crate
run stock
echo "keys-kit-probe: Kit's card, head, tabs, rail, close, captions and tab controls and the hint's glass passed in both looks"
