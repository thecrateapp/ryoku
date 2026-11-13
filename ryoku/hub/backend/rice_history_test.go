package main

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"testing"
	"time"
)

func historyStamps(t *testing.T) []string {
	t.Helper()
	entries, err := os.ReadDir(filepath.Join(ricesDir(), ".history"))
	if err != nil && !os.IsNotExist(err) {
		t.Fatal(err)
	}
	var out []string
	for _, e := range entries {
		out = append(out, e.Name())
	}
	sort.Strings(out)
	return out
}

// Every apply replaces .previous; the one it replaces moves into .history so a
// second apply (a stray first-login default, a misclick) never destroys the
// only copy of the user's own look.
func TestRotatePreviousKeepsTheReplacedLook(t *testing.T) {
	t.Setenv("XDG_CONFIG_HOME", t.TempDir())
	prev := filepath.Join(ricesDir(), ".previous")
	writeHistoryFile(t, filepath.Join(prev, "shell.json"), `{"mine":true}`)

	now := time.Date(2026, 11, 13, 9, 19, 8, 0, time.UTC)
	if err := rotatePrevious(now); err != nil {
		t.Fatal(err)
	}
	if _, err := os.Stat(prev); !os.IsNotExist(err) {
		t.Fatalf(".previous still present after rotation (err=%v)", err)
	}
	got, err := os.ReadFile(filepath.Join(ricesDir(), ".history", "20261113-091908", "shell.json"))
	if err != nil || string(got) != `{"mine":true}` {
		t.Fatalf("history copy = %q, %v", got, err)
	}

	// the same second twice keeps both
	writeHistoryFile(t, filepath.Join(prev, "shell.json"), `{"second":true}`)
	if err := rotatePrevious(now); err != nil {
		t.Fatal(err)
	}
	if stamps := historyStamps(t); len(stamps) != 2 {
		t.Fatalf("history = %v, want two entries", stamps)
	}
}

func TestRotatePreviousWithoutPreviousIsANoop(t *testing.T) {
	t.Setenv("XDG_CONFIG_HOME", t.TempDir())
	if err := rotatePrevious(time.Now()); err != nil {
		t.Fatal(err)
	}
	if stamps := historyStamps(t); len(stamps) != 0 {
		t.Fatalf("history = %v, want none", stamps)
	}
}

func TestRotatePreviousKeepsTheNewestTen(t *testing.T) {
	t.Setenv("XDG_CONFIG_HOME", t.TempDir())
	base := time.Date(2026, 11, 1, 0, 0, 0, 0, time.UTC)
	for i := range 13 {
		writeHistoryFile(t, filepath.Join(ricesDir(), ".previous", "shell.json"), fmt.Sprintf(`{"n":%d}`, i))
		if err := rotatePrevious(base.Add(time.Duration(i) * time.Hour)); err != nil {
			t.Fatal(err)
		}
	}
	stamps := historyStamps(t)
	if len(stamps) != riceHistoryKeep {
		t.Fatalf("history holds %d entries, want %d", len(stamps), riceHistoryKeep)
	}
	if stamps[0] != "20261101-030000" || stamps[len(stamps)-1] != "20261101-120000" {
		t.Fatalf("history = %v, want the newest ten", stamps)
	}
}

func TestRiceRestoreSlot(t *testing.T) {
	for _, c := range []struct {
		arg, want string
		ok        bool
	}{
		{"", ".baseline", true},
		{"previous", ".previous", true},
		{"history/20261113-091908", filepath.Join(".history", "20261113-091908"), true},
		{"history/../crate", "", false},
		{"history/", "", false},
		{"history/a/b", "", false},
	} {
		got, err := riceRestoreSlot(c.arg)
		if (err == nil) != c.ok || got != c.want {
			t.Errorf("riceRestoreSlot(%q) = %q, %v; want %q ok=%v", c.arg, got, err, c.want, c.ok)
		}
	}
}

func writeHistoryFile(t *testing.T, path, body string) {
	t.Helper()
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, []byte(body), 0o644); err != nil {
		t.Fatal(err)
	}
}
