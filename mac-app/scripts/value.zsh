#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
API="${TERMINAL_BRAIN_API:-http://127.0.0.1:8765}"

case "${1:-}" in
  --help|-h)
    cat <<'EOF'
Usage: ./mac-app/scripts/value.zsh

Prints Terminal Brain's current value read without launching the app.

Behavior:
  - If Terminal Brain is reachable, print the live Value Brief.
  - If Terminal Brain is closed, print a plain-language value map and next command.

This script never launches, foregrounds, quits, or controls Terminal Brain.
EOF
    exit 0
    ;;
  "")
    ;;
  *)
    echo "Unknown option: $1" >&2
    echo "Run ./mac-app/scripts/value.zsh --help" >&2
    exit 64
    ;;
esac

health="$(curl -fsS --max-time 0.5 "$API/health" 2>/dev/null || true)"

if [[ -n "$health" ]]; then
  curl -fsS "$API/value-brief/markdown"
  exit 0
fi

cat <<EOF
# Terminal Brain Value Now

Terminal Brain is built to turn scattered local work context into one useful next move and a durable written outcome.

## What You Can Get From It

- A one-block work path: what to notice, decide, test, create, and avoid.
- Agent-ready prompts grounded in local project memory.
- Obsidian-backed writeback for ideas, reads, outcomes, and next actions.
- Runtime checks that prove whether the app, MCP, config, and API are actually ready.
- Guardrails that prevent background agents from launching or stealing focus.

## Fastest Useful Path

Open Terminal Brain manually when you want the UI/API active, then run:

\`\`\`zsh
make start-here
\`\`\`

If you only want to inspect readiness without opening the app:

\`\`\`zsh
make doctor
\`\`\`

## Current State

EOF

"$ROOT/mac-app/scripts/status.zsh"
