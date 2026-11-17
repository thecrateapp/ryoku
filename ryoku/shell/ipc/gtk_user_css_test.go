package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// The GTK templates end with the user's own include, so a stylesheet the user
// (or a rice) writes to user.css survives every palette render.
func TestGtkTemplatesImportUserCSS(t *testing.T) {
	for _, name := range []string{"gtk3-colors.css", "gtk4-colors.css"} {
		b, err := os.ReadFile(filepath.Join("..", "matugen", "templates", name))
		if err != nil {
			t.Fatal(err)
		}
		if !strings.HasSuffix(strings.TrimSpace(string(b)), `@import url("user.css");`) {
			t.Errorf("%s does not end with the user.css import", name)
		}
	}
}

func TestEnsureGtkUserCSSCreatesMissing(t *testing.T) {
	base := t.TempDir()
	ensureGtkUserCSS(base)
	for _, rel := range []string{"gtk-3.0/user.css", "gtk-4.0/user.css"} {
		b, err := os.ReadFile(filepath.Join(base, rel))
		if err != nil {
			t.Fatalf("%s: %v", rel, err)
		}
		if len(b) != 0 {
			t.Errorf("%s should start empty, got %q", rel, b)
		}
	}
}

func TestEnsureGtkUserCSSKeepsExisting(t *testing.T) {
	base := t.TempDir()
	mine := []byte("window { padding: 2px; }\n")
	p := filepath.Join(base, "gtk-4.0", "user.css")
	if err := os.MkdirAll(filepath.Dir(p), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(p, mine, 0o600); err != nil {
		t.Fatal(err)
	}
	ensureGtkUserCSS(base)
	b, _ := os.ReadFile(p)
	if string(b) != string(mine) {
		t.Errorf("user.css rewritten: %q", b)
	}
	if st, _ := os.Stat(p); st.Mode().Perm() != 0o600 {
		t.Errorf("user.css mode changed to %v", st.Mode().Perm())
	}
}
