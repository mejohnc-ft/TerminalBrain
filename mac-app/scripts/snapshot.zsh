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
Usage: ./mac-app/scripts/snapshot.zsh [--markdown|--json] [--copy] [--output FILE]

Prints the current Terminal Brain operator snapshot from an already-running app.
This script never launches or foregrounds Terminal Brain.

Options:
  --markdown  Print prompt-ready Markdown. Default.
  --json      Print raw snapshot JSON.
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
