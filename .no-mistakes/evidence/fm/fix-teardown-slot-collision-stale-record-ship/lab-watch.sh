#!/usr/bin/env bash
# lab-watch.sh <out> [seconds]: run the real watcher with a 1s heartbeat until it
# wakes (exits) or the budget elapses; prints the wake reason.
E=$(cd "$(dirname "$0")" && pwd)
out=$1 budget=${2:-60}
LABRUN_EXTRA="FM_POLL=1 FM_SIGNAL_GRACE=1 FM_CHECK_INTERVAL=999999 FM_HEARTBEAT=1" \
  "$E/labrun.sh" bin/fm-watch.sh > "$out" 2>&1 &
p=$!
i=0
while [ "$i" -lt "$budget" ] && kill -0 "$p" 2>/dev/null; do sleep 1; i=$((i + 1)); done
if kill -0 "$p" 2>/dev/null; then kill "$p"; wait "$p" 2>/dev/null; echo "(watcher still running after ${budget}s; killed)"; fi
cat "$out"
