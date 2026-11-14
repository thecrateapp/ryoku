#!/usr/bin/env bash
# The connected panel surface draws its caret outside its card: 5 px above the
# top edge (below the bottom edge on a bottom bar). A card that hosts the
# surface and sets `clip: true` cuts the caret off and leaves only the notch in
# the outline. Fail when any QS Bar panel puts the surface inside a clipping
# card; clip the content in an inner item instead (see PluginPanel.qml).
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
panels="$repo/ryoku/shell/quickshell/shell/modules/bar/barstyles/qsbar/panels"
python3 - "$panels" <<'EOF'
import pathlib, re, sys

def indent(line):
    return len(line) - len(line.lstrip(" "))

bad, checked = [], 0
for path in sorted(pathlib.Path(sys.argv[1]).glob("*.qml")):
    lines = path.read_text().splitlines()
    for i, line in enumerate(lines):
        if not re.match(r"\s*(ConnectedPanelSurface|AiPanelSurface)\s*\{", line):
            continue
        checked += 1
        depth = indent(line)
        # the enclosing object opens on the nearest earlier line indented less
        start = next(j for j in range(i - 1, -1, -1)
                     if lines[j].strip() and indent(lines[j]) < depth)
        # its own properties sit at the surface's indent, up to its closing brace
        end = next((j for j in range(i + 1, len(lines))
                    if lines[j].strip() and indent(lines[j]) < depth), len(lines))
        for j in range(start + 1, end):
            if indent(lines[j]) == depth and re.match(r"\s*clip:\s*true\b", lines[j]):
                bad.append(f"{path.name}:{j + 1}")
if checked == 0:
    sys.exit("panel-caret-clip: found no connected panel surface to check")
if bad:
    sys.exit("panel-caret-clip: a card hosting the panel surface clips its caret: " + ", ".join(bad))
print(f"panel-caret-clip: {checked} connected surfaces, none inside a clipping card")
EOF
