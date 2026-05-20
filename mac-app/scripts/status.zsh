#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
API="${TERMINAL_BRAIN_API:-http://127.0.0.1:8765}"

case "${1:-}" in
  --help|-h)
    cat <<'EOF'
Usage: ./mac-app/scripts/status.zsh

Prints a non-launching Terminal Brain status:
  - git branch and dirty state
  - latest commit
  - latest GitHub CI run when gh is available
  - local Terminal Brain process state
  - launchctl registration state
  - localhost API health if the app is already running

This script never launches, foregrounds, quits, or controls Terminal Brain.
EOF
    exit 0
    ;;
  "")
    ;;
  *)
    echo "Unknown option: $1" >&2
    echo "Run ./mac-app/scripts/status.zsh --help" >&2
    exit 64
    ;;
esac

echo "# Terminal Brain Status"
echo
echo "Checked: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo

if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch="$(git -C "$ROOT" branch --show-current 2>/dev/null || true)"
  head="$(git -C "$ROOT" log -1 --oneline 2>/dev/null || true)"
  dirty="$(git -C "$ROOT" status --short 2>/dev/null || true)"
  upstream="$(git -C "$ROOT" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)"
  echo "## Repo"
  echo "- Branch: ${branch:-unknown}"
  echo "- Upstream: ${upstream:-none}"
  echo "- Head: ${head:-unknown}"
  if [[ -n "$dirty" ]]; then
    echo "- Working tree: dirty"
    printf '%s\n' "$dirty" | sed 's/^/  /'
  else
    echo "- Working tree: clean"
  fi
  echo
fi

echo "## CI"
if command -v gh >/dev/null 2>&1 && git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch="$(git -C "$ROOT" branch --show-current 2>/dev/null || echo main)"
  latest_run="$(gh run list --branch "$branch" --limit 1 2>/dev/null || true)"
  if [[ -n "$latest_run" ]]; then
    printf '%s\n' "$latest_run" | sed 's/^/- /'
  else
    echo "- No run found or GitHub CLI is not authenticated."
  fi
else
  echo "- GitHub CLI unavailable."
fi
echo

echo "## Local Runtime"
process_pids="$(pgrep -x TerminalBrain 2>/dev/null || true)"
processes=""
if [[ -n "$process_pids" ]]; then
  processes="$(ps -p "${(j:,:)${(f)process_pids}}" -o pid=,comm=,args= 2>/dev/null || true)"
fi
if [[ -n "$processes" ]]; then
  echo "- App process: running"
  printf '%s\n' "$processes" | sed 's/^/  /'
else
  echo "- App process: not running"
fi

launch_items="$(launchctl list 2>/dev/null | grep -Ei 'terminalbrain|terminal brain' || true)"
if [[ -n "$launch_items" ]]; then
  echo "- launchctl: registered"
  printf '%s\n' "$launch_items" | sed 's/^/  /'
else
  echo "- launchctl: no matching loaded service"
fi

health="$(curl -fsS --max-time 0.5 "$API/health" 2>/dev/null || true)"
if [[ -n "$health" ]]; then
  echo "- API: reachable at $API"
  printf '%s\n' "$health" | sed 's/^/  /'
else
  echo "- API: not reachable at $API"
fi
echo

echo "## Guardrails"
echo "- This command did not launch or foreground Terminal Brain."
echo "- Static guard: run make verify to enforce no foregrounding from scripts and MCP tooling."
