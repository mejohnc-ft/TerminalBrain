#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

case "${1:-}" in
  --help|-h)
    cat <<'EOF'
Usage: ./mac-app/scripts/playbook.zsh

Prints a non-launching operator playbook:
  - what to run for common situations
  - the first five-minute loop
  - the daily cadence
  - the agent handoff path
  - the current readiness summary

This script never launches, foregrounds, quits, kills, or controls Terminal Brain.
EOF
    exit 0
    ;;
  "")
    ;;
  *)
    echo "Unknown option: $1" >&2
    echo "Run ./mac-app/scripts/playbook.zsh --help" >&2
    exit 64
    ;;
esac

echo "# Terminal Brain Playbook"
echo
echo "Use this when you do not want to read docs and just need Terminal Brain to become useful."
echo
echo "## Pick The Situation"
echo
echo "| Situation | Run | What You Get |"
echo "| --- | --- | --- |"
echo "| I need proof this is useful | \`make demo\` | Temporary seeded ideas, Bubble Up, Work Block, and real-use commands |"
echo "| I need one real thing to do | \`make work-block\` | Pull-forward signal, review queue, and outcome command |"
echo "| I need the direct read | \`make oracle-brief\` | Next moves, missing signal, cheapest test, agent handoff |"
echo "| I need to save a thought | \`make idea IDEA=\"...\" PROJECT=\"...\"\` | Durable Oracle Inbox note with review status |"
echo "| I need to ask the system | \`make ask QUERY=\"...\"\` | Oracle answer with closed-app fallback |"
echo "| I need an agent handoff | \`make agent-prompt\` | Bounded Codex/Claude prompt with guardrails |"
echo "| I finished something | \`make outcome TITLE=\"...\" OUTCOME=\"...\" PROJECT=\"...\" NEXT=\"...\"\` | Accepted memory note and next action |"
echo "| I need to know what is running | \`make processes\` | App, MCP, Codex, kernel, Drafts, launchctl, and API state |"
echo
echo "## First Five Minutes"
echo
echo "\`\`\`zsh"
echo "make demo"
echo "make work-block"
echo "make idea IDEA=\"one rough thought worth not losing\" PROJECT=\"Terminal Brain\""
echo "make bubble-up"
echo "make outcome TITLE=\"First useful loop\" OUTCOME=\"Captured, reviewed, and chose one next action.\" PROJECT=\"Terminal Brain\" NEXT=\"Run make work-block tomorrow.\""
echo "\`\`\`"
echo
echo "Done means: one idea captured, one signal pulled forward, and one outcome written back."
echo
echo "## Daily Cadence"
echo
echo "1. Run \`make work-block\` before planning."
echo "2. Turn one item into action, delegation, or dismissal."
echo "3. Run \`make outcome ...\` when the work changes something."
echo "4. Run \`make review\` at the end of the day and clear stale notes."
echo
echo "## Agent Cadence"
echo
echo "1. Start with MCP \`terminal_brain_work_block_markdown\` or \`terminal_brain_oracle_brief_markdown\`."
echo "2. Ask for one bounded patch or research artifact, not broad exploration."
echo "3. Close with MCP \`terminal_brain_commit_outcome\` or \`make outcome ...\`."
echo
echo "## Current Readiness"
echo
"$ROOT/mac-app/scripts/doctor.zsh" | sed -n '/^## Summary/,$p'
echo
echo "## Guardrail"
echo
echo "- This playbook did not launch, foreground, quit, kill, or control Terminal Brain."
