#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
API="${TERMINAL_BRAIN_API:-http://127.0.0.1:8765}"

case "${1:-}" in
  --help|-h)
    cat <<'EOF'
Usage: ./mac-app/scripts/now.zsh

Prints the fastest Terminal Brain orientation:
  - bottom line
  - immediate next action
  - process truth
  - readiness verdict

If the app is reachable, this prints live Now Markdown. If the app is closed,
it prints a useful terminal-only orientation. This script never launches,
foregrounds, quits, kills, or controls Terminal Brain.
EOF
    exit 0
    ;;
  "")
    ;;
  *)
    echo "Unknown option: $1" >&2
    echo "Run ./mac-app/scripts/now.zsh --help" >&2
    exit 64
    ;;
esac

health="$(curl -fsS --max-time 0.5 "$API/health" 2>/dev/null || true)"

if [[ -n "$health" ]]; then
  curl -fsS "$API/now/markdown"
  exit 0
fi

echo "# Terminal Brain Now"
echo
echo "Checked: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo

doctor_output="$("$ROOT/mac-app/scripts/doctor.zsh")"
readiness="$(printf '%s\n' "$doctor_output" | sed -nE 's/^- readiness: //p' | tail -1)"
doctor_next="$(printf '%s\n' "$doctor_output" | sed -nE 's/^- next: //p' | tail -1)"

echo "## Bottom Line"
echo
echo "Terminal Brain is installed and agent-wired, but the app/API is closed. That is fine: background checks can still explain value, process state, setup, and the next manual step without stealing focus."
echo

echo "## Do This"
echo
echo "1. Stay terminal-only when you want zero focus changes:"
echo
echo "   \`\`\`zsh"
echo "   make oracle-brief"
echo "   make work-block"
echo "   make bubble-up"
echo "   make processes"
echo "   make doctor"
echo "   \`\`\`"
echo
echo "2. Open Terminal Brain manually only when you want the UI/API active, then run:"
echo
echo "   \`\`\`zsh"
echo "   make start-here"
echo "   \`\`\`"
echo
echo "3. After useful work happens, write the outcome back:"
echo
echo "   \`\`\`zsh"
echo "   make outcome TITLE=\"...\" OUTCOME=\"...\" PROJECT=\"...\" NEXT=\"...\""
echo "   \`\`\`"
echo

process_output="$("$ROOT/mac-app/scripts/processes.zsh")"
printf '%s\n' "$process_output" | awk '
  $0 == "# Terminal Brain Process Map" {
    print "## Process Map"
    next
  }
  /^## / {
    sub(/^## /, "### ")
  }
  { print }
'
echo

echo "## Readiness"
echo
echo "- ${readiness:-unknown}"
echo "- Next: ${doctor_next:-run make work-block}"
echo
echo "## Guardrail"
echo
echo "- This command did not launch, foreground, quit, kill, or control Terminal Brain."
