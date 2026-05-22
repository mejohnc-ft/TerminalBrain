#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

case "${1:-}" in
  --help|-h)
    cat <<'EOF'
Usage: ./mac-app/scripts/daily-brief.zsh

Prints a proactive non-launching daily brief:
  - source freshness
  - ranked action cards
  - current Oracle answer
  - commands to close the loop

This script never launches, foregrounds, screenshots, quits, kills, or controls Terminal Brain.
EOF
    exit 0
    ;;
  "")
    ;;
  *)
    echo "Unknown option: $1" >&2
    echo "Run ./mac-app/scripts/daily-brief.zsh --help" >&2
    exit 64
    ;;
esac

demote() {
  awk '
    /^# / { print "## " substr($0, 3); next }
    /^## / { print "### " substr($0, 4); next }
    /^### / { print "#### " substr($0, 5); next }
    { print }
  '
}

strip_guardrail() {
  awk '
    /^## Guardrail$/ { skip = 1; next }
    skip { next }
    { print }
  '
}

echo "# Terminal Brain Daily Brief"
echo
echo "Checked: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo
echo "## Bottom Line"
echo
echo "- Use this as the proactive start of day: check freshness, pick one action card, then save the outcome."
echo "- It is designed to turn your local notes, agent histories, review queue, and repo state into one action."
echo
echo "## Freshness"
echo
"$ROOT/mac-app/scripts/freshness.zsh" | strip_guardrail | demote
echo
echo "## Ranked Actions"
echo
"$ROOT/mac-app/scripts/action-cards.zsh" --limit 3 | strip_guardrail | demote
echo
echo "## Oracle Check"
echo
"$ROOT/mac-app/scripts/oracle.zsh" "What should I do next, what am I missing, and what cheap test would create value?" | strip_guardrail | demote
echo
echo "## Start Working"
echo
echo '```zsh'
echo "make action-cards"
echo "make agent-prompt"
echo "make outcome TITLE=\"Daily brief outcome\" OUTCOME=\"...\" PROJECT=\"Terminal Brain\" NEXT=\"...\""
echo '```'
echo
echo "## Guardrail"
echo
echo "- This command did not launch, foreground, screenshot, quit, kill, or control Terminal Brain."
