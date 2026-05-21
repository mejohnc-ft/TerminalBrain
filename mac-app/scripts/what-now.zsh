#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
API="${TERMINAL_BRAIN_API:-http://127.0.0.1:8765}"

case "${1:-}" in
  --help|-h)
    cat <<'EOF'
Usage: ./mac-app/scripts/what-now.zsh

Prints a concise non-launching situation read:
  - whether Terminal Brain is running or stealing focus
  - repo, CI, and last shipped change
  - agent/runtime process noise
  - a plain interpretation of runtime counts
  - the current blocker and next value command

This script never launches, foregrounds, quits, kills, screenshots, or controls Terminal Brain.
EOF
    exit 0
    ;;
  "")
    ;;
  *)
    echo "Unknown option: $1" >&2
    echo "Run ./mac-app/scripts/what-now.zsh --help" >&2
    exit 64
    ;;
esac

count_processes() {
  local pattern="$1"
  ps -axo pid=,ppid=,stat=,command= | awk -v pattern="$pattern" '
    index(tolower($0), pattern) > 0 &&
    index($0, "mac-app/scripts/what-now.zsh") == 0 &&
    index($0, "awk -v pattern") == 0 {
      count += 1
    }
    END { print count + 0 }
  '
}

branch="$(git -C "$ROOT" branch --show-current 2>/dev/null || echo unknown)"
head_line="$(git -C "$ROOT" log -1 --oneline 2>/dev/null || echo unknown)"
dirty="$(git -C "$ROOT" status --short 2>/dev/null || true)"
dirty_count="$(printf '%s\n' "$dirty" | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' ')"

ci_line=""
if command -v gh >/dev/null 2>&1; then
  ci_line="$(gh run list --branch "$branch" --limit 1 2>/dev/null | head -n 1 || true)"
fi

app_pids="$(pgrep -x TerminalBrain 2>/dev/null || true)"
app_count=0
if [[ -n "$app_pids" ]]; then
  app_count="$(printf '%s\n' "$app_pids" | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' ')"
fi

launch_items="$(launchctl list 2>/dev/null | grep -Ei 'terminalbrain|terminal brain' || true)"
health="$(curl -fsS --max-time 0.5 "$API/health" 2>/dev/null || true)"

codex_sessions="$(count_processes 'node /usr/local/bin/codex')"
codex_engines="$(count_processes '/vendor/aarch64-apple-darwin/codex/codex')"
terminal_brain_mcp="$(count_processes '/software/terminal-brain-mcp/server.mjs')"
brain_kernel="$(count_processes '/software/brain-kernel/server.mjs')"
drafts_processes="$(count_processes '/applications/drafts.app')"

echo "# Terminal Brain What Now"
echo
echo "Checked: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo

echo "## Plain Answer"
if (( app_count > 0 )); then
  echo "- Terminal Brain app is running ($app_count process(es))."
else
  echo "- Terminal Brain app is not running."
fi

if [[ -n "$launch_items" ]]; then
  echo "- launchctl has a matching Terminal Brain item loaded; review it before assuming manual-only behavior."
else
  echo "- No Terminal Brain launch agent is loaded."
fi

if [[ -n "$health" ]]; then
  echo "- App API is reachable at $API."
else
  echo "- App API is closed; app-backed tools wait for a manual app open."
fi

if (( app_count == 0 )) && [[ -z "$launch_items" ]] && [[ -z "$health" ]]; then
  echo "- No Terminal Brain relaunch loop is detected."
fi
echo

echo "## Repo And CI"
echo "- Branch: $branch"
echo "- Head: $head_line"
if (( dirty_count > 0 )); then
  echo "- Working tree: dirty ($dirty_count change(s))"
else
  echo "- Working tree: clean"
fi
if [[ -n "$ci_line" ]]; then
  echo "- Latest CI: $ci_line"
else
  echo "- Latest CI: unavailable from this shell"
fi
echo

echo "## Runtime Noise"
echo "- Codex CLI sessions: $codex_sessions"
echo "- Codex engine processes: $codex_engines"
echo "- terminal-brain-mcp children: $terminal_brain_mcp"
echo "- brain-kernel children: $brain_kernel"
echo "- Drafts app/widget processes: $drafts_processes"
echo

echo "## Read"
if (( app_count == 0 )) && [[ -z "$launch_items" ]] && [[ -z "$health" ]]; then
  echo "- Terminal Brain is not the focus stealer in this state."
else
  echo "- Terminal Brain has active runtime state; use make processes for details before changing anything."
fi
if (( codex_sessions > 1 )); then
  echo "- Multiple Codex sessions usually mean open agent chats or old shells, not a Terminal Brain relaunch loop."
else
  echo "- Codex session count is low."
fi
if (( terminal_brain_mcp == 0 && brain_kernel == 0 )); then
  echo "- No Terminal Brain MCP/kernel child processes are currently attached."
else
  echo "- Terminal Brain MCP/kernel children exist; use make cleanup-plan for a non-destructive review before killing anything."
fi
echo

echo "## Current Blocker"
echo "- CLI, MCP, and static native value paths are ready."
echo "- Live visual UX certification is still blocked until you explicitly open Terminal Brain or authorize an app inspection."
echo

echo "## Get Value Now"
echo "Run:"
echo
echo "\`\`\`zsh"
echo "make start"
echo "\`\`\`"
echo
echo "That gives one move, why it matters, compact context, ask/capture/delegate options, and the outcome writeback command."
echo
echo "If you only want process truth, run:"
echo
echo "\`\`\`zsh"
echo "make processes"
echo "make doctor"
echo "\`\`\`"
echo

echo "## Guardrail"
echo "- This command did not launch, foreground, screenshot, quit, kill, or control Terminal Brain."
