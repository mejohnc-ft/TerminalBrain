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
  - If Terminal Brain is closed, print the one-move Use Now path and closed-app loop.

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

demote_oracle() {
  awk '
    /^# Terminal Brain Oracle Brief$/ { next }
    /^## Runtime Truth$/ { skip_runtime = 1; next }
    skip_runtime { next }
    /^## / { print "### " substr($0, 4); next }
    /^### / { print "#### " substr($0, 5); next }
    { print }
  '
}

cat <<EOF
# Terminal Brain Next

Terminal Brain is not currently reachable at $API, so this stays local and closed-app.

## Next Move

Start with one move:

\`\`\`zsh
make use-now
\`\`\`

## Use Now

EOF

TERMINAL_BRAIN_API="$API" "$ROOT/mac-app/scripts/use-now.zsh" | demote_oracle

cat <<EOF

## Closed-App Loop

\`\`\`zsh
make use-now
make ask QUERY="What should I do next for Terminal Brain, and what am I missing?"
make agent-prompt
make outcome TITLE="..." OUTCOME="..." PROJECT="Terminal Brain" NEXT="..."
\`\`\`

Open Terminal Brain manually only when you want the UI/API active, then run:

\`\`\`zsh
make start-here
\`\`\`

## Guardrail

- This command did not launch or foreground Terminal Brain.
- It read local artifacts and status only.
EOF
