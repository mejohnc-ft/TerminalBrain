#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PROOF_API="${TERMINAL_BRAIN_PROOF_API:-http://127.0.0.1:1}"
TMP_WORKSPACE="$(mktemp -d)"
trap 'rm -rf "$TMP_WORKSPACE"' EXIT

case "${1:-}" in
  --help|-h)
    cat <<'EOF'
Usage: ./mac-app/scripts/prove-value.zsh

Runs a non-launching value proof:
  1. Capture a rough thought through Use Now and show it bubble up.
  2. Print the closed-app Oracle Brief.
  3. Print the closed-app Agent Prompt.
  4. Write an accepted outcome note into a temporary Oracle Inbox.
  5. Print the temporary note preview, then remove the temp workspace.

This script never launches, foregrounds, quits, or controls Terminal Brain.
EOF
    exit 0
    ;;
  "")
    ;;
  *)
    echo "Unknown option: $1" >&2
    echo "Run ./mac-app/scripts/prove-value.zsh --help" >&2
    exit 64
    ;;
esac

echo "# Terminal Brain Value Proof"
echo
echo "This proves the closed-app loop without writing to the real workspace."
echo
echo "## 1. Use Now Capture"
echo
TERMINAL_BRAIN_API="$PROOF_API" \
TERMINAL_BRAIN_WORKSPACE="$TMP_WORKSPACE" \
  "$ROOT/mac-app/scripts/use-now.zsh" \
    --project "Terminal Brain" \
    --idea "I need one obvious Terminal Brain value path that captures a thought, surfaces it, and closes the loop." \
    --title "Value Proof Use Now Capture" \
    --limit 1 \
  | sed -n '1,90p'
echo
echo "## 2. Oracle Brief"
echo
TERMINAL_BRAIN_API="$PROOF_API" "$ROOT/mac-app/scripts/oracle-brief.zsh" | sed -n '1,34p'
echo
echo "## 3. Agent Prompt"
echo
TERMINAL_BRAIN_API="$PROOF_API" "$ROOT/mac-app/scripts/agent-prompt.zsh" | sed -n '1,42p'
echo
echo "## 4. Outcome Writeback"
echo
outcome_json="$(
  TERMINAL_BRAIN_API="$PROOF_API" \
  TERMINAL_BRAIN_WORKSPACE="$TMP_WORKSPACE" \
  "$ROOT/mac-app/scripts/outcome.zsh" \
    --title "Value Proof" \
    --project "Terminal Brain" \
    --next "Use make start for the next real work block" \
    --evidence "Use Now capture, Oracle Brief, and Agent Prompt were available without launching the app." \
    "Proved the closed-app Terminal Brain loop can capture a rough thought, surface it as reviewable work, produce a direct read, produce an agent prompt, and write an accepted outcome note."
)"
printf '%s\n' "$outcome_json"

note_path="$(ruby -rjson -e 'puts JSON.parse(STDIN.read).fetch("path")' <<<"$outcome_json")"
echo
echo "## 5. Temporary Note Preview"
echo
sed -n '1,44p' "$note_path"
echo
echo "## Guardrail"
echo
echo "- This proof did not launch, foreground, quit, kill, or control Terminal Brain."
echo "- The temporary workspace was removed after the proof command exited."
