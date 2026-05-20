#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CLOSED_API="http://127.0.0.1:1"

require_contains() {
  local text="$1"
  local pattern="$2"
  local label="$3"

  if ! grep -qE -- "$pattern" <<<"$text"; then
    echo "Entrypoint check failed: missing $label" >&2
    echo "$text" >&2
    exit 1
  fi
}

call_mcp_tool() {
  local tool="$1"
  TERMINAL_BRAIN_API="$CLOSED_API" printf '%s\n' "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{\"name\":\"$tool\",\"arguments\":{}}}" \
    | TERMINAL_BRAIN_API="$CLOSED_API" node "$ROOT/mcp-server/server.mjs"
}

next_output="$(TERMINAL_BRAIN_API="$CLOSED_API" "$ROOT/mac-app/scripts/next.zsh")"
require_contains "$next_output" '# Terminal Brain Next' "next title"
require_contains "$next_output" 'make start-here' "next manual start command"
require_contains "$next_output" 'did not launch or foreground' "next guardrail"

value_output="$(TERMINAL_BRAIN_API="$CLOSED_API" "$ROOT/mac-app/scripts/value.zsh")"
require_contains "$value_output" '# Terminal Brain Value Now' "value title"
require_contains "$value_output" 'What You Can Get From It' "value explanation"
require_contains "$value_output" 'make doctor' "value doctor command"

now_output="$(TERMINAL_BRAIN_API="$CLOSED_API" "$ROOT/mac-app/scripts/now.zsh")"
require_contains "$now_output" '# Terminal Brain Now' "now title"
require_contains "$now_output" 'make outcome' "now outcome command"
require_contains "$now_output" 'did not launch, foreground, quit, kill, or control' "now guardrail"

doctor_output="$(TERMINAL_BRAIN_API="$CLOSED_API" "$ROOT/mac-app/scripts/doctor.zsh")"
require_contains "$doctor_output" '# Terminal Brain Doctor' "doctor title"
require_contains "$doctor_output" 'MCP tool contract valid' "doctor MCP contract"
require_contains "$doctor_output" 'doctor did not launch or foreground' "doctor guardrail"

agent_prompt_output="$(TERMINAL_BRAIN_API="$CLOSED_API" "$ROOT/mac-app/scripts/agent-prompt.zsh")"
require_contains "$agent_prompt_output" '# Terminal Brain Agent Prompt' "agent prompt title"
require_contains "$agent_prompt_output" 'make oracle-brief' "agent prompt fallback command"
require_contains "$agent_prompt_output" 'did not launch, foreground, quit, kill, or control' "agent prompt guardrail"

outcome_workspace="$(mktemp -d)"
outcome_output="$(TERMINAL_BRAIN_API="$CLOSED_API" TERMINAL_BRAIN_WORKSPACE="$outcome_workspace" "$ROOT/mac-app/scripts/outcome.zsh" --title "Entrypoint Test" --project "Terminal Brain" --next "Remove temp workspace" "Verified local fallback.")"
require_contains "$outcome_output" '"mode":"local-fallback"' "outcome local fallback mode"
require_contains "$outcome_output" '"reviewStatus":"accepted"' "outcome accepted fallback status"
test -f "$outcome_workspace/Oracle Inbox/"*.md || {
  echo "Entrypoint check failed: outcome fallback did not write note" >&2
  echo "$outcome_output" >&2
  exit 1
}
rm -rf "$outcome_workspace"

mcp_next_output="$(call_mcp_tool terminal_brain_next_markdown)"
require_contains "$mcp_next_output" '# Terminal Brain Next' "MCP next title"
require_contains "$mcp_next_output" 'terminal_brain_runtime_status' "MCP next fallback"

mcp_now_output="$(call_mcp_tool terminal_brain_now_markdown)"
require_contains "$mcp_now_output" '# Terminal Brain Now' "MCP now title"
require_contains "$mcp_now_output" 'make outcome' "MCP now outcome command"

mcp_value_output="$(call_mcp_tool terminal_brain_value_now_markdown)"
require_contains "$mcp_value_output" '# Terminal Brain Value Now' "MCP value title"
require_contains "$mcp_value_output" 'What You Can Get From It' "MCP value explanation"

mcp_oracle_output="$(call_mcp_tool terminal_brain_oracle_brief_markdown)"
require_contains "$mcp_oracle_output" '# Terminal Brain Oracle Brief' "MCP Oracle Brief title"
require_contains "$mcp_oracle_output" 'cheapest test' "MCP Oracle Brief closed fallback"

mcp_agent_prompt_output="$(call_mcp_tool terminal_brain_agent_prompt_markdown)"
require_contains "$mcp_agent_prompt_output" '# Terminal Brain Agent Prompt' "MCP agent prompt title"
require_contains "$mcp_agent_prompt_output" 'make oracle-brief' "MCP agent prompt closed fallback"

mcp_process_output="$(call_mcp_tool terminal_brain_process_map_markdown)"
require_contains "$mcp_process_output" '# Terminal Brain Process Map' "MCP process map title"
require_contains "$mcp_process_output" 'did not launch, foreground, quit, kill, or control anything' "MCP process map guardrail"

mcp_cleanup_output="$(call_mcp_tool terminal_brain_cleanup_plan_markdown)"
require_contains "$mcp_cleanup_output" '# Terminal Brain Cleanup Plan' "MCP cleanup plan title"
require_contains "$mcp_cleanup_output" 'did not launch, foreground, quit, kill, or control anything' "MCP cleanup plan guardrail"

mcp_support_output="$(call_mcp_tool terminal_brain_support_bundle_markdown)"
require_contains "$mcp_support_output" '# Terminal Brain Support Bundle' "MCP support bundle title"
require_contains "$mcp_support_output" '# Now' "MCP support bundle now section"
require_contains "$mcp_support_output" '# Oracle Brief' "MCP support bundle Oracle Brief section"
require_contains "$mcp_support_output" '# Cleanup Plan' "MCP support bundle cleanup section"

mcp_doctor_output="$(call_mcp_tool terminal_brain_doctor_markdown)"
require_contains "$mcp_doctor_output" '# Terminal Brain Doctor' "MCP doctor title"
require_contains "$mcp_doctor_output" 'MCP tool contract valid' "MCP doctor contract"

mcp_audit_output="$(call_mcp_tool terminal_brain_audit_markdown)"
require_contains "$mcp_audit_output" '# Terminal Brain Capability Audit' "MCP audit title"
require_contains "$mcp_audit_output" 'MCP Audit' "MCP audit self evidence"
require_contains "$mcp_audit_output" 'MCP Outcome Commit' "MCP audit outcome evidence"
require_contains "$mcp_audit_output" 'make audit' "MCP audit command evidence"

echo "entrypoints ok"
