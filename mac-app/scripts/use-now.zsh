#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PROJECT="${PROJECT:-Terminal Brain}"
LIMIT="${LIMIT:-1}"
IDEA_TEXT="${IDEA:-}"
TITLE="${TITLE:-Use Now Capture}"
SOURCE="${SOURCE:-Terminal Brain Use Now}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --idea)
      IDEA_TEXT="${2:-}"
      shift
      ;;
    --idea=*)
      IDEA_TEXT="${1#--idea=}"
      ;;
    --title)
      TITLE="${2:-Use Now Capture}"
      shift
      ;;
    --title=*)
      TITLE="${1#--title=}"
      ;;
    --project)
      PROJECT="${2:-Terminal Brain}"
      shift
      ;;
    --project=*)
      PROJECT="${1#--project=}"
      ;;
    --limit)
      LIMIT="${2:-2}"
      shift
      ;;
    --limit=*)
      LIMIT="${1#--limit=}"
      ;;
    --help|-h)
      cat <<'EOF'
Usage: ./mac-app/scripts/use-now.zsh [--project PROJECT] [--limit N]

Prints the shortest useful Terminal Brain path for a new or overwhelmed operator:
  - what value you can get immediately
  - optional idea capture if IDEA or --idea is supplied
  - the current pull-forward work block
  - the exact ask, capture, delegate, and outcome commands

This script never launches, foregrounds, quits, kills, screenshots, or controls Terminal Brain.
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Run ./mac-app/scripts/use-now.zsh --help" >&2
      exit 64
      ;;
  esac
  shift
done

demote_work_block() {
  awk '
    /^# Terminal Brain Work Block$/ { next }
    /^Checked: / { next }
    /^## Use This Block$/ { skip_intro = 1; next }
    skip_intro && /^## Pull Forward$/ { skip_intro = 0; print "### Pull Forward"; next }
    skip_intro { next }
    /^## Guardrail$/ { skip = 1; next }
    skip { next }
    /^## Completed Evidence$/ { skip_completed = 1; next }
    skip_completed && /^## Recent Work Signals$/ { skip_completed = 0; print "### Recent Work Signals"; next }
    skip_completed && /^## Next Clean Move$/ { skip_completed = 0; print "### Next Clean Move"; next }
    skip_completed && /^## Broader Queue$/ { skip_completed = 0; print "### Broader Queue"; next }
    skip_completed { next }
    /^# Equivalent manual capture:$/ { skip_manual_capture = 1; next }
    skip_manual_capture && /^make work-block$/ { skip_manual_capture = 0; next }
    skip_manual_capture { next }
    /^## / { print "### " substr($0, 4); next }
    /^### / { print "#### " substr($0, 5); next }
    { print }
  '
}

one_move_from_work_block() {
  awk '
    /^## Pull Forward$/ { pull_forward = 1; next }
    pull_forward && /^```zsh$/ { in_code = 1; note = ""; next }
    pull_forward && in_code && /^```$/ { in_code = 0; note = ""; next }
    pull_forward && in_code && /^NOTE=/ { note = $0; next }
    pull_forward && in_code && /^make review-status / {
      if (note != "") { print note }
      print
      found = 1
      exit
    }
    pull_forward && in_code && /^make recent-work INDEX=/ { print; found = 1; exit }
    pull_forward && in_code && /^make idea / { print; found = 1; exit }
    END {
      if (!found) { print "make agent-prompt" }
    }
  '
}

echo "# Terminal Brain Use Now"
echo
echo "This is the one-command path when you do not want to think about which Terminal Brain surface to use."
echo
echo "## What You Get In 60 Seconds"
echo
echo "- One concrete pull-forward signal instead of a dashboard."
echo "- One command to ask what you may be missing."
echo "- One command to capture the thought before it disappears."
echo "- One command to hand a bounded task to Codex or Claude."
echo "- One command to write the outcome back into memory."
echo
echo "## Do This"
echo
echo "1. Read the pull-forward block below."
echo "2. Pick exactly one item or capture one pressure point."
echo "3. Run the ask or agent command if the next action is unclear."
echo "4. When anything useful happens, run the outcome command."
echo
if [[ -n "$IDEA_TEXT" ]]; then
  echo "## Captured First Signal"
  echo
  capture_output="$(
    IDEA="$IDEA_TEXT" \
    TITLE="$TITLE" \
    PROJECT="$PROJECT" \
    SOURCE="$SOURCE" \
    "$ROOT/mac-app/scripts/idea.zsh"
  )"
  if ! CAPTURE_OUTPUT="$capture_output" ruby -rjson -e '
    payload = JSON.parse(ENV.fetch("CAPTURE_OUTPUT"))
    puts "- Captured: #{payload.fetch("title", "Captured Idea")}"
    puts "- Project: #{payload.fetch("project", "General Brain")}"
    puts "- Review status: #{payload.fetch("reviewStatus", "new")}"
    puts "- Path: #{payload.fetch("path", "(app API)")}"
    puts "- Guardrail: #{payload.fetch("guardrail", "capture did not launch or foreground Terminal Brain")}"
  '; then
    printf '%s\n' "$capture_output"
  fi
  echo
fi

work_block_output="$("$ROOT/mac-app/scripts/work-block.zsh" --project "$PROJECT" --limit "$LIMIT")"
one_move="$(printf '%s\n' "$work_block_output" | one_move_from_work_block)"

echo "## One Move"
echo
echo '```zsh'
printf '%s\n' "$one_move"
echo '```'
echo
echo "## Current Work Block"
echo
printf '%s\n' "$work_block_output" | demote_work_block
echo
echo "## Ask, Capture, Delegate, Close"
echo
echo '```zsh'
echo "make ask QUERY=\"What should I do next for ${PROJECT}, and what am I missing?\""
echo "make use-now IDEA=\"The thing I keep circling is ...\" PROJECT=\"$PROJECT\""
echo "make agent-prompt"
echo "make outcome TITLE=\"...\" OUTCOME=\"...\" PROJECT=\"$PROJECT\" NEXT=\"...\""
echo '```'
echo
echo "## If This Still Feels Empty"
echo
echo "Seed the brain with one real point of pressure, then come back here:"
echo
echo '```zsh'
echo "make idea IDEA=\"I need Terminal Brain to help me with ...\" PROJECT=\"$PROJECT\""
echo "make use-now PROJECT=\"$PROJECT\""
echo '```'
echo
echo "## Guardrail"
echo
echo "- This command did not launch, foreground, screenshot, quit, kill, or control Terminal Brain."
