#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
API="${TERMINAL_BRAIN_API:-http://127.0.0.1:8765}"

case "${1:-}" in
  --help|-h)
    cat <<'EOF'
Usage: ./mac-app/scripts/agent-prompt.zsh

Prints a focused Terminal Brain agent prompt without launching the app.

Behavior:
  - If Terminal Brain is reachable, print the live Agent Prompt.
  - If Terminal Brain is closed, print a fallback prompt that uses safe local commands.

This script never launches, foregrounds, quits, or controls Terminal Brain.
EOF
    exit 0
    ;;
  "")
    ;;
  *)
    echo "Unknown option: $1" >&2
    echo "Run ./mac-app/scripts/agent-prompt.zsh --help" >&2
    exit 64
    ;;
esac

health="$(curl -fsS --max-time 0.5 "$API/health" 2>/dev/null || true)"

if [[ -n "$health" ]]; then
  curl -fsS "$API/agent-prompt/markdown"
  exit 0
fi

cat <<EOF
# Terminal Brain Agent Prompt

Terminal Brain is not currently reachable at $API.

## Task

Make the next Terminal Brain work block useful without launching or foregrounding the app.

## Starting Context

Use the safe local reads first:

\`\`\`zsh
make oracle-brief
make work-block
make bubble-up
make status
make processes
\`\`\`

## Acceptance Criteria

- Produce one concrete artifact, patch, recommendation, or decision.
- State what changed, why it matters, and the next action.
- If you need the app-backed API, stop and say that Terminal Brain must be opened manually by the operator.
- Do not launch, relaunch, quit, or foreground Terminal Brain.

## Close Loop

When the app is manually open, commit the result with:

\`\`\`zsh
make outcome TITLE="..." OUTCOME="..." PROJECT="Terminal Brain" NEXT="..."
\`\`\`

## Guardrails

- This prompt command did not launch, foreground, quit, kill, or control anything.
- Do not use UI automation or AppleScript against Terminal Brain unless explicitly asked in the current turn.
EOF
