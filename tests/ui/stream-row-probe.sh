#!/usr/bin/env bash
# Exercise the real QML component, including its volume limits and signal.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
repo="$here/../.."
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

mkdir -p "$work/Ryoku" "$work/config" "$work/runtime"
chmod 700 "$work/runtime"
ln -s "${RYOKU_UI_SOURCE:-$repo/ryoku/ui}" "$work/Ryoku/Ui"

QT_QPA_PLATFORM=offscreen \
XDG_CONFIG_HOME="$work/config" \
XDG_RUNTIME_DIR="$work/runtime" \
QML2_IMPORT_PATH="$work:${QML2_IMPORT_PATH:-$HOME/.local/lib/qt6/qml}" \
    timeout 20 qs -p "$here/stream-row-probe.qml" >"$work/log" 2>&1 || true
if ! grep -q STREAM-ROW-PROBE-PASS "$work/log"; then
    echo "stream-row-probe: FAILED" >&2
    sed -n '1,120p' "$work/log" >&2
    exit 1
fi

echo "stream-row-probe: creation, clamping, and adjusted signal passed"
