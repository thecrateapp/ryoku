package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"unicode"
)

// usertheme.go projects RyoStore-installed colour schemes into the daemon's
// static-theme world. RyoStore installs a scheme (install-only) under
// userThemeDir()/<id>/ as a Noctalia-format scheme.json ({dark?, light?} of
// mPrimary/.../mSurface roles) plus a meta.json ({label, provider}). Here the
// chosen Noctalia block is converted into the 34-role catalog palette every
// static-theme seam consumes (matugenApplyStatic, resolveThemePalette, the theme
// catalog projection, and theme.theme validation), so a downloaded scheme
// behaves exactly like a built-in one: it appears in the switcher belt and the
// Hub picker, applies through `ryoku-shell theme <id>`, and matugen fans it into
// every app. themePalettes (themes_gen.go) stays the built-in source of truth;
// the library only adds names and never shadows a built-in id.

// userThemeDir is the install root RyoStore writes to and this reads.
func userThemeDir() string {
	return filepath.Join(matugenDataHome(), "ryoku", "themes")
}

// noctaliaColors is the reduced Material set each Noctalia block carries. The
// catalog derives ANSI colours from the roles, exactly as it does for every
// built-in theme; a block's terminal sub-object, when present, replaces that
// derivation for the terminal templates only (term_* keys). Roles optionally pins
// catalog roles the reduced set cannot express (an accent-coloured
// inverseSurface, a surfaceContainerLow that is not the surface/variant midpoint)
// by their catalog name.
type noctaliaColors struct {
	Primary          string            `json:"mPrimary"`
	OnPrimary        string            `json:"mOnPrimary"`
	Secondary        string            `json:"mSecondary"`
	OnSecondary      string            `json:"mOnSecondary"`
	Tertiary         string            `json:"mTertiary"`
	OnTertiary       string            `json:"mOnTertiary"`
	Error            string            `json:"mError"`
	OnError          string            `json:"mOnError"`
	Surface          string            `json:"mSurface"`
	OnSurface        string            `json:"mOnSurface"`
	SurfaceVariant   string            `json:"mSurfaceVariant"`
	OnSurfaceVariant string            `json:"mOnSurfaceVariant"`
	Outline          string            `json:"mOutline"`
	Shadow           string            `json:"mShadow"`
	Roles            map[string]string `json:"roles"`
	Style            *themeStyleSpec   `json:"style"`
	Terminal         *noctaliaTerminal `json:"terminal"`
}

// noctaliaTerminal is a Noctalia block's terminal palette: the sixteen ANSI
// colours plus the surface, ink and cursor. A monochrome UI palette derives a
// terminal of one accent repeated; a scheme that ships its own reads as intended.
type noctaliaTerminal struct {
	Foreground string       `json:"foreground"`
	Background string       `json:"background"`
	Cursor     string       `json:"cursor"`
	CursorText string       `json:"cursorText"`
	SelectionF string       `json:"selectionFg"`
	SelectionB string       `json:"selectionBg"`
	Normal     noctaliaANSI `json:"normal"`
	Bright     noctaliaANSI `json:"bright"`
}

type noctaliaANSI struct {
	Black   string `json:"black"`
	Red     string `json:"red"`
	Green   string `json:"green"`
	Yellow  string `json:"yellow"`
	Blue    string `json:"blue"`
	Magenta string `json:"magenta"`
	Cyan    string `json:"cyan"`
	White   string `json:"white"`
}

// terminalValues maps a terminal block onto the term_* template keys
// (term_color0..15, term_background, term_foreground, term_cursor,
// term_cursor_text, term_selection_background, term_selection_foreground),
// keeping only valid #rrggbb values; nil when the block sets none.
func terminalValues(t *noctaliaTerminal) map[string]string {
	if t == nil {
		return nil
	}
	out := map[string]string{}
	put := func(key, hex string) {
		hex = strings.TrimSpace(hex)
		if _, _, _, ok := parseHexRGB(hex); ok && strings.HasPrefix(hex, "#") {
			out["term_"+key] = strings.ToLower(hex)
		}
	}
	put("background", t.Background)
	put("foreground", t.Foreground)
	put("cursor", t.Cursor)
	put("cursor_text", t.CursorText)
	put("selection_background", t.SelectionB)
	put("selection_foreground", t.SelectionF)
	for i, set := range []noctaliaANSI{t.Normal, t.Bright} {
		for j, hex := range []string{set.Black, set.Red, set.Green, set.Yellow, set.Blue, set.Magenta, set.Cyan, set.White} {
			put(fmt.Sprintf("color%d", i*8+j), hex)
		}
	}
	if len(out) == 0 {
		return nil
	}
	return out
}

// themeStyleSpec is a scheme's optional non-colour look for the Ryoku.Ui kit:
// how strong hairlines are (the ink alpha of Tokens.line, 0.26 by default), the
// display face and weight (Fraunces, regular), and a few switches for how
// navigation and state read: uppercase tracked navigation labels, accent
// selection marks and hover text, an accent focus edge, accent section
// captions, and whether a selected row also fills. Absent fields keep the
// signature look.
type themeStyleSpec struct {
	LineAlpha     *float64 `json:"lineAlpha"`
	Display       string   `json:"display"`
	NavFont       string   `json:"navFont"`
	DisplayWeight *int     `json:"displayWeight"`
	NavCaps       *bool    `json:"navCaps"`
	AccentMarks   *bool    `json:"accentMarks"`
	FocusAccent   *bool    `json:"focusAccent"`
	LabelAccent   *bool    `json:"labelAccent"`
	SelectFill    *bool    `json:"selectFill"`
}

const (
	minLineAlpha = 0.04
	maxLineAlpha = 0.6
)

// themeStyleValues sanitises a style block into the shell.json themeStyle map;
// nil when nothing usable is set, so a theme without a style writes no key.
// safeFace reports whether a font family from a theme file is fit to hand to
// the shell: non-empty, at most 64 bytes, and free of quotes, backslashes and
// control characters.
func safeFace(face string) bool {
	return face != "" && len(face) <= 64 && !strings.ContainsAny(face, "\"\\") &&
		strings.IndexFunc(face, unicode.IsControl) < 0
}

func themeStyleValues(spec *themeStyleSpec) map[string]any {
	if spec == nil {
		return nil
	}
	out := map[string]any{}
	if spec.LineAlpha != nil {
		a := *spec.LineAlpha
		if a < minLineAlpha {
			a = minLineAlpha
		}
		if a > maxLineAlpha {
			a = maxLineAlpha
		}
		out["lineAlpha"] = a
	}
	if face := strings.TrimSpace(spec.Display); safeFace(face) {
		out["display"] = face
	}
	if face := strings.TrimSpace(spec.NavFont); safeFace(face) {
		out["navFont"] = face
	}
	if spec.DisplayWeight != nil {
		w := *spec.DisplayWeight
		if w < 100 {
			w = 100
		}
		if w > 900 {
			w = 900
		}
		out["displayWeight"] = w
	}
	for key, v := range map[string]*bool{
		"navCaps":     spec.NavCaps,
		"accentMarks": spec.AccentMarks,
		"focusAccent": spec.FocusAccent,
		"labelAccent": spec.LabelAccent,
		"selectFill":  spec.SelectFill,
	} {
		if v != nil {
			out[key] = *v
		}
	}
	if len(out) == 0 {
		return nil
	}
	return out
}

// noctaliaScheme is the on-disk scheme.json: a dark and/or light block.
type noctaliaScheme struct {
	Dark  *noctaliaColors `json:"dark"`
	Light *noctaliaColors `json:"light"`
}

// userThemeMeta is the on-disk meta.json: the display label and the provider the
// scheme came from (the RyoStore subtab that offered it).
type userThemeMeta struct {
	Label    string `json:"label"`
	Provider string `json:"provider"`
}

// userTheme is one installed scheme resolved to the catalog's role palette. The
// preview art beside it, when present, is reported on the card by
// userThemeCards, not carried here.
type userTheme struct {
	ID       string
	Label    string
	Provider string
	Palette  map[string]string // the 34 catalog roles
	Style    map[string]any    // sanitised themeStyle, nil when the scheme sets none
	Terminal map[string]string // term_* template keys, nil when the scheme sets none
}

// userThemes loads and converts every installed scheme, id-sorted for a stable
// catalog order. A malformed or unreadable entry is skipped, never fatal: a bad
// download can never blank the belt or the built-in catalog.
func userThemes() []userTheme {
	entries, err := os.ReadDir(userThemeDir())
	if err != nil {
		return nil
	}
	out := make([]userTheme, 0, len(entries))
	for _, e := range entries {
		if !e.IsDir() {
			continue
		}
		id := e.Name()
		if _, baked := themePalettes[id]; baked {
			continue // a built-in id always wins; the library never shadows it
		}
		dir := filepath.Join(userThemeDir(), id)
		schemeRaw, err := os.ReadFile(filepath.Join(dir, "scheme.json"))
		if err != nil {
			continue
		}
		var scheme noctaliaScheme
		if json.Unmarshal(schemeRaw, &scheme) != nil {
			continue
		}
		block := scheme.Dark
		if block == nil {
			block = scheme.Light
		}
		if block == nil {
			continue
		}
		pal := noctaliaTo34(*block)
		if pal == nil {
			continue
		}
		meta := userThemeMeta{}
		if metaRaw, err := os.ReadFile(filepath.Join(dir, "meta.json")); err == nil {
			_ = json.Unmarshal(metaRaw, &meta)
		}
		label := meta.Label
		if label == "" {
			label = id
		}
		out = append(out, userTheme{ID: id, Label: label, Provider: meta.Provider, Palette: pal, Style: themeStyleValues(block.Style), Terminal: terminalValues(block.Terminal)})
	}
	sort.Slice(out, func(i, j int) bool { return out[i].ID < out[j].ID })
	return out
}

// noctaliaTo34 converts one Noctalia block into the 34-role catalog palette. The
// elevation ramp runs surface -> surfaceVariant -> outline; each accent maps to
// its Material role with the surface variant as its container. A block missing
// the core roles (surface, onSurface, primary) is unusable and returns nil.
// Entries in the block's roles object then replace derived roles; an unknown
// role name or a value that is not #rrggbb is ignored, so a typo never blanks a
// role.
func noctaliaTo34(c noctaliaColors) map[string]string {
	pal := deriveNoctalia34(c)
	if pal == nil {
		return nil
	}
	for name, value := range c.Roles {
		if _, known := pal[name]; !known {
			continue
		}
		if _, _, _, ok := parseHexRGB(value); ok && strings.HasPrefix(value, "#") {
			pal[name] = strings.ToLower(value)
		}
	}
	return pal
}

func deriveNoctalia34(c noctaliaColors) map[string]string {
	if c.Surface == "" || c.OnSurface == "" || c.Primary == "" {
		return nil
	}
	role := func(v, fallback string) string {
		if v != "" {
			return v
		}
		return fallback
	}
	sv := role(c.SurfaceVariant, mixHex(c.Surface, c.OnSurface, 0.12))
	outline := role(c.Outline, mixHex(c.Surface, c.OnSurface, 0.4))
	shadow := role(c.Shadow, "#000000")
	return map[string]string{
		"surface":                 c.Surface,
		"background":              c.Surface,
		"scrim":                   shadow,
		"shadow":                  shadow,
		"surfaceContainerLowest":  c.Surface,
		"inverseOnSurface":        c.Surface,
		"onSurface":               c.OnSurface,
		"onBackground":            c.OnSurface,
		"inverseSurface":          c.OnSurface,
		"surfaceVariant":          sv,
		"onSurfaceVariant":        role(c.OnSurfaceVariant, c.OnSurface),
		"surfaceContainerLow":     mixHex(c.Surface, sv, 0.5),
		"surfaceContainer":        sv,
		"surfaceContainerHigh":    mixHex(sv, outline, 0.35),
		"surfaceContainerHighest": mixHex(sv, outline, 0.6),
		"surfaceTint":             c.Primary,
		"primary":                 c.Primary,
		"onPrimary":               role(c.OnPrimary, c.Surface),
		"primaryContainer":        sv,
		"onPrimaryContainer":      c.Primary,
		"secondary":               role(c.Secondary, c.Primary),
		"onSecondary":             role(c.OnSecondary, c.Surface),
		"secondaryContainer":      sv,
		"onSecondaryContainer":    role(c.Secondary, c.Primary),
		"tertiary":                role(c.Tertiary, c.Primary),
		"onTertiary":              role(c.OnTertiary, c.Surface),
		"tertiaryContainer":       sv,
		"onTertiaryContainer":     role(c.Tertiary, c.Primary),
		"error":                   role(c.Error, c.Primary),
		"onError":                 role(c.OnError, c.Surface),
		"errorContainer":          sv,
		"onErrorContainer":        role(c.Error, c.Primary),
		"outline":                 outline,
		"outlineVariant":          mixHex(outline, c.Surface, 0.5),
	}
}

// lookupThemePalette resolves a theme.theme value to its 34-role palette: a
// built-in first (themes_gen.go), then the installed library. It is the single
// seam matugenApplyStatic and resolveThemePalette share so both honour a
// downloaded scheme.
func lookupThemePalette(name string) (map[string]string, bool) {
	if pal, ok := themePalettes[name]; ok {
		return pal, true
	}
	for _, t := range userThemes() {
		if t.ID == name {
			return t.Palette, true
		}
	}
	return nil, false
}

// lookupThemeStyle resolves a theme.theme value to its themeStyle; built-in
// themes carry none.
func lookupThemeStyle(name string) map[string]any {
	if _, ok := themePalettes[name]; ok {
		return nil
	}
	for _, t := range userThemes() {
		if t.ID == name {
			return t.Style
		}
	}
	return nil
}

// lookupThemeTerminal resolves a theme.theme value to its term_* overrides;
// built-in themes carry none.
func lookupThemeTerminal(name string) map[string]string {
	if _, ok := themePalettes[name]; ok {
		return nil
	}
	for _, t := range userThemes() {
		if t.ID == name {
			return t.Terminal
		}
	}
	return nil
}

// userThemeIDs lists the installed scheme ids, for theme.theme validation.
func userThemeIDs() []string {
	ts := userThemes()
	ids := make([]string, 0, len(ts))
	for _, t := range ts {
		ids = append(ids, t.ID)
	}
	return ids
}

// removeUserTheme deletes an installed library scheme's directory. Set
// membership in the installed library is required, so a built-in name or a
// bogus id (path traversal included) is refused and only a real downloaded
// scheme is ever removed.
func removeUserTheme(id string) error {
	if id == "" {
		return fmt.Errorf("expected a scheme id")
	}
	for _, x := range userThemeIDs() {
		if x == id {
			return os.RemoveAll(filepath.Join(userThemeDir(), id))
		}
	}
	return fmt.Errorf("%q is not an installed scheme", id)
}

// effectiveThemeThemeValues is the set theme.theme accepts: the built-in names
// plus every installed library id, so applying a downloaded scheme validates.
func effectiveThemeThemeValues() []string {
	ids := userThemeIDs()
	if len(ids) == 0 {
		return themeThemeValues
	}
	return append(append([]string{}, themeThemeValues...), ids...)
}

// userThemeCards projects the installed library into the switcher/Hub catalog
// projection, after the built-ins, each tagged with its provider and, when the
// scheme folder carries preview art (the store installs the catalogue's image
// beside scheme.json), the path to it.
func userThemeCards() []themeCard {
	ts := userThemes()
	cards := make([]themeCard, 0, len(ts))
	for _, t := range ts {
		sw := make([]string, len(themeSwatchRoles))
		for i, r := range themeSwatchRoles {
			sw[i] = t.Palette[r]
		}
		luma, ok := hexLuma(t.Palette["surface"])
		cards = append(cards, themeCard{
			ID:       t.ID,
			Label:    t.Label,
			Provider: t.Provider,
			Dark:     !ok || luma < 0.5,
			Sw:       sw,
			Preview:  userThemePreview(t.ID),
		})
	}
	return cards
}

// userThemePreview is the preview image beside an installed scheme, or "" when
// the folder carries none. The accepted names match colorschemes/AUTHORING.md.
func userThemePreview(id string) string {
	for _, name := range []string{"preview.jpg", "preview.png", "preview.jpeg", "preview.webp"} {
		p := filepath.Join(userThemeDir(), id, name)
		if st, err := os.Stat(p); err == nil && st.Mode().IsRegular() {
			return p
		}
	}
	return ""
}

// mixHex linearly blends two hex colours by t in [0,1]; a non-hex input returns
// the first colour unchanged.
func mixHex(a, b string, t float64) string {
	ar, ag, ab, ok1 := parseHexRGB(a)
	br, bg, bb, ok2 := parseHexRGB(b)
	if !ok1 || !ok2 {
		return a
	}
	m := func(x, y int) int {
		v := float64(x) + (float64(y)-float64(x))*t
		switch {
		case v < 0:
			v = 0
		case v > 255:
			v = 255
		}
		return int(v + 0.5)
	}
	return fmt.Sprintf("#%02x%02x%02x", m(ar, br), m(ag, bg), m(ab, bb))
}

// parseHexRGB splits a #rrggbb string into channels, ok=false when malformed.
func parseHexRGB(hex string) (int, int, int, bool) {
	h := strings.TrimPrefix(hex, "#")
	if len(h) != 6 {
		return 0, 0, 0, false
	}
	r, e1 := strconv.ParseInt(h[0:2], 16, 0)
	g, e2 := strconv.ParseInt(h[2:4], 16, 0)
	b, e3 := strconv.ParseInt(h[4:6], 16, 0)
	if e1 != nil || e2 != nil || e3 != nil {
		return 0, 0, 0, false
	}
	return int(r), int(g), int(b), true
}
