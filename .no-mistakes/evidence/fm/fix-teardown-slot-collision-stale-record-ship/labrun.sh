#!/usr/bin/env bash
# labrun.sh <command...>: run inside the lab's clean environment (mirrors
# bin/fm-live-lab.sh lab_run): FM_HOME=lab, private tmux socket, lab treehouse root.
. /tmp/fmsc-current
cd "$LAB"
exec env -i HOME="$HOME" USER="$USER" LOGNAME="$USER" PATH="$PATH" SHELL=/bin/zsh \
  TERM=xterm-256color LANG=en_US.UTF-8 TMUX_TMPDIR="$TMUX_DIR" \
  TREEHOUSE_ROOT="$ROOT/treehouse" FM_BACKEND=tmux DISABLE_AUTOUPDATER=1 \
  FM_HOME="$LAB" ${LABRUN_EXTRA:-} "$@"
