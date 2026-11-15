#!/usr/bin/env bash
# plugin-api-spectrum: every host that builds a bar plugin's pluginApi hands it the
# shell's shared spectrum (AudioBars), and the plugin docs say how to use it. A
# plugin may not import shell services (R4), so this is its only way to the levels.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/.." && pwd)"
fail() { echo "plugin-api-spectrum: $*" >&2; exit 1; }

shell="$repo/ryoku/shell/quickshell/shell/modules/bar"
for host in "$shell/barstyles/qsbar/BarSlot.qml" "$shell/PluginPopouts.qml"; do
    grep -Eq 'readonly property var spectrum: (Svc\.)?AudioBars' "$host" \
        || fail "$(basename "$host") does not hand pluginApi.spectrum to plugins"
done
grep -q '^| `spectrum` |' "$repo/docs/plugins.md" || fail "docs/plugins.md does not document pluginApi.spectrum"
grep -q 'spectrum' "$repo/ryoku/cli/plugin_template/AGENTS.md" || fail "the plugin template's AGENTS.md does not mention spectrum"
echo "plugin-api-spectrum: bar plugin hosts share AudioBars as pluginApi.spectrum, documented"
