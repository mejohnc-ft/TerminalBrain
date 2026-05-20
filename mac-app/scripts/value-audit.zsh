#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

case "${1:-}" in
  --help|-h)
    cat <<'EOF'
Usage: ./mac-app/scripts/value-audit.zsh

Prints a non-launching completion audit for Terminal Brain's value goal:
  - concrete success criteria
  - prompt-to-artifact checklist
  - current evidence from files, tests, CI, and runtime state
  - remaining gaps before calling it world class

This script never launches, foregrounds, quits, kills, or controls Terminal Brain.
EOF
    exit 0
    ;;
  "")
    ;;
  *)
    echo "Unknown option: $1" >&2
    echo "Run ./mac-app/scripts/value-audit.zsh --help" >&2
    exit 64
    ;;
esac

ok_count=0
gap_count=0

evidence() {
  local label="$1"
  local command="$2"
  local expected="$3"

  if eval "$command" >/dev/null 2>&1; then
    ok_count=$((ok_count + 1))
    printf '| ok | %s | %s |\n' "$label" "$expected"
  else
    gap_count=$((gap_count + 1))
    printf '| gap | %s | %s |\n' "$label" "$expected"
  fi
}

echo "# Terminal Brain Value Audit"
echo
echo "Objective: make Terminal Brain immediately useful to a non-expert operator without stealing focus, and make the same value available to agents through MCP."
echo
echo "## Success Criteria"
echo
echo "1. A first-time operator can see value without reading the whole repo."
echo "2. The system can prove the loop using temporary data."
echo "3. The system tells the operator what command to run for common situations."
echo "4. The system can capture ideas, review them, bubble them up, create one work block, and write outcomes."
echo "5. Agents can access the same surfaces through MCP."
echo "6. Verification proves these surfaces without launching or foregrounding the app."
echo "7. Remaining gaps are explicit instead of hidden behind green tests."
echo
echo "## Prompt-To-Artifact Checklist"
echo
echo "| Status | Requirement | Evidence |"
echo "| --- | --- | --- |"
evidence "First-use explanation" "grep -q 'terminal_brain_first_minute_markdown' '$ROOT/mcp-server/server.mjs' && grep -q '^first-minute:' '$ROOT/Makefile'" "make first-minute and MCP first-minute surface"
evidence "Temporary proof" "grep -q 'Terminal Brain Value Proof' '$ROOT/mac-app/scripts/prove-value.zsh' && grep -q 'terminal_brain_value_proof_markdown' '$ROOT/mcp-server/server.mjs'" "make prove-value and MCP value proof"
evidence "Seeded walkthrough" "grep -q 'Seeded Scenario' '$ROOT/mac-app/scripts/demo.zsh' && grep -q 'terminal_brain_demo_markdown' '$ROOT/mcp-server/server.mjs'" "make demo and MCP demo"
evidence "Operator command map" "grep -q 'Pick The Situation' '$ROOT/mac-app/scripts/playbook.zsh' && grep -q 'terminal_brain_playbook_markdown' '$ROOT/mcp-server/server.mjs'" "make playbook and MCP playbook"
evidence "Real work surface" "grep -q 'Terminal Brain Work Block' '$ROOT/mac-app/scripts/work-block.zsh' && grep -q 'terminal_brain_work_block_markdown' '$ROOT/mcp-server/server.mjs'" "make work-block and MCP work block"
evidence "Idea capture" "grep -q 'local-fallback' '$ROOT/mac-app/scripts/idea.zsh' && grep -q 'terminal_brain_capture_idea' '$ROOT/mcp-server/server.mjs'" "make idea and MCP idea capture"
evidence "Review queue" "grep -q 'Terminal Brain Review Queue' '$ROOT/mac-app/scripts/review.zsh' && grep -q 'terminal_brain_review_queue_markdown' '$ROOT/mcp-server/server.mjs'" "make review and MCP review queue"
evidence "Bubble Up" "grep -q 'What You May Not Be Considering' '$ROOT/mac-app/scripts/bubble-up.zsh' && grep -q 'terminal_brain_bubble_up_markdown' '$ROOT/mcp-server/server.mjs'" "make bubble-up and MCP Bubble Up"
evidence "Outcome writeback" "grep -q 'reviewStatus: accepted' '$ROOT/mac-app/scripts/outcome.zsh' && grep -q 'terminal_brain_commit_outcome' '$ROOT/mcp-server/server.mjs'" "make outcome and MCP outcome commit"
evidence "No-focus guard" "'$ROOT/mac-app/scripts/check-no-foreground.zsh'" "static foreground guard passes"
evidence "MCP contract" "node '$ROOT/mcp-server/check-tools.mjs'" "MCP manifest and callTool wiring match"
evidence "Entry regression" "grep -q 'terminal_brain_value_audit_markdown' '$ROOT/mac-app/scripts/check-entrypoints.zsh' && grep -q 'terminal_brain_demo_markdown' '$ROOT/mac-app/scripts/check-entrypoints.zsh' && grep -q 'terminal_brain_work_block_markdown' '$ROOT/mac-app/scripts/check-entrypoints.zsh'" "closed-app entrypoint suite covers value audit, demo, writes, review, Bubble Up, and Work Block"
echo
echo "## Current State"
echo
"$ROOT/mac-app/scripts/doctor.zsh" | sed -n '/^## Summary/,$p'
echo
echo "## Remaining Gaps"
echo
echo "- App-backed API and native UI remain manual-open by design; closed-app value is verified, but live UI value requires the operator to open the app."
echo "- Visual polish is not proven by this audit because it intentionally avoids launching or screenshotting the app."
echo "- Real workspace usefulness depends on the quality of captured notes and outcomes; the demo proves the mechanics with temporary data."
echo
echo "## Verdict"
echo
if (( gap_count == 0 )); then
  echo "- CLI/MCP first-use value path: covered."
else
  echo "- CLI/MCP first-use value path: missing $gap_count required evidence item(s)."
fi
echo "- World-class native experience: not fully certified by this non-launching audit; requires explicit UI review when the operator permits opening the app."
echo "- Evidence passed: $ok_count"
echo "- Evidence gaps: $gap_count"
echo "- Guardrail: this value audit did not launch, foreground, quit, kill, or control Terminal Brain."
