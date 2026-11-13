#!/usr/bin/env bash
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
out=$(mktemp -d)
trap 'rm -rf -- "$out"' EXIT
for look in crate stock; do
    if ! bash "$here/../visual/surfaces/hub-session.sh" "$here/hub-chrome-probe.qml" "$look" "$out" >"$out/log" 2>&1 \
        || ! grep -q "HUB-CHROME-PASS $look" "$out/log"; then
        cat "$out/log" >&2
        exit 1
    fi
    echo "hub-chrome-probe: $look passed"
done
