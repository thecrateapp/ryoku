#!/usr/bin/env bash
# reload-cover-probe: the reload cover under a crate theme with a coverMark, and
# unchanged without one.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"

run() {
    local look="$1" work
    work="$(mktemp -d)"
    trap 'rm -rf -- "$work"' RETURN
    mkdir -p "$work/Ryoku" "$work/config/ryoku" "$work/runtime" "$work/shell"
    chmod 700 "$work/runtime"
    ln -s "${RYOKU_UI_SOURCE:-$repo/ryoku/ui}" "$work/Ryoku/Ui"
    ln -s "$repo/ryoku/shell/quickshell/reload-cover" "$work/shell/reload-cover"
    cp "$here/reload-cover-probe.qml" "$work/shell/shell.qml"
    local mark="$here/fixtures/cover-mark.svg"
    if [ "$look" = crate ]; then
        printf '{"themeStyle":{"controls":"crate","mono":"JetBrainsMono Nerd Font","coverMark":"%s"}}\n' "$mark" >"$work/config/ryoku/shell.json"
    else
        echo '{}' >"$work/config/ryoku/shell.json"
    fi
    PROBE_LOOK="$look" PROBE_MARK="$mark" RYOKU_I18N_DIR="$repo/ryoku/i18n/catalog" \
    QT_QPA_PLATFORM=offscreen HOME="$work" XDG_CONFIG_HOME="$work/config" XDG_CACHE_HOME="$work/cache" \
    XDG_RUNTIME_DIR="$work/runtime" QML2_IMPORT_PATH="$work" QML_IMPORT_PATH="$work" \
        timeout 20 qs -p "$work/shell/shell.qml" >"$work/log" 2>&1 || true
    if ! grep -q "RELOAD-COVER-PROBE-PASS $look" "$work/log" || grep -q RELOAD-COVER-PROBE-FAIL "$work/log"; then
        echo "reload-cover-probe ($look): FAILED" >&2
        sed -n '1,80p' "$work/log" >&2
        return 1
    fi
}

run stock
run crate
echo "reload-cover-probe: the theme's mark, glosses and Beam under crate; Ryoku's cover unchanged otherwise"
