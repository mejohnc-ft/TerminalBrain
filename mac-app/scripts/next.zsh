#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
API="${TERMINAL_BRAIN_API:-http://127.0.0.1:8765}"

case "${1:-}" in
  --help|-h)
    cat <<'EOF'
Usage: ./mac-app/scripts/next.zsh

Prints the next useful Terminal Brain move without launching the app.

Behavior:
  - If Terminal Brain is already reachable, print Start Here.
  - If Terminal Brain is closed, print the useful closed-app loop and runtime status.

This script never launches, foregrounds, quits, or controls Terminal Brain.
EOF
    exit 0
    ;;
  "")
    ;;
  *)
    echo "Unknown option: $1" >&2
    echo "Run ./mac-app/scripts/next.zsh --help" >&2
    exit 64
    ;;
esac

health="$(curl -fsS --max-time 0.5 "$API/health" 2>/dev/null || true)"

if [[ -n "$health" ]]; then
  curl -fsS "$API/start-here/markdown"
  exit 0
fi

cat <<EOF
# Terminal Brain Next

Terminal Brain is not currently reachable at $API.

## Next Move

Use the closed-app loop now:

\`\`\`zsh
make oracle-brief
make agent-prompt
make outcome TITLE="..." OUTCOME="..." PROJECT="Terminal Brain" NEXT="..."
\`\`\`

Open Terminal Brain manually only when you want the UI/API active. Then run:

\`\`\`zsh
make start-here
\`\`\`

## Runtime State

EOF

"$ROOT/mac-app/scripts/status.zsh"
