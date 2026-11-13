#!/usr/bin/env bash
# The installer leaves a default-rice-pending marker for a new account, and the
# first login applies it. A marker that outlives that first login (a login that
# timed out waiting for the shell, a reboot before the shell came up) must never
# repaint an account that has since applied a rice of its own: it would wipe the
# user's whole look on some later boot. ryoku-hub, ryoku-shell, ryogami, qs and
# logger are shims; ryoku-hub records whether the default rice was applied.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
script="$root/ryoku/shell/scripts/ryoku-session-intro"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin"
for tool in ryoku-shell ryogami qs logger; do
	printf '#!/bin/sh\nexit 0\n' >"$tmp/bin/$tool"
done
printf '#!/bin/sh\nprintf "%%s\\n" "$*" >> "$RYOKU_TEST_CALLS"\n' >"$tmp/bin/ryoku-hub"
chmod +x "$tmp/bin"/*

fail=0
# run_case NAME SETUP WANT: SETUP runs inside the account's home.
run_case() {
	local name=$1 setup=$2 want_apply=$3
	local home="$tmp/$name"
	local cfg="$home/.config/ryoku" state="$home/.local/state/ryoku"
	mkdir -p "$cfg/rices/default" "$state" "$home/run"
	printf '{"assets":{"wallpaper":"x.webp"}}\n' >"$cfg/rices/default/rice.json"
	printf 'default\n' >"$state/default-rice-pending"
	printf '19' >"$state/welcome-seen"
	(cd "$home" && eval "$setup")
	: >"$home/calls"
	env -i PATH="$tmp/bin:/usr/bin:/bin" HOME="$home" XDG_RUNTIME_DIR="$home/run" \
		RYOKU_TEST_CALLS="$home/calls" bash "$script" welcome >/dev/null 2>&1 || true
	local applied=no
	grep -qx 'rice apply default' "$home/calls" && applied=yes
	if [[ $applied != "$want_apply" ]]; then
		echo "FAIL $name: default rice applied=$applied, want $want_apply" >&2
		fail=1
	fi
	if [[ -e $state/default-rice-pending ]]; then
		echo "FAIL $name: the marker survived the login" >&2
		fail=1
	fi
}

run_case fresh-account ':' yes
run_case active-rice 'printf crate > .config/ryoku/rices/.active' no
run_case applied-before 'mkdir -p .config/ryoku/rices/.previous && : > .config/ryoku/rices/.previous/shell.json' no
run_case baseline-only 'mkdir -p .config/ryoku/rices/.baseline && : > .config/ryoku/rices/.baseline/desktop.json' no

((fail == 0)) && echo "session-intro default rice: ok"
exit "$fail"
