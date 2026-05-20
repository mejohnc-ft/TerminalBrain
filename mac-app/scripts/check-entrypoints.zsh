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
require_contains "$next_output" 'make oracle-brief' "next closed-app Oracle Brief command"
require_contains "$next_output" 'make work-block' "next closed-app Work Block command"
require_contains "$next_output" 'make bubble-up' "next closed-app Bubble Up command"
require_contains "$next_output" 'make agent-prompt' "next closed-app Agent Prompt command"
require_contains "$next_output" 'make outcome' "next closed-app outcome command"
require_contains "$next_output" 'did not launch or foreground' "next guardrail"

first_minute_output="$(TERMINAL_BRAIN_API="$CLOSED_API" TERMINAL_BRAIN_FIRST_MINUTE_PROOF_API="$CLOSED_API" "$ROOT/mac-app/scripts/first-minute.zsh")"
require_contains "$first_minute_output" '# Terminal Brain First Minute' "first minute title"
require_contains "$first_minute_output" 'What You Can Get Immediately' "first minute value section"
require_contains "$first_minute_output" '# Terminal Brain Value Proof' "first minute proof"
require_contains "$first_minute_output" 'reviewStatus.*accepted' "first minute accepted proof"
require_contains "$first_minute_output" 'did not launch, foreground, quit, kill, or control' "first minute guardrail"

value_output="$(TERMINAL_BRAIN_API="$CLOSED_API" "$ROOT/mac-app/scripts/value.zsh")"
require_contains "$value_output" '# Terminal Brain Value Now' "value title"
require_contains "$value_output" 'What You Can Get From It' "value explanation"
require_contains "$value_output" 'make doctor' "value doctor command"

now_output="$(TERMINAL_BRAIN_API="$CLOSED_API" "$ROOT/mac-app/scripts/now.zsh")"
require_contains "$now_output" '# Terminal Brain Now' "now title"
require_contains "$now_output" 'make work-block' "now Work Block command"
require_contains "$now_output" 'make bubble-up' "now Bubble Up command"
require_contains "$now_output" 'make outcome' "now outcome command"
require_contains "$now_output" 'did not launch, foreground, quit, kill, or control' "now guardrail"

doctor_output="$(TERMINAL_BRAIN_API="$CLOSED_API" "$ROOT/mac-app/scripts/doctor.zsh")"
require_contains "$doctor_output" '# Terminal Brain Doctor' "doctor title"
require_contains "$doctor_output" 'MCP tool contract valid' "doctor MCP contract"
require_contains "$doctor_output" 'doctor did not launch or foreground' "doctor guardrail"

agent_prompt_output="$(TERMINAL_BRAIN_API="$CLOSED_API" "$ROOT/mac-app/scripts/agent-prompt.zsh")"
require_contains "$agent_prompt_output" '# Terminal Brain Agent Prompt' "agent prompt title"
require_contains "$agent_prompt_output" 'make oracle-brief' "agent prompt fallback command"
require_contains "$agent_prompt_output" 'make work-block' "agent prompt Work Block command"
require_contains "$agent_prompt_output" 'make bubble-up' "agent prompt Bubble Up command"
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

idea_workspace="$(mktemp -d)"
idea_output="$(TERMINAL_BRAIN_API="$CLOSED_API" TERMINAL_BRAIN_WORKSPACE="$idea_workspace" "$ROOT/mac-app/scripts/idea.zsh" --title "Entrypoint Idea" --project "Terminal Brain" "Captured idea fallback.")"
require_contains "$idea_output" '"mode":"local-fallback"' "idea local fallback mode"
require_contains "$idea_output" '"reviewStatus":"new"' "idea fallback review status"
test -f "$idea_workspace/Oracle Inbox/"*.md || {
  echo "Entrypoint check failed: idea fallback did not write note" >&2
  echo "$idea_output" >&2
  exit 1
}
rm -rf "$idea_workspace"

review_workspace="$(mktemp -d)"
TERMINAL_BRAIN_API="$CLOSED_API" TERMINAL_BRAIN_WORKSPACE="$review_workspace" "$ROOT/mac-app/scripts/idea.zsh" --title "Review Queue Idea" --project "Terminal Brain" "Review queue fallback item." >/dev/null
review_output="$(TERMINAL_BRAIN_WORKSPACE="$review_workspace" "$ROOT/mac-app/scripts/review.zsh" --limit 3)"
require_contains "$review_output" '# Terminal Brain Review Queue' "review queue title"
require_contains "$review_output" 'Review Queue Idea' "review queue captured idea"
require_contains "$review_output" 'Status: new' "review queue status"
require_contains "$review_output" 'make review-status' "review queue action commands"
require_contains "$review_output" 'did not launch, foreground, quit, kill, or control' "review queue guardrail"
bubble_output="$(TERMINAL_BRAIN_WORKSPACE="$review_workspace" "$ROOT/mac-app/scripts/bubble-up.zsh" --limit 3)"
require_contains "$bubble_output" '# Terminal Brain Bubble Up' "bubble up title"
require_contains "$bubble_output" 'What You May Not Be Considering' "bubble up under-considered section"
require_contains "$bubble_output" 'Review Queue Idea' "bubble up captured idea"
require_contains "$bubble_output" 'make review-status' "bubble up action commands"
require_contains "$bubble_output" 'did not launch, foreground, quit, kill, or control' "bubble up guardrail"
work_block_output="$(TERMINAL_BRAIN_WORKSPACE="$review_workspace" "$ROOT/mac-app/scripts/work-block.zsh" --limit 2)"
require_contains "$work_block_output" '# Terminal Brain Work Block' "work block title"
require_contains "$work_block_output" '### Bubble Up' "work block Bubble Up section"
require_contains "$work_block_output" 'Broader Queue' "work block broader queue section"
require_contains "$work_block_output" 'make outcome' "work block outcome command"
require_contains "$work_block_output" 'did not launch, foreground, quit, kill, or control' "work block guardrail"
review_note="$(find "$review_workspace/Oracle Inbox" -type f -name '*.md' | head -n 1)"
review_status_output="$(TERMINAL_BRAIN_WORKSPACE="$review_workspace" "$ROOT/mac-app/scripts/review-status.zsh" --id "$review_note" --status accepted)"
require_contains "$review_status_output" '"status":"accepted"' "review status accepted"
review_accepted_output="$(TERMINAL_BRAIN_WORKSPACE="$review_workspace" "$ROOT/mac-app/scripts/review.zsh" --status accepted --limit 3)"
require_contains "$review_accepted_output" 'Status: accepted' "review queue accepted status"
rm -rf "$review_workspace"

proof_output="$(TERMINAL_BRAIN_PROOF_API="$CLOSED_API" "$ROOT/mac-app/scripts/prove-value.zsh")"
require_contains "$proof_output" '# Terminal Brain Value Proof' "value proof title"
require_contains "$proof_output" '# Terminal Brain Oracle Brief' "value proof Oracle Brief"
require_contains "$proof_output" '# Terminal Brain Agent Prompt' "value proof Agent Prompt"
require_contains "$proof_output" '"reviewStatus":"accepted"' "value proof accepted outcome"
require_contains "$proof_output" 'Temporary Note Preview' "value proof note preview"

mcp_next_output="$(call_mcp_tool terminal_brain_next_markdown)"
require_contains "$mcp_next_output" '# Terminal Brain Next' "MCP next title"
require_contains "$mcp_next_output" 'make oracle-brief' "MCP next Oracle Brief fallback"
require_contains "$mcp_next_output" 'make work-block' "MCP next Work Block fallback"
require_contains "$mcp_next_output" 'make bubble-up' "MCP next Bubble Up fallback"
require_contains "$mcp_next_output" 'make agent-prompt' "MCP next Agent Prompt fallback"
require_contains "$mcp_next_output" 'make outcome' "MCP next outcome fallback"

mcp_first_minute_output="$(call_mcp_tool terminal_brain_first_minute_markdown)"
require_contains "$mcp_first_minute_output" '# Terminal Brain First Minute' "MCP first minute title"
require_contains "$mcp_first_minute_output" 'What You Can Get Immediately' "MCP first minute value section"
require_contains "$mcp_first_minute_output" '# Terminal Brain Value Proof' "MCP first minute proof"
require_contains "$mcp_first_minute_output" 'reviewStatus.*accepted' "MCP first minute accepted proof"

mcp_now_output="$(call_mcp_tool terminal_brain_now_markdown)"
require_contains "$mcp_now_output" '# Terminal Brain Now' "MCP now title"
require_contains "$mcp_now_output" 'make work-block' "MCP now Work Block command"
require_contains "$mcp_now_output" 'make bubble-up' "MCP now Bubble Up command"
require_contains "$mcp_now_output" 'make outcome' "MCP now outcome command"

mcp_value_output="$(call_mcp_tool terminal_brain_value_now_markdown)"
require_contains "$mcp_value_output" '# Terminal Brain Value Now' "MCP value title"
require_contains "$mcp_value_output" 'What You Can Get From It' "MCP value explanation"

mcp_proof_output="$(call_mcp_tool terminal_brain_value_proof_markdown)"
require_contains "$mcp_proof_output" '# Terminal Brain Value Proof' "MCP value proof title"
require_contains "$mcp_proof_output" '# Terminal Brain Oracle Brief' "MCP value proof Oracle Brief"
require_contains "$mcp_proof_output" '# Terminal Brain Agent Prompt' "MCP value proof Agent Prompt"
require_contains "$mcp_proof_output" 'reviewStatus.*accepted' "MCP value proof accepted outcome"
require_contains "$mcp_proof_output" 'Temporary Note Preview' "MCP value proof note preview"

mcp_oracle_output="$(call_mcp_tool terminal_brain_oracle_brief_markdown)"
require_contains "$mcp_oracle_output" '# Terminal Brain Oracle Brief' "MCP Oracle Brief title"
require_contains "$mcp_oracle_output" 'cheapest test' "MCP Oracle Brief closed fallback"

mcp_idea_workspace="$(mktemp -d)"
mcp_idea_output="$(TERMINAL_BRAIN_API="$CLOSED_API" TERMINAL_BRAIN_WORKSPACE="$mcp_idea_workspace" printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"terminal_brain_capture_idea","arguments":{"title":"MCP Entrypoint Idea","content":"Captured through MCP fallback.","project":"Terminal Brain"}}}' | TERMINAL_BRAIN_API="$CLOSED_API" TERMINAL_BRAIN_WORKSPACE="$mcp_idea_workspace" node "$ROOT/mcp-server/server.mjs")"
require_contains "$mcp_idea_output" 'local-fallback' "MCP idea local fallback"
require_contains "$mcp_idea_output" 'reviewStatus.*new' "MCP idea review status"
test -f "$mcp_idea_workspace/Oracle Inbox/"*.md || {
  echo "Entrypoint check failed: MCP idea fallback did not write note" >&2
  echo "$mcp_idea_output" >&2
  exit 1
}
rm -rf "$mcp_idea_workspace"

mcp_review_workspace="$(mktemp -d)"
TERMINAL_BRAIN_API="$CLOSED_API" TERMINAL_BRAIN_WORKSPACE="$mcp_review_workspace" "$ROOT/mac-app/scripts/idea.zsh" --title "MCP Review Queue Idea" --project "Terminal Brain" "MCP review queue fallback item." >/dev/null
mcp_review_output="$(TERMINAL_BRAIN_WORKSPACE="$mcp_review_workspace" printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"terminal_brain_review_queue_markdown","arguments":{"limit":3}}}' | TERMINAL_BRAIN_WORKSPACE="$mcp_review_workspace" node "$ROOT/mcp-server/server.mjs")"
require_contains "$mcp_review_output" '# Terminal Brain Review Queue' "MCP review queue title"
require_contains "$mcp_review_output" 'MCP Review Queue Idea' "MCP review queue captured idea"
require_contains "$mcp_review_output" 'Status: new' "MCP review queue status"
require_contains "$mcp_review_output" 'make review-status' "MCP review queue action commands"
mcp_bubble_output="$(TERMINAL_BRAIN_WORKSPACE="$mcp_review_workspace" printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"terminal_brain_bubble_up_markdown","arguments":{"limit":3}}}' | TERMINAL_BRAIN_WORKSPACE="$mcp_review_workspace" node "$ROOT/mcp-server/server.mjs")"
require_contains "$mcp_bubble_output" '# Terminal Brain Bubble Up' "MCP bubble up title"
require_contains "$mcp_bubble_output" 'What You May Not Be Considering' "MCP bubble up under-considered section"
require_contains "$mcp_bubble_output" 'MCP Review Queue Idea' "MCP bubble up captured idea"
require_contains "$mcp_bubble_output" 'make review-status' "MCP bubble up action commands"
mcp_work_block_output="$(TERMINAL_BRAIN_WORKSPACE="$mcp_review_workspace" printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"terminal_brain_work_block_markdown","arguments":{"limit":2}}}' | TERMINAL_BRAIN_WORKSPACE="$mcp_review_workspace" node "$ROOT/mcp-server/server.mjs")"
require_contains "$mcp_work_block_output" '# Terminal Brain Work Block' "MCP work block title"
require_contains "$mcp_work_block_output" '### Bubble Up' "MCP work block Bubble Up section"
require_contains "$mcp_work_block_output" 'Broader Queue' "MCP work block broader queue section"
require_contains "$mcp_work_block_output" 'make outcome' "MCP work block outcome command"
mcp_review_note="$(find "$mcp_review_workspace/Oracle Inbox" -type f -name '*.md' | head -n 1)"
mcp_review_status_output="$(TERMINAL_BRAIN_WORKSPACE="$mcp_review_workspace" printf '%s\n' "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{\"name\":\"terminal_brain_oracle_review_status\",\"arguments\":{\"id\":\"$mcp_review_note\",\"status\":\"dismissed\"}}}" | TERMINAL_BRAIN_WORKSPACE="$mcp_review_workspace" node "$ROOT/mcp-server/server.mjs")"
require_contains "$mcp_review_status_output" 'dismissed' "MCP review status dismissed"
rm -rf "$mcp_review_workspace"

mcp_agent_prompt_output="$(call_mcp_tool terminal_brain_agent_prompt_markdown)"
require_contains "$mcp_agent_prompt_output" '# Terminal Brain Agent Prompt' "MCP agent prompt title"
require_contains "$mcp_agent_prompt_output" 'make oracle-brief' "MCP agent prompt closed fallback"
require_contains "$mcp_agent_prompt_output" 'make work-block' "MCP agent prompt Work Block command"
require_contains "$mcp_agent_prompt_output" 'make bubble-up' "MCP agent prompt Bubble Up command"

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
require_contains "$mcp_support_output" '# Work Block' "MCP support bundle Work Block section"
require_contains "$mcp_support_output" '# Bubble Up' "MCP support bundle Bubble Up section"
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
