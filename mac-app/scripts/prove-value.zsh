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
  1. Print the closed-app Oracle Brief.
  2. Print the closed-app Agent Prompt.
  3. Write an accepted outcome note into a temporary Oracle Inbox.
  4. Print the temporary note preview, then remove the temp workspace.

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
echo "## 1. Oracle Brief"
echo
TERMINAL_BRAIN_API="$PROOF_API" "$ROOT/mac-app/scripts/oracle-brief.zsh" | sed -n '1,34p'
echo
echo "## 2. Agent Prompt"
echo
TERMINAL_BRAIN_API="$PROOF_API" "$ROOT/mac-app/scripts/agent-prompt.zsh" | sed -n '1,42p'
echo
echo "## 3. Outcome Writeback"
echo
outcome_json="$(
  TERMINAL_BRAIN_API="$PROOF_API" \
  TERMINAL_BRAIN_WORKSPACE="$TMP_WORKSPACE" \
  "$ROOT/mac-app/scripts/outcome.zsh" \
    --title "Value Proof" \
    --project "Terminal Brain" \
    --next "Use make next for the next real work block" \
    --evidence "Oracle Brief and Agent Prompt were available without launching the app." \
    "Proved the closed-app Terminal Brain loop can produce a direct read, an agent prompt, and an accepted outcome note."
)"
printf '%s\n' "$outcome_json"

note_path="$(ruby -rjson -e 'puts JSON.parse(STDIN.read).fetch("path")' <<<"$outcome_json")"
echo
echo "## 4. Temporary Note Preview"
echo
sed -n '1,44p' "$note_path"
echo
echo "## Guardrail"
echo
echo "- This proof did not launch, foreground, quit, kill, or control Terminal Brain."
echo "- The temporary workspace was removed after the proof command exited."
