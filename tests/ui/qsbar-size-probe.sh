#!/usr/bin/env bash
# qsbar-size-probe: a stored QS Bar scale changes its live shell height.
set -euo pipefail
# The probe runs on the live Wayland session (the qsbar Theme does not load
# offscreen) but in its own XDG_RUNTIME_DIR: the shell writes shell.json through
# the daemon socket there, and sharing it would rewrite the live config.

here="$(cd "$(dirname "$0")" && pwd)"
repo="$here/../.."
src="$repo/ryoku/shell/quickshell/shell"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

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
cp "$here/qsbar-size-probe.qml" "$work/shell/probe.qml"

cat >"$work/cfg/ryoku/shell.json" <<'JSON'
{"qsbar":{"barScale":1.5}}
JSON

HOME="$work/home" XDG_CONFIG_HOME="$work/cfg" XDG_CACHE_HOME="$work/home/.cache" \
XDG_RUNTIME_DIR="$work/runtime" WAYLAND_DISPLAY="$wayland" \
QML2_IMPORT_PATH="$work:${QML2_IMPORT_PATH:-$HOME/.local/lib/qt6/qml}" \
timeout 20 qs -p "$work/shell/probe.qml" >"$work/probe.log" 2>&1 || true

if ! grep -q QSBAR-SIZE-PROBE-PASS "$work/probe.log"; then
    echo "qsbar-size-probe: FAILED" >&2
    sed -n '1,120p' "$work/probe.log" >&2
    exit 1
fi

echo "qsbar-size-probe: persisted scale changes the live bar height"
