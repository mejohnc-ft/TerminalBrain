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
  - If Terminal Brain is closed, print runtime status and the manual next step.

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

Open Terminal Brain manually when you want it in focus, then run:

\`\`\`zsh
make start-here
\`\`\`

Until then, this repo can still answer runtime state:

\`\`\`zsh
make status
\`\`\`

EOF

"$ROOT/mac-app/scripts/status.zsh"
