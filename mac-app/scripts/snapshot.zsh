#!/usr/bin/env zsh
set -euo pipefail

API="${TERMINAL_BRAIN_API:-http://127.0.0.1:8765}"
FORMAT="markdown"
COPY="0"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json)
      FORMAT="json"
      ;;
    --markdown)
      FORMAT="markdown"
      ;;
    --copy)
      COPY="1"
      ;;
    --help|-h)
      cat <<'EOF'
Usage: ./mac-app/scripts/snapshot.zsh [--markdown|--json] [--copy]

Prints the current Terminal Brain operator snapshot from an already-running app.
This script never launches or foregrounds Terminal Brain.

Options:
  --markdown  Print prompt-ready Markdown. Default.
  --json      Print raw snapshot JSON.
  --copy      Copy output to the clipboard as well as printing it.
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
  markdown)
    OUTPUT="$(curl -fsS "$API/snapshot/markdown")"
    ;;
esac

if [[ "$COPY" == "1" ]]; then
  printf "%s" "$OUTPUT" | pbcopy
fi

printf "%s\n" "$OUTPUT"
