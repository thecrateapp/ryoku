package doctor

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"

	"ryoku-cli/internal/sys"

	i18n "ryoku-i18n"
)

// reconcileObsidianSnippet links the Ryoku palette snippet into every Obsidian
// vault and enables it, so notes track the wallpaper scheme the way the rest of
// the app suite does. matugen renders the snippet to one file
// (~/.config/matugen/generated/obsidian.css); Obsidian only loads snippets that
// live under <vault>/.obsidian/snippets, so each vault gets a symlink to that one
// file plus "ryoku" in its enabled list. A dangling link until matugen first
// renders is harmless. No-op when Obsidian is absent; idempotent, and it never
// drops a user's other snippets.
//
// The snippet recolours Obsidian's default theme. It loads after a community
// theme and outranks it (body.theme-dark three times over), so a vault whose
// appearance.json names a cssTheme gets it switched off instead: the theme the
// user picked is what shows, and choosing the default theme again brings the
// palette back on the next run.
func reconcileObsidianSnippet(checkOnly bool) recResult {
	cfg := filepath.Join(configHome(), "obsidian", "obsidian.json")
	if !sys.Has("obsidian") && !sys.Exists(cfg) {
		return okRes(i18n.T("Obsidian not installed"))
	}
	vaults, err := obsidianVaultPaths(cfg)
	if err != nil || len(vaults) == 0 {
		return okRes(i18n.T("no Obsidian vaults registered yet"))
	}
	generated := filepath.Join(configHome(), "matugen", "generated", "obsidian.css")

	var did, pending []string
	for _, vault := range vaults {
		if !sys.Exists(vault) {
			continue // stale entry: the vault was moved or deleted.
		}
		dot := filepath.Join(vault, ".obsidian")
		link := filepath.Join(dot, "snippets", "ryoku.css")

		if !symlinkPointsAt(link, generated) {
			if checkOnly {
				pending = append(pending, i18n.Tf("link palette snippet into %s", tildeOf(vault)))
			} else {
				if err := os.MkdirAll(filepath.Dir(link), 0o755); err != nil {
					return failRes(i18n.T("could not create %s: %v"), tildeOf(filepath.Dir(link)), err)
				}
				_ = os.Remove(link)
				if err := os.Symlink(generated, link); err != nil {
					return failRes(i18n.T("could not link the palette snippet in %s: %v"), tildeOf(vault), err)
				}
				did = append(did, i18n.Tf("linked %s", tildeOf(vault)))
			}
		}

		appearance := filepath.Join(dot, "appearance.json")
		change, err := syncObsidianSnippet(appearance, !checkOnly)
		if err != nil {
			return failRes(i18n.T("could not enable the snippet in %s: %v"), tildeOf(vault), err)
		}
		switch {
		case change == snippetEnabled && checkOnly:
			pending = append(pending, i18n.Tf("enable the snippet in %s", tildeOf(vault)))
		case change == snippetEnabled:
			did = append(did, i18n.Tf("enabled in %s", tildeOf(vault)))
		case change == snippetDisabled && checkOnly:
			pending = append(pending, i18n.Tf("turn the snippet off in %s, which uses its own theme", tildeOf(vault)))
		case change == snippetDisabled:
			did = append(did, i18n.Tf("turned off in %s, which uses its own theme", tildeOf(vault)))
		}
	}

	switch {
	case checkOnly && len(pending) > 0:
		return wouldRes("%s", strings.Join(pending, "; "))
	case len(did) > 0:
		return fixedRes("%s", strings.Join(did, "; "))
	default:
		return okRes(i18n.T("palette snippet is linked and enabled in every vault"))
	}
}

// obsidianVaultPaths reads the absolute vault paths from Obsidian's registry
// (~/.config/obsidian/obsidian.json: {"vaults":{"<id>":{"path":"/abs"}}}).
func obsidianVaultPaths(cfgPath string) ([]string, error) {
	b, err := os.ReadFile(cfgPath)
	if err != nil {
		return nil, err
	}
	var doc struct {
		Vaults map[string]struct {
			Path string `json:"path"`
		} `json:"vaults"`
	}
	if err := json.Unmarshal(b, &doc); err != nil {
		return nil, err
	}
	var out []string
	for _, v := range doc.Vaults {
		if p := strings.TrimSpace(v.Path); p != "" {
			out = append(out, p)
		}
	}
	return out, nil
}

// symlinkPointsAt reports whether path is already a symlink to target.
func symlinkPointsAt(path, target string) bool {
	fi, err := os.Lstat(path)
	if err != nil || fi.Mode()&os.ModeSymlink == 0 {
		return false
	}
	dst, err := os.Readlink(path)
	return err == nil && dst == target
}

type snippetChange int

const (
	snippetUnchanged snippetChange = iota
	snippetEnabled
	snippetDisabled
)

// syncObsidianSnippet makes a vault's enabledCssSnippets agree with its theme:
// "ryoku" is on while the vault uses Obsidian's default theme (no cssTheme) and
// off while it uses a community theme, which the snippet would otherwise
// override. appearance.json is created when absent, and every other snippet and
// setting is preserved. It reports the change needed; the change is written
// only when apply is true, so the check-only pass can report without touching
// the file. An unparseable appearance.json is left untouched rather than
// clobbered.
func syncObsidianSnippet(path string, apply bool) (snippetChange, error) {
	b, err := os.ReadFile(path)
	if os.IsNotExist(err) {
		if !apply {
			return snippetEnabled, nil
		}
		if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
			return snippetUnchanged, err
		}
		return snippetEnabled, os.WriteFile(path, []byte(`{"enabledCssSnippets":["ryoku"]}`+"\n"), 0o644)
	}
	if err != nil {
		return snippetUnchanged, err
	}
	var doc map[string]any
	if json.Unmarshal(b, &doc) != nil {
		return snippetUnchanged, nil
	}
	theme, _ := doc["cssTheme"].(string)
	want := strings.TrimSpace(theme) == ""

	list, _ := doc["enabledCssSnippets"].([]any)
	kept := make([]any, 0, len(list))
	has := false
	for _, s := range list {
		if v, ok := s.(string); ok && v == "ryoku" {
			has = true
			continue
		}
		kept = append(kept, s)
	}
	var change snippetChange
	switch {
	case want && !has:
		change = snippetEnabled
		kept = append(list, "ryoku")
	case !want && has:
		change = snippetDisabled
	default:
		return snippetUnchanged, nil
	}
	if !apply {
		return change, nil
	}
	doc["enabledCssSnippets"] = kept
	out, err := json.MarshalIndent(doc, "", "  ")
	if err != nil {
		return snippetUnchanged, err
	}
	return change, os.WriteFile(path, append(out, '\n'), 0o644)
}
