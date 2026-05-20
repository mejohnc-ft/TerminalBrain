#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
API="${TERMINAL_BRAIN_API:-http://127.0.0.1:8765}"
CLOSED_API="${TERMINAL_BRAIN_FIRST_MINUTE_PROOF_API:-http://127.0.0.1:1}"

case "${1:-}" in
  --help|-h)
    cat <<'EOF'
Usage: ./mac-app/scripts/first-minute.zsh

Prints one non-launching first-minute artifact:
  - what Terminal Brain is
  - the value available now
  - the safest next action
  - a working closed-app proof

This script never launches, foregrounds, quits, kills, or controls Terminal Brain.
EOF
    exit 0
    ;;
  "")
    ;;
  *)
    echo "Unknown option: $1" >&2
    echo "Run ./mac-app/scripts/first-minute.zsh --help" >&2
    exit 64
    ;;
esac

health="$(curl -fsS --max-time 0.5 "$API/health" 2>/dev/null || true)"

echo "# Terminal Brain First Minute"
echo
echo "Terminal Brain is a local macOS control center for turning scattered work context into one useful next move, one agent prompt, and one durable memory writeback."
echo

echo "## What You Can Get Immediately"
echo
echo "- A direct read on what matters next."
echo "- A focused Codex/Claude prompt with guardrails."
echo "- A written outcome note in the Oracle Inbox so useful work is not lost."
echo "- A process/readiness truth check that does not steal focus."
echo

echo "## Do This First"
echo
if [[ -n "$health" ]]; then
  echo "Terminal Brain is reachable at $API. Use the live app-backed Start Here path:"
  echo
  echo "\`\`\`zsh"
  echo "make start-here"
  echo "\`\`\`"
else
  echo "Terminal Brain is not reachable at $API. Use the closed-app path:"
  echo
  echo "\`\`\`zsh"
  echo "make agent-prompt"
  echo "make outcome TITLE=\"...\" OUTCOME=\"...\" PROJECT=\"Terminal Brain\" NEXT=\"...\""
  echo "\`\`\`"
fi
echo

echo "## Working Proof"
echo
echo "This command proves the closed-app loop in a temporary workspace. It does not write to the real workspace."
echo
TERMINAL_BRAIN_PROOF_API="$CLOSED_API" "$ROOT/mac-app/scripts/prove-value.zsh" | sed -n '1,90p'
echo

echo "## Guardrail"
echo
echo "- This command did not launch, foreground, quit, kill, or control Terminal Brain."
