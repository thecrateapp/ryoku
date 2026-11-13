package main

import (
	"fmt"
	"os"
	"strings"
	"testing"
)

// The tests run commands such as `ryoku-shell theme`, notify-send and
// `qs ipc call`; with the developer's session in reach they repaint the live
// desktop and flood its notifications. TestMain cuts every socket off first.
func TestTestsCannotReachTheLiveSession(t *testing.T) {
	for _, key := range []string{
		"WAYLAND_DISPLAY", "DISPLAY",
		"NIRI_SOCKET", "SWAYSOCK", "DBUS_SESSION_BUS_ADDRESS",
	} {
		if v := os.Getenv(key); v != "" {
			t.Errorf("%s = %q reaches the live session", key, v)
		}
	}
	if rt := os.Getenv("XDG_RUNTIME_DIR"); !strings.HasPrefix(rt, os.TempDir()) {
		t.Errorf("XDG_RUNTIME_DIR = %q, want a throwaway dir under %s", rt, os.TempDir())
	}
}

// detachFromLiveSession drops the display, compositor and session-bus sockets
// and points XDG_RUNTIME_DIR at a throwaway 0700 dir, so a command a test runs
// finds no shell daemon, compositor or notification server to act on (sockets
// that live under the runtime dir go out of reach with it). It
// returns the cleanup for that dir.
func detachFromLiveSession() func() {
	for _, key := range []string{
		"WAYLAND_DISPLAY", "DISPLAY",
		"NIRI_SOCKET", "SWAYSOCK", "DBUS_SESSION_BUS_ADDRESS",
	} {
		os.Unsetenv(key)
	}
	rt, err := os.MkdirTemp("", "ryoku-test-runtime-")
	if err != nil {
		fmt.Fprintln(os.Stderr, "tests: runtime dir:", err)
		os.Exit(1)
	}
	_ = os.Chmod(rt, 0o700)
	os.Setenv("XDG_RUNTIME_DIR", rt)
	return func() { os.RemoveAll(rt) }
}
