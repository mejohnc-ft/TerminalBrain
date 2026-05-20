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
  - If Terminal Brain is closed, print a local pull-forward read and current status.

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

demote_without_guardrail() {
  awk '
    /^# Terminal Brain Work Block$/ { next }
    /^## Use This Block$/ { skip_use = 1; next }
    skip_use && /^## Pull Forward$/ { skip_use = 0; next }
    skip_use { next }
    /^## Pull Forward$/ { next }
    /^## Guardrail$/ { skip = 1; next }
    skip { next }
    /^Checked: / { next }
    /^# / { print "### " substr($0, 3); next }
    /^## / { print "### " substr($0, 4); next }
    /^### / { print "### " substr($0, 5); next }
    { print }
  '
}

cat <<EOF
# Terminal Brain Oracle Brief

Terminal Brain is not currently reachable at $API, so this is a local closed-app read.

## Direct Read

- Treat the pull-forward item below as the current highest-signal thread.
- Do one small action, then commit the result so the system gets smarter.
- Open Terminal Brain manually only when you want the UI/API active.

## Local Pull Forward

EOF

"$ROOT/mac-app/scripts/work-block.zsh" --limit 1 | demote_without_guardrail

cat <<EOF

## What May Be Missing

- The useful question is not "what does the dashboard say?" It is "what should change because this signal surfaced?"
- If the pulled-forward item is vague, pressure-test it before turning it into a project.
- If it is already actionable, skip more reading and close one loop.

## Cheapest Test

\`\`\`zsh
make ask QUERY="What is the smallest useful next action for the pulled-forward item?" PROJECT="Terminal Brain"
make ask-commit QUERY="What did this work reveal that should be saved?" PROJECT="Terminal Brain"
\`\`\`

## Agent Handoff

\`\`\`zsh
make agent-prompt
make outcome TITLE="..." OUTCOME="..." PROJECT="Terminal Brain" NEXT="..."
\`\`\`

## Why This Exists

- It collapses current focus, blindspots, ideas, review queue, and project memory into one read.
- It names what to do next, what may be missing, the cheapest test, and the agent handoff.
- It is designed to produce one useful artifact and one committed outcome, not another dashboard scan.

## Runtime Truth

EOF

"$ROOT/mac-app/scripts/status.zsh"
