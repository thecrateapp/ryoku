"""bin/ryoku-dev-design-lint: QML outside the kit must not grow new private
controls (sliders, progress bars, *Chip/*Slider/*Progress components) or new
literal type sizes and hex colours. Today's debt is counted per file and rule
in a shrink-only file: a count may only go down."""
import json
import os
import subprocess
import sys

import pytest

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LINT = os.path.join(REPO, "bin", "ryoku-dev-design-lint")


def run(root, *args):
    return subprocess.run([sys.executable, LINT, "--root", str(root), *args],
                          capture_output=True, text=True)


def write(root, rel, text):
    p = root / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(text)
    return p


def debt(root):
    return json.loads((root / "tests/design-lint/debt.json").read_text())


@pytest.fixture
def tree(tmp_path):
    write(tmp_path, "tests/design-lint/debt.json", "{}\n")
    return tmp_path


def test_counts_each_rule(tree):
    write(tree, "ryoku/shell/quickshell/shell/modules/x/Panel.qml",
          'Item {\n'
          '  QQC.Slider { }\n'
          '  Rectangle { width: parent.width * root.value }\n'
          '  Text { font.pixelSize: 13; color: "#ff735d" }\n'
          '  Rectangle { color: "#1a1a1a"; font.pixelSize: Tokens.fSmall }\n'
          '}\n')
    write(tree, "ryoku/apps/foo/MiniChip.qml", "Item {}\n")
    r = run(tree, "--report")
    assert r.returncode == 0, r.stderr
    counts = json.loads(r.stdout)
    assert counts["ryoku/shell/quickshell/shell/modules/x/Panel.qml"] == {
        "slider": 1, "progress": 1, "pixel-size": 1, "hex-colour": 2}
    assert counts["ryoku/apps/foo/MiniChip.qml"] == {"control-name": 1}


def test_the_kit_and_tests_are_not_scanned(tree):
    write(tree, "ryoku/ui/Beam.qml", 'Item { QQC.Slider {} Text { color: "#ffffff" } }\n')
    write(tree, "tests/ui/probe.qml", 'Item { Text { font.pixelSize: 12 } }\n')
    r = run(tree, "--report")
    assert json.loads(r.stdout) == {}


def test_new_debt_fails_and_names_the_file(tree):
    write(tree, "ryoku/shell/quickshell/shell/modules/x/Panel.qml", 'Text { color: "#ffffff" }\n')
    r = run(tree)
    assert r.returncode == 1
    assert "ryoku/shell/quickshell/shell/modules/x/Panel.qml" in r.stderr
    assert "hex-colour" in r.stderr


def test_recorded_debt_passes(tree):
    write(tree, "ryoku/shell/quickshell/shell/modules/x/Panel.qml", 'Text { color: "#ffffff" }\n')
    assert run(tree, "--baseline").returncode == 0
    assert debt(tree) == {"ryoku/shell/quickshell/shell/modules/x/Panel.qml": {"hex-colour": 1}}
    assert run(tree).returncode == 0


def test_debt_only_shrinks(tree):
    f = write(tree, "ryoku/shell/quickshell/shell/modules/x/Panel.qml",
              'Text { color: "#ffffff" }\nText { color: "#000000" }\n')
    run(tree, "--baseline")
    f.write_text('Text { color: "#ffffff" }\n')
    r = run(tree)
    assert r.returncode == 1 and "--update" in r.stderr  # a paid-down debt must be recorded
    run(tree, "--update")
    assert debt(tree)["ryoku/shell/quickshell/shell/modules/x/Panel.qml"] == {"hex-colour": 1}
    f.write_text('Text { color: "#ffffff" }\nText { color: "#000000" }\nText { color: "#111111" }\n')
    r = run(tree, "--update")
    assert r.returncode == 1  # --update never raises a count
    assert debt(tree)["ryoku/shell/quickshell/shell/modules/x/Panel.qml"] == {"hex-colour": 1}


def test_a_cleared_file_leaves_the_debt_file(tree):
    f = write(tree, "ryoku/shell/quickshell/shell/modules/x/Panel.qml", 'Text { color: "#ffffff" }\n')
    run(tree, "--baseline")
    f.write_text("Text { color: Tokens.ink }\n")
    run(tree, "--update")
    assert debt(tree) == {}


def test_update_never_adds_a_new_file(tree):
    write(tree, "ryoku/shell/quickshell/shell/modules/x/New.qml", 'Text { color: "#ffffff" }\n')
    assert run(tree, "--update").returncode == 1
    assert debt(tree) == {}


def test_staged_mode_checks_only_the_named_files(tree):
    write(tree, "ryoku/shell/quickshell/shell/modules/x/Old.qml", 'Text { color: "#ffffff" }\n')
    write(tree, "ryoku/shell/quickshell/shell/modules/x/New.qml", 'Text { color: Tokens.ink }\n')
    r = run(tree, "--files", "ryoku/shell/quickshell/shell/modules/x/New.qml")
    assert r.returncode == 0, r.stderr
