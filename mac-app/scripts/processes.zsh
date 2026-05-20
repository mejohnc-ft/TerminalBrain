#!/usr/bin/env zsh
set -euo pipefail

API="${TERMINAL_BRAIN_API:-http://127.0.0.1:8765}"
DETAILS=0

case "${1:-}" in
  --help|-h)
    cat <<'EOF'
Usage: ./mac-app/scripts/processes.zsh [--details]

Prints a non-launching process map for Terminal Brain and related agent runtimes:
  - Terminal Brain app process
  - launchctl registration state
  - localhost API health if the app is already running
  - Codex sessions and per-session MCP/kernel children
  - Drafts and brain-console helper processes

This script never launches, foregrounds, quits, kills, or controls Terminal Brain.
EOF
    exit 0
    ;;
  --details)
    DETAILS=1
    ;;
  "")
    ;;
  *)
    echo "Unknown option: $1" >&2
    echo "Run ./mac-app/scripts/processes.zsh --help" >&2
    exit 64
    ;;
esac

all_processes() {
  ps -axo pid=,ppid=,stat=,command=
}

matching_processes() {
  local pattern="$1"
  all_processes | awk -v pattern="$pattern" '
    index(tolower($0), pattern) > 0 &&
    index($0, "mac-app/scripts/processes.zsh") == 0 &&
    index($0, "awk -v pattern") == 0 {
      print
    }
  '
}

count_matches() {
  local pattern="$1"
  matching_processes "$pattern" | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' '
}

print_details() {
  local title="$1"
  local pattern="$2"
  local rows

  rows="$(matching_processes "$pattern" | sed -n '1,20p')"
  if [[ -n "$rows" ]]; then
    echo
    echo "### $title"
    printf '%s\n' "$rows" | sed 's/^/- /'
  fi
}

app_pids="$(pgrep -x TerminalBrain 2>/dev/null || true)"
app_count=0
if [[ -n "$app_pids" ]]; then
  app_count="$(printf '%s\n' "$app_pids" | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' ')"
fi

launch_items="$(launchctl list 2>/dev/null | grep -Ei 'terminalbrain|terminal brain' || true)"
health="$(curl -fsS --max-time 0.5 "$API/health" 2>/dev/null || true)"

codex_sessions="$(count_matches 'node /usr/local/bin/codex')"
codex_engines="$(count_matches '/vendor/aarch64-apple-darwin/codex/codex')"
terminal_brain_mcp="$(count_matches '/software/terminal-brain-mcp/server.mjs')"
brain_kernel="$(count_matches '/software/brain-kernel/server.mjs')"
brain_console="$(count_matches '/software/brain-console')"
drafts_processes="$(count_matches '/applications/drafts.app')"

echo "# Terminal Brain Process Map"
echo
echo "Checked: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo

echo "## Focus Stealers"
if (( app_count > 0 )); then
  echo "- Terminal Brain app: running ($app_count process(es))"
else
  echo "- Terminal Brain app: not running"
fi

if [[ -n "$launch_items" ]]; then
  echo "- launchctl: registered"
else
  echo "- launchctl: no matching loaded service"
fi

if [[ -n "$health" ]]; then
  echo "- API: reachable at $API"
else
  echo "- API: not reachable at $API"
fi
echo "- This command did not launch, foreground, quit, kill, or control anything."
echo

echo "## Agent Runtime Noise"
echo "- Codex CLI sessions: $codex_sessions"
echo "- Codex engine processes: $codex_engines"
echo "- terminal-brain-mcp children: $terminal_brain_mcp"
echo "- brain-kernel children: $brain_kernel"
echo "- brain-console helpers: $brain_console"
echo "- Drafts app/widget processes: $drafts_processes"
echo

if (( terminal_brain_mcp > 1 || brain_kernel > 1 )); then
  echo "## Read"
  echo "- Terminal Brain is not the relaunch loop when the app is not running and launchctl is empty."
  echo "- Multiple Codex sessions can each hold their own MCP/kernel child, so duplicate Node processes usually mean old agent sessions are still open."
  echo "- Cleanup should be explicit because killing those processes can close active Codex chats."
else
  echo "## Read"
  echo "- Runtime process count is normal."
fi

if (( DETAILS == 1 )); then
  print_details "Terminal Brain MCP" '/software/terminal-brain-mcp/server.mjs'
  print_details "Brain Kernel" '/software/brain-kernel/server.mjs'
  print_details "Codex Sessions" 'node /usr/local/bin/codex'
  print_details "Drafts" '/applications/drafts.app'
  print_details "Brain Console" '/software/brain-console'
fi
