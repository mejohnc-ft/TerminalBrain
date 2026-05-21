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
echo "7. Native signal surfaces can convert Radar, Blindspots, and Ideas into challenge, capture, commit, or execution paths."
echo "8. The native app defaults to a simple operator navigation path instead of a metrics-first surface map."
echo "9. The first screen supports inline Oracle challenge and commit-read writeback before asking the operator to browse more views."
echo "10. Verification proves these surfaces without launching or foregrounding the app."
echo "11. A clean queue still gives a concrete choice menu and a committed Oracle path instead of empty dashboard metrics."
echo "12. Remaining gaps are explicit instead of hidden behind green tests."
echo "13. The operator can ask what is happening now and get one plain answer before deeper diagnostics."
echo
echo "## Prompt-To-Artifact Checklist"
echo
echo "| Status | Requirement | Evidence |"
echo "| --- | --- | --- |"
evidence "One-command Use Now path" "grep -q 'Terminal Brain Use Now' '$ROOT/mac-app/scripts/use-now.zsh' && grep -q 'No-Choice Path' '$ROOT/mac-app/scripts/use-now.zsh' && grep -q '## One Move' '$ROOT/mac-app/scripts/use-now.zsh' && grep -q '^use-now:' '$ROOT/Makefile' && grep -q '^start: use-now' '$ROOT/Makefile' && grep -q '^easy: use-now' '$ROOT/Makefile' && grep -q 'terminal_brain_use_now_markdown' '$ROOT/mcp-server/server.mjs'" "make start, make easy, make use-now, default no-choice operator path, and MCP use-now surface"
evidence "One-command capture loop" "grep -q 'Captured First Signal' '$ROOT/mac-app/scripts/use-now.zsh' && grep -q 'idea.zsh' '$ROOT/mac-app/scripts/use-now.zsh' && grep -q 'make start IDEA=' '$ROOT/mac-app/scripts/use-now.zsh' && grep -q 'use_now_capture_output' '$ROOT/mac-app/scripts/check-entrypoints.zsh'" "make start IDEA=... writes a reviewable note before showing the work block"
evidence "Agent first-signal capture loop" "grep -q 'args.idea' '$ROOT/mcp-server/server.mjs' && grep -q 'mcp_use_now_capture_output' '$ROOT/mac-app/scripts/check-entrypoints.zsh'" "terminal_brain_use_now_markdown can capture an idea before returning the work block"
evidence "Clean-queue operator menu" "grep -q 'Choose Your Mode' '$ROOT/mac-app/scripts/use-now.zsh' && grep -q 'Selected Signal' '$ROOT/mac-app/scripts/use-now.zsh' && grep -q 'make ask QUERY=.*cheap test' '$ROOT/mac-app/scripts/use-now.zsh' && grep -q 'get one direct decision read' '$ROOT/mac-app/scripts/use-now.zsh' && grep -q 'recent-work.zsh.*--dry-run' '$ROOT/mac-app/scripts/use-now.zsh' && grep -q '## Choose Your Mode' '$ROOT/mac-app/scripts/check-entrypoints.zsh'" "Use Now offers a direct ask first, then pressure-test, recent-work, capture, delegate, and outcome lanes when no open item dominates without creating automatic notes"
evidence "First-use explanation" "grep -q 'terminal_brain_first_minute_markdown' '$ROOT/mcp-server/server.mjs' && grep -q '^first-minute:' '$ROOT/Makefile'" "make first-minute and MCP first-minute surface"
evidence "Plain situation answer" "grep -q 'Terminal Brain What Now' '$ROOT/mac-app/scripts/what-now.zsh' && grep -q '^what-now:' '$ROOT/Makefile' && grep -q 'terminal_brain_what_now_markdown' '$ROOT/mcp-server/server.mjs' && grep -q 'What Now' '$ROOT/mac-app/scripts/support-bundle.zsh'" "make what-now, MCP What Now, and Support Bundle answer app focus, repo/CI, runtime noise, blocker, and next value command"
evidence "Temporary proof" "grep -q 'Terminal Brain Value Proof' '$ROOT/mac-app/scripts/prove-value.zsh' && grep -q 'terminal_brain_value_proof_markdown' '$ROOT/mcp-server/server.mjs'" "make prove-value and MCP value proof"
evidence "Seeded walkthrough" "grep -q 'Seeded Scenario' '$ROOT/mac-app/scripts/demo.zsh' && grep -q 'terminal_brain_demo_markdown' '$ROOT/mcp-server/server.mjs'" "make demo and MCP demo"
evidence "Operator command map" "grep -q 'Pick The Situation' '$ROOT/mac-app/scripts/playbook.zsh' && grep -q 'terminal_brain_playbook_markdown' '$ROOT/mcp-server/server.mjs'" "make playbook and MCP playbook"
evidence "Real work surface" "grep -q 'Terminal Brain Work Block' '$ROOT/mac-app/scripts/work-block.zsh' && grep -q 'terminal_brain_work_block_markdown' '$ROOT/mcp-server/server.mjs'" "make work-block and MCP work block"
evidence "Idea capture" "grep -q 'local-fallback' '$ROOT/mac-app/scripts/idea.zsh' && grep -q '## Cheap Test' '$ROOT/mac-app/scripts/idea.zsh' && grep -q '## Kill Criteria' '$ROOT/mac-app/scripts/idea.zsh' && grep -q '## Cheap Test' '$ROOT/mac-app/Sources/TerminalBrain/LocalControlServer.swift' && grep -q 'terminal_brain_capture_idea' '$ROOT/mcp-server/server.mjs'" "make idea, app API, and MCP idea capture with cheap-test prompts"
evidence "Review queue" "grep -q 'Terminal Brain Review Queue' '$ROOT/mac-app/scripts/review.zsh' && grep -q 'terminal_brain_review_queue_markdown' '$ROOT/mcp-server/server.mjs'" "make review and MCP review queue"
evidence "Bubble Up" "grep -q 'What You May Not Be Considering' '$ROOT/mac-app/scripts/bubble-up.zsh' && grep -q 'terminal_brain_bubble_up_markdown' '$ROOT/mcp-server/server.mjs'" "make bubble-up and MCP Bubble Up"
evidence "Agent handoff is actionable" "grep -q 'Current One Move' '$ROOT/mac-app/scripts/agent-prompt.zsh' && grep -q 'analysis alone is not enough' '$ROOT/mac-app/scripts/agent-prompt.zsh' && grep -q 'closed-app local fallback' '$ROOT/mac-app/scripts/agent-prompt.zsh' && grep -q 'terminal_brain_agent_prompt_markdown' '$ROOT/mcp-server/server.mjs'" "make agent-prompt and MCP handoff carry the current move, concrete artifact requirement, and closed-app outcome writeback"
evidence "Outcome writeback" "grep -q 'reviewStatus: accepted' '$ROOT/mac-app/scripts/outcome.zsh' && grep -q 'terminal_brain_commit_outcome' '$ROOT/mcp-server/server.mjs'" "make outcome and MCP outcome commit"
evidence "Native default value section" "grep -q 'selectedSection = \"use-now\"' '$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift' && grep -q 'useNowView' '$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift'" "native app defaults to Use Now"
evidence "Native Use Now operator lanes" "grep -q 'useNowNoChoicePanel' '$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift' && grep -q 'No-Choice Path' '$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift' && grep -q 'Do This Now' '$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift' && grep -q 'Save Result' '$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift' && grep -q 'title: \"Why this move\"' '$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift' && grep -q 'title: \"Recent work\"' '$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift' && grep -q 'promoteRecentWork(index: 1)' '$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift' && grep -q 'title: \"What am I missing?\"' '$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift'" "native Use Now exposes no-choice action, challenge, recent-work promotion, ask, capture, delegate, and close-loop lanes"
evidence "Native simple navigation" "grep -q 'operatorPathOnly' '$ROOT/mac-app/Sources/TerminalBrain/Models.swift' && grep -q 'Show All Surfaces' '$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift' && grep -q 'Simple operator navigation' '$ROOT/mac-app/Sources/TerminalBrain/SettingsView.swift'" "native sidebar defaults to the operator path with an explicit advanced-surface escape hatch"
evidence "Native inline Oracle loop" "grep -q 'useNowOraclePanel' '$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift' && grep -q 'Ask, Decide, Remember' '$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift' && grep -q 'Commit Read' '$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift'" "Use Now lets the operator challenge, test, delegate, and commit a useful read on the first screen"
evidence "Native value sections" "grep -q 'demoView' '$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift' && grep -q 'playbookView' '$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift' && grep -q 'valueAuditView' '$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift'" "native Demo, Playbook, and Value Audit sections"
evidence "Native signal action paths" "grep -q 'Check Blindspots' '$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift' && grep -q 'Capture as Idea' '$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift' && grep -q 'focusIdeaCapturePanel(focus)' '$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift' && grep -q 'native Radar counter-signal path' '$ROOT/mac-app/scripts/audit.zsh'" "Radar can route to Blindspots, Blindspots can become tracked ideas, and Ideas has direct capture"
evidence "Manual visual certification plan" "grep -q '^visual-review-plan:' '$ROOT/Makefile' && grep -q 'Terminal Brain Visual Review Plan' '$ROOT/mac-app/scripts/visual-review-plan.zsh' && grep -q 'Use Now opens first' '$ROOT/mac-app/scripts/visual-review-plan.zsh'" "non-launching checklist for the remaining visual review gap"
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
