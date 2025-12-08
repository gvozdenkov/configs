#!/usr/bin/env bash
# tmux-restore.sh: restore tmux sessions, windows, and panes for 1-based indexing.

set -euo pipefail

SNAPSHOT_FILE="$(pwd)/.tmux-session"

[ -f "${SNAPSHOT_FILE}" ] || {
    echo "No snapshot file: ${SNAPSHOT_FILE}" >&2
    exit 1
}

declare -A CREATED_WINDOWS
declare -A CREATED_PANES

while IFS=$'\t' read -r session win_idx win_name pane_idx pane_path pane_cmd; do
    win_key="${session}:${win_idx}"

    # Create session if missing (first pane becomes pane 1)
    if ! tmux has-session -t "${session}" 2>/dev/null; then
        echo "Creating session: ${session}"
        tmux new-session -d -s "${session}" -n "${win_name}" -c "${pane_path}"
        # Send command to pane 1 (your config's first pane)
        if [ -n "${pane_cmd}" ]; then
            tmux send-keys -t "${session}:1.1" "${pane_cmd}" C-m
        fi
        CREATED_WINDOWS["${win_key}"]=1
        CREATED_PANES["${win_key}:1"]=1
        continue
    fi

    # Create window if missing (first pane becomes pane 1)
    if [ -z "${CREATED_WINDOWS[${win_key}]+x}" ]; then
        echo "Creating window ${win_idx} (${win_name}) in ${session}"
        tmux new-window -t "${session}" -n "${win_name}" -c "${pane_path}"
        # Send command to pane 1 in new window
        if [ -n "${pane_cmd}" ]; then
            tmux send-keys -t "${session}:${win_idx}.1" "${pane_cmd}" C-m
        fi
        CREATED_WINDOWS["${win_key}"]=1
        CREATED_PANES["${win_key}:1"]=1
        continue
    fi

    # Add additional panes (pane_idx > 1) by splitting from pane 1
    if [ "${pane_idx}" -gt 1 ]; then
        pane_key="${win_key}:${pane_idx}"
        if [ -z "${CREATED_PANES[${pane_key}]+x}" ]; then
            echo "Adding pane ${pane_idx} to ${session}:${win_idx}"
            # Split horizontally from pane 1 (your config uses | for horizontal)
            tmux split-window -h -t "${session}:${win_idx}.1" -c "${pane_path}"
            # Send command to new pane
            if [ -n "${pane_cmd}" ]; then
                tmux send-keys -t "${session}:${win_idx}." "${pane_cmd}" C-m
            fi
            CREATED_PANES["${pane_key}"]=1
            # Apply tiled layout to match your workflow
            tmux select-layout -t "${session}:${win_idx}" tiled 2>/dev/null || true
        fi
    fi
done < "${SNAPSHOT_FILE}"

echo "Tmux sessions restored from ${SNAPSHOT_FILE}"
echo "Attach with: tmux attach -t ${session}"
