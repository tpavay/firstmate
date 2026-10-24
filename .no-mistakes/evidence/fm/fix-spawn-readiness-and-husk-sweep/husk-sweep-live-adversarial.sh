#!/usr/bin/env bash
# Ad-hoc live adversarial husk-sweep check against real herdr in a named lab session.
# Run from the repository worktree root.
set -u
. "$(pwd)/tests/lib.sh"
. "$ROOT/tests/herdr-test-safety.sh"
herdr_forget_inherited_pane
SESSION=$("$ROOT/bin/fm-herdr-lab.sh" name fm-husk-adv)
export HERDR_SESSION="$SESSION"
TMP_ROOT=$(fm_test_tmproot fm-husk-adv)
trap 'herdr_safe_stop_and_delete "$SESSION"' EXIT
fm_herdr_lab_prepare "$SESSION" || fail "prepare"
. "$ROOT/bin/fm-backend.sh"
fm_backend_source herdr
fm_backend_herdr_server_ensure "$SESSION" || fail server
HOME_DIR="$TMP_ROOT/home"
mkdir -p "$HOME_DIR/data" "$HOME_DIR/state" "$HOME_DIR/config" "$HOME_DIR/projects"
printf 'herdr\n' > "$HOME_DIR/config/backend"
printf 'manual\n' > "$HOME_DIR/config/backlog-backend"
CWD="$TMP_ROOT/cwd"
POOL="$TMP_ROOT/pool"
mkdir -p "$CWD" "$POOL/7/repo"
printf '{}\n' > "$POOL/treehouse-state.json"
printf 'task=parked-lane\nhome=%s\n' "$HOME_DIR" > "$POOL/7/.fm-slot-owner"
printf 'kind=ship\nworktree=%s\nbackend=herdr\n' "$CWD/nowhere" > "$HOME_DIR/state/adv-meta.meta"
WSID=$(herdr workspace create --label firstmate --cwd "$CWD" --no-focus --session "$SESSION" | jq -r '.result.workspace.workspace_id')
mk() { herdr tab create --workspace "$WSID" --cwd "$2" --label "$1" --no-focus --session "$SESSION" | jq -r '.result.root_pane.pane_id'; }
P_META=$(mk fm-adv-meta "$CWD")
P_SLOT=$(mk fm-adv-slot "$POOL/7/repo")
P_NOTASK=$(mk not-a-task "$CWD")
P_HUSK=$(mk fm-adv-husk "$CWD")
for p in $P_META $P_SLOT $P_NOTASK $P_HUSK; do
  fm_backend_herdr_pane_idle_shell_wait "$SESSION" "$p" 120 0.25 >/dev/null || fail "idle $p"
done
echo "--- tabs before:"
herdr tab list --session "$SESSION" | jq -r '.result.tabs[] | "\(.label) \(.tab_id)"'
out=$(FM_HOME="$HOME_DIR" FM_ROOT_OVERRIDE="$HOME_DIR" FM_BOOTSTRAP_NETWORK=skip "$ROOT/bin/fm-bootstrap.sh" 2>/dev/null | grep '^BOOTSTRAP_INFO: herdr husk')
echo "--- sweep output:"
echo "$out"
echo "--- tabs after:"
herdr tab list --session "$SESSION" | jq -r '.result.tabs[] | "\(.label) \(.tab_id)"'
for p in $P_META $P_SLOT $P_NOTASK; do
  [ "$(fm_backend_herdr_pane_presence_state "$SESSION" "$p")" = present ] || fail "pane $p was closed"
done
[ "$(fm_backend_herdr_pane_presence_state "$SESSION" "$P_HUSK")" = dead ] || fail "real husk not closed"
case "$out" in *fm-adv-meta*) fail "meta-recorded tab treated as a candidate" ;; esac
case "$out" in *"fm-adv-slot"*"kept: its shell sits in claimed pool slot"*) : ;; *) fail "slot tab not kept for slot" ;; esac
case "$out" in *not-a-task*) fail "non-task label touched" ;; esac
pass "live adversarial: meta-present and claimed-slot tabs kept, non-task label ignored, true husk closed"
