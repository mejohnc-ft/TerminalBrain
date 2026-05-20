#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
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

Writes a prompt-ready Terminal Brain handoff file.
This script never launches or foregrounds Terminal Brain.

If the app is closed, it composes a local handoff from closed-app safe reads.

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

demote_section() {
  awk '
    /^# / { print "## " substr($0, 3); next }
    /^## / { print "### " substr($0, 4); next }
    /^### / { print "#### " substr($0, 5); next }
    { print }
  '
}

health="$(curl -fsS --max-time 0.5 "$API/health" 2>/dev/null || true)"
if [[ -n "$health" ]]; then
  OUTPUT="$(curl -fsS "$API/handoff/markdown")"
else
  OUTPUT="$(
    cat <<EOF
# Terminal Brain Handoff

Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')

Terminal Brain is not currently reachable at $API, so this is a local closed-app handoff.

EOF
    TERMINAL_BRAIN_API="$API" "$ROOT/mac-app/scripts/snapshot.zsh" --start-here | demote_section
    echo
    TERMINAL_BRAIN_API="$API" "$ROOT/mac-app/scripts/oracle-brief.zsh" | demote_section
    echo
    "$ROOT/mac-app/scripts/work-block.zsh" --limit 1 | demote_section
    echo
    TERMINAL_BRAIN_API="$API" "$ROOT/mac-app/scripts/agent-prompt.zsh" | demote_section
    echo
    "$ROOT/mac-app/scripts/processes.zsh" | demote_section
    cat <<'EOF'

## Close Loop

```zsh
make outcome TITLE="..." OUTCOME="..." PROJECT="Terminal Brain" NEXT="..."
```

## Guardrail

- This handoff did not launch, foreground, quit, kill, or control Terminal Brain.
EOF
  )"
fi

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
