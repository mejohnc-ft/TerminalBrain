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
echo "6. The native app opens on the same high-value Use Now path and exposes it through sections, copy actions, menus, and Shortcuts."
echo "7. Verification proves these surfaces without launching or foregrounding the app."
echo "8. Remaining gaps are explicit instead of hidden behind green tests."
echo
echo "## Prompt-To-Artifact Checklist"
echo
echo "| Status | Requirement | Evidence |"
echo "| --- | --- | --- |"
evidence "One-command Use Now path" "grep -q 'Terminal Brain Use Now' '$ROOT/mac-app/scripts/use-now.zsh' && grep -q '^use-now:' '$ROOT/Makefile' && grep -q 'terminal_brain_use_now_markdown' '$ROOT/mcp-server/server.mjs'" "make use-now, default operator path, and MCP use-now surface"
evidence "First-use explanation" "grep -q 'terminal_brain_first_minute_markdown' '$ROOT/mcp-server/server.mjs' && grep -q '^first-minute:' '$ROOT/Makefile'" "make first-minute and MCP first-minute surface"
evidence "Temporary proof" "grep -q 'Terminal Brain Value Proof' '$ROOT/mac-app/scripts/prove-value.zsh' && grep -q 'terminal_brain_value_proof_markdown' '$ROOT/mcp-server/server.mjs'" "make prove-value and MCP value proof"
evidence "Seeded walkthrough" "grep -q 'Seeded Scenario' '$ROOT/mac-app/scripts/demo.zsh' && grep -q 'terminal_brain_demo_markdown' '$ROOT/mcp-server/server.mjs'" "make demo and MCP demo"
evidence "Operator command map" "grep -q 'Pick The Situation' '$ROOT/mac-app/scripts/playbook.zsh' && grep -q 'terminal_brain_playbook_markdown' '$ROOT/mcp-server/server.mjs'" "make playbook and MCP playbook"
evidence "Real work surface" "grep -q 'Terminal Brain Work Block' '$ROOT/mac-app/scripts/work-block.zsh' && grep -q 'terminal_brain_work_block_markdown' '$ROOT/mcp-server/server.mjs'" "make work-block and MCP work block"
evidence "Idea capture" "grep -q 'local-fallback' '$ROOT/mac-app/scripts/idea.zsh' && grep -q 'terminal_brain_capture_idea' '$ROOT/mcp-server/server.mjs'" "make idea and MCP idea capture"
evidence "Review queue" "grep -q 'Terminal Brain Review Queue' '$ROOT/mac-app/scripts/review.zsh' && grep -q 'terminal_brain_review_queue_markdown' '$ROOT/mcp-server/server.mjs'" "make review and MCP review queue"
evidence "Bubble Up" "grep -q 'What You May Not Be Considering' '$ROOT/mac-app/scripts/bubble-up.zsh' && grep -q 'terminal_brain_bubble_up_markdown' '$ROOT/mcp-server/server.mjs'" "make bubble-up and MCP Bubble Up"
evidence "Outcome writeback" "grep -q 'reviewStatus: accepted' '$ROOT/mac-app/scripts/outcome.zsh' && grep -q 'terminal_brain_commit_outcome' '$ROOT/mcp-server/server.mjs'" "make outcome and MCP outcome commit"
evidence "Native default value section" "grep -q 'selectedSection = \"use-now\"' '$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift' && grep -q 'useNowView' '$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift'" "native app defaults to Use Now"
evidence "Native value sections" "grep -q 'demoView' '$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift' && grep -q 'playbookView' '$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift' && grep -q 'valueAuditView' '$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift'" "native Demo, Playbook, and Value Audit sections"
evidence "Native copy actions" "grep -q 'func copyUseNow' '$ROOT/mac-app/Sources/TerminalBrain/BrainStatusModel.swift' && grep -q 'func copyDemo' '$ROOT/mac-app/Sources/TerminalBrain/BrainStatusModel.swift' && grep -q 'func copyPlaybook' '$ROOT/mac-app/Sources/TerminalBrain/BrainStatusModel.swift' && grep -q 'func copyValueAudit' '$ROOT/mac-app/Sources/TerminalBrain/BrainStatusModel.swift'" "in-app copy actions for Use Now and high-value surfaces"
evidence "Native menus" "grep -q 'Copy Use Now' '$ROOT/mac-app/Sources/TerminalBrain/TerminalBrainApp.swift' && grep -q 'Copy Demo' '$ROOT/mac-app/Sources/TerminalBrain/TerminalBrainApp.swift' && grep -q 'Copy Playbook' '$ROOT/mac-app/Sources/TerminalBrain/TerminalBrainApp.swift' && grep -q 'Copy Value Audit' '$ROOT/mac-app/Sources/TerminalBrain/TerminalBrainApp.swift'" "menu and menu bar access"
evidence "Native shortcuts" "grep -q 'CopyUseNowIntent' '$ROOT/mac-app/Sources/TerminalBrain/AppShortcuts.swift' && grep -q 'CopyDemoIntent' '$ROOT/mac-app/Sources/TerminalBrain/AppShortcuts.swift' && grep -q 'CopyPlaybookIntent' '$ROOT/mac-app/Sources/TerminalBrain/AppShortcuts.swift' && grep -q 'CopyValueAuditIntent' '$ROOT/mac-app/Sources/TerminalBrain/AppShortcuts.swift'" "App Shortcuts for Use Now and high-value surfaces"
evidence "App API routes" "grep -q '\"/use-now/markdown\"' '$ROOT/mac-app/Sources/TerminalBrain/LocalControlServer.swift' && grep -q '\"/demo/markdown\"' '$ROOT/mac-app/Sources/TerminalBrain/LocalControlServer.swift' && grep -q '\"/playbook/markdown\"' '$ROOT/mac-app/Sources/TerminalBrain/LocalControlServer.swift' && grep -q '\"/value-audit/markdown\"' '$ROOT/mac-app/Sources/TerminalBrain/LocalControlServer.swift'" "app-backed Markdown endpoints for Use Now, Demo, Playbook, and Value Audit"
evidence "No-focus guard" "'$ROOT/mac-app/scripts/check-no-foreground.zsh'" "static foreground guard passes"
evidence "MCP contract" "node '$ROOT/mcp-server/check-tools.mjs'" "MCP manifest and callTool wiring match"
evidence "Entry regression" "grep -q 'terminal_brain_value_audit_markdown' '$ROOT/mac-app/scripts/check-entrypoints.zsh' && grep -q 'terminal_brain_demo_markdown' '$ROOT/mac-app/scripts/check-entrypoints.zsh' && grep -q 'terminal_brain_work_block_markdown' '$ROOT/mac-app/scripts/check-entrypoints.zsh'" "closed-app entrypoint suite covers value audit, demo, writes, review, Bubble Up, and Work Block"
evidence "Static app verification" "'$ROOT/mac-app/scripts/check-api-routes.zsh' && '$ROOT/mac-app/scripts/check-value-surfaces.zsh'" "API route manifest and native value-surface evidence pass"
echo
echo "## Current State"
echo
"$ROOT/mac-app/scripts/doctor.zsh" | sed -n '/^## Summary/,$p'
echo
echo "## Remaining Gaps"
echo
echo "- App-backed API and native UI surfaces are statically verified, but live interaction requires the operator to open the app."
echo "- Visual polish is not certified by this audit because it intentionally avoids launching or screenshotting the app."
echo "- Real workspace usefulness depends on the quality of captured notes and outcomes; the demo proves the mechanics with temporary data."
echo
echo "## Verdict"
echo
if (( gap_count == 0 )); then
  echo "- CLI/MCP/native first-use value path: statically covered."
else
  echo "- CLI/MCP/native first-use value path: missing $gap_count required evidence item(s)."
fi
echo "- World-class native experience: statically wired, not visually certified; requires explicit UI review when the operator permits opening the app."
echo "- Evidence passed: $ok_count"
echo "- Evidence gaps: $gap_count"
echo "- Guardrail: this value audit did not launch, foreground, quit, kill, or control Terminal Brain."
