#!/usr/bin/env bash
# bar-device-glyphs-probe: the audio and Bluetooth bar glyphs come from the kit under crate.
set -euo pipefail
# The probe runs on the live Wayland session (the qsbar Theme does not load
# offscreen) but in its own XDG_RUNTIME_DIR: the shell writes shell.json through
# the daemon socket there, and sharing it would rewrite the live config.

here="$(cd "$(dirname "$0")" && pwd)"
repo="$here/../.."
src="$repo/ryoku/shell/quickshell/shell"
run() {
    local kit="$1"
    work="$(mktemp -d)"
    trap 'rm -rf "$work"' RETURN

    mkdir -p "$work/runtime" "$work/home" && chmod 700 "$work/runtime"
    wayland="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/${WAYLAND_DISPLAY:-wayland-1}"
    mkdir -p "$work/Ryoku" "$work/shell/modules" "$work/cfg/ryoku"
    if [ "$kit" = old ]; then
        # a kit from before the new glyphs: the widgets must fall back to drawn
        # glyphs it has, not print a missing name as text
        cp -r "$repo/ryoku/ui" "$work/Ryoku/Ui"
        python3 -c 'import re, sys
p = sys.argv[1]; s = open(p).read()
for n in ("bluetooth-square-off", "bluetooth-square", "headphones-round-sound", "speaker-minimalistic", "laptop"):
    s = re.sub(r"\n    \"%s\": \"[^\n]*\"," % re.escape(n), "", s)
open(p, "w").write(s)' "$work/Ryoku/Ui/lib/glyphs.js"
    else
        ln -s "$repo/ryoku/ui" "$work/Ryoku/Ui"
    fi
    ln -s "$repo/ryoku/shell/framebars" "$work/Ryoku/FrameBars"
    ln -s "$repo/ryoku/shell/quickshell/inir" "$work/inir"
    for child in "$src"/*; do
        name="$(basename "$child")"
        [[ "$name" == modules ]] && continue
        ln -s "$child" "$work/shell/$name"
    done
    for child in "$src/modules"/*; do
        ln -s "$child" "$work/shell/modules/$(basename "$child")"
    done
    cp "$here/bar-device-glyphs-probe.qml" "$work/shell/probe.qml"
    export PROBE_KIT="$kit"

    printf '%s\n' '{"themeStyle":{"controls":"crate"}}' >"$work/cfg/ryoku/shell.json"

    HOME="$work" XDG_CONFIG_HOME="$work/cfg" XDG_CACHE_HOME="$work/cache" \
    XDG_RUNTIME_DIR="$work/runtime" WAYLAND_DISPLAY="$wayland" \
    QML2_IMPORT_PATH="$work:${QML2_IMPORT_PATH:-$HOME/.local/lib/qt6/qml}" \
    timeout 20 qs -p "$work/shell/probe.qml" >"$work/probe.log" 2>&1 || true

    if ! grep -q BAR-DEVICE-GLYPHS-PROBE-PASS "$work/probe.log"; then
        echo "bar-device-glyphs-probe: FAILED" >&2
        sed -n "1,120p" "$work/probe.log" >&2
        exit 1
    fi

    echo "bar-device-glyphs-probe: the audio output and squared Bluetooth glyphs draw from the kit under crate"
}

run new
run old
