#!/usr/bin/env zsh
set -euo pipefail

API="${TERMINAL_BRAIN_API:-http://127.0.0.1:8765}"
TITLE="${TITLE:-}"
PROJECT="${PROJECT:-}"
NEXT_ACTION="${NEXT_ACTION:-${NEXT:-}}"
SOURCE="${SOURCE:-Terminal Brain CLI}"
TAGS=()
EVIDENCE=()
OUTCOME_TEXT="${OUTCOME:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --title)
      TITLE="${2:-}"
      shift
      ;;
    --title=*)
      TITLE="${1#--title=}"
      ;;
    --project)
      PROJECT="${2:-}"
      shift
      ;;
    --project=*)
      PROJECT="${1#--project=}"
      ;;
    --next|--next-action)
      NEXT_ACTION="${2:-}"
      shift
      ;;
    --next=*|--next-action=*)
      NEXT_ACTION="${1#*=}"
      ;;
    --source)
      SOURCE="${2:-}"
      shift
      ;;
    --source=*)
      SOURCE="${1#--source=}"
      ;;
    --tag)
      TAGS+=("${2:-}")
      shift
      ;;
    --tag=*)
      TAGS+=("${1#--tag=}")
      ;;
    --evidence)
      EVIDENCE+=("${2:-}")
      shift
      ;;
    --evidence=*)
      EVIDENCE+=("${1#--evidence=}")
      ;;
    --help|-h)
      cat <<'EOF'
Usage: ./mac-app/scripts/outcome.zsh --title TITLE [--project PROJECT] [--next TEXT] [--evidence TEXT] OUTCOME

Commits a structured outcome into Terminal Brain's Oracle Inbox through an already-running app.
This script never launches or foregrounds Terminal Brain.

Environment:
  TERMINAL_BRAIN_API  Override API URL. Default: http://127.0.0.1:8765
  TITLE               Outcome title if --title is omitted.
  OUTCOME             Outcome body if no positional text is supplied.
  PROJECT             Project name if --project is omitted.
  NEXT_ACTION / NEXT  Next action if --next is omitted.

Options:
  --title       Short title.
  --project     Project name.
  --next        Recommended next action.
  --evidence    Evidence line. Repeatable.
  --tag         Additional tag. Repeatable.
  --source      Source label. Default: Terminal Brain CLI.
  --help        Show this help.
EOF
      exit 0
      ;;
    *)
      if [[ -z "$OUTCOME_TEXT" ]]; then
        OUTCOME_TEXT="$1"
      else
        OUTCOME_TEXT="$OUTCOME_TEXT $1"
      fi
      ;;
  esac
  shift
done

TITLE="${TITLE:-Outcome}"
OUTCOME_TEXT="${OUTCOME_TEXT:-}"

if [[ -z "$OUTCOME_TEXT" ]]; then
  echo "Outcome text is required. Pass OUTCOME=... or positional text." >&2
  exit 64
fi

if ! curl -fsS "$API/health" >/dev/null 2>&1; then
  echo "Terminal Brain is not reachable at $API. Start it yourself, then rerun this command." >&2
  exit 2
fi

payload="$(
  TITLE="$TITLE" \
  OUTCOME_TEXT="$OUTCOME_TEXT" \
  NEXT_ACTION="$NEXT_ACTION" \
  PROJECT="$PROJECT" \
  SOURCE="$SOURCE" \
  TAGS_JOINED="${(j:,:)TAGS}" \
  EVIDENCE_JOINED="${(j:||:)EVIDENCE}" \
  ruby -rjson -e '
    tags = ENV.fetch("TAGS_JOINED", "").split(",").map(&:strip).reject(&:empty?)
    evidence = ENV.fetch("EVIDENCE_JOINED", "").split("||").map(&:strip).reject(&:empty?)
    puts JSON.generate({
      title: ENV.fetch("TITLE", "Outcome"),
      outcome: ENV.fetch("OUTCOME_TEXT", ""),
      nextAction: ENV.fetch("NEXT_ACTION", ""),
      project: ENV.fetch("PROJECT", ""),
      source: ENV.fetch("SOURCE", "Terminal Brain CLI"),
      tags: tags,
      evidence: evidence
    })
  '
)"

curl -fsS "$API/outcomes/commit" \
  -H "content-type: application/json" \
  -d "$payload"
printf "\n"
