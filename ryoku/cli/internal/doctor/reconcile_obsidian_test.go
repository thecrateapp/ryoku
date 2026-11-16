package doctor

import (
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"testing"
)

// TestReconcileObsidianSnippet covers the guard (no vault -> no-op), the install
// (snippet symlink + enable), preservation of a user's other snippets, and
// idempotency.
func TestReconcileObsidianSnippet(t *testing.T) {
	home := t.TempDir()
	t.Setenv("HOME", home)
	t.Setenv("XDG_CONFIG_HOME", filepath.Join(home, ".config"))

	if r := reconcileObsidianSnippet(false); r.status != recOK {
		t.Fatalf("no config: status=%s want ok", r.status.label())
	}

	cfg := filepath.Join(home, ".config")
	generated := filepath.Join(cfg, "matugen", "generated", "obsidian.css")
	browserMkdir(t, filepath.Dir(generated))
	if err := os.WriteFile(generated, []byte(".theme-dark{}"), 0o644); err != nil {
		t.Fatal(err)
	}
	vault := filepath.Join(home, "vault")
	browserMkdir(t, filepath.Join(vault, ".obsidian"))
	// a pre-existing user snippet the reconciler must not drop
	if err := os.WriteFile(filepath.Join(vault, ".obsidian", "appearance.json"), []byte(`{"enabledCssSnippets":["mine"]}`), 0o644); err != nil {
		t.Fatal(err)
	}
	browserMkdir(t, filepath.Join(cfg, "obsidian"))
	if err := os.WriteFile(filepath.Join(cfg, "obsidian", "obsidian.json"),
		[]byte(`{"vaults":{"abc":{"path":`+strconv.Quote(vault)+`}}}`), 0o644); err != nil {
		t.Fatal(err)
	}

	r := reconcileObsidianSnippet(false)
	if r.status != recFixed {
		t.Fatalf("install: status=%s want fixed (detail=%s)", r.status.label(), r.detail)
	}
	link := filepath.Join(vault, ".obsidian", "snippets", "ryoku.css")
	if tgt, err := os.Readlink(link); err != nil || tgt != generated {
		t.Fatalf("snippet link=%q err=%v want -> %s", tgt, err, generated)
	}
	ap := browserReadManifest(t, filepath.Join(vault, ".obsidian", "appearance.json"))
	snips, _ := ap["enabledCssSnippets"].([]any)
	hasRyoku, hasMine := false, false
	for _, s := range snips {
		if s == "ryoku" {
			hasRyoku = true
		}
		if s == "mine" {
			hasMine = true
		}
	}
	if !hasRyoku || !hasMine {
		t.Fatalf("enabledCssSnippets=%v want both ryoku and mine", snips)
	}

	if r2 := reconcileObsidianSnippet(false); r2.status != recOK {
		t.Fatalf("second run: status=%s want ok (detail=%s)", r2.status.label(), r2.detail)
	}
}

// TestSyncObsidianSnippetFollowsTheTheme: the palette snippet is on only while
// a vault uses Obsidian's default theme; a community theme (Crate, Nord...) is
// left to show its own colours, and every other snippet and setting survives.
func TestSyncObsidianSnippetFollowsTheTheme(t *testing.T) {
	cases := []struct {
		name     string
		in       string // "" means no appearance.json
		want     snippetChange
		snippets []string // enabledCssSnippets after an apply
		theme    string   // cssTheme after an apply ("" when absent)
	}{
		{"no file, default theme", "", snippetEnabled, []string{"ryoku"}, ""},
		{"default theme, not yet on", `{"enabledCssSnippets":["mine"]}`, snippetEnabled, []string{"mine", "ryoku"}, ""},
		{"default theme, already on", `{"cssTheme":"","enabledCssSnippets":["ryoku"]}`, snippetUnchanged, []string{"ryoku"}, ""},
		{"community theme, snippet on", `{"cssTheme":"Crate","enabledCssSnippets":["mine","ryoku"],"theme":"obsidian"}`, snippetDisabled, []string{"mine"}, "Crate"},
		{"community theme, snippet off", `{"cssTheme":"Nord","enabledCssSnippets":["mine"]}`, snippetUnchanged, []string{"mine"}, "Nord"},
		{"community theme, no snippets", `{"cssTheme":"Nord"}`, snippetUnchanged, nil, "Nord"},
		{"blank theme name counts as default", `{"cssTheme":"  "}`, snippetEnabled, []string{"ryoku"}, "  "},
		{"unparseable file left alone", `{not json`, snippetUnchanged, nil, ""},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			path := filepath.Join(t.TempDir(), ".obsidian", "appearance.json")
			if tc.in != "" {
				browserMkdir(t, filepath.Dir(path))
				if err := os.WriteFile(path, []byte(tc.in), 0o644); err != nil {
					t.Fatal(err)
				}
			}

			// check-only reports the same change without writing
			got, err := syncObsidianSnippet(path, false)
			if err != nil || got != tc.want {
				t.Fatalf("check: change=%v err=%v want %v", got, err, tc.want)
			}
			if tc.in != "" {
				if b, _ := os.ReadFile(path); string(b) != tc.in {
					t.Fatalf("check-only rewrote the file: %s", b)
				}
			} else if _, err := os.Stat(path); err == nil {
				t.Fatal("check-only created appearance.json")
			}

			got, err = syncObsidianSnippet(path, true)
			if err != nil || got != tc.want {
				t.Fatalf("apply: change=%v err=%v want %v", got, err, tc.want)
			}
			if tc.in == `{not json` {
				if b, _ := os.ReadFile(path); string(b) != tc.in {
					t.Fatalf("unparseable file was rewritten: %s", b)
				}
				return
			}
			ap := browserReadManifest(t, path)
			var snips []string
			if list, ok := ap["enabledCssSnippets"].([]any); ok {
				for _, s := range list {
					snips = append(snips, s.(string))
				}
			}
			if strings.Join(snips, ",") != strings.Join(tc.snippets, ",") {
				t.Fatalf("enabledCssSnippets=%v want %v", snips, tc.snippets)
			}
			if th, _ := ap["cssTheme"].(string); th != tc.theme {
				t.Fatalf("cssTheme=%q want %q (never edited)", th, tc.theme)
			}
			if again, _ := syncObsidianSnippet(path, true); again != snippetUnchanged {
				t.Fatalf("second apply: change=%v want unchanged", again)
			}
		})
	}
}

// TestReconcileObsidianSnippetLeavesACommunityTheme: a vault on the Crate theme
// keeps the link (harmless) but loses the enabled snippet; a vault on the
// default theme in the same run gets it.
func TestReconcileObsidianSnippetLeavesACommunityTheme(t *testing.T) {
	home := t.TempDir()
	t.Setenv("HOME", home)
	t.Setenv("XDG_CONFIG_HOME", filepath.Join(home, ".config"))
	cfg := filepath.Join(home, ".config")

	themed := filepath.Join(home, "themed")
	plain := filepath.Join(home, "plain")
	for _, v := range []string{themed, plain} {
		browserMkdir(t, filepath.Join(v, ".obsidian"))
	}
	if err := os.WriteFile(filepath.Join(themed, ".obsidian", "appearance.json"),
		[]byte(`{"cssTheme":"Crate","enabledCssSnippets":["ryoku"]}`), 0o644); err != nil {
		t.Fatal(err)
	}
	browserMkdir(t, filepath.Join(cfg, "obsidian"))
	if err := os.WriteFile(filepath.Join(cfg, "obsidian", "obsidian.json"),
		[]byte(`{"vaults":{"a":{"path":`+strconv.Quote(themed)+`},"b":{"path":`+strconv.Quote(plain)+`}}}`), 0o644); err != nil {
		t.Fatal(err)
	}

	if r := reconcileObsidianSnippet(true); r.status != recWouldFix || !strings.Contains(r.detail, "own theme") {
		t.Fatalf("check: status=%s detail=%q want would, naming the themed vault", r.status.label(), r.detail)
	}
	if r := reconcileObsidianSnippet(false); r.status != recFixed {
		t.Fatalf("apply: status=%s want fixed (detail=%s)", r.status.label(), r.detail)
	}
	themedAp := browserReadManifest(t, filepath.Join(themed, ".obsidian", "appearance.json"))
	if list, _ := themedAp["enabledCssSnippets"].([]any); len(list) != 0 {
		t.Fatalf("themed vault snippets=%v want none", list)
	}
	if themedAp["cssTheme"] != "Crate" {
		t.Fatalf("themed vault cssTheme=%v want Crate", themedAp["cssTheme"])
	}
	plainAp := browserReadManifest(t, filepath.Join(plain, ".obsidian", "appearance.json"))
	if list, _ := plainAp["enabledCssSnippets"].([]any); len(list) != 1 || list[0] != "ryoku" {
		t.Fatalf("plain vault snippets=%v want [ryoku]", list)
	}
	if r := reconcileObsidianSnippet(false); r.status != recOK {
		t.Fatalf("second run: status=%s want ok (detail=%s)", r.status.label(), r.detail)
	}
}
