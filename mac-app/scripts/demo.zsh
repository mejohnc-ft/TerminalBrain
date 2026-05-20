#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CLOSED_API="${TERMINAL_BRAIN_DEMO_API:-http://127.0.0.1:1}"
TMP_WORKSPACE="$(mktemp -d)"
trap 'rm -rf "$TMP_WORKSPACE"' EXIT

case "${1:-}" in
  --help|-h)
    cat <<'EOF'
Usage: ./mac-app/scripts/demo.zsh

Runs a non-launching Terminal Brain demo in a temporary workspace:
  1. Seed realistic Oracle Inbox notes.
  2. Show Review Queue.
  3. Show Bubble Up.
  4. Show Work Block.
  5. Show the exact real-work commands to keep using the loop.

This script never launches, foregrounds, quits, kills, or controls Terminal Brain.
EOF
    exit 0
    ;;
  "")
    ;;
  *)
    echo "Unknown option: $1" >&2
    echo "Run ./mac-app/scripts/demo.zsh --help" >&2
    exit 64
    ;;
esac

note_path_from_json() {
  ruby -rjson -e 'puts JSON.parse(STDIN.read).fetch("path")'
}

seed_idea() {
  TERMINAL_BRAIN_API="$CLOSED_API" \
  TERMINAL_BRAIN_WORKSPACE="$TMP_WORKSPACE" \
  "$ROOT/mac-app/scripts/idea.zsh" "$@" | note_path_from_json
}

seed_outcome() {
  TERMINAL_BRAIN_API="$CLOSED_API" \
  TERMINAL_BRAIN_WORKSPACE="$TMP_WORKSPACE" \
  "$ROOT/mac-app/scripts/outcome.zsh" "$@" | note_path_from_json
}

delegated_note="$(
  seed_idea \
    --title "Unify capture inboxes" \
    --project "Terminal Brain Demo" \
    --tag demo \
    "Drafts, Apple Notes, Obsidian, and agent chats should land in one review lane with source, project, and next action preserved."
)"

seed_idea \
  --title "Mine agent histories" \
  --project "Terminal Brain Demo" \
  --tag demo \
  "Claude Code and Codex histories can become project memory if each useful result is collapsed into a durable outcome or delegated read." >/dev/null

seed_idea \
  --title "Make the app feel like an oracle" \
  --project "Terminal Brain Demo" \
  --tag demo \
  "The first screen should answer what matters, what is missing, and what to do next before it shows raw metrics." >/dev/null

seed_outcome \
  --title "Stopped focus stealing" \
  --project "Terminal Brain Demo" \
  --tag demo \
  --evidence "Doctor confirms no Terminal Brain process is running and no launch agent is loaded." \
  --next "Keep every verifier and demo path non-launching." \
  "Converted runtime checks into closed-app surfaces so agents can inspect status without relaunching the UI." >/dev/null

TERMINAL_BRAIN_WORKSPACE="$TMP_WORKSPACE" \
  "$ROOT/mac-app/scripts/review-status.zsh" --id "$delegated_note" --status delegated >/dev/null

echo "# Terminal Brain Demo"
echo
echo "This is a temporary, non-launching demo for someone who has never used Terminal Brain."
echo
echo "## What It Proves"
echo
echo "- Rough ideas become reviewable Oracle Inbox notes."
echo "- Important signals bubble up without opening the app."
echo "- A work block turns scattered notes into one next action."
echo "- Outcomes close the loop as durable memory."
echo
echo "## Seeded Scenario"
echo
echo "- Project: Terminal Brain Demo"
echo "- Temporary workspace: $TMP_WORKSPACE"
echo "- Notes seeded: 3 ideas, 1 accepted outcome, 1 delegated item"
echo
echo "## Review Queue"
echo
TERMINAL_BRAIN_WORKSPACE="$TMP_WORKSPACE" "$ROOT/mac-app/scripts/review.zsh" --limit 6
echo
echo "## Bubble Up"
echo
TERMINAL_BRAIN_WORKSPACE="$TMP_WORKSPACE" "$ROOT/mac-app/scripts/bubble-up.zsh" --limit 4
echo
echo "## Work Block"
echo
TERMINAL_BRAIN_WORKSPACE="$TMP_WORKSPACE" "$ROOT/mac-app/scripts/work-block.zsh" --limit 3
echo
echo "## Use It For Real"
echo
echo "\`\`\`zsh"
echo "make idea IDEA=\"Capture the rough thought before it disappears.\" PROJECT=\"Terminal Brain\""
echo "make bubble-up"
echo "make work-block"
echo "make outcome TITLE=\"...\" OUTCOME=\"what changed and why it matters\" PROJECT=\"Terminal Brain\" NEXT=\"...\""
echo "\`\`\`"
echo
echo "## Guardrail"
echo
echo "- This demo did not launch, foreground, quit, kill, or control Terminal Brain."
echo "- The temporary workspace is removed after the demo command exits."
