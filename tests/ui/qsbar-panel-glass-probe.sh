#!/usr/bin/env bash
# qsbar-panel-glass-probe: CRATE wordmark and Crate glyph exist, persist and draw.
set -euo pipefail
# The probe runs on the live Wayland session (the qsbar Theme does not load
# offscreen) but in its own XDG_RUNTIME_DIR: the shell writes shell.json through
# the daemon socket there, and sharing it would rewrite the live config.

here="$(cd "$(dirname "$0")" && pwd)"
repo="$here/../.."
src="$repo/ryoku/shell/quickshell/shell"
run() {
    local look="$1"
    work="$(mktemp -d)"
    trap 'rm -rf "$work"' RETURN

    mkdir -p "$work/runtime" "$work/home" && chmod 700 "$work/runtime"
    wayland="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/${WAYLAND_DISPLAY:-wayland-1}"
    mkdir -p "$work/Ryoku" "$work/shell/modules" "$work/cfg/ryoku"
    ln -s "$repo/ryoku/ui" "$work/Ryoku/Ui"
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
    cp "$here/qsbar-panel-glass-probe.qml" "$work/shell/probe.qml"

    if [ "$look" = crate ]; then
        echo '{"themeStyle":{"controls":"crate"},"qsbar":{"barFrostEnabled":false}}' >"$work/cfg/ryoku/shell.json"
    else
        echo '{"qsbar":{"barFrostEnabled":false}}' >"$work/cfg/ryoku/shell.json"
    fi

    PROBE_LOOK="$look" HOME="$work" XDG_CONFIG_HOME="$work/cfg" XDG_CACHE_HOME="$work/cache" \
    XDG_RUNTIME_DIR="$work/runtime" WAYLAND_DISPLAY="$wayland" \
    QML2_IMPORT_PATH="$work:${QML2_IMPORT_PATH:-$HOME/.local/lib/qt6/qml}" \
    timeout 20 qs -p "$work/shell/probe.qml" >"$work/probe.log" 2>&1 || true

    if ! grep -q QSBAR-PANEL-GLASS-PROBE-PASS $look "$work/probe.log"; then
        echo "qsbar-panel-glass-probe: FAILED" >&2
        sed -n "1,120p" "$work/probe.log" >&2
        exit 1
    fi


}

run crate
run stock
# the panel bodies paint the panel fill, not the bar's
q="$repo/ryoku/shell/quickshell/shell/modules/bar/barstyles/qsbar"
if grep -nE 'surface\.root\.bg|pointer\.root\.bg' "$q/modules/AiPanelSurface.qml" "$q/modules/PanelPointer.qml" \
   || grep -nE 'color: root\.bg$' "$q/panels/TrayMenu.qml"; then
    echo "qsbar-panel-glass-probe: a panel body still paints the bar's bg" >&2
    exit 1
fi
echo "qsbar-panel-glass-probe: under crate every QS Bar panel is the one glass, whatever the bar's own opacity"
