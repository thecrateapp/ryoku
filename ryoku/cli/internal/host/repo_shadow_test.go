package host

import (
	"reflect"
	"strings"
	"testing"
)

// pacmanShadowRunner answers the pacman reads RepoPackages and RepoInstalledSet
// make: [ryoku]'s list, the full list in pacman.conf order, the installed
// versions and vercmp over the versions the tests use.
func pacmanShadowRunner(ryoku, all string, installed map[string]string) *fakeRunner {
	order := []string{
		"1.4.1-1",
		"1.4.1.r10.g167adef-1",
		"1:1.0.9.r6109.g08ff328-1",
		"1:1.0.9.r6306.g4c28781-1",
		"1:1.0.9.r6307.gabcdef0-1",
		"1:1.1.0.r6200.g1234567-1",
	}
	rank := func(v string) int {
		for i, o := range order {
			if o == v {
				return i
			}
		}
		return -1
	}
	return &fakeRunner{answer: func(command Command) Result {
		line := argv(command)
		switch {
		case line == "pacman -Sl ryoku":
			return Result{Output: ryoku}
		case line == "pacman -Sl":
			if all == "" {
				return Result{Code: 1}
			}
			return Result{Output: all}
		case strings.HasPrefix(line, "pacman -Q "):
			name := strings.TrimPrefix(line, "pacman -Q ")
			if v, ok := installed[name]; ok {
				return Result{Output: name + " " + v + "\n"}
			}
			return Result{Code: 1}
		case strings.HasPrefix(line, "vercmp "):
			f := strings.Fields(line)
			a, b := rank(f[1]), rank(f[2])
			switch {
			case a < b:
				return Result{Output: "-1\n"}
			case a > b:
				return Result{Output: "1\n"}
			}
			return Result{Output: "0\n"}
		}
		return Result{Code: 1}
	}}
}

const shadowRyokuList = "ryoku ryoku-desktop 1:1.1.0.r6200.g1234567-1\n" +
	"ryoku ryoku-shell 1:1.1.0.r6200.g1234567-1\n" +
	"ryoku xdg-desktop-portal-hyprland 1.4.1.r10.g167adef-1\n" +
	"ryoku prowl 1.4.1-1\n"

func TestRepoInstalledSetFollowsARepositoryAboveRyoku(t *testing.T) {
	tests := []struct {
		name          string
		all           string
		installed     map[string]string
		wantSet       []string
		wantHeld      int
		wantAvailable string
	}{
		{
			// stock: only [ryoku] serves Ryoku; extra's portal is older and is
			// not a Ryoku repository, so everything stays qualified with ryoku/
			name: "ryoku alone",
			all: "extra xdg-desktop-portal-hyprland 1.4.1-1\n" +
				shadowRyokuList,
			installed: map[string]string{
				"ryoku-desktop":               "1:1.0.9.r6306.g4c28781-1",
				"ryoku-shell":                 "1:1.0.9.r6306.g4c28781-1",
				"xdg-desktop-portal-hyprland": "1.4.1.r10.g167adef-1",
			},
			wantSet:       []string{"ryoku/ryoku-desktop", "ryoku/ryoku-shell", "ryoku/xdg-desktop-portal-hyprland"},
			wantAvailable: "1:1.1.0.r6200.g1234567-1",
		},
		{
			// a repository above [ryoku] serving its own ryoku-desktop decides
			// for the names it serves, even when [ryoku] names a higher version;
			// a name it does not serve stays with [ryoku]
			name: "shadowing repository",
			all: "extra xdg-desktop-portal-hyprland 1.4.1-1\n" +
				"fork ryoku-desktop 1:1.0.9.r6307.gabcdef0-1\n" +
				"fork ryoku-shell 1:1.0.9.r6307.gabcdef0-1\n" +
				"fork some-app 1.0-1\n" +
				shadowRyokuList,
			installed: map[string]string{
				"ryoku-desktop":               "1:1.0.9.r6306.g4c28781-1",
				"ryoku-shell":                 "1:1.0.9.r6307.gabcdef0-1",
				"xdg-desktop-portal-hyprland": "1.4.1.r10.g167adef-1",
			},
			wantSet:       []string{"fork/ryoku-desktop", "fork/ryoku-shell", "ryoku/xdg-desktop-portal-hyprland"},
			wantAvailable: "1:1.0.9.r6307.gabcdef0-1",
		},
		{
			// what the shadowing repository serves is compared against its own
			// version: an install newer than it is held back, never moved
			// to [ryoku]'s higher version
			name: "newer than the shadowing repository",
			all: "fork ryoku-desktop 1:1.0.9.r6306.g4c28781-1\n" +
				shadowRyokuList,
			installed: map[string]string{
				"ryoku-desktop": "1:1.0.9.r6307.gabcdef0-1",
			},
			wantHeld:      1,
			wantAvailable: "1:1.0.9.r6306.g4c28781-1",
		},
		{
			// pacman takes a package from the first repository that has it, so a
			// repository listed below [ryoku] changes nothing
			name: "repository below ryoku",
			all: shadowRyokuList +
				"fork ryoku-desktop 1:1.0.9.r6307.gabcdef0-1\n",
			installed: map[string]string{
				"ryoku-desktop": "1:1.0.9.r6306.g4c28781-1",
			},
			wantSet:       []string{"ryoku/ryoku-desktop"},
			wantAvailable: "1:1.1.0.r6200.g1234567-1",
		},
		{
			// an unreadable full listing falls back to [ryoku] alone
			name:          "listing unreadable",
			installed:     map[string]string{"ryoku-desktop": "1:1.0.9.r6306.g4c28781-1"},
			wantSet:       []string{"ryoku/ryoku-desktop"},
			wantAvailable: "1:1.1.0.r6200.g1234567-1",
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			runner := pacmanShadowRunner(shadowRyokuList, tt.all, tt.installed)
			app, _, _ := testApp(runner, map[string]string{"RYOKU_HOST_PKGMGR": "pacman"})
			set, held, err := app.RepoInstalledSet(false, nil)
			if err != nil {
				t.Fatal(err)
			}
			if !reflect.DeepEqual(set, tt.wantSet) || held != tt.wantHeld {
				t.Fatalf("set = %v, held = %d; want %v, %d", set, held, tt.wantSet, tt.wantHeld)
			}
			available, err := app.RepoAvailableVersion("ryoku-desktop")
			if err != nil || available != tt.wantAvailable {
				t.Fatalf("available ryoku-desktop = %q, %v; want %q", available, err, tt.wantAvailable)
			}
		})
	}
}

// A channel move or rollback passes allowDowngrade: the shadowing repository's
// packages are moved to its own version, never to [ryoku]'s.
func TestRepoInstalledSetChannelMoveKeepsTheShadowingRepository(t *testing.T) {
	all := "fork ryoku-desktop 1:1.0.9.r6306.g4c28781-1\n" + shadowRyokuList
	runner := pacmanShadowRunner(shadowRyokuList, all, map[string]string{
		"ryoku-desktop": "1:1.0.9.r6307.gabcdef0-1",
		"prowl":         "1.4.1-1",
	})
	app, _, _ := testApp(runner, map[string]string{"RYOKU_HOST_PKGMGR": "pacman"})
	set, held, err := app.RepoInstalledSet(true, nil)
	if err != nil {
		t.Fatal(err)
	}
	if want := []string{"fork/ryoku-desktop", "ryoku/prowl"}; !reflect.DeepEqual(set, want) || held != 0 {
		t.Fatalf("set = %v, held = %d; want %v", set, held, want)
	}
}
