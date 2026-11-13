#!/usr/bin/env bash
# Share the Hub's bwrap filesystem and the exact same look for both shell panels.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../../.." && pwd)
out=$(realpath -m "${1:?usage: shell-states.sh OUT_DIR}")
overlay=$(mktemp -d)
trap 'rm -rf -- "$overlay"' EXIT
cp -a "$repo/ryoku/shell/quickshell/shell" "$overlay/"
cp -a "$repo/ryoku/shell/quickshell/inir" "$overlay/"
panel="$overlay/shell/modules/bar/barstyles/qsbar/panels/AiUsagePanel.qml"
sidebar="$overlay/shell/modules/sidebar"
# Qt's offscreen backend has no layer-shell window. Adapt only the host window
# in this scratch copy. Preserve both production Loader branches and all markup.
sed -i -e 's/^PanelWindow {/Item {/' -e '/^    screen: root.activePopupScreen$/d' \
    -e '/^    color: "transparent"$/d' -e '/^    anchors { top: true; bottom: true; left: true; right: true }$/d' \
    -e '/^    exclusionMode: /d' -e '/^    WlrLayershell\./d' "$panel"
cp "$here/shell-fixture/SampleMonitor.qml" "$sidebar/"
sed -i 's/^    SystemMonitor {/    SampleMonitor {/' "$sidebar/ControlsHero.qml"
mkdir -p "$out"
for look in stock crate; do
    log="$out/shell-states-$look.log"
    if ! RYOKU_HUB_FIXTURE_APP_OVERLAY="$overlay" "$here/hub-session.sh" "$here/scenes/shell-states.qml" "$look" "$out" >"$log" 2>&1 \
        || ! grep -q SHELL-STATES-DONE "$log" || grep -Eq 'TypeError|ReferenceError|Binding loop detected|Unable to assign' "$log"; then
        tail -50 "$log" >&2
        exit 1
    fi
done
