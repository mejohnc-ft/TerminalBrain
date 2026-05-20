#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
API="${TERMINAL_BRAIN_API:-http://127.0.0.1:8765}"

case "${1:-}" in
  --help|-h)
    cat <<'EOF'
Usage: ./mac-app/scripts/oracle-brief.zsh

Prints Terminal Brain's direct Oracle Brief without launching the app.

Behavior:
  - If Terminal Brain is reachable, print the live Oracle Brief.
  - If Terminal Brain is closed, print a plain fallback and current status.

This script never launches, foregrounds, quits, or controls Terminal Brain.
EOF
    exit 0
    ;;
  "")
    ;;
  *)
    echo "Unknown option: $1" >&2
    echo "Run ./mac-app/scripts/oracle-brief.zsh --help" >&2
    exit 64
    ;;
esac

health="$(curl -fsS --max-time 0.5 "$API/health" 2>/dev/null || true)"

if [[ -n "$health" ]]; then
  curl -fsS "$API/oracle/brief/markdown"
  exit 0
fi

cat <<EOF
# Terminal Brain Oracle Brief

Terminal Brain is not currently reachable at $API.

## Direct Read

Open Terminal Brain manually when you want the UI/API active. Then run:

\`\`\`zsh
make oracle-brief
\`\`\`

## Why This Exists

- It collapses current focus, blindspots, ideas, review queue, and project memory into one read.
- It names what to do next, what may be missing, the cheapest test, and the agent handoff.
- It is designed to produce one useful artifact and one committed outcome, not another dashboard scan.

## Current State

EOF

"$ROOT/mac-app/scripts/status.zsh"
