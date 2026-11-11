package main

import (
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
)

// sampleBlock is a Noctalia block with known values so the conversion is checked
// against exact expected roles, including the interpolated elevation ramp.
var sampleBlock = noctaliaColors{
	Primary:          "#ff0000",
	OnPrimary:        "#000000",
	Secondary:        "#00ff00",
	OnSecondary:      "#000000",
	Tertiary:         "#0000ff",
	OnTertiary:       "#000000",
	Error:            "#ff00ff",
	OnError:          "#000000",
	Surface:          "#000000",
	OnSurface:        "#ffffff",
	SurfaceVariant:   "#101010",
	OnSurfaceVariant: "#cccccc",
	Outline:          "#808080",
	Shadow:           "#000000",
}

func TestNoctaliaTo34Golden(t *testing.T) {
	pal := noctaliaTo34(sampleBlock)
	if pal == nil {
		t.Fatal("conversion returned nil for a complete block")
	}
	if len(pal) != len(themeRoles) {
		t.Fatalf("palette has %d roles, want %d", len(pal), len(themeRoles))
	}
	for _, role := range themeRoles {
		if !hexColor.MatchString(pal[role]) {
			t.Fatalf("role %q = %q, not a hex colour", role, pal[role])
		}
	}
	want := map[string]string{
		"surface":                 "#000000",
		"background":              "#000000",
		"onSurface":               "#ffffff",
		"primary":                 "#ff0000",
		"surfaceTint":             "#ff0000",
		"onPrimary":               "#000000",
		"secondary":               "#00ff00",
		"tertiary":                "#0000ff",
		"error":                   "#ff00ff",
		"surfaceVariant":          "#101010",
		"onSurfaceVariant":        "#cccccc",
		"outline":                 "#808080",
		"surfaceContainerLow":     "#080808", // mix(#000000,#101010,0.5)
		"surfaceContainer":        "#101010",
		"surfaceContainerHigh":    "#373737", // mix(#101010,#808080,0.35)
		"surfaceContainerHighest": "#535353", // mix(#101010,#808080,0.6)
		"outlineVariant":          "#404040", // mix(#808080,#000000,0.5)
		"primaryContainer":        "#101010",
		"scrim":                   "#000000",
	}
	for role, exp := range want {
		if pal[role] != exp {
			t.Errorf("role %q = %q, want %q", role, pal[role], exp)
		}
	}
}

func TestNoctaliaTo34RejectsIncomplete(t *testing.T) {
	if noctaliaTo34(noctaliaColors{Surface: "#000000"}) != nil {
		t.Fatal("a block missing onSurface/primary must not convert")
	}
}

// installFixtureTheme writes a library entry under a temp XDG_DATA_HOME.
func installFixtureTheme(t *testing.T, id, label, provider string, scheme noctaliaScheme) {
	t.Helper()
	dir := filepath.Join(userThemeDir(), id)
	if err := os.MkdirAll(dir, 0o755); err != nil {
		t.Fatal(err)
	}
	sb, _ := json.Marshal(scheme)
	if err := os.WriteFile(filepath.Join(dir, "scheme.json"), sb, 0o644); err != nil {
		t.Fatal(err)
	}
	mb, _ := json.Marshal(userThemeMeta{Label: label, Provider: provider})
	if err := os.WriteFile(filepath.Join(dir, "meta.json"), mb, 0o644); err != nil {
		t.Fatal(err)
	}
}

func TestUserThemeLibraryFlow(t *testing.T) {
	t.Setenv("XDG_DATA_HOME", t.TempDir())
	blk := sampleBlock
	installFixtureTheme(t, "hancore-sample", "Sample", "HANCORE-linux", noctaliaScheme{Dark: &blk})

	// lookupThemePalette resolves the installed id.
	pal, ok := lookupThemePalette("hancore-sample")
	if !ok || pal["primary"] != "#ff0000" {
		t.Fatalf("lookupThemePalette(installed) = %v, %v", pal["primary"], ok)
	}
	// A built-in still resolves and is not shadowed by the library.
	if _, ok := lookupThemePalette("Dracula"); !ok {
		t.Fatal("built-in Dracula no longer resolves")
	}
	// An unknown name resolves to nothing.
	if _, ok := lookupThemePalette("nope"); ok {
		t.Fatal("unknown theme resolved")
	}

	// theme.theme validation accepts the installed id.
	found := false
	for _, v := range effectiveThemeThemeValues() {
		if v == "hancore-sample" {
			found = true
		}
	}
	if !found {
		t.Fatal("effectiveThemeThemeValues omits the installed id")
	}

	// The catalog projection carries the user card after the built-ins, tagged.
	cat := themeCatalog()
	var card *themeCard
	for i := range cat {
		if cat[i].ID == "hancore-sample" {
			card = &cat[i]
		}
	}
	if card == nil {
		t.Fatal("themeCatalog omits the installed scheme")
	}
	if card.Provider != "HANCORE-linux" || card.Label != "Sample" || !card.Dark {
		t.Fatalf("user card = %+v, want provider HANCORE-linux, label Sample, dark true", *card)
	}
	if len(card.Sw) != len(themeSwatchRoles) || card.Sw[0] != "#000000" || card.Sw[2] != "#ff0000" {
		t.Fatalf("user card swatch = %v", card.Sw)
	}
}

func TestUserThemeBuiltinIDNotShadowed(t *testing.T) {
	t.Setenv("XDG_DATA_HOME", t.TempDir())
	blk := sampleBlock
	installFixtureTheme(t, "Dracula", "Impostor", "x", noctaliaScheme{Dark: &blk})
	// The built-in palette must win over a library dir that reuses its id.
	pal, ok := lookupThemePalette("Dracula")
	if !ok || pal["primary"] == "#ff0000" {
		t.Fatal("library entry shadowed the built-in Dracula")
	}
	for _, tm := range userThemes() {
		if tm.ID == "Dracula" {
			t.Fatal("userThemes surfaced a built-in id")
		}
	}
}

// TestUserThemeCardsIgnorePreviewArt proves a scheme that ships preview art is
// still projected as swatches, like every other card. The libraries ship a 16:9
// illustrated mockup, which cannot be cropped into the picker's portrait tile
// without reading as a broken nested card, so the art on disk is ignored and the
// palette is what the picker draws.
func TestUserThemeCardsIgnorePreviewArt(t *testing.T) {
	t.Setenv("XDG_DATA_HOME", t.TempDir())
	blk := sampleBlock
	installFixtureTheme(t, "with-art", "With Art", "Ryoku", noctaliaScheme{Dark: &blk})
	installFixtureTheme(t, "no-art", "No Art", "Ryoku", noctaliaScheme{Dark: &blk})

	art := filepath.Join(userThemeDir(), "with-art", "preview.png")
	if err := os.WriteFile(art, []byte("\x89PNG\r\n"), 0o644); err != nil {
		t.Fatal(err)
	}

	cards := map[string]themeCard{}
	for _, c := range userThemeCards() {
		cards[c.ID] = c
	}
	for _, id := range []string{"with-art", "no-art"} {
		c, ok := cards[id]
		if !ok {
			t.Fatalf("%s missing from the catalog", id)
		}
		if len(c.Sw) != len(themeSwatchRoles) {
			t.Fatalf("%s carries %d swatches, want %d", id, len(c.Sw), len(themeSwatchRoles))
		}
		for i, s := range c.Sw {
			if s == "" {
				t.Fatalf("%s swatch %d is empty; the picker would draw a gap", id, i)
			}
		}
	}
}

// TestRemoveUserTheme proves an installed scheme is deleted, and that a built-in
// name, an unknown id, and a path-traversal id are all refused so removal can
// never touch anything outside the library.
func TestRemoveUserTheme(t *testing.T) {
	t.Setenv("XDG_DATA_HOME", t.TempDir())
	blk := sampleBlock
	installFixtureTheme(t, "hancore-sample", "Sample", "HANCORE-linux", noctaliaScheme{Dark: &blk})

	if err := removeUserTheme("hancore-sample"); err != nil {
		t.Fatalf("removeUserTheme(installed) = %v", err)
	}
	if _, err := os.Stat(filepath.Join(userThemeDir(), "hancore-sample")); !os.IsNotExist(err) {
		t.Fatalf("scheme dir survived removal: %v", err)
	}

	// A second removal, a built-in name, and a traversal id are all refused.
	if err := removeUserTheme("hancore-sample"); err == nil {
		t.Fatal("removing an absent scheme should error")
	}
	if err := removeUserTheme("Dracula"); err == nil {
		t.Fatal("removing a built-in name should error")
	}
	if err := removeUserTheme("../evil"); err == nil {
		t.Fatal("a traversal id should be refused")
	}
}

// TestDispatchThemeRemove drives the wired `theme remove <id>` path: it deletes
// the scheme and, when that scheme is the applied one, resets theme.theme to
// Default first so the desktop never keeps a scheme whose files are gone.
func TestDispatchThemeRemove(t *testing.T) {
	t.Setenv("XDG_DATA_HOME", t.TempDir())
	blk := sampleBlock
	installFixtureTheme(t, "hancore-sample", "Sample", "HANCORE-linux", noctaliaScheme{Dark: &blk})

	store := newSettingsStore(filepath.Join(t.TempDir(), "shell.json"))
	id, _ := json.Marshal("hancore-sample")
	if err := store.patch("theme.theme", id); err != nil {
		t.Fatalf("apply installed scheme: %v", err)
	}
	d := &daemon{settings: store}

	if got := d.dispatch("theme remove hancore-sample"); got != "ok" {
		t.Fatalf("dispatch theme remove = %q, want ok", got)
	}
	if _, err := os.Stat(filepath.Join(userThemeDir(), "hancore-sample")); !os.IsNotExist(err) {
		t.Fatalf("scheme dir survived removal: %v", err)
	}
	if got := store.themeName(); got != "Default" {
		t.Fatalf("applied scheme = %q after removing the active one, want Default", got)
	}
}

func TestNoctaliaRolesOverrideDerivedRoles(t *testing.T) {
	block := sampleBlock
	block.Roles = map[string]string{
		"inverseSurface":      "#67E8F9",
		"inverseOnSurface":    "#0a0a0f",
		"surfaceContainerLow": "#0f1016",
	}
	pal := noctaliaTo34(block)
	want := map[string]string{
		"inverseSurface":      "#67e8f9",
		"inverseOnSurface":    "#0a0a0f",
		"surfaceContainerLow": "#0f1016",
	}
	for role, value := range want {
		if pal[role] != value {
			t.Fatalf("role %q = %q, want %q", role, pal[role], value)
		}
	}
	base := noctaliaTo34(sampleBlock)
	for role, value := range base {
		if _, pinned := want[role]; !pinned && pal[role] != value {
			t.Fatalf("unpinned role %q changed: %q -> %q", role, value, pal[role])
		}
	}
	if len(pal) != len(themeRoles) {
		t.Fatalf("palette has %d roles, want %d", len(pal), len(themeRoles))
	}
}

func TestNoctaliaRolesIgnoreUnknownAndMalformed(t *testing.T) {
	block := sampleBlock
	block.Roles = map[string]string{
		"inverseSurface": "cyan",
		"onSurface":      "#12345",
		"primary":        "67e8f9",
		"notARole":       "#67e8f9",
	}
	pal := noctaliaTo34(block)
	base := noctaliaTo34(sampleBlock)
	if len(pal) != len(base) {
		t.Fatalf("an unknown role was added: %d roles, want %d", len(pal), len(base))
	}
	for role, value := range base {
		if pal[role] != value {
			t.Fatalf("role %q = %q, want the derived %q", role, pal[role], value)
		}
	}
}

func TestNoctaliaRolesFromSchemeJSON(t *testing.T) {
	raw := `{"dark": {"mPrimary": "#06b6d4", "mSurface": "#0a0a0f", "mOnSurface": "#f1f5f9",
		"roles": {"inverseSurface": "#67e8f9", "inverseOnSurface": "#0a0a0f"}}}`
	var scheme noctaliaScheme
	if err := json.Unmarshal([]byte(raw), &scheme); err != nil {
		t.Fatal(err)
	}
	pal := noctaliaTo34(*scheme.Dark)
	if pal["inverseSurface"] != "#67e8f9" || pal["inverseOnSurface"] != "#0a0a0f" {
		t.Fatalf("roles from scheme.json not applied: %q / %q", pal["inverseSurface"], pal["inverseOnSurface"])
	}
}

func TestThemeStyleValuesSanitise(t *testing.T) {
	alpha := func(v float64) *float64 { return &v }
	weight := func(v int) *int { return &v }
	on := func(v bool) *bool { return &v }
	cases := []struct {
		name string
		spec *themeStyleSpec
		want map[string]any
	}{
		{"absent", nil, nil},
		{"empty", &themeStyleSpec{}, nil},
		{"set", &themeStyleSpec{LineAlpha: alpha(0.1), Display: " Bricolage Grotesque "},
			map[string]any{"lineAlpha": 0.1, "display": "Bricolage Grotesque"}},
		{"clamped low", &themeStyleSpec{LineAlpha: alpha(0)}, map[string]any{"lineAlpha": minLineAlpha}},
		{"clamped high", &themeStyleSpec{LineAlpha: alpha(3)}, map[string]any{"lineAlpha": maxLineAlpha}},
		{"bad face", &themeStyleSpec{Display: "Evil\"Font"}, nil},
		{"switches and weight", &themeStyleSpec{DisplayWeight: weight(1200), NavCaps: on(true), SelectFill: on(false)},
			map[string]any{"displayWeight": 900, "navCaps": true, "selectFill": false}},
	}
	for _, c := range cases {
		got := themeStyleValues(c.spec)
		if len(got) != len(c.want) {
			t.Fatalf("%s: got %v, want %v", c.name, got, c.want)
		}
		for k, v := range c.want {
			if got[k] != v {
				t.Fatalf("%s: %s = %v, want %v", c.name, k, got[k], v)
			}
		}
	}
}

func TestResolveThemePaletteWritesUserThemeStyle(t *testing.T) {
	data := t.TempDir()
	t.Setenv("XDG_DATA_HOME", data)
	t.Setenv("XDG_CONFIG_HOME", t.TempDir())
	dir := filepath.Join(data, "ryoku", "themes", "crate")
	if err := os.MkdirAll(dir, 0o755); err != nil {
		t.Fatal(err)
	}
	scheme := `{"dark": {"mPrimary": "#06b6d4", "mSurface": "#0a0a0f", "mOnSurface": "#f1f5f9",
		"style": {"lineAlpha": 0.1, "display": "Bricolage Grotesque"}}}`
	if err := os.WriteFile(filepath.Join(dir, "scheme.json"), []byte(scheme), 0o644); err != nil {
		t.Fatal(err)
	}
	full := map[string]any{}
	resolveThemePalette(full, "crate")
	style, ok := full["themeStyle"].(map[string]any)
	if !ok || style["lineAlpha"] != 0.1 || style["display"] != "Bricolage Grotesque" {
		t.Fatalf("themeStyle = %#v", full["themeStyle"])
	}
	if _, ok := full["themePalette"]; !ok {
		t.Fatal("themePalette missing")
	}
	// a built-in theme clears it
	for name := range themePalettes {
		resolveThemePalette(full, name)
		break
	}
	if _, ok := full["themeStyle"]; ok {
		t.Fatal("themeStyle kept for a built-in theme")
	}
}
