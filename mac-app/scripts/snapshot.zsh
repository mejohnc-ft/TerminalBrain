#!/usr/bin/env zsh
set -euo pipefail

API="${TERMINAL_BRAIN_API:-http://127.0.0.1:8765}"
FORMAT="markdown"
COPY="0"
OUTPUT_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json)
      FORMAT="json"
      ;;
    --deck)
      FORMAT="deck"
      ;;
    --brief)
      FORMAT="brief"
      ;;
    --value|--value-brief)
      FORMAT="value"
      ;;
    --brief-markdown|--brief-md)
      FORMAT="brief-markdown"
      ;;
    --today|--decision-lane)
      FORMAT="today"
      ;;
    --blindspots|--blindspot-brief)
      FORMAT="blindspots"
      ;;
    --ideas|--idea-pulse)
      FORMAT="ideas"
      ;;
    --projects)
      FORMAT="projects"
      ;;
    --deck-markdown|--deck-md)
      FORMAT="deck-markdown"
      ;;
    --latest-pack)
      FORMAT="latest-pack"
      ;;
    --markdown)
      FORMAT="markdown"
      ;;
    --copy)
      COPY="1"
      ;;
    --output)
      if [[ $# -lt 2 || -z "${2:-}" ]]; then
        echo "--output requires a file path" >&2
        exit 64
      fi
      OUTPUT_PATH="$2"
      shift
      ;;
    --output=*)
      OUTPUT_PATH="${1#--output=}"
      if [[ -z "$OUTPUT_PATH" ]]; then
        echo "--output requires a file path" >&2
        exit 64
      fi
      ;;
    --help|-h)
      cat <<'EOF'
Usage: ./mac-app/scripts/snapshot.zsh [--markdown|--json|--brief|--brief-markdown|--value|--today|--blindspots|--ideas|--projects|--deck|--deck-markdown|--latest-pack] [--copy] [--output FILE]

Prints the current Terminal Brain operator snapshot from an already-running app.
This script never launches or foregrounds Terminal Brain.

Options:
  --markdown  Print prompt-ready Markdown. Default.
  --json      Print raw snapshot JSON.
  --brief     Print raw Operator Brief JSON.
  --brief-markdown
              Print prompt-ready Operator Brief Markdown.
  --value     Print prompt-ready Value Brief Markdown.
  --today     Print prompt-ready Decision Lane Markdown.
  --blindspots
              Print prompt-ready Blindspot Brief Markdown.
  --ideas     Print prompt-ready Idea Pulse Markdown.
  --projects  Print prompt-ready Project Memory Markdown.
  --deck      Print raw Operator Deck JSON.
  --deck-markdown
              Print prompt-ready Operator Deck Markdown.
  --latest-pack
              Print the latest context pack Markdown.
  --copy      Copy output to the clipboard as well as printing it.
  --output    Write output to a file as well as printing it.
  --help      Show this help.
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Run ./mac-app/scripts/snapshot.zsh --help" >&2
      exit 64
      ;;
  esac
  shift
done

if ! curl -fsS "$API/health" >/dev/null 2>&1; then
  echo "Terminal Brain is not reachable at $API. Start it yourself, then rerun this command." >&2
  exit 2
fi

case "$FORMAT" in
  json)
    OUTPUT="$(curl -fsS "$API/snapshot")"
    ;;
  deck)
    OUTPUT="$(curl -fsS "$API/operator-deck")"
    ;;
  brief)
    OUTPUT="$(curl -fsS "$API/operator-brief")"
    ;;
  brief-markdown)
    OUTPUT="$(curl -fsS "$API/operator-brief/markdown")"
    ;;
  value)
    OUTPUT="$(curl -fsS "$API/value-brief/markdown")"
    ;;
  today)
    OUTPUT="$(curl -fsS "$API/today/markdown")"
    ;;
  blindspots)
    OUTPUT="$(curl -fsS "$API/blindspots/markdown")"
    ;;
  ideas)
    OUTPUT="$(curl -fsS "$API/ideas/markdown")"
    ;;
  projects)
    OUTPUT="$(curl -fsS "$API/projects/markdown")"
    ;;
  deck-markdown)
    OUTPUT="$(curl -fsS "$API/operator-deck/markdown")"
    ;;
  latest-pack)
    OUTPUT="$(curl -fsS "$API/context-packs/latest/markdown")"
    ;;
  markdown)
    OUTPUT="$(curl -fsS "$API/snapshot/markdown")"
    ;;
esac

if [[ "$COPY" == "1" ]]; then
  printf "%s" "$OUTPUT" | pbcopy
fi

if [[ -n "$OUTPUT_PATH" ]]; then
  OUTPUT_DIR="$(dirname "$OUTPUT_PATH")"
  if [[ "$OUTPUT_DIR" != "." ]]; then
    mkdir -p "$OUTPUT_DIR"
  fi
  printf "%s\n" "$OUTPUT" > "$OUTPUT_PATH"
  echo "Wrote snapshot to $OUTPUT_PATH" >&2
fi

printf "%s\n" "$OUTPUT"
