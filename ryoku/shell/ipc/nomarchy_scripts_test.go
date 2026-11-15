package main

import (
	"os"
	"os/exec"
	"path/filepath"
	"testing"
)

// nomarchyHome is a throwaway XDG layout with nomarchy activated once: the
// command root exists and the theme it rendered sits in Omarchy's state.
type nomarchyHome struct {
	home, data, state, config, cache, bin string
}

func newNomarchyHome(t *testing.T) nomarchyHome {
	t.Helper()
	home := t.TempDir()
	h := nomarchyHome{
		home:   home,
		data:   filepath.Join(home, ".local", "share"),
		state:  filepath.Join(home, ".local", "state"),
		config: filepath.Join(home, ".config"),
		cache:  filepath.Join(home, ".cache"),
		bin:    filepath.Join(home, ".local", "bin"),
	}
	for _, d := range []string{
		filepath.Join(h.data, "ryoku", "nomarchy"),
		filepath.Join(h.state, "omarchy", "current", "theme"),
		filepath.Join(h.config, "omarchy"),
		h.cache, h.bin,
	} {
		if err := os.MkdirAll(d, 0o755); err != nil {
			t.Fatal(err)
		}
	}
	writeFile(t, filepath.Join(h.state, "omarchy", "current", "theme", "colors.toml"), "accent = \"#b1c5ff\"\n")
	writeFile(t, filepath.Join(h.config, "omarchy", "current-theme"), "ryoku\n")
	return h
}

func (h nomarchyHome) run(t *testing.T, script string, args ...string) error {
	t.Helper()
	cmd := exec.Command(script, args...)
	cmd.Env = []string{
		"HOME=" + h.home,
		"PATH=" + h.bin + ":" + os.Getenv("PATH"),
		"XDG_DATA_HOME=" + h.data,
		"XDG_STATE_HOME=" + h.state,
		"XDG_CONFIG_HOME=" + h.config,
		"XDG_CACHE_HOME=" + h.cache,
		"XDG_BIN_HOME=" + h.bin,
		"XDG_RUNTIME_DIR=" + t.TempDir(),
	}
	out, err := cmd.CombinedOutput()
	if err != nil {
		t.Logf("%s: %s", filepath.Base(script), out)
	}
	return err
}

func exists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}

// Apps that follow Omarchy (ZapFast and the other fastframe apps) treat
// ~/.config/omarchy plus ~/.local/state/omarchy/current as "Omarchy is
// running" and then call omarchy-* commands. Once the nomarchy bar style is
// off those commands are gone, so the theme it left in Omarchy's state has to
// go too; activation renders it again.
func TestNomarchyDeactivateClearsTheOmarchyThemeItRendered(t *testing.T) {
	h := newNomarchyHome(t)
	script := "../nomarchy/nomarchy-deactivate"
	current := filepath.Join(h.state, "omarchy", "current")

	if err := h.run(t, script, "--check"); err == nil {
		t.Fatal("--check passed while nomarchy's theme is still in Omarchy's state")
	}
	if err := h.run(t, script); err != nil {
		t.Fatal(err)
	}
	if exists(current) {
		t.Error("deactivation left ~/.local/state/omarchy/current behind")
	}
	if !exists(filepath.Join(h.config, "omarchy", "current-theme")) {
		t.Error("deactivation removed the user's Omarchy config")
	}
	if err := h.run(t, script, "--check"); err != nil {
		t.Errorf("--check after deactivation = %v, want clean", err)
	}
}

func TestNomarchyDeactivateLeavesARealOmarchyAlone(t *testing.T) {
	h := newNomarchyHome(t)
	if err := os.MkdirAll(filepath.Join(h.data, "omarchy"), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := h.run(t, "../nomarchy/nomarchy-deactivate"); err != nil {
		t.Fatal(err)
	}
	if !exists(filepath.Join(h.state, "omarchy", "current", "theme", "colors.toml")) {
		t.Error("deactivation removed the theme of an Omarchy install that is not nomarchy's")
	}
}

// matugen 4 refuses a config file without a [config] table.
func TestOmarchyThemeSetRendersTheWallpaperPaletteWithMatugen4(t *testing.T) {
	h := newNomarchyHome(t)
	for _, d := range []string{filepath.Join(h.cache, "ryoku"), filepath.Join(h.config, "matugen", "templates")} {
		if err := os.MkdirAll(d, 0o755); err != nil {
			t.Fatal(err)
		}
	}
	writeFile(t, filepath.Join(h.cache, "ryoku", "matugen-carrier.json"), "{}\n")
	writeFile(t, filepath.Join(h.config, "matugen", "templates", "nomarchy-colors.toml"), "accent = \"{{colors.primary.default.hex}}\"\n")
	writeFile(t, filepath.Join(h.bin, "matugen"), `#!/bin/bash
while [[ $# -gt 0 ]]; do [[ $1 == -c ]] && cfg=$2; shift; done
grep -q '^\[config\]' "$cfg" || { echo "missing field config" >&2; exit 1; }
out=$(sed -n 's/^output_path = "\(.*\)"$/\1/p' "$cfg")
echo 'accent = "#06b6d4"' >"$out"
`)
	if err := os.Chmod(filepath.Join(h.bin, "matugen"), 0o755); err != nil {
		t.Fatal(err)
	}
	// the rest of a theme switch (shell templates, the live shell) is out of
	// scope here: only the palette render is checked
	_ = h.run(t, "../nomarchy/bin/omarchy-theme-set", "ryoku")
	if !exists(filepath.Join(h.cache, "ryoku", "nomarchy-colors.toml")) {
		t.Fatal("the wallpaper palette was not rendered: matugen rejected the config")
	}
}
