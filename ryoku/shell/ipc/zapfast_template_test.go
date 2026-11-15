package main

import (
	"encoding/json"
	"os"
	"regexp"
	"strings"
	"testing"
)

// ZapFast (a WhatsApp client) reads palettes from ~/.config/zapfast/themes and
// lists each file by name; the shipped template renders the active Ryoku palette
// there as "Ryoku", so choosing it in ZapFast follows every theme change.
func TestZapFastTemplateShipsEveryPaletteKey(t *testing.T) {
	apps, err := os.ReadFile("../matugen/apps.toml")
	if err != nil {
		t.Fatal(err)
	}
	block := regexp.MustCompile(`(?m)^\[templates\.zapfast\]\ninput_path = "~/\.config/matugen/templates/zapfast\.json"\noutput_path = "~/\.config/zapfast/themes/Ryoku\.json"$`)
	if !block.Match(apps) {
		t.Fatal("apps.toml has no [templates.zapfast] block rendering ~/.config/zapfast/themes/Ryoku.json")
	}

	raw, err := os.ReadFile("../matugen/templates/zapfast.json")
	if err != nil {
		t.Fatal(err)
	}
	// every placeholder stands for one colour string; the rest must already be JSON
	filled := regexp.MustCompile(`\{\{[^}]*\}\}`).ReplaceAllString(string(raw), "x")
	var theme struct {
		Base   string            `json:"base"`
		Colors map[string]string `json:"colors"`
	}
	if err := json.Unmarshal([]byte(filled), &theme); err != nil {
		t.Fatalf("template is not JSON once filled: %v", err)
	}
	if theme.Base != "x" {
		t.Errorf("base = %q, want the {{mode}} placeholder", theme.Base)
	}
	want := []string{
		"window", "panel", "surface", "surface_hover", "surface_active", "outline",
		"text", "secondary", "dim", "accent", "accent_hover", "on_accent", "danger",
		"warning", "overlay", "shadow", "chat", "bubble_in", "bubble_out", "link", "read",
	}
	for _, k := range want {
		v, ok := theme.Colors[k]
		if !ok {
			t.Errorf("colour %q missing", k)
		} else if !strings.Contains(v, "x") {
			t.Errorf("colour %q = %q is fixed, not taken from the palette", k, v)
		}
	}
	if len(theme.Colors) != len(want) {
		t.Errorf("template has %d colours, ZapFast reads %d", len(theme.Colors), len(want))
	}
}
