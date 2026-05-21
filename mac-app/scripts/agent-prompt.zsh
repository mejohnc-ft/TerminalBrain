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

use_now_output="$("$ROOT/mac-app/scripts/use-now.zsh" --limit 1)"
one_move="$(
  printf '%s\n' "$use_now_output" | awk '
    /^## One Move$/ { in_section = 1; next }
    in_section && /^## / { exit }
    in_section { print }
  '
)"
why_move="$(
  printf '%s\n' "$use_now_output" | awk '
    /^## Why This Move$/ { in_section = 1; next }
    in_section && /^## / { exit }
    in_section { print }
  '
)"

if grep -q 'make agent-prompt' <<<"$one_move"; then
  one_move=$'```zsh\nmake work-block\n```'
  why_move="Use Now selected delegation because the queue is clean and the clean-queue Oracle read is already accepted. For an agent, the next non-recursive move is to read the work block and produce one concrete artifact, patch, recommendation, or decision."
fi

cat <<EOF
# Terminal Brain Agent Prompt

Terminal Brain is not currently reachable at $API.

## Task

Use the current Terminal Brain signal to produce one concrete artifact, patch, recommendation, or decision without launching or foregrounding the app.

## Current One Move

$one_move

## Why This Move

$why_move

## Starting Context

Use these safe local reads if the One Move needs more context:

\`\`\`zsh
make use-now
make oracle-brief
make work-block
make bubble-up
make status
make processes
\`\`\`

## Acceptance Criteria

- Do the smallest useful task that advances the Current One Move.
- Produce one concrete artifact, patch, recommendation, or decision; analysis alone is not enough.
- State what changed, why it matters, and the next action.
- If you need the app-backed API, stop and say that Terminal Brain must be opened manually by the operator.
- Do not launch, relaunch, quit, or foreground Terminal Brain.

## Close Loop

Commit the result through the CLI. It will use the app API if reachable or a closed-app local fallback if not:

\`\`\`zsh
make outcome TITLE="..." OUTCOME="..." PROJECT="Terminal Brain" NEXT="..." EVIDENCE="..."
\`\`\`

## Guardrails

- This prompt command did not launch, foreground, quit, kill, or control anything.
- Do not use UI automation or AppleScript against Terminal Brain unless explicitly asked in the current turn.
EOF
