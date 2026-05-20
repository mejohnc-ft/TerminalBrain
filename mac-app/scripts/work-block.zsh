#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PROJECT="${PROJECT:-}"
LIMIT="${LIMIT:-3}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)
      PROJECT="${2:-}"
      shift
      ;;
    --project=*)
      PROJECT="${1#--project=}"
      ;;
    --limit)
      LIMIT="${2:-3}"
      shift
      ;;
    --limit=*)
      LIMIT="${1#--limit=}"
      ;;
    --help|-h)
      cat <<'EOF'
Usage: ./mac-app/scripts/work-block.zsh [--limit N] [--project PROJECT]

Prints one non-launching work block:
  - what to pull forward
  - what review items are waiting
  - the exact close-loop command shape

This script never launches, foregrounds, quits, kills, or controls Terminal Brain.
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Run ./mac-app/scripts/work-block.zsh --help" >&2
      exit 64
      ;;
  esac
  shift
done

echo "# Terminal Brain Work Block"
echo
echo "Checked: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo
echo "## Use This Block"
echo
echo "1. Pull one item forward from Bubble Up."
echo "2. Accept, delegate, dismiss, or link it with the printed command."
echo "3. Do the smallest useful work."
echo "4. Commit the outcome back into memory."
echo
echo "If there are no signals yet, use the Prime The Brain prompts below to capture one real pressure point first."
echo
echo '```zsh'
echo "make outcome TITLE=\"...\" OUTCOME=\"...\" PROJECT=\"${PROJECT:-Terminal Brain}\" NEXT=\"...\""
echo '```'
echo

clean_section() {
  awk '
    /^# Terminal Brain Bubble Up$/ { print "### Bubble Up"; next }
    /^# Terminal Brain Review Queue$/ { print "### Review Queue"; next }
    /^Workspace: / { next }
    /^Inbox: / { next }
    /^## Guardrail$/ { skip = 1; next }
    skip { next }
    { print }
  '
}

bubble_args=(--limit "$LIMIT")
if [[ -n "$PROJECT" ]]; then
  bubble_args+=(--project "$PROJECT")
fi

echo "## Pull Forward"
echo
"$ROOT/mac-app/scripts/bubble-up.zsh" "${bubble_args[@]}" | clean_section
echo
echo "## Broader Queue"
echo
echo "If the pulled-forward item is not the right one, inspect the full queue:"
echo
echo '```zsh'
if [[ -n "$PROJECT" ]]; then
  echo "make review PROJECT=\"$PROJECT\""
else
  echo "make review"
fi
echo '```'
echo
echo "## Guardrail"
echo
echo "- This command did not launch, foreground, quit, kill, or control Terminal Brain."
