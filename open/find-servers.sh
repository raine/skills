#!/usr/bin/env bash
# Find dev servers running in tmux panes by cross-referencing
# tmux pane process trees with listening TCP ports.
#
# Output: tab-separated lines of PANE PORT COMMAND
# Example: 4.1	8000	python3 -m http.server 8000

set -euo pipefail

if ! tmux info &>/dev/null; then
  echo "error: not in a tmux session" >&2
  exit 1
fi

declare -A pid_to_pane

# Recursively walk all descendants of a PID
walk_descendants() {
  local pid=$1 pane_id=$2
  local child
  for child in $(pgrep -P "$pid" 2>/dev/null); do
    pid_to_pane[$child]="$pane_id"
    walk_descendants "$child" "$pane_id"
  done
}

while IFS= read -r line; do
  pane_pid=$(echo "$line" | awk '{print $1}')
  pane_id=$(echo "$line" | awk '{print $2}')
  pid_to_pane[$pane_pid]="$pane_id"
  walk_descendants "$pane_pid" "$pane_id"
done < <(tmux list-panes -F '#{pane_pid} #{window_index}.#{pane_index}')

# Cross-reference with listening TCP ports
while IFS= read -r line; do
  pid=$(echo "$line" | awk '{print $2}')
  if [[ -n "${pid_to_pane[$pid]+x}" ]]; then
    port=$(echo "$line" | awk '{print $9}' | sed 's/.*://')
    cmd=$(ps -p "$pid" -o command= 2>/dev/null)
    # Skip claude/node MCP internal ports (high ephemeral ports from claude processes)
    if [[ "$cmd" == *"claude"* ]] || [[ "$cmd" == *"@anthropic"* ]]; then
      continue
    fi
    printf "%s\t%s\t%s\n" "${pid_to_pane[$pid]}" "$port" "$cmd"
  fi
done < <(lsof -iTCP -sTCP:LISTEN -P -n 2>/dev/null | tail -n +2)
