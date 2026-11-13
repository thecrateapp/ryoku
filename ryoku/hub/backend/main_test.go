package main

import (
	"os"
	"testing"
)

// TestMain keeps every test away from the developer's running desktop: the
// backend shells out to ryoku-shell, ryogami and the compositor, which would
// otherwise repaint the live session.
func TestMain(m *testing.M) {
	cleanup := detachFromLiveSession()
	code := m.Run()
	cleanup()
	os.Exit(code)
}
