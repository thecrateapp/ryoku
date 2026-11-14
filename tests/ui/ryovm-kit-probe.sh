#!/usr/bin/env bash
# Ryoport on the kit (PageHeader, Beam, TrackLabel captions, PickCard, pick edges) in
# the crate and the stock look, against a plain config.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT
mkdir -p "$work/Ryoku" "$work/bin" "$work/config/ryoku" "$work/runtime"
chmod 700 "$work/runtime"
echo '{"language":"en"}' > "$work/config/ryoku/shell.json"
ln -s "$repo/ryoku/ui" "$work/Ryoku/Ui"
cp -a "$repo/ryoku/apps/ryovm/quickshell" "$work/ryovm"
cp "$here/ryovm-kit-probe.qml" "$work/probe.qml"
cat > "$work/bin/ryovm" <<'FAKE'
#!/usr/bin/env bash
case "${1:-}" in
create) sleep 8 ;;
list) echo '[{"name":"fedora-41","os":"fedora","running":false,"cores":"auto","ram":"4G","display":"gtk","diskUsed":0}]' ;;
catalog|cloud-catalog|lg|usb|portfwd) echo '[]' ;;
*) echo '{}' ;;
esac
FAKE
printf '%s\n' '#!/usr/bin/env bash' 'echo "[]"' > "$work/bin/ryossh"
chmod +x "$work/bin/ryovm" "$work/bin/ryossh"
PATH="$work/bin:$PATH" QT_QPA_PLATFORM=offscreen XDG_CONFIG_HOME="$work/config" XDG_RUNTIME_DIR="$work/runtime" \
RYOKU_I18N_DIR="$repo/ryoku/i18n/catalog" QML2_IMPORT_PATH="$work" QML_IMPORT_PATH="$work" \
    timeout 30 qs -p "$work/probe.qml" >"$work/log" 2>&1 || true
if ! grep -q RYOVM-KIT-PROBE-PASS "$work/log" || grep -Eq 'TypeError|ReferenceError' "$work/log"; then
    echo "ryovm-kit-probe: FAILED" >&2
    grep -v "AnimatedImage\|pipewire\|PulseAudio" "$work/log" | sed -n '1,60p' >&2
    exit 1
fi
echo "ryovm-kit-probe: header, downloads, captions, cards and rows passed in both looks"
