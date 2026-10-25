#!/usr/bin/env bash
# Build a disposable lab: home = checkout of the change under test, private tmux
# socket, treehouse root inside the lab, local-only notes project.
set -eu
W=$1
ROOT=$(cd "$(mktemp -d /tmp/fmsc.XXXXXX)" && pwd -P); LAB=$ROOT/home
"$W/bin/fm-lab-home.sh" create "$LAB" >/dev/null
git -C "$LAB" init -q -b main
git -C "$LAB" fetch -q "$W" HEAD
git -C "$LAB" checkout -q -f -B main FETCH_HEAD
git -C "$LAB" config user.name lab; git -C "$LAB" config user.email lab@example.invalid
mkdir -p "$LAB/state" "$LAB/data" "$LAB/config" "$LAB/projects" "$ROOT/treehouse"
printf 'tmux\n' > "$LAB/config/backend"
printf 'claude\n' > "$LAB/config/crew-harness"
printf 'auto\n' > "$LAB/config/claude-permission-mode"
TMUX_DIR=$("$LAB/bin/fm-lab-home.sh" tmux-dir "$LAB")
seed=$ROOT/origins/notes-seed; mkdir -p "$seed/notes" "$seed/tests"; git init -q -b main "$seed"
printf 'NOTES = []\n\ndef add_note(t):\n    NOTES.append(t)\n' > "$seed/notes/__init__.py"
printf 'import unittest\nimport notes\nclass T(unittest.TestCase):\n    def test_a(self):\n        notes.add_note("x")\n' > "$seed/tests/test_notes.py"
git -C "$seed" add -A; git -C "$seed" -c user.name=lab -c user.email=l@e.invalid commit -qm seed
git clone -q --bare "$seed" "$ROOT/origins/notes.git"; rm -rf "$seed"
git clone -q "$ROOT/origins/notes.git" "$LAB/projects/notes"
printf '# Projects\n\n- notes [local-only +yolo] - tiny lab notes library\n' > "$LAB/data/projects.md"
{ echo "ROOT=$ROOT"; echo "LAB=$LAB"; echo "TMUX_DIR=$TMUX_DIR"; } > /tmp/fmsc-current
cat /tmp/fmsc-current
git -C "$LAB" log --oneline -1
