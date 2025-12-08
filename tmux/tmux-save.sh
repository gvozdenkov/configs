#!/usr/bin/env bash
# tmux-save.sh: save tmux sessions, windows, and panes.

set -euo pipefail

SNAPSHOT_FILE="$(pwd)/.tmux-session"

d=$'\t'
# Format: session_name<TAB>window_index<TAB>window_name<TAB>pane_index<TAB>pane_current_path<TAB>pane_current_command
tmux list-panes -a -F "#S${d}#I${d}#W${d}#P${d}#{pane_current_path}${d}#{pane_current_command}" \
> "${SNAPSHOT_FILE}"

echo "Saved tmux snapshot to ${SNAPSHOT_FILE}"
