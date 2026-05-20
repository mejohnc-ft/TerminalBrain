#!/usr/bin/env zsh
set -euo pipefail

case "${1:-}" in
  --help|-h)
    cat <<'EOF'
Usage: ./mac-app/scripts/cleanup-plan.zsh

Prints a non-destructive cleanup plan for stale agent runtime noise:
  - Terminal Brain process and launchctl state
  - duplicate terminal-brain-mcp and brain-kernel children
  - Codex parent sessions that own those children
  - copyable review/kill commands for an operator to run manually

This script never launches, foregrounds, quits, kills, or controls Terminal Brain,
Codex, MCP, kernel, Drafts, or any other process.
EOF
    exit 0
    ;;
  "")
    ;;
  *)
    echo "Unknown option: $1" >&2
    echo "Run ./mac-app/scripts/cleanup-plan.zsh --help" >&2
    exit 64
    ;;
esac

process_rows() {
  ps -axo pid=,ppid=,stat=,etime=,command=
}

matching_pids() {
  local pattern="$1"
  process_rows | awk -v pattern="$pattern" '
    index(tolower($0), pattern) > 0 &&
    index($0, "mac-app/scripts/cleanup-plan.zsh") == 0 &&
    index($0, "awk -v pattern") == 0 {
      print $1
    }
  '
}

count_pids() {
  local pids="$1"
  printf '%s\n' "$pids" | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' '
}

join_pids() {
  local pids="$1"
  printf '%s\n' "$pids" | sed '/^[[:space:]]*$/d' | paste -sd, -
}

space_pids() {
  local pids="$1"
  printf '%s\n' "$pids" | sed '/^[[:space:]]*$/d' | paste -sd' ' -
}

print_table() {
  local title="$1"
  local pids="$2"
  local joined

  joined="$(join_pids "$pids")"
  if [[ -z "$joined" ]]; then
    return
  fi

  echo
  echo "### $title"
  ps -o pid=,ppid=,stat=,etime=,command= -p "$joined" 2>/dev/null | sed 's/^/- /'
}

app_pids="$(pgrep -x TerminalBrain 2>/dev/null || true)"
launch_items="$(launchctl list 2>/dev/null | grep -Ei 'terminalbrain|terminal brain' || true)"
mcp_pids="$(matching_pids '/software/terminal-brain-mcp/server.mjs')"
kernel_pids="$(matching_pids '/software/brain-kernel/server.mjs')"
codex_pids="$(matching_pids 'node /usr/local/bin/codex')"
brain_console_pids="$(matching_pids '/software/brain-console')"

mcp_count="$(count_pids "$mcp_pids")"
kernel_count="$(count_pids "$kernel_pids")"
codex_count="$(count_pids "$codex_pids")"
console_count="$(count_pids "$brain_console_pids")"

candidate_pids="$(printf '%s\n%s\n' "$mcp_pids" "$kernel_pids" | sed '/^[[:space:]]*$/d' | sort -n | uniq)"
candidate_count="$(count_pids "$candidate_pids")"
candidate_joined="$(join_pids "$candidate_pids")"
candidate_spaced="$(space_pids "$candidate_pids")"

echo "# Terminal Brain Cleanup Plan"
echo
echo "Checked: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo

echo "## Bottom Line"
if [[ -n "$app_pids" || -n "$launch_items" ]]; then
  echo "- Terminal Brain itself may be active. Do not clean app-related processes unless you intentionally opened it."
else
  echo "- Terminal Brain is not running and has no matching launch agent."
fi
echo "- Codex sessions: $codex_count"
echo "- terminal-brain-mcp children: $mcp_count"
echo "- brain-kernel children: $kernel_count"
echo "- brain-console helpers: $console_count"
echo "- Cleanup candidates: $candidate_count MCP/kernel child process(es)"
echo

echo "## Recommendation"
if (( candidate_count == 0 )); then
  echo "- No Terminal Brain MCP/kernel cleanup candidate is visible."
elif (( codex_count > 1 )); then
  echo "- Multiple Codex sessions are open. Prefer closing stale Codex chats/windows first, then rerun make processes."
  echo "- If you are sure a listed MCP/kernel child is stale, terminate only those child PIDs, not the active Codex parent."
else
  echo "- Runtime noise is limited. Leave it alone unless you know the child process is stale."
fi
echo
echo "## Safe Review Commands"
echo
echo '```zsh'
echo "make processes"
echo "./mac-app/scripts/processes.zsh --details"
if [[ -n "$candidate_joined" ]]; then
  echo "ps -o pid,ppid,stat,etime,command -p $candidate_joined"
fi
echo '```'
echo

if [[ -n "$candidate_joined" ]]; then
  echo "## Manual Cleanup Commands"
  echo
  echo "Review the table below before running either command. These are suggestions only; this script did not kill anything."
  echo
  echo '```zsh'
  echo "kill $candidate_spaced"
  echo "# If a reviewed stale child refuses to exit:"
  echo "# kill -TERM $candidate_spaced"
  echo '```'
fi

print_table "Cleanup Candidates" "$candidate_pids"
print_table "Codex Parents" "$codex_pids"
print_table "Brain Console Helpers" "$brain_console_pids"

echo
echo "## Guardrail"
echo "- This command did not launch, foreground, quit, kill, or control anything."
echo "- It only prints a plan. Manual cleanup should happen in a terminal you control."
