#!/usr/bin/env bash
# stage-kit-probe: what the hero launcher draws (the card, the search field,
# the modes, the lead result, the ledger rows, the action shelf, the window rail
# tiles) on the kit and Tokens roles under crate, and as before in the stock
# look. The card and the rail are layer windows, which need a compositor, so the
# probe loads the Items they host, offscreen, in an isolated session.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
plugin="$repo/ryoku/shell/plugin"
build="${RYOKU_BLOBS_BUILD:-$plugin/build}"
if [ ! -f "$build/qml/Ryoku/Blobs/qmldir" ]; then
    cmake -S "$plugin" -B "$build" -G Ninja -DCMAKE_BUILD_TYPE=Release >/dev/null
    cmake --build "$build" >/dev/null
fi
work="$(mktemp -d)"
cleanup() {
    # a crashed run leaves Quickshell's crash handler behind in this session
    for p in $(pgrep -x quickshell); do
        tr '\0' '\n' < "/proc/$p/environ" 2>/dev/null | grep -qx "XDG_RUNTIME_DIR=$work/runtime" && kill "$p"
    done
    rm -rf -- "$work"
}
trap cleanup EXIT
mkdir -p "$work/mods/Ryoku" "$work/root" "$work/config/ryoku" "$work/runtime" "$work/home"
chmod 700 "$work/runtime"
echo '{"language":"en"}' >"$work/config/ryoku/shell.json"
ln -s "$repo/ryoku/ui" "$work/mods/Ryoku/Ui"
ln -s "$build/qml/Ryoku/Blobs" "$work/mods/Ryoku/Blobs"
for entry in "$repo/ryoku/shell/quickshell/shell"/*; do
    [ "$(basename "$entry")" = shell.qml ] || ln -s "$entry" "$work/root/$(basename "$entry")"
done
cp "$here/stage-kit-probe.qml" "$work/root/shell.qml"
env -u WAYLAND_DISPLAY -u DISPLAY -u DBUS_SESSION_BUS_ADDRESS -u HYPRLAND_INSTANCE_SIGNATURE \
    QT_QPA_PLATFORM=offscreen HOME="$work/home" XDG_CONFIG_HOME="$work/config" \
    XDG_CACHE_HOME="$work/cache" XDG_RUNTIME_DIR="$work/runtime" \
    XDG_STATE_HOME="$work/state" XDG_DATA_HOME="$work/data" \
    RYOKU_I18N_DIR="$repo/ryoku/i18n/catalog" \
    STAGE_WIDGETS="$repo/ryoku/shell/quickshell/stage/modules/ii/background/widgets" \
    QML_IMPORT_PATH="$work/mods:$repo/ryoku/shell/quickshell" QML2_IMPORT_PATH="$work/mods" \
    timeout 40 qs -p "$work/root/shell.qml" >"$work/log" 2>&1 || true
if ! grep -q STAGE-KIT-PROBE-PASS "$work/log" || grep -Eq 'TypeError|ReferenceError|STAGE-KIT-PROBE-FAIL' "$work/log"; then
    echo "stage-kit-probe: FAILED" >&2
    grep -E 'STAGE-KIT-PROBE|TypeError|ReferenceError|ERROR|caused by' "$work/log" | head -40 >&2
    exit 1
fi
echo "stage-kit-probe: the Stage editor and desktop widgets draw from the kit and Tokens under crate; stock unchanged"
