#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PROJECT="${PROJECT:-Terminal Brain}"
TITLE="${TITLE:-Check-in Signal}"
IDEA_TEXT="${IDEA:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)
      PROJECT="${2:-Terminal Brain}"
      shift
      ;;
    --project=*)
      PROJECT="${1#--project=}"
      ;;
    --title)
      TITLE="${2:-Check-in Signal}"
      shift
      ;;
    --title=*)
      TITLE="${1#--title=}"
      ;;
    --idea)
      IDEA_TEXT="${2:-}"
      shift
      ;;
    --idea=*)
      IDEA_TEXT="${1#--idea=}"
      ;;
    --help|-h)
      cat <<'EOF'
Usage: ./mac-app/scripts/check-in.zsh [--project PROJECT] [--title TITLE] [--idea IDEA]

Runs a non-launching guided check-in for a clean queue or confused operator.
Without --idea, prints three plain prompts and exact commands.
With --idea, captures the answer as reviewable Oracle Inbox memory.

This script never launches, foregrounds, quits, kills, screenshots, or controls Terminal Brain.
EOF
      exit 0
      ;;
    *)
      if [[ -z "$IDEA_TEXT" ]]; then
        IDEA_TEXT="$1"
      else
        IDEA_TEXT="$IDEA_TEXT $1"
      fi
      ;;
  esac
  shift
done

PROJECT="${PROJECT:-Terminal Brain}"
TITLE="${TITLE:-Check-in Signal}"

if [[ -n "$IDEA_TEXT" ]]; then
  echo "# Terminal Brain Check In"
  echo
  echo "Project: $PROJECT"
  echo
  echo "## Captured Check-In Signal"
  echo
  "$ROOT/mac-app/scripts/idea.zsh" \
    --title "$TITLE" \
    --project "$PROJECT" \
    --source "Terminal Brain Check In" \
    --tag check-in \
    "$IDEA_TEXT"
  echo
  echo "## Next"
  echo
  echo '```zsh'
  echo "make answer"
  echo "make work-block"
  echo '```'
  echo
  echo "## Guardrail"
  echo
  echo "- This command did not launch, foreground, screenshot, quit, kill, or control Terminal Brain."
  exit 0
fi

echo "# Terminal Brain Check In"
echo
echo "Project: $PROJECT"
echo
echo "Use this when the queue is clean, the app is closed, or you do not know what signal to give Terminal Brain."
echo
echo "## Answer One Line"
echo
echo "Pick the one that feels most true right now:"
echo
echo "1. The decision I keep circling is ..."
echo "2. The loose end that may cost me later is ..."
echo "3. The useful artifact I could create in the next 30 minutes is ..."
echo
echo "## Capture The Answer"
echo
echo '```zsh'
echo "make check-in IDEA=\"The decision I keep circling is ...\" PROJECT=\"$PROJECT\""
echo '```'
echo
echo "## Ask For Judgment"
echo
echo '```zsh'
echo "make ask-commit QUERY=\"Given my check-in, what should I do next for $PROJECT, what am I missing, and what cheap test would create value?\" PROJECT=\"$PROJECT\""
echo '```'
echo
echo "## Close The Loop"
echo
echo '```zsh'
echo "make outcome TITLE=\"Check-in outcome\" OUTCOME=\"What changed, why it mattered, and what evidence exists.\" PROJECT=\"$PROJECT\" NEXT=\"The next concrete action.\""
echo '```'
echo
echo "## Done Criteria"
echo
echo "- One real sentence is captured."
echo "- One Oracle read or work block uses it."
echo "- One outcome records what changed."
echo
echo "## Guardrail"
echo
echo "- This command did not launch, foreground, screenshot, quit, kill, or control Terminal Brain."
