#!/usr/bin/env zsh
set -euo pipefail

API="${TERMINAL_BRAIN_API:-http://127.0.0.1:8765}"
OUTPUT_PATH="${OUTPUT:-/tmp/terminal-brain-handoff.md}"
COPY="0"

while [[ $# -gt 0 ]]; do
  case "$1" in
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
    --copy)
      COPY="1"
      ;;
    --help|-h)
      cat <<'EOF'
Usage: ./mac-app/scripts/handoff.zsh [--output FILE] [--copy]

Writes a prompt-ready Terminal Brain handoff file from an already-running app.
This script never launches or foregrounds Terminal Brain.

Options:
  --output  Handoff Markdown path. Default: /tmp/terminal-brain-handoff.md
  --copy    Copy the handoff Markdown to the clipboard after writing it.
  --help    Show this help.
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Run ./mac-app/scripts/handoff.zsh --help" >&2
      exit 64
      ;;
  esac
  shift
done

if ! curl -fsS "$API/health" >/dev/null 2>&1; then
  echo "Terminal Brain is not reachable at $API. Start it yourself, then rerun this command." >&2
  exit 2
fi

OUTPUT="$(curl -fsS "$API/handoff/markdown")"

OUTPUT_DIR="$(dirname "$OUTPUT_PATH")"
if [[ "$OUTPUT_DIR" != "." ]]; then
  mkdir -p "$OUTPUT_DIR"
fi

printf "%s\n" "$OUTPUT" > "$OUTPUT_PATH"

if [[ "$COPY" == "1" ]]; then
  printf "%s\n" "$OUTPUT" | pbcopy
fi

echo "Wrote handoff to $OUTPUT_PATH" >&2
printf "%s\n" "$OUTPUT_PATH"
