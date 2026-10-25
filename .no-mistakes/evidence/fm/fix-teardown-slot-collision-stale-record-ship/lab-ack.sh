#!/usr/bin/env bash
# lab-ack.sh: drain the lab wake queue and acknowledge it (the primary's job).
E=$(cd "$(dirname "$0")" && pwd)
err=$(mktemp)
"$E/labrun.sh" bin/fm-wake-drain.sh 2> "$err"
seq=$(sed -n 's/^WAKE_ACK_REQUIRED:.*--ack-through \([0-9][0-9]*\) --recovery-generation .*/\1/p' "$err")
gen=$(sed -n 's/^WAKE_ACK_REQUIRED:.*--recovery-generation \([A-Za-z0-9._-]*\)$/\1/p' "$err")
rm -f "$err"
[ -n "$seq" ] && [ -n "$gen" ] || exit 0
"$E/labrun.sh" bin/fm-wake-drain.sh --ack-through "$seq" --recovery-generation "$gen" >/dev/null
