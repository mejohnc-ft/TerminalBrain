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

require_not_contains_literal() {
  local text="$1"
  local needle="$2"
  local label="$3"

  if grep -qF -- "$needle" <<<"$text"; then
    echo "Entrypoint check failed: unexpected $label" >&2
    echo "$text" >&2
    exit 1
  fi
}

call_mcp_tool() {
  local tool="$1"
  TERMINAL_BRAIN_API="$CLOSED_API" printf '%s\n' "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{\"name\":\"$tool\",\"arguments\":{}}}" \
    | TERMINAL_BRAIN_API="$CLOSED_API" node "$ROOT/mcp-server/server.mjs"
}

call_mcp_tool_json() {
  local tool="$1"
  local arguments_json="$2"
  TERMINAL_BRAIN_API="$CLOSED_API" TOOL="$tool" ARGS_JSON="$arguments_json" ruby -rjson -e '
    puts JSON.generate({
      jsonrpc: "2.0",
      id: 1,
      method: "tools/call",
      params: {
        name: ENV.fetch("TOOL"),
        arguments: JSON.parse(ENV.fetch("ARGS_JSON"))
      }
    })
  ' | TERMINAL_BRAIN_API="$CLOSED_API" node "$ROOT/mcp-server/server.mjs"
}

next_output="$(TERMINAL_BRAIN_API="$CLOSED_API" "$ROOT/mac-app/scripts/next.zsh")"
require_contains "$next_output" '# Terminal Brain Next' "next title"
require_contains "$next_output" 'make use-now' "next closed-app Use Now command"
require_contains "$next_output" 'Use Now' "next inline Use Now section"
require_contains "$next_output" 'Current Work Block' "next inline work block"
require_contains "$next_output" 'One Move' "next inline one-move section"
require_contains "$next_output" 'make agent-prompt' "next closed-app Agent Prompt command"
require_contains "$next_output" 'make outcome' "next closed-app outcome command"
require_contains "$next_output" 'did not launch or foreground' "next guardrail"

start_here_output="$(TERMINAL_BRAIN_API="$CLOSED_API" "$ROOT/mac-app/scripts/snapshot.zsh" --start-here)"
require_contains "$start_here_output" '# Terminal Brain Start Here' "start here title"
require_contains "$start_here_output" 'local closed-app Start Here path' "start here local fallback"
require_contains "$start_here_output" 'Oracle Signal' "start here Oracle signal"
require_contains "$start_here_output" 'Done Criteria' "start here done criteria"
require_contains "$start_here_output" 'did not launch or foreground' "start here guardrail"

use_now_output="$(TERMINAL_BRAIN_API="$CLOSED_API" "$ROOT/mac-app/scripts/use-now.zsh" --project "Terminal Brain" --limit 1)"
require_contains "$use_now_output" '# Terminal Brain Use Now' "use now title"
require_contains "$use_now_output" 'What You Get In 60 Seconds' "use now value section"
require_contains "$use_now_output" '## One Move' "use now one move section"
require_contains "$use_now_output" '## Why This Move' "use now one move rationale"
require_contains "$use_now_output" 'Current Work Block' "use now work block section"
require_contains "$use_now_output" 'make (use-now|agent-prompt|recent-work|review-status)' "use now one executable action"
require_not_contains_literal "$use_now_output" '### Pull Forward' "use now empty Pull Forward wrapper"
require_not_contains_literal "$use_now_output" '#### Bubble Up' "use now empty nested Bubble Up wrapper"
require_not_contains_literal "$use_now_output" 'Reviewable items:' "use now dashboard metrics"
require_not_contains_literal "$use_now_output" 'No open items matched.' "use now empty pull-forward placeholder"
require_not_contains_literal "$use_now_output" 'Next Clean Move' "use now duplicate next-clean section"
require_not_contains_literal "$use_now_output" '# Equivalent manual capture:' "use now verbose manual capture fallback"
require_contains "$use_now_output" 'Ask, Capture, Delegate, Close' "use now command section"
require_contains "$use_now_output" 'make ask QUERY=' "use now ask command"
require_contains "$use_now_output" 'make idea IDEA=' "use now idea command"
require_contains "$use_now_output" 'make agent-prompt' "use now agent prompt command"
require_contains "$use_now_output" 'make outcome TITLE=' "use now outcome command"
require_contains "$use_now_output" 'did not launch, foreground, screenshot, quit, kill, or control' "use now guardrail"
use_now_workspace="$(mktemp -d)"
use_now_capture_output="$(TERMINAL_BRAIN_API="$CLOSED_API" TERMINAL_BRAIN_WORKSPACE="$use_now_workspace" "$ROOT/mac-app/scripts/use-now.zsh" --project "Terminal Brain" --idea "Capture this first-use pressure point." --limit 1)"
require_contains "$use_now_capture_output" 'Captured First Signal' "use now capture section"
require_contains "$use_now_capture_output" 'Review status: new' "use now capture review status"
require_contains "$use_now_capture_output" 'Capture this first-use pressure point' "use now captured idea visible"
test -f "$use_now_workspace/Oracle Inbox/"*.md || {
  echo "Entrypoint check failed: use now capture did not write note" >&2
  echo "$use_now_capture_output" >&2
  exit 1
}
rm -rf "$use_now_workspace"

handoff_workspace="$(mktemp -d)"
handoff_path="$handoff_workspace/handoff.md"
handoff_cli_output="$(TERMINAL_BRAIN_API="$CLOSED_API" "$ROOT/mac-app/scripts/handoff.zsh" --output "$handoff_path")"
require_contains "$handoff_cli_output" "$handoff_path" "handoff output path"
test -f "$handoff_path" || {
  echo "Entrypoint check failed: handoff file was not written" >&2
  echo "$handoff_cli_output" >&2
  exit 1
}
handoff_output="$(cat "$handoff_path")"
require_contains "$handoff_output" '# Terminal Brain Handoff' "handoff title"
require_contains "$handoff_output" 'local closed-app handoff' "handoff local fallback"
require_contains "$handoff_output" 'Terminal Brain Start Here' "handoff Start Here section"
require_contains "$handoff_output" 'Terminal Brain Agent Prompt' "handoff Agent Prompt section"
require_contains "$handoff_output" 'did not launch, foreground, quit, kill, or control' "handoff guardrail"
rm -rf "$handoff_workspace"

first_minute_output="$(TERMINAL_BRAIN_API="$CLOSED_API" TERMINAL_BRAIN_FIRST_MINUTE_PROOF_API="$CLOSED_API" "$ROOT/mac-app/scripts/first-minute.zsh")"
require_contains "$first_minute_output" '# Terminal Brain First Minute' "first minute title"
require_contains "$first_minute_output" 'What You Can Get Immediately' "first minute value section"
require_contains "$first_minute_output" 'make use-now' "first minute use-now first action"
require_contains "$first_minute_output" '# Terminal Brain Value Proof' "first minute proof"
require_contains "$first_minute_output" 'reviewStatus.*accepted' "first minute accepted proof"
require_contains "$first_minute_output" 'did not launch, foreground, quit, kill, or control' "first minute guardrail"

value_output="$(TERMINAL_BRAIN_API="$CLOSED_API" "$ROOT/mac-app/scripts/value.zsh")"
require_contains "$value_output" '# Terminal Brain Value Now' "value title"
require_contains "$value_output" 'What You Can Get From It' "value explanation"
require_contains "$value_output" 'make doctor' "value doctor command"

now_output="$(TERMINAL_BRAIN_API="$CLOSED_API" "$ROOT/mac-app/scripts/now.zsh")"
require_contains "$now_output" '# Terminal Brain Now' "now title"
require_contains "$now_output" 'make use-now' "now Use Now command"
require_contains "$now_output" 'one executable move' "now one-move rationale"
require_contains "$now_output" 'make ask QUERY=' "now Ask command"
require_contains "$now_output" 'make agent-prompt' "now Agent Prompt command"
require_contains "$now_output" 'make outcome' "now outcome command"
require_contains "$now_output" 'did not launch, foreground, quit, kill, or control' "now guardrail"

sources_workspace="$(mktemp -d)"
sources_output="$(TERMINAL_BRAIN_WORKSPACE="$sources_workspace" "$ROOT/mac-app/scripts/sources.zsh")"
require_contains "$sources_output" '# Terminal Brain Source Inventory' "sources title"
require_contains "$sources_output" 'Guarded Import Plan' "sources guarded import plan"
require_contains "$sources_output" 'does not dump raw transcript content' "sources raw transcript guardrail"
rm -rf "$sources_workspace"

memory_workspace="$(mktemp -d)"
mkdir -p "$memory_workspace/.brain"
cat >"$memory_workspace/.brain/agent-history-stats.json" <<'JSON'
{
  "generatedAt": "2026-05-20T00:00:00Z",
  "sessions": 1,
  "records": 10,
  "bySource": { "codex": 1 }
}
JSON
cat >"$memory_workspace/.brain/agent-work-memory.json" <<'JSON'
{
  "generatedAt": "2026-05-20T00:00:00Z",
  "count": 1,
  "memories": [
    {
      "id": "entrypoint-memory",
      "source": "codex",
      "project": "Terminal Brain",
      "cwd": "/tmp/TerminalBrain",
      "startedAt": "2026-05-20T00:00:00Z",
      "endedAt": "2026-05-20T01:00:00Z",
      "records": 10,
      "textChars": 1000,
      "taskHint": "Prove memory promotion works",
      "outcomeHint": "Synthetic memory can be promoted into Oracle Inbox without raw transcript content."
    }
  ]
}
JSON
cat >"$memory_workspace/.brain/project-dossiers.json" <<'JSON'
{
  "generatedAt": "2026-05-20T00:00:00Z",
  "count": 1,
  "dossiers": [
    {
      "key": "terminal-brain",
      "title": "Terminal Brain",
      "cwd": "/tmp/TerminalBrain",
      "sessions": 1,
      "lastSeen": "2026-05-20T01:00:00Z",
      "sources": [{ "name": "codex", "count": 1 }]
    }
  ]
}
JSON
memory_output="$(TERMINAL_BRAIN_WORKSPACE="$memory_workspace" "$ROOT/mac-app/scripts/memory.zsh" --limit 1)"
require_contains "$memory_output" '# Terminal Brain Memory Brief' "memory title"
require_contains "$memory_output" 'Continuity Leads' "memory continuity leads"
require_contains "$memory_output" 'Prove memory promotion works' "memory synthetic lead"
require_contains "$memory_output" 'Promote If Useful' "memory promotion command"
require_contains "$memory_output" 'does not dump raw Codex or Claude transcript bodies' "memory raw transcript guardrail"
memory_promote_dry_output="$(TERMINAL_BRAIN_API="$CLOSED_API" TERMINAL_BRAIN_WORKSPACE="$memory_workspace" "$ROOT/mac-app/scripts/memory-promote.zsh" --index 1 --dry-run)"
require_contains "$memory_promote_dry_output" '"title":"Follow up: Prove memory promotion works"' "memory promote dry title"
require_contains "$memory_promote_dry_output" 'derived summaries only' "memory promote dry guardrail"
memory_promote_output="$(TERMINAL_BRAIN_API="$CLOSED_API" TERMINAL_BRAIN_WORKSPACE="$memory_workspace" "$ROOT/mac-app/scripts/memory-promote.zsh" --index 1)"
require_contains "$memory_promote_output" '"mode":"local-fallback"' "memory promote local fallback"
require_contains "$memory_promote_output" '"reviewStatus":"new"' "memory promote review status"
test -f "$memory_workspace/Oracle Inbox/"*.md || {
  echo "Entrypoint check failed: memory promotion did not write note" >&2
  echo "$memory_promote_output" >&2
  exit 1
}
rm -rf "$memory_workspace"

doctor_output="$(TERMINAL_BRAIN_API="$CLOSED_API" "$ROOT/mac-app/scripts/doctor.zsh")"
require_contains "$doctor_output" '# Terminal Brain Doctor' "doctor title"
require_contains "$doctor_output" 'MCP tool contract valid' "doctor MCP contract"
require_contains "$doctor_output" 'legacy local-brain/terminal-brain MCP auto-start entries' "doctor legacy MCP autostart guard"
require_contains "$doctor_output" 'Terminal Brain MCP/kernel' "doctor duplicate MCP process guard"
require_contains "$doctor_output" 'doctor did not launch or foreground' "doctor guardrail"

agent_prompt_output="$(TERMINAL_BRAIN_API="$CLOSED_API" "$ROOT/mac-app/scripts/agent-prompt.zsh")"
require_contains "$agent_prompt_output" '# Terminal Brain Agent Prompt' "agent prompt title"
require_contains "$agent_prompt_output" 'make oracle-brief' "agent prompt fallback command"
require_contains "$agent_prompt_output" 'make work-block' "agent prompt Work Block command"
require_contains "$agent_prompt_output" 'make bubble-up' "agent prompt Bubble Up command"
require_contains "$agent_prompt_output" 'did not launch, foreground, quit, kill, or control' "agent prompt guardrail"

oracle_output="$(TERMINAL_BRAIN_API="$CLOSED_API" "$ROOT/mac-app/scripts/oracle-brief.zsh")"
require_contains "$oracle_output" '# Terminal Brain Oracle Brief' "oracle brief title"
require_contains "$oracle_output" 'Local Pull Forward' "oracle brief local pull-forward"
require_contains "$oracle_output" 'make ask-commit' "oracle brief closed-app ask commit"
require_contains "$oracle_output" 'make outcome' "oracle brief outcome close loop"
require_contains "$oracle_output" 'did not launch or foreground' "oracle brief status guardrail"

ask_workspace="$(mktemp -d)"
ask_output="$(TERMINAL_BRAIN_API="$CLOSED_API" TERMINAL_BRAIN_WORKSPACE="$ask_workspace" "$ROOT/mac-app/scripts/oracle.zsh" "what should I do next?")"
require_contains "$ask_output" '# Terminal Brain Oracle' "ask fallback title"
require_contains "$ask_output" 'Mode: local-fallback' "ask fallback mode"
require_contains "$ask_output" 'Local Read' "ask fallback local read"
require_contains "$ask_output" 'Suggested Actions' "ask fallback suggested actions"
ask_commit_output="$(TERMINAL_BRAIN_API="$CLOSED_API" TERMINAL_BRAIN_WORKSPACE="$ask_workspace" "$ROOT/mac-app/scripts/oracle.zsh" --commit --project "Terminal Brain" "what should I do next?")"
require_contains "$ask_commit_output" '"mode":"local-fallback"' "ask commit fallback mode"
require_contains "$ask_commit_output" '"reviewStatus":"new"' "ask commit review status"
test -f "$ask_workspace/Oracle Inbox/"*.md || {
  echo "Entrypoint check failed: ask commit fallback did not write note" >&2
  echo "$ask_commit_output" >&2
  exit 1
}
rm -rf "$ask_workspace"

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

make_outcome_workspace="$(mktemp -d)"
make_outcome_output="$(cd "$ROOT" && TERMINAL_BRAIN_API="$CLOSED_API" TERMINAL_BRAIN_WORKSPACE="$make_outcome_workspace" TITLE="Make Outcome Evidence" PROJECT="Terminal Brain" OUTCOME="Verified Make outcome evidence passthrough." EVIDENCE="commit evidence-123" make outcome)"
require_contains "$make_outcome_output" '"mode":"local-fallback"' "make outcome local fallback mode"
make_outcome_note="$(find "$make_outcome_workspace/Oracle Inbox" -type f -name '*.md' | head -n 1)"
require_contains "$(cat "$make_outcome_note")" 'commit evidence-123' "make outcome evidence passthrough"
rm -rf "$make_outcome_workspace"

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
completed_bubble_output="$(TERMINAL_BRAIN_WORKSPACE="$review_workspace" "$ROOT/mac-app/scripts/bubble-up.zsh" --limit 2)"
require_contains "$completed_bubble_output" 'Completed Evidence' "bubble up completed evidence lane"
require_contains "$completed_bubble_output" 'Recent Work Signals' "bubble up fresh recent-work lane after review queue is clean"
require_contains "$completed_bubble_output" 'make recent-work INDEX=1' "bubble up recent work action after review queue is clean"
rm -rf "$review_workspace"

recent_work_workspace="$(mktemp -d)"
recent_work_dry_output="$(TERMINAL_BRAIN_WORKSPACE="$recent_work_workspace" "$ROOT/mac-app/scripts/recent-work.zsh" --index 1 --dry-run)"
require_contains "$recent_work_dry_output" '"title":"Follow up:' "recent work dry-run title"
require_contains "$recent_work_dry_output" 'recent-work promotion did not launch or foreground' "recent work guardrail"
recent_work_output="$(TERMINAL_BRAIN_API="$CLOSED_API" TERMINAL_BRAIN_WORKSPACE="$recent_work_workspace" "$ROOT/mac-app/scripts/recent-work.zsh" --index 1)"
require_contains "$recent_work_output" '"mode":"local-fallback"' "recent work local fallback"
require_contains "$recent_work_output" '"reviewStatus":"new"' "recent work review status"
test -f "$recent_work_workspace/Oracle Inbox/"*.md || {
  echo "Entrypoint check failed: recent work promotion did not write note" >&2
  echo "$recent_work_output" >&2
  exit 1
}
rm -rf "$recent_work_workspace"

covered_recent_workspace="$(mktemp -d)"
latest_subject="$(git -C "$ROOT" log -1 --pretty=%s)"
latest_short="$(git -C "$ROOT" log -1 --pretty=%h)"
commit_count="$(git -C "$ROOT" rev-list --count --max-count=2 HEAD)"
LATEST_SUBJECT="$latest_subject" LATEST_SHORT="$latest_short" WORKSPACE="$covered_recent_workspace" ruby -rfileutils -rtime -e '
  workspace = ENV.fetch("WORKSPACE")
  inbox = File.join(workspace, "Oracle Inbox")
  FileUtils.mkdir_p(inbox)
  created = Time.now.utc.iso8601
  path = File.join(inbox, "#{created.tr(":", "-")}-covered-recent-work.md")
  File.write(path, <<~MARKDOWN)
    ---
    type: oracle_commit
    source: Entrypoint Test
    project: Terminal Brain
    created: #{created}
    reviewStatus: accepted
    tags:
      - terminal-brain
      - outcome
    ---

    # Outcome - Covered recent work

    ## Outcome

    Latest work is already covered by accepted memory.

    ## Evidence

    - Commit #{ENV.fetch("LATEST_SHORT")}: #{ENV.fetch("LATEST_SUBJECT")}
  MARKDOWN
'
if (( commit_count > 1 )); then
  covered_recent_output="$(TERMINAL_BRAIN_WORKSPACE="$covered_recent_workspace" "$ROOT/mac-app/scripts/recent-work.zsh" --index 1 --dry-run)"
  require_not_contains_literal "$covered_recent_output" "$latest_subject" "covered latest commit in recent-work dry run"
  covered_bubble_output="$(TERMINAL_BRAIN_WORKSPACE="$covered_recent_workspace" "$ROOT/mac-app/scripts/bubble-up.zsh" --limit 3)"
  covered_bubble_recent_section="$(printf '%s\n' "$covered_bubble_output" | ruby -e 'text = STDIN.read; puts text[/## Recent Work Signals.*?(?=\n## |\z)/m].to_s')"
  require_contains "$covered_bubble_recent_section" 'Recent Work Signals' "covered bubble recent work section"
  require_not_contains_literal "$covered_bubble_recent_section" "$latest_subject" "covered latest commit in Bubble Up recent work lane"
else
  set +e
  covered_recent_output="$(TERMINAL_BRAIN_WORKSPACE="$covered_recent_workspace" "$ROOT/mac-app/scripts/recent-work.zsh" --index 1 --dry-run 2>&1)"
  covered_recent_status=$?
  set -e
  if [[ "$covered_recent_status" != "66" ]]; then
    echo "Entrypoint check failed: covered one-commit recent-work should exit 66" >&2
    echo "$covered_recent_output" >&2
    exit 1
  fi
  require_contains "$covered_recent_output" 'No uncaptured recent work signal' "covered one-commit recent-work empty state"
fi
rm -rf "$covered_recent_workspace"

proof_output="$(TERMINAL_BRAIN_PROOF_API="$CLOSED_API" "$ROOT/mac-app/scripts/prove-value.zsh")"
require_contains "$proof_output" '# Terminal Brain Value Proof' "value proof title"
require_contains "$proof_output" 'Use Now Capture' "value proof Use Now capture"
require_contains "$proof_output" 'Review status: new' "value proof capture review status"
require_contains "$proof_output" '# Terminal Brain Oracle Brief' "value proof Oracle Brief"
require_contains "$proof_output" '# Terminal Brain Agent Prompt' "value proof Agent Prompt"
require_contains "$proof_output" '"reviewStatus":"accepted"' "value proof accepted outcome"
require_contains "$proof_output" 'Temporary Note Preview' "value proof note preview"

demo_output="$(TERMINAL_BRAIN_DEMO_API="$CLOSED_API" "$ROOT/mac-app/scripts/demo.zsh")"
require_contains "$demo_output" '# Terminal Brain Demo' "demo title"
require_contains "$demo_output" 'Seeded Scenario' "demo seeded scenario"
require_contains "$demo_output" '# Terminal Brain Review Queue' "demo review queue"
require_contains "$demo_output" '# Terminal Brain Bubble Up' "demo Bubble Up"
require_contains "$demo_output" '# Terminal Brain Work Block' "demo Work Block"
require_contains "$demo_output" 'Use It For Real' "demo real commands"
require_contains "$demo_output" 'did not launch, foreground, quit, kill, or control' "demo guardrail"

playbook_output="$(TERMINAL_BRAIN_API="$CLOSED_API" "$ROOT/mac-app/scripts/playbook.zsh")"
require_contains "$playbook_output" '# Terminal Brain Playbook' "playbook title"
require_contains "$playbook_output" 'Pick The Situation' "playbook situations"
require_contains "$playbook_output" 'First Five Minutes' "playbook first five minutes"
require_contains "$playbook_output" 'Daily Cadence' "playbook daily cadence"
require_contains "$playbook_output" 'Agent Cadence' "playbook agent cadence"
require_contains "$playbook_output" 'readiness:' "playbook readiness"
require_contains "$playbook_output" 'did not launch, foreground, quit, kill, or control' "playbook guardrail"

value_audit_output="$(TERMINAL_BRAIN_API="$CLOSED_API" "$ROOT/mac-app/scripts/value-audit.zsh")"
require_contains "$value_audit_output" '# Terminal Brain Value Audit' "value audit title"
require_contains "$value_audit_output" 'Success Criteria' "value audit success criteria"
require_contains "$value_audit_output" 'Prompt-To-Artifact Checklist' "value audit checklist"
require_contains "$value_audit_output" 'Remaining Gaps' "value audit gaps"
require_contains "$value_audit_output" 'World-class native experience' "value audit native gap"
require_contains "$value_audit_output" 'did not launch, foreground, quit, kill, or control' "value audit guardrail"

design_audit_output="$("$ROOT/mac-app/scripts/design-audit.zsh")"
require_contains "$design_audit_output" '# Terminal Brain Design Audit' "design audit title"
require_contains "$design_audit_output" 'Liquid Glass' "design audit liquid glass section"
require_contains "$design_audit_output" 'transparent titlebar' "design audit transparent titlebar"
require_contains "$design_audit_output" 'native split-view shell' "design audit split-view shell"
require_contains "$design_audit_output" 'screenshot-level polish still requires explicit permission' "design audit visual permission gap"
require_contains "$design_audit_output" 'did not launch, foreground, screenshot, quit, kill, or control' "design audit guardrail"

mcp_next_output="$(call_mcp_tool terminal_brain_next_markdown)"
require_contains "$mcp_next_output" '# Terminal Brain Next' "MCP next title"
require_contains "$mcp_next_output" 'make use-now' "MCP next Use Now fallback"
require_contains "$mcp_next_output" 'One Move' "MCP next one-move fallback"
require_contains "$mcp_next_output" 'make agent-prompt' "MCP next Agent Prompt fallback"
require_contains "$mcp_next_output" 'make outcome' "MCP next outcome fallback"

mcp_use_now_output="$(call_mcp_tool terminal_brain_use_now_markdown)"
require_contains "$mcp_use_now_output" '# Terminal Brain Use Now' "MCP use now title"
require_contains "$mcp_use_now_output" 'What You Get In 60 Seconds' "MCP use now value section"
require_contains "$mcp_use_now_output" 'Ask, Capture, Delegate, Close' "MCP use now command section"
require_contains "$mcp_use_now_output" 'make outcome TITLE=' "MCP use now outcome command"
mcp_use_now_workspace="$(mktemp -d)"
mcp_use_now_capture_output="$(TERMINAL_BRAIN_WORKSPACE="$mcp_use_now_workspace" call_mcp_tool_json terminal_brain_use_now_markdown '{"project":"Terminal Brain","idea":"MCP captured first-use pressure point.","title":"MCP Use Now Capture","limit":1}')"
require_contains "$mcp_use_now_capture_output" 'Captured First Signal' "MCP use now capture section"
require_contains "$mcp_use_now_capture_output" 'Review status: new' "MCP use now capture review status"
require_contains "$mcp_use_now_capture_output" 'MCP captured first-use pressure point' "MCP use now captured idea visible"
test -f "$mcp_use_now_workspace/Oracle Inbox/"*.md || {
  echo "Entrypoint check failed: MCP use now capture did not write note" >&2
  echo "$mcp_use_now_capture_output" >&2
  exit 1
}
rm -rf "$mcp_use_now_workspace"

mcp_start_here_output="$(call_mcp_tool terminal_brain_start_here_markdown)"
require_contains "$mcp_start_here_output" '# Terminal Brain Start Here' "MCP start here title"
require_contains "$mcp_start_here_output" 'local closed-app Start Here path' "MCP start here local fallback"
require_contains "$mcp_start_here_output" 'Done Criteria' "MCP start here done criteria"

mcp_handoff_output="$(call_mcp_tool terminal_brain_handoff_markdown)"
require_contains "$mcp_handoff_output" '# Terminal Brain Handoff' "MCP handoff title"
require_contains "$mcp_handoff_output" 'local closed-app handoff' "MCP handoff local fallback"
require_contains "$mcp_handoff_output" 'Terminal Brain Start Here' "MCP handoff Start Here section"
require_contains "$mcp_handoff_output" 'Terminal Brain Agent Prompt' "MCP handoff Agent Prompt section"

mcp_snapshot_output="$(call_mcp_tool terminal_brain_snapshot_markdown)"
require_contains "$mcp_snapshot_output" '# Terminal Brain Snapshot' "MCP snapshot markdown title"
require_contains "$mcp_snapshot_output" 'local closed-app snapshot' "MCP snapshot markdown fallback"
require_contains "$mcp_snapshot_output" 'Start Here' "MCP snapshot markdown Start Here"
mcp_snapshot_json_output="$(call_mcp_tool terminal_brain_snapshot)"
require_contains "$mcp_snapshot_json_output" 'local-fallback' "MCP snapshot local fallback"
require_contains "$mcp_snapshot_json_output" 'startHereMarkdown' "MCP snapshot structured Start Here"
require_contains "$mcp_snapshot_json_output" 'processMapMarkdown' "MCP snapshot structured Process Map"

mcp_status_output="$(call_mcp_tool terminal_brain_status)"
require_contains "$mcp_status_output" 'local-fallback' "MCP status local fallback"
require_contains "$mcp_status_output" 'app-api-unreachable' "MCP status app unavailable state"
require_contains "$mcp_status_output" 'runtimeStatus' "MCP status runtime fallback"

mcp_first_minute_output="$(call_mcp_tool terminal_brain_first_minute_markdown)"
require_contains "$mcp_first_minute_output" '# Terminal Brain First Minute' "MCP first minute title"
require_contains "$mcp_first_minute_output" 'What You Can Get Immediately' "MCP first minute value section"
require_contains "$mcp_first_minute_output" '# Terminal Brain Value Proof' "MCP first minute proof"
require_contains "$mcp_first_minute_output" 'reviewStatus.*accepted' "MCP first minute accepted proof"

mcp_now_output="$(call_mcp_tool terminal_brain_now_markdown)"
require_contains "$mcp_now_output" '# Terminal Brain Now' "MCP now title"
require_contains "$mcp_now_output" 'make use-now' "MCP now Use Now command"
require_contains "$mcp_now_output" 'one executable move' "MCP now one-move rationale"
require_contains "$mcp_now_output" 'make ask QUERY=' "MCP now Ask command"
require_contains "$mcp_now_output" 'make agent-prompt' "MCP now Agent Prompt command"
require_contains "$mcp_now_output" 'make outcome' "MCP now outcome command"

mcp_value_output="$(call_mcp_tool terminal_brain_value_now_markdown)"
require_contains "$mcp_value_output" '# Terminal Brain Value Now' "MCP value title"
require_contains "$mcp_value_output" 'What You Can Get From It' "MCP value explanation"

mcp_proof_output="$(call_mcp_tool terminal_brain_value_proof_markdown)"
require_contains "$mcp_proof_output" '# Terminal Brain Value Proof' "MCP value proof title"
require_contains "$mcp_proof_output" 'Use Now Capture' "MCP value proof Use Now capture"
require_contains "$mcp_proof_output" 'Review status: new' "MCP value proof capture review status"
require_contains "$mcp_proof_output" '# Terminal Brain Oracle Brief' "MCP value proof Oracle Brief"
require_contains "$mcp_proof_output" '# Terminal Brain Agent Prompt' "MCP value proof Agent Prompt"
require_contains "$mcp_proof_output" 'reviewStatus.*accepted' "MCP value proof accepted outcome"
require_contains "$mcp_proof_output" 'Temporary Note Preview' "MCP value proof note preview"

mcp_demo_output="$(call_mcp_tool terminal_brain_demo_markdown)"
require_contains "$mcp_demo_output" '# Terminal Brain Demo' "MCP demo title"
require_contains "$mcp_demo_output" 'Seeded Scenario' "MCP demo seeded scenario"
require_contains "$mcp_demo_output" '# Terminal Brain Review Queue' "MCP demo review queue"
require_contains "$mcp_demo_output" '# Terminal Brain Bubble Up' "MCP demo Bubble Up"
require_contains "$mcp_demo_output" '# Terminal Brain Work Block' "MCP demo Work Block"
require_contains "$mcp_demo_output" 'Use It For Real' "MCP demo real commands"

mcp_playbook_output="$(call_mcp_tool terminal_brain_playbook_markdown)"
require_contains "$mcp_playbook_output" '# Terminal Brain Playbook' "MCP playbook title"
require_contains "$mcp_playbook_output" 'Pick The Situation' "MCP playbook situations"
require_contains "$mcp_playbook_output" 'First Five Minutes' "MCP playbook first five minutes"
require_contains "$mcp_playbook_output" 'Agent Cadence' "MCP playbook agent cadence"

mcp_value_audit_output="$(call_mcp_tool terminal_brain_value_audit_markdown)"
require_contains "$mcp_value_audit_output" '# Terminal Brain Value Audit' "MCP value audit title"
require_contains "$mcp_value_audit_output" 'Prompt-To-Artifact Checklist' "MCP value audit checklist"
require_contains "$mcp_value_audit_output" 'Remaining Gaps' "MCP value audit gaps"

mcp_memory_workspace="$(mktemp -d)"
mkdir -p "$mcp_memory_workspace/.brain"
cat >"$mcp_memory_workspace/.brain/agent-history-stats.json" <<'JSON'
{
  "generatedAt": "2026-05-20T00:00:00Z",
  "sessions": 1,
  "records": 10,
  "bySource": { "codex": 1 }
}
JSON
cat >"$mcp_memory_workspace/.brain/agent-work-memory.json" <<'JSON'
{
  "generatedAt": "2026-05-20T00:00:00Z",
  "count": 1,
  "memories": [
    {
      "id": "mcp-memory",
      "source": "codex",
      "project": "Terminal Brain",
      "cwd": "/tmp/TerminalBrain",
      "startedAt": "2026-05-20T00:00:00Z",
      "endedAt": "2026-05-20T01:00:00Z",
      "records": 10,
      "textChars": 1000,
      "taskHint": "Prove MCP memory promotion works",
      "outcomeHint": "Synthetic MCP memory can be promoted without raw transcript content."
    }
  ]
}
JSON
cat >"$mcp_memory_workspace/.brain/project-dossiers.json" <<'JSON'
{
  "generatedAt": "2026-05-20T00:00:00Z",
  "count": 1,
  "dossiers": [
    {
      "key": "terminal-brain",
      "title": "Terminal Brain",
      "cwd": "/tmp/TerminalBrain",
      "sessions": 1,
      "lastSeen": "2026-05-20T01:00:00Z",
      "sources": [{ "name": "codex", "count": 1 }]
    }
  ]
}
JSON
mcp_memory_output="$(TERMINAL_BRAIN_WORKSPACE="$mcp_memory_workspace" printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"terminal_brain_memory_brief_markdown","arguments":{"limit":1}}}' | TERMINAL_BRAIN_WORKSPACE="$mcp_memory_workspace" node "$ROOT/mcp-server/server.mjs")"
require_contains "$mcp_memory_output" '# Terminal Brain Memory Brief' "MCP memory title"
require_contains "$mcp_memory_output" 'Prove MCP memory promotion works' "MCP memory synthetic lead"
mcp_memory_promote_dry_output="$(TERMINAL_BRAIN_API="$CLOSED_API" TERMINAL_BRAIN_WORKSPACE="$mcp_memory_workspace" printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"terminal_brain_memory_promote","arguments":{"index":1,"dryRun":true}}}' | TERMINAL_BRAIN_API="$CLOSED_API" TERMINAL_BRAIN_WORKSPACE="$mcp_memory_workspace" node "$ROOT/mcp-server/server.mjs")"
require_contains "$mcp_memory_promote_dry_output" 'Prove MCP memory promotion works' "MCP memory promote dry title"
require_contains "$mcp_memory_promote_dry_output" 'derived summaries only' "MCP memory promote dry guardrail"
mcp_memory_promote_output="$(TERMINAL_BRAIN_API="$CLOSED_API" TERMINAL_BRAIN_WORKSPACE="$mcp_memory_workspace" printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"terminal_brain_memory_promote","arguments":{"index":1}}}' | TERMINAL_BRAIN_API="$CLOSED_API" TERMINAL_BRAIN_WORKSPACE="$mcp_memory_workspace" node "$ROOT/mcp-server/server.mjs")"
require_contains "$mcp_memory_promote_output" 'local-fallback' "MCP memory promote local fallback"
require_contains "$mcp_memory_promote_output" 'reviewStatus.*new' "MCP memory promote review status"
test -f "$mcp_memory_workspace/Oracle Inbox/"*.md || {
  echo "Entrypoint check failed: MCP memory promotion did not write note" >&2
  echo "$mcp_memory_promote_output" >&2
  exit 1
}
rm -rf "$mcp_memory_workspace"

mcp_recent_work_workspace="$(mktemp -d)"
mcp_recent_work_dry_output="$(TERMINAL_BRAIN_WORKSPACE="$mcp_recent_work_workspace" printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"terminal_brain_recent_work_promote","arguments":{"index":1,"dryRun":true}}}' | TERMINAL_BRAIN_WORKSPACE="$mcp_recent_work_workspace" node "$ROOT/mcp-server/server.mjs")"
require_contains "$mcp_recent_work_dry_output" 'Follow up:' "MCP recent work dry title"
require_contains "$mcp_recent_work_dry_output" 'recent-work promotion did not launch or foreground' "MCP recent work dry guardrail"
mcp_recent_work_output="$(TERMINAL_BRAIN_API="$CLOSED_API" TERMINAL_BRAIN_WORKSPACE="$mcp_recent_work_workspace" printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"terminal_brain_recent_work_promote","arguments":{"index":1}}}' | TERMINAL_BRAIN_API="$CLOSED_API" TERMINAL_BRAIN_WORKSPACE="$mcp_recent_work_workspace" node "$ROOT/mcp-server/server.mjs")"
require_contains "$mcp_recent_work_output" 'local-fallback' "MCP recent work local fallback"
require_contains "$mcp_recent_work_output" 'reviewStatus.*new' "MCP recent work review status"
test -f "$mcp_recent_work_workspace/Oracle Inbox/"*.md || {
  echo "Entrypoint check failed: MCP recent work promotion did not write note" >&2
  echo "$mcp_recent_work_output" >&2
  exit 1
}
rm -rf "$mcp_recent_work_workspace"

mcp_oracle_output="$(call_mcp_tool terminal_brain_oracle_brief_markdown)"
require_contains "$mcp_oracle_output" '# Terminal Brain Oracle Brief' "MCP Oracle Brief title"
require_contains "$mcp_oracle_output" 'cheapest test' "MCP Oracle Brief closed fallback"

mcp_ask_workspace="$(mktemp -d)"
mcp_ask_output="$(TERMINAL_BRAIN_API="$CLOSED_API" TERMINAL_BRAIN_WORKSPACE="$mcp_ask_workspace" printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"terminal_brain_oracle_ask","arguments":{"question":"what should I do next?"}}}' | TERMINAL_BRAIN_API="$CLOSED_API" TERMINAL_BRAIN_WORKSPACE="$mcp_ask_workspace" node "$ROOT/mcp-server/server.mjs")"
require_contains "$mcp_ask_output" 'Mode: local-fallback' "MCP ask local fallback"
require_contains "$mcp_ask_output" 'Suggested Actions' "MCP ask suggested actions"
mcp_ask_commit_output="$(TERMINAL_BRAIN_API="$CLOSED_API" TERMINAL_BRAIN_WORKSPACE="$mcp_ask_workspace" printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"terminal_brain_oracle_ask_commit","arguments":{"question":"what should I do next?","project":"Terminal Brain"}}}' | TERMINAL_BRAIN_API="$CLOSED_API" TERMINAL_BRAIN_WORKSPACE="$mcp_ask_workspace" node "$ROOT/mcp-server/server.mjs")"
require_contains "$mcp_ask_commit_output" 'local-fallback' "MCP ask commit local fallback"
require_contains "$mcp_ask_commit_output" 'reviewStatus' "MCP ask commit review status"
test -f "$mcp_ask_workspace/Oracle Inbox/"*.md || {
  echo "Entrypoint check failed: MCP ask commit fallback did not write note" >&2
  echo "$mcp_ask_commit_output" >&2
  exit 1
}
rm -rf "$mcp_ask_workspace"

mcp_commit_workspace="$(mktemp -d)"
mcp_oracle_commit_output="$(TERMINAL_BRAIN_API="$CLOSED_API" TERMINAL_BRAIN_WORKSPACE="$mcp_commit_workspace" printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"terminal_brain_oracle_commit","arguments":{"title":"MCP Local Commit","content":"Persist this read without the app.","question":"Can agents write memory closed-app?","project":"Terminal Brain"}}}' | TERMINAL_BRAIN_API="$CLOSED_API" TERMINAL_BRAIN_WORKSPACE="$mcp_commit_workspace" node "$ROOT/mcp-server/server.mjs")"
require_contains "$mcp_oracle_commit_output" 'local-fallback' "MCP oracle commit local fallback"
require_contains "$mcp_oracle_commit_output" 'reviewStatus.*new' "MCP oracle commit review status"
mcp_outcome_commit_output="$(TERMINAL_BRAIN_API="$CLOSED_API" TERMINAL_BRAIN_WORKSPACE="$mcp_commit_workspace" printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"terminal_brain_commit_outcome","arguments":{"title":"MCP Local Outcome","outcome":"Persist this outcome without the app.","nextAction":"Review the note.","project":"Terminal Brain"}}}' | TERMINAL_BRAIN_API="$CLOSED_API" TERMINAL_BRAIN_WORKSPACE="$mcp_commit_workspace" node "$ROOT/mcp-server/server.mjs")"
require_contains "$mcp_outcome_commit_output" 'local-fallback' "MCP outcome commit local fallback"
require_contains "$mcp_outcome_commit_output" 'reviewStatus.*accepted' "MCP outcome commit accepted status"
note_count="$(find "$mcp_commit_workspace/Oracle Inbox" -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ')"
if [[ "$note_count" != "2" ]]; then
  echo "Entrypoint check failed: MCP commit fallbacks wrote $note_count notes, expected 2" >&2
  echo "$mcp_oracle_commit_output" >&2
  echo "$mcp_outcome_commit_output" >&2
  exit 1
fi
rm -rf "$mcp_commit_workspace"

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
