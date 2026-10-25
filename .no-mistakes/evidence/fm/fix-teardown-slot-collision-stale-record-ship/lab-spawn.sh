#!/usr/bin/env bash
# lab-spawn.sh <task-id> <spec-text>: scaffold a brief, add a backlog item, and
# run the real bin/fm-spawn.sh for one lab worker on the notes project.
set -eu
. /tmp/fmsc-current
E=$(cd "$(dirname "$0")" && pwd)
ID=$1 SPEC=$2
"$E/labrun.sh" "$LAB/bin/fm-brief.sh" "$ID" notes --mode local-only >/dev/null
TASK_TEXT="Lab worker $ID for a live slot-collision validation lab. Do no real work." SPEC_TEXT="$SPEC" \
  python3 - "$LAB/data/$ID/brief.md" <<'PY'
import os, sys
p = sys.argv[1]
t = open(p, encoding="utf-8").read()
t = t.replace("{TASK}", os.environ["TASK_TEXT"], 1).replace("{FIRSTMATE_SPEC}", os.environ["SPEC_TEXT"], 1)
open(p, "w", encoding="utf-8").write(t)
PY
"$E/labrun.sh" "$LAB/bin/fm-tasks-axi.sh" add "$ID" "lab worker $ID" --kind ship --repo notes >/dev/null
"$E/labrun.sh" "$LAB/bin/fm-spawn.sh" "$ID" "$LAB/projects/notes" \
  --mode local-only --yolo on --harness claude --model sonnet --effort low
