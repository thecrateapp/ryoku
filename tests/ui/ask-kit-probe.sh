#!/usr/bin/env bash
# ask-kit-probe: the Ask bar (Rashin's question bar) and its bubble, loaded
# offscreen in both looks. Under crate they draw with the kit and Tokens on the
# one glass; in the stock look they draw exactly as before.
# PROBE_KEEP=DIR keeps each look's log in DIR.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
plugin="$repo/ryoku/shell/plugin"
build="${RYOKU_BLOBS_BUILD:-$plugin/build}"
cmake -S "$plugin" -B "$build" -G Ninja -DCMAKE_BUILD_TYPE=Release >/dev/null
cmake --build "$build" >/dev/null

run() {
    local look="$1" work
    work="$(mktemp -d)"
    trap 'rm -rf -- "$work"' RETURN
    mkdir -p "$work/Ryoku" "$work/root" "$work/bin" "$work/home" "$work/config" "$work/cache" "$work/runtime"
    chmod 700 "$work/runtime"
    ln -s "${RYOKU_UI_SOURCE:-$repo/ryoku/ui}" "$work/Ryoku/Ui"
    ln -s "$build/qml/Ryoku/Blobs" "$work/Ryoku/Blobs"
    for entry in "$repo/ryoku/shell/quickshell/shell"/*; do
        [ "$(basename "$entry")" = shell.qml ] || ln -s "$entry" "$work/root/$(basename "$entry")"
    done
    cp "$here/ask-kit-probe.qml" "$work/root/shell.qml"
    # what the file picker lists: one folder and two files it accepts
    mkdir -p "$work/home/Videos"
    touch "$work/home/clip.mp4" "$work/home/photo.png"
    # Rashin and the download engine stay out of reach: the services' start-up
    # probes get an empty answer instead of the real helpers.
    for tool in ryoku-rashin ryoku-docker stash-install.sh; do
        printf '#!/bin/sh\nexit 0\n' >"$work/bin/$tool"
        chmod +x "$work/bin/$tool"
    done
    # Only this checkout's kit: the desktop's QML2_IMPORT_PATH points at the
    # installed one, and so does any session's display, bus or compositor.
    env -u QML2_IMPORT_PATH -u WAYLAND_DISPLAY -u DISPLAY -u DBUS_SESSION_BUS_ADDRESS \
        -u HYPRLAND_INSTANCE_SIGNATURE -u NIRI_SOCKET \
        PROBE_LOOK="$look" PATH="$work/bin:$PATH" RYOKU_I18N_DIR="$repo/ryoku/i18n/catalog" \
        QT_QPA_PLATFORM=offscreen HOME="$work/home" XDG_CONFIG_HOME="$work/config" XDG_CACHE_HOME="$work/cache" \
        XDG_DATA_HOME="$work/home/.local/share" XDG_RUNTIME_DIR="$work/runtime" \
        QML_IMPORT_PATH="$work:$repo/ryoku/shell/quickshell" \
        timeout 40 qs -p "$work/root/shell.qml" >"$work/log" 2>&1 || true
    [ -n "${PROBE_KEEP:-}" ] && cp "$work/log" "$PROBE_KEEP/ask-kit-probe-$look.log"
    if ! grep -q "ASK-KIT-PROBE-PASS $look" "$work/log" || grep -q ASK-KIT-PROBE-FAIL "$work/log"; then
        echo "ask-kit-probe ($look): FAILED" >&2
        grep -E "ASK-KIT|Error|error|caused by|is not|Cannot" "$work/log" | sed -n '1,60p' >&2
        return 1
    fi
}

run stock
run crate
echo "ask-kit-probe: under crate the bar and bubble sit on the glass with kit controls and Solar glyphs; stock unchanged"
