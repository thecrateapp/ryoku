#!/usr/bin/env bash
# Exercise the hardware-key entry point with independent displays and changing focus.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
key="$root/ryoku/shell/scripts/ryoku-cmd-brightness"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export FIXTURE="$tmp" PATH="$tmp/bin:$PATH"
mkdir "$tmp/bin"
touch "$tmp/events"

cat > "$tmp/bin/ryoku" <<'SH'
#!/usr/bin/env bash
[[ $* == 'wm state' && ! -e $FIXTURE/wm-offline ]] || exit 1
echo focus >> "$FIXTURE/events"
cat "$FIXTURE/state"
SH
cat > "$tmp/bin/ryoku-brightness-output" <<'SH'
#!/usr/bin/env bash
set -eu
[[ $# == 3 && $1 == adjust ]] || exit 1
echo "adjust $2 $3" >> "$FIXTURE/events"
case "$2" in DP-3|DP-5|eDP-1) ;; *) exit 1 ;; esac
if [[ -e $FIXTURE/next-focus ]]; then mv "$FIXTURE/next-focus" "$FIXTURE/state"; fi
level=$(( $(<"$FIXTURE/$2") + $3 ))
echo "$level" > "$FIXTURE/$2"
echo "$level"
SH
cat > "$tmp/bin/qs" <<'SH'
#!/usr/bin/env bash
[[ $# == 9 && ${*:1:7} == '-c shell ipc call -- brightnessOsd show' ]] || exit 1
echo "osd $8 $9" >> "$FIXTURE/events"
[[ ! -e $FIXTURE/osd-offline ]]
SH
for cmd in ddcutil brightnessctl; do
  cat > "$tmp/bin/$cmd" <<'SH'
#!/usr/bin/env bash
echo 'unexpected direct hardware access' >> "$FIXTURE/events"
exit 1
SH
done
chmod +x "$tmp/bin/"*
echo 41 > "$tmp/eDP-1"
echo 52 > "$tmp/DP-3"
echo 63 > "$tmp/DP-5"

# The first hardware reply arrives after focus moves. Its OSD stays with that
# write, while the very next key goes to the newly focused external screen.
echo '{"focusedOutput":"DP-3"}' > "$tmp/state"
echo '{"focusedOutput":"DP-5"}' > "$tmp/next-focus"
"$key" +5
"$key" -7
echo '{"focusedOutput":"eDP-1"}' > "$tmp/state"
touch "$tmp/osd-offline"
"$key" +2
[[ $(<"$tmp/DP-3") == 57 && $(<"$tmp/DP-5") == 56 && $(<"$tmp/eDP-1") == 43 ]]

reject() {
  if "$key" "$@" >/dev/null 2>&1; then
    echo "unexpected success for $*" >&2
    exit 1
  fi
}
echo '{"focusedOutput":"HDMI-A-2"}' > "$tmp/state"
reject +5
echo '{"focusedOutput":"","outputs":[{"name":"eDP-1"}]}' > "$tmp/state"
reject -5
echo '{}' > "$tmp/state"
reject +5
touch "$tmp/wm-offline"
reject +5
reject nonsense
reject
reject +5 extra
diff -u - "$tmp/events" <<'EXPECTED'
focus
adjust DP-3 +5
osd DP-3 57
focus
adjust DP-5 -7
osd DP-5 56
focus
adjust eDP-1 +2
osd eDP-1 43
focus
adjust HDMI-A-2 +5
focus
focus
EXPECTED
echo 'brightness keys: focused output, delayed feedback, missing focus and offline devices passed'
