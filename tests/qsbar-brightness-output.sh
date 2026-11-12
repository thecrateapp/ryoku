#!/usr/bin/env bash
# All monitor traffic is simulated, including concurrent read/modify/write.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
helper="$root/ryoku/shell/scripts/ryoku-brightness-output"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export XDG_RUNTIME_DIR="$tmp/run" RYOKU_DRM_PATH="$tmp/drm" RYOKU_BACKLIGHT_PATH="$tmp/bl"
export FAKE_STATE="$tmp/state" PATH="$tmp/bin:$PATH"
mkdir -p "$tmp"/{run,drm,bl,state,bin}
touch "$FAKE_STATE/log"
ln -s "$root/system/hardware/display/ryoku-hw-backlight" "$tmp/bin"
cat > "$tmp/bin/brightnessctl" <<'BASH'
#!/usr/bin/env bash
set -eu
[[ ! -e $FAKE_STATE/no_io ]] || { echo io >> "$FAKE_STATE/unexpected"; exit 1; }
[[ $1 == -d ]]
state="$FAKE_STATE/$2"
read -r current maximum < "$state"
if [[ $3 == set ]]; then
  printf 'backlight %s %d\n' "$2" "$4" >> "$FAKE_STATE/log"
  printf '%d %d\n' "$4" "$maximum" > "$state"
else
  [[ $3 == -m ]]
  printf '%s,backlight,%d,%d%%,%d\n' "$2" "$current" "$((current * 100 / maximum))" "$maximum"
fi
BASH
cat > "$tmp/bin/ddcutil" <<'BASH'
#!/usr/bin/env bash
set -eu
[[ ! -e $FAKE_STATE/no_io ]] || { echo io >> "$FAKE_STATE/unexpected"; exit 1; }
[[ $1 == --bus ]] || exit 1
state="$FAKE_STATE/bus-$2"
read -r current maximum < "$state"
if [[ $3 == --brief && $4 == getvcp && $5 == 10 ]]; then
  if [[ $current == unsupported ]]; then echo 'VCP 10 ERR'; exit 0; fi
  if [[ -e $FAKE_STATE/slow ]]; then sleep 0.08; fi
  printf 'VCP 10 C %s %s\n' "$current" "$maximum"
elif [[ $3 == setvcp && $4 == 10 ]]; then
  [[ ! -e $FAKE_STATE/denied ]]
  printf 'ddc %s %d\n' "$2" "$5" >> "$FAKE_STATE/log"
  printf '%d %d\n' "$5" "$maximum" > "$state"
else
  exit 1
fi
BASH
chmod +x "$tmp/bin/"{brightnessctl,ddcutil}

expect() {
  local expected=$1 got
  shift
  got=$("$helper" "$@")
  [[ $got == "$expected" ]] || { echo "expected $expected from $*, got $got" >&2; exit 1; }
}
reject() {
  local writes result
  writes=$(wc -l < "$FAKE_STATE/log")
  if result=$("$helper" "$@" 2>/dev/null); then echo "unexpected success: $*" >&2; exit 1; fi
  [[ -z $result && $(wc -l < "$FAKE_STATE/log") == "$writes" ]]
}
connect() {
  mkdir -p "$tmp/drm/$1"
  echo connected > "$tmp/drm/$1/status"
}
bus() {
  mkdir -p "$tmp/drm/$1/i2c-$2"
  ln -sfn "i2c-$2" "$tmp/drm/$1/ddc"
}

connect card0-eDP-1
mkdir -p "$tmp/bl/intel_backlight"
ln -s "$tmp/drm/card0-eDP-1" "$tmp/bl/intel_backlight/device"
echo '8 400' > "$FAKE_STATE/intel_backlight"
connect card0-DP-3
connect card0-DP-5
bus card0-DP-3 17
bus card0-DP-5 19
# Same EDID/model and different VCP ranges on two separate physical monitors.
echo Philips > "$tmp/drm/card0-DP-3/edid"
echo Philips > "$tmp/drm/card0-DP-5/edid"
echo '128 200' > "$FAKE_STATE/bus-17"
echo '26 50' > "$FAKE_STATE/bus-19"
# Reverse mapping succeeds with the hardware programs unavailable.
touch "$FAKE_STATE/no_io"
expect eDP-1 output-for-backlight intel_backlight
[[ ! -f $FAKE_STATE/unexpected ]]
rm "$FAKE_STATE/no_io"
reject output-for-backlight missing
reject output-for-backlight '../intel_backlight'
expect 2 get eDP-1
expect 3 step eDP-1 up
expect 1 set eDP-1 1
expect 1 step eDP-1 down
expect 64 get DP-3
expect 52 get DP-5
expect 74 set DP-3 74
expect 52 get DP-5
expect 1 get eDP-1
[[ $(<"$FAKE_STATE/bus-17") == '148 200' ]]
expect 58 step DP-5 up
expect 74 get DP-3
expect 98 set DP-5 97
expect 100 step DP-5 up
expect 100 step DP-5 up

# A monitor with only ten levels must still register a relative step.
echo '6 10' > "$FAKE_STATE/bus-19"
expect 50 step DP-5 down
expect 60 step DP-5 up

# Keys accept arbitrary signed percentage changes and reach zero. Relative
# writes operate on native units, including non-percent and coarse VCP ranges.
expect 70 adjust DP-5 +1
expect 60 adjust DP-5 -1
expect 90 adjust DP-5 +00029
expect 100 adjust DP-5 +999999999999999999999999
expect 0 adjust DP-5 -32768
writes=$(wc -l < "$FAKE_STATE/log")
expect 0 adjust DP-5 +0000
expect 0 adjust DP-5 -0
[[ $(wc -l < "$FAKE_STATE/log") == "$writes" ]]
expect 74 get DP-3
expect 1 get eDP-1
expect 13 adjust eDP-1 +12
expect 1 adjust eDP-1 -12
expect 0 adjust eDP-1 -6
expect 1 adjust eDP-1 +1
reject adjust DP-3 5
reject adjust DP-3 +1x
reject adjust DP-3 --
reject adjust DP-3 '+2.5'
reject adjust DP-3 +5 unexpected

# Locking must serialize the read and write, not just the latter.
touch "$FAKE_STATE/slow"
"$helper" step DP-3 down > "$tmp/step-1" &
pid1=$!
"$helper" adjust DP-3 -5 > "$tmp/step-2" &
pid2=$!
wait "$pid1"
wait "$pid2"
rm "$FAKE_STATE/slow"
expect 64 get DP-3

# Missing devices, permission failures, invalid ranges and ambiguous names
# never become a write on another connector.
touch "$FAKE_STATE/denied"
reject set DP-5 42
rm "$FAKE_STATE/denied"
echo 'unsupported 0' > "$FAKE_STATE/bus-19"
reject get DP-5
reject step DP-5 up
reject set DP-3 0
reject set DP-3 101
reject step DP-3 yes
reject set 'DP-3/../eDP-1' 53
reject set DP-3-extra 53
echo disconnected > "$tmp/drm/card0-DP-3/status"
reject set DP-3 31
connect card0-DP-3
connect card1-DP-3
reject set DP-3 31
echo disconnected > "$tmp/drm/card1-DP-3/status"

# Replug on a different bus, then a driver exposing only a connector child.
rm -rf "$tmp/drm/card0-DP-3/i2c-17"
bus card0-DP-3 21
echo '16 100' > "$FAKE_STATE/bus-21"
expect 16 get DP-3
expect 21 step DP-3 up
[[ $(<"$FAKE_STATE/bus-17") == '128 200' ]]
rm "$tmp/drm/card0-DP-3/ddc"
expect 21 get DP-3
ln -s "$tmp/drm/card0-DP-3/i2c-21" "$tmp/drm/card0-DP-5/ddc-shared"
mv -Tf "$tmp/drm/card0-DP-5/ddc-shared" "$tmp/drm/card0-DP-5/ddc"
reject set DP-3 51
reject set DP-5 51
rm "$tmp/drm/card0-DP-5/ddc"
rm -rf "$tmp/drm/card0-DP-5/i2c-19"
reject set DP-5 51
expect 21 get DP-3

# A second internal panel with no mapped backlight cannot use the first one's
# device. A single panel with a platform backlight can use the system selector.
connect card1-eDP-2
reject set eDP-2 66
expect 1 get eDP-1
expect eDP-1 output-for-backlight intel_backlight
# A platform backlight on two connected internal panels has no unique owner.
rm "$tmp/bl/intel_backlight/device"
reject output-for-backlight intel_backlight
echo disconnected > "$tmp/drm/card1-eDP-2/status"
mv "$tmp/bl/intel_backlight" "$tmp/bl/acpi_video0"
echo '38 100' > "$FAKE_STATE/acpi_video0"
expect eDP-1 output-for-backlight acpi_video0
expect 38 get eDP-1

# Native brightness controls can also belong to an external connector.
mkdir -p "$tmp/bl/oled"
ln -s "$tmp/drm/card0-DP-5" "$tmp/bl/oled/device"
echo '33 100' > "$FAKE_STATE/oled"
expect DP-5 output-for-backlight oled
expect 33 get DP-5
expect 39 set DP-5 39
expect 21 get DP-3
rm -rf "$tmp/bl/acpi_video0"
reject set eDP-1 55

# A panel with its own DDC controller still works without a native backlight.
bus card0-eDP-1 8
echo '25 50' > "$FAKE_STATE/bus-8"
expect 50 get eDP-1
expect 72 set eDP-1 72
expect 39 get DP-5

# A kernel ddcci backlight may be attached to the I2C client under a connector.
mkdir -p "$tmp/drm/card0-DP-3/i2c-21/21-0037/ddcci21" "$tmp/bl/ddcci21"
ln -s "$tmp/drm/card0-DP-3/i2c-21/21-0037/ddcci21" "$tmp/bl/ddcci21/device"
echo '88 100' > "$FAKE_STATE/ddcci21"
expect DP-3 output-for-backlight ddcci21
expect 88 get DP-3
expect 43 set DP-3 43
[[ $(<"$FAKE_STATE/bus-21") == '21 100' ]]
rm -rf "$tmp/drm/card0-eDP-1/i2c-8" "$tmp/bl/oled"
reject set eDP-1 90
echo 'qsbar-brightness-output: passed'
