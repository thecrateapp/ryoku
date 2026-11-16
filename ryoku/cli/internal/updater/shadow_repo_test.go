package updater

import (
	"reflect"
	"testing"

	"ryoku-cli/internal/host"
)

// A repository above [ryoku] that serves its own Ryoku qualifies the names it
// serves; the metas a channel move adds follow it, and the system lane still
// recognises its targets as Ryoku's.
func TestTargetsFollowTheServingRepository(t *testing.T) {
	t.Setenv("RYOKU_HOST_PKGMGR", "pacman")
	old := ryokuRepoPackages
	t.Cleanup(func() { ryokuRepoPackages = old })
	ryokuRepoPackages = func() ([]host.RepoPackage, error) {
		return []host.RepoPackage{
			{Name: "ryoku-desktop", Version: "1:1.0.9.r6306.g4c28781-5", Repository: "fork"},
			{Name: "ryoku-desktop-hyprland", Version: "1:1.0.9.r6306.g4c28781-2", Repository: "fork"},
			{Name: "prowl", Version: "0.17.2-2", Repository: "ryoku"},
			{Name: "ryoku-keyring", Version: "20260620-2"},
		}, nil
	}
	for name, want := range map[string]string{
		"ryoku-desktop-hyprland": "fork/ryoku-desktop-hyprland",
		"prowl":                  "ryoku/prowl",
		"ryoku-keyring":          "ryoku/ryoku-keyring",
		"ryoku-desktop-niri":     "ryoku/ryoku-desktop-niri",
	} {
		if got := ryokuTarget(name); got != want {
			t.Errorf("ryokuTarget(%q) = %q, want %q", name, got, want)
		}
	}

	names := targetPackageNames([]string{"fork/ryoku-desktop", "ryoku/prowl", "ryoku-shell"})
	if want := map[string]bool{"ryoku-desktop": true, "prowl": true, "ryoku-shell": true}; !reflect.DeepEqual(names, want) {
		t.Fatalf("targetPackageNames = %v, want %v", names, want)
	}
}

// Without the served list (unsynced, or no pacman) a target stays ryoku/<name>.
func TestTargetFallsBackToRyoku(t *testing.T) {
	t.Setenv("RYOKU_HOST_PKGMGR", "pacman")
	if got := ryokuTarget("ryoku-desktop-hyprland"); got != "ryoku/ryoku-desktop-hyprland" {
		t.Fatalf("ryokuTarget = %q", got)
	}
}
