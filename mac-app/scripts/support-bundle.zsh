#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUTPUT="${OUTPUT:-/tmp/terminal-brain-support-bundle.md}"

case "${1:-}" in
  --help|-h)
    cat <<'EOF'
Usage: OUTPUT=/tmp/terminal-brain-support-bundle.md ./mac-app/scripts/support-bundle.zsh

Writes a non-launching Markdown support bundle:
  - Now orientation
  - Doctor readiness
  - Capability audit
  - Process map
  - Cleanup plan
  - Git head and working tree

This script never launches, foregrounds, quits, kills, or controls Terminal Brain,
Codex, MCP, kernel, Drafts, or any other process.
EOF
    exit 0
    ;;
  "")
    ;;
  *)
    echo "Unknown option: $1" >&2
    echo "Run ./mac-app/scripts/support-bundle.zsh --help" >&2
    exit 64
    ;;
esac

run_section() {
  local title="$1"
  shift
  echo
  echo "---"
  echo
  echo "# $title"
  echo
  if "$@"; then
    return 0
  fi
  local status=$?
  echo
  echo "_Section command exited with status $status._"
  return 0
}

mkdir -p "$(dirname "$OUTPUT")"

{
  echo "# Terminal Brain Support Bundle"
  echo
  echo "Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')"
  echo "Repo: $ROOT"
  echo
  echo "Guardrail: this bundle command did not launch, foreground, quit, kill, or control anything."
  echo
  echo "## Git"
  echo
  echo "- Head: $(git -C "$ROOT" log -1 --oneline 2>/dev/null || echo unknown)"
  echo "- Branch: $(git -C "$ROOT" branch --show-current 2>/dev/null || echo unknown)"
  echo
  echo '```text'
  git -C "$ROOT" status --short 2>/dev/null || true
  echo '```'

  run_section "Now" "$ROOT/mac-app/scripts/now.zsh"
  run_section "Doctor" "$ROOT/mac-app/scripts/doctor.zsh"
  run_section "Capability Audit" "$ROOT/mac-app/scripts/audit.zsh"
  run_section "Process Map" "$ROOT/mac-app/scripts/processes.zsh" --details
  run_section "Cleanup Plan" "$ROOT/mac-app/scripts/cleanup-plan.zsh"
} > "$OUTPUT"

echo "$OUTPUT"
