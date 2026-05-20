#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
missing_count=0

case "${1:-}" in
  --help|-h)
    cat <<'EOF'
Usage: ./mac-app/scripts/audit.zsh

Prints a non-launching Terminal Brain capability audit:
  - value-first surfaces
  - agent/MCP surfaces
  - safety and readiness guardrails
  - current readiness verdict

This script never launches, foregrounds, quits, or controls Terminal Brain.
EOF
    exit 0
    ;;
  "")
    ;;
  *)
    echo "Unknown option: $1" >&2
    echo "Run ./mac-app/scripts/audit.zsh --help" >&2
    exit 64
    ;;
esac

require_evidence() {
  local file="$1"
  local pattern="$2"
  local label="$3"

  if grep -qE -- "$pattern" "$file"; then
    printf 'ok   %s\n' "$label"
  else
    missing_count=$((missing_count + 1))
    printf 'miss %s\n' "$label"
  fi
}

tool_count="$(node "$ROOT/mcp-server/check-tools.mjs" 2>/dev/null | sed -nE 's/^mcp tools ok count=([0-9]+)$/\1/p' || true)"
doctor_summary="$("$ROOT/mac-app/scripts/doctor.zsh" | sed -n '/^## Summary/,$p')"

echo "# Terminal Brain Capability Audit"
echo
echo "Purpose: make the local brain useful in the first minute, safe for agents, and durable enough to write outcomes back to memory."
echo

echo "## Current Readiness"
echo
printf '%s\n' "$doctor_summary"
echo

echo "## Value-First Surfaces"
echo
require_evidence "$ROOT/Makefile" '^value:' "make value"
require_evidence "$ROOT/Makefile" '^next:' "make next"
require_evidence "$ROOT/Makefile" '^doctor:' "make doctor"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift" 'selectedSection = "value"' "native app opens on Value Now"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift" 'Open Value Now' "command palette can open Value Now"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift" 'Commit Outcome' "native outcome close loop"
echo

echo "## Agent Surfaces"
echo
echo "ok   MCP tool contract count: ${tool_count:-unknown}"
require_evidence "$ROOT/mcp-server/server.mjs" 'terminal_brain_value_now_markdown' "MCP Value Now"
require_evidence "$ROOT/mcp-server/server.mjs" 'terminal_brain_next_markdown' "MCP Next"
require_evidence "$ROOT/mcp-server/server.mjs" 'terminal_brain_process_map_markdown' "MCP Process Map"
require_evidence "$ROOT/mcp-server/server.mjs" 'terminal_brain_doctor_markdown' "MCP Doctor"
require_evidence "$ROOT/mcp-server/server.mjs" 'terminal_brain_audit_markdown' "MCP Audit"
require_evidence "$ROOT/mcp-server/server.mjs" 'terminal_brain_runtime_status' "MCP Runtime Status"
require_evidence "$ROOT/mcp-server/server.mjs" 'terminal_brain_commit_outcome' "MCP Outcome Commit"
echo

echo "## Safety And Reliability"
echo
require_evidence "$ROOT/mac-app/scripts/check-no-foreground.zsh" 'Foreground app launch|AppleScript|automation is not allowed' "foreground guard"
require_evidence "$ROOT/mac-app/scripts/processes.zsh" 'This command did not launch, foreground, quit, kill, or control anything' "process map guard"
require_evidence "$ROOT/mac-app/scripts/doctor.zsh" 'Prompt Safety' "prompt safety doctor section"
require_evidence "$ROOT/mac-app/scripts/doctor.zsh" 'installed app executable matches current build' "installed app freshness"
require_evidence "$ROOT/mac-app/scripts/check-entrypoints.zsh" 'terminal_brain_value_now_markdown' "closed-API entrypoint regression"
require_evidence "$ROOT/mac-app/scripts/verify-static.zsh" 'check-entrypoints.zsh' "entrypoint guard in static verifier"
echo

echo "## Non-Launching Commands"
echo
echo "- make value"
echo "- make next"
echo "- make doctor"
echo "- make audit"
echo "- make status"
echo "- make processes"
echo "- make verify"
echo
echo "Guardrail: audit did not launch or foreground Terminal Brain."

if (( missing_count > 0 )); then
  echo
  echo "Audit failed: $missing_count required evidence item(s) missing." >&2
  exit 1
fi
