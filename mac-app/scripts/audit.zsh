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
  - native macOS design shell evidence
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
require_evidence "$ROOT/Makefile" '^first-minute:' "make first-minute"
require_evidence "$ROOT/Makefile" '^demo:' "make demo"
require_evidence "$ROOT/Makefile" '^playbook:' "make playbook"
require_evidence "$ROOT/Makefile" '^value-audit:' "make value-audit"
require_evidence "$ROOT/Makefile" '^design-audit:' "make design-audit"
require_evidence "$ROOT/Makefile" '^prove-value:' "make prove-value"
require_evidence "$ROOT/Makefile" '^now:' "make now"
require_evidence "$ROOT/Makefile" '^sources:' "make sources"
require_evidence "$ROOT/Makefile" '^memory:' "make memory"
require_evidence "$ROOT/Makefile" '^memory-promote:' "make memory-promote"
require_evidence "$ROOT/Makefile" '^recent-work:' "make recent-work"
require_evidence "$ROOT/Makefile" '^agent-prompt:' "make agent-prompt"
require_evidence "$ROOT/Makefile" '^work-block:' "make work-block"
require_evidence "$ROOT/Makefile" '^next:' "make next"
require_evidence "$ROOT/Makefile" '^doctor:' "make doctor"
require_evidence "$ROOT/mac-app/scripts/snapshot.zsh" 'local_start_here' "closed-app Start Here fallback"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift" 'selectedSection = "work-block"' "native app opens on Work Block"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift" 'Text\("Learn"\)' "native sidebar Learn group"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift" 'Text\("Signals"\)' "native sidebar Signals group"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift" 'workBlockView' "native Work Block value surface"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift" 'Top Review Action' "native Work Block direct review actions"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift" 'focusIdeaCapturePanel\(focus\)' "native Work Block capture thought"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift" 'firstMinuteView' "native First Minute value surface"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift" 'demoView' "native Demo value surface"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift" 'playbookView' "native Playbook value surface"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift" 'valueAuditView' "native Value Audit surface"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift" 'memoryBriefView' "native Memory Brief surface"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift" 'Promote' "native Memory Promote action"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift" 'focusIdeaCapturePanel\(focus\)' "native First Minute capture thought"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift" 'Open First Minute' "command palette can open First Minute"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift" 'Open Work Block' "command palette can open Work Block"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift" 'Open Memory' "command palette can open Memory"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift" 'Open Value Now' "command palette can open Value Now"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift" 'Open Now' "command palette can open Now"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift" 'Promote Recent Work' "command palette can promote Recent Work"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/LocalControlServer.swift" '"/now/markdown"' "Now API artifact"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/LocalControlServer.swift" '"/now"' "Now JSON API"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/LocalControlServer.swift" '"/sources/markdown"' "Source Inventory API artifact"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/LocalControlServer.swift" '"/memory/markdown"' "Memory Brief API artifact"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/LocalControlServer.swift" '"/memory/promote"' "Memory Promote API artifact"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/LocalControlServer.swift" '"/recent-work/promote"' "Recent Work Promote API artifact"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/LocalControlServer.swift" '"/first-minute/markdown"' "First Minute API artifact"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/LocalControlServer.swift" '"/demo/markdown"' "Demo API artifact"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/LocalControlServer.swift" '"/playbook/markdown"' "Playbook API artifact"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/LocalControlServer.swift" '"/value-audit/markdown"' "Value Audit API artifact"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/LocalControlServer.swift" '"/cleanup-plan/markdown"' "Cleanup Plan API artifact"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/LocalControlServer.swift" '"/process-map/markdown"' "Process Map API artifact"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/LocalControlServer.swift" '"/support-bundle/markdown"' "Support Bundle API artifact"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/LocalControlServer.swift" '"/work-block/markdown"' "Work Block API artifact"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/LocalControlServer.swift" '"/value-proof/markdown"' "Value Proof API artifact"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/LocalControlServer.swift" '"/oracle/brief/markdown"' "Oracle Brief API artifact"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/AppShortcuts.swift" 'CopyNowIntent' "Copy Now shortcut"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/AppShortcuts.swift" 'CopyFirstMinuteIntent' "Copy First Minute shortcut"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/AppShortcuts.swift" 'CopyDemoIntent' "Copy Demo shortcut"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/AppShortcuts.swift" 'CopyPlaybookIntent' "Copy Playbook shortcut"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/AppShortcuts.swift" 'CopyValueAuditIntent' "Copy Value Audit shortcut"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/AppShortcuts.swift" 'CopyOracleBriefIntent' "Copy Oracle Brief shortcut"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/AppShortcuts.swift" 'CopyCleanupPlanIntent' "Copy Cleanup Plan shortcut"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/AppShortcuts.swift" 'CopyProcessMapIntent' "Copy Process Map shortcut"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/AppShortcuts.swift" 'CopySupportBundleIntent' "Copy Support Bundle shortcut"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/AppShortcuts.swift" 'CopyWorkBlockIntent' "Copy Work Block shortcut"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/AppShortcuts.swift" 'CopySourceInventoryIntent' "Copy Source Inventory shortcut"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/AppShortcuts.swift" 'CopyMemoryBriefIntent' "Copy Memory Brief shortcut"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/AppShortcuts.swift" 'CopyValueProofIntent' "Copy Value Proof shortcut"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/BrainStatusModel.swift" 'func promoteMemoryLead' "native Memory Promote write action"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/BrainStatusModel.swift" 'func promoteRecentWork' "native Recent Work Promote write action"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift" 'Commit Outcome' "native outcome close loop"
require_evidence "$ROOT/mac-app/scripts/idea.zsh" 'local-fallback' "closed-app idea capture fallback"
require_evidence "$ROOT/mac-app/scripts/review.zsh" 'Terminal Brain Review Queue' "closed-app review queue"
require_evidence "$ROOT/mac-app/scripts/review.zsh" 'make review-status' "review queue action commands"
require_evidence "$ROOT/mac-app/scripts/review-status.zsh" 'reviewStatus' "closed-app review status"
require_evidence "$ROOT/mac-app/scripts/sources.zsh" 'Codex local history' "closed-app Codex source inventory"
require_evidence "$ROOT/mac-app/scripts/sources.zsh" 'Claude local history' "closed-app Claude source inventory"
require_evidence "$ROOT/mac-app/scripts/sources.zsh" 'does not dump raw transcript content' "closed-app raw transcript guardrail"
require_evidence "$ROOT/mac-app/scripts/memory.zsh" 'Continuity Leads' "closed-app memory continuity leads"
require_evidence "$ROOT/mac-app/scripts/memory.zsh" 'Promote If Useful' "closed-app memory promotion commands"
require_evidence "$ROOT/mac-app/scripts/memory.zsh" 'does not dump raw Codex or Claude transcript bodies' "closed-app memory raw transcript guardrail"
require_evidence "$ROOT/mac-app/scripts/memory-promote.zsh" 'idea.zsh' "closed-app memory promote write path"
require_evidence "$ROOT/mac-app/scripts/memory-promote.zsh" 'derived summaries only' "closed-app memory promote raw transcript guardrail"
require_evidence "$ROOT/mac-app/scripts/bubble-up.zsh" 'What You May Not Be Considering' "closed-app Bubble Up"
require_evidence "$ROOT/mac-app/scripts/bubble-up.zsh" 'Prime The Brain' "closed-app actionable empty state"
require_evidence "$ROOT/mac-app/scripts/bubble-up.zsh" 'Recent Work Signals' "closed-app recent work fallback"
require_evidence "$ROOT/mac-app/scripts/bubble-up.zsh" 'Completed Evidence' "closed-app completed evidence lane"
require_evidence "$ROOT/mac-app/scripts/recent-work.zsh" 'Terminal Brain Recent Work' "closed-app recent work promotion"
require_evidence "$ROOT/mac-app/scripts/bubble-up.zsh" 'Decision pressure' "closed-app starter capture prompts"
require_evidence "$ROOT/mac-app/scripts/work-block.zsh" 'Terminal Brain Work Block' "closed-app Work Block"
require_evidence "$ROOT/mac-app/scripts/work-block.zsh" 'Prime The Brain' "closed-app Work Block empty-state guidance"
require_evidence "$ROOT/mac-app/scripts/work-block.zsh" 'Next Clean Move' "closed-app Work Block no-open-item guidance"
require_evidence "$ROOT/mac-app/scripts/oracle.zsh" 'local-fallback' "closed-app Oracle Ask fallback"
require_evidence "$ROOT/mac-app/scripts/oracle.zsh" 'write_local_commit' "closed-app Oracle Ask commit fallback"
require_evidence "$ROOT/mac-app/scripts/outcome.zsh" 'local-fallback' "closed-app outcome writeback fallback"
require_evidence "$ROOT/mac-app/scripts/demo.zsh" 'Seeded Scenario' "closed-app temporary demo"
require_evidence "$ROOT/mac-app/scripts/playbook.zsh" 'Pick The Situation' "closed-app operator playbook"
require_evidence "$ROOT/mac-app/scripts/value-audit.zsh" 'Prompt-To-Artifact Checklist' "closed-app value audit"
echo

echo "## Native Mac Design Shell"
echo
require_evidence "$ROOT/mac-app/scripts/design-audit.zsh" 'Terminal Brain Design Audit' "closed-app design audit"
require_evidence "$ROOT/mac-app/scripts/design-audit.zsh" 'Liquid Glass' "liquid glass design evidence"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/WindowConfigurator.swift" 'titlebarAppearsTransparent = true' "transparent native titlebar"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/WindowConfigurator.swift" 'fullSizeContentView' "full-size content window"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/GlassStyles.swift" 'ultraThinMaterial' "material-backed glass primitives"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift" 'NavigationSplitView' "native split-view navigation"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift" 'profileMenu' "profile menu"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/SettingsView.swift" 'Picker\("Theme"' "theme settings"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/SettingsView.swift" 'Reduce glass effects' "reduce-glass accessibility setting"
require_evidence "$ROOT/mac-app/scripts/check-entrypoints.zsh" 'design-audit.zsh' "design audit regression"
echo

echo "## Agent Surfaces"
echo
echo "ok   MCP tool contract count: ${tool_count:-unknown}"
require_evidence "$ROOT/mcp-server/server.mjs" 'terminal_brain_value_now_markdown' "MCP Value Now"
require_evidence "$ROOT/mcp-server/server.mjs" 'terminal_brain_first_minute_markdown' "MCP First Minute"
require_evidence "$ROOT/mcp-server/server.mjs" 'terminal_brain_value_proof_markdown' "MCP Value Proof"
require_evidence "$ROOT/mcp-server/server.mjs" 'terminal_brain_demo_markdown' "MCP Demo"
require_evidence "$ROOT/mcp-server/server.mjs" 'terminal_brain_playbook_markdown' "MCP Playbook"
require_evidence "$ROOT/mcp-server/server.mjs" 'terminal_brain_value_audit_markdown' "MCP Value Audit"
require_evidence "$ROOT/mcp-server/server.mjs" 'terminal_brain_now_markdown' "MCP Now"
require_evidence "$ROOT/mcp-server/server.mjs" 'terminal_brain_now' "MCP Now Structured"
require_evidence "$ROOT/mcp-server/server.mjs" 'terminal_brain_sources_markdown' "MCP Source Inventory"
require_evidence "$ROOT/mcp-server/server.mjs" 'terminal_brain_memory_brief_markdown' "MCP Memory Brief"
require_evidence "$ROOT/mcp-server/server.mjs" 'terminal_brain_memory_promote' "MCP Memory Promote"
require_evidence "$ROOT/mcp-server/server.mjs" 'terminal_brain_recent_work_promote' "MCP Recent Work Promote"
require_evidence "$ROOT/mcp-server/server.mjs" 'terminal_brain_next_markdown' "MCP Next"
require_evidence "$ROOT/mcp-server/server.mjs" 'terminal_brain_oracle_brief_markdown' "MCP Oracle Brief"
require_evidence "$ROOT/mcp-server/server.mjs" 'startHereMarkdown' "MCP Start Here fallback"
require_evidence "$ROOT/mcp-server/server.mjs" 'agentPromptMarkdown' "MCP Agent Prompt fallback"
require_evidence "$ROOT/mcp-server/server.mjs" 'terminal_brain_process_map_markdown' "MCP Process Map"
require_evidence "$ROOT/mcp-server/server.mjs" 'terminal_brain_cleanup_plan_markdown' "MCP Cleanup Plan"
require_evidence "$ROOT/mcp-server/server.mjs" 'terminal_brain_support_bundle_markdown' "MCP Support Bundle"
require_evidence "$ROOT/mcp-server/server.mjs" 'handoffMarkdown' "MCP Handoff fallback"
require_evidence "$ROOT/mcp-server/server.mjs" 'localSnapshotMarkdown' "MCP Snapshot Markdown fallback"
require_evidence "$ROOT/mcp-server/server.mjs" 'localSnapshot' "MCP Snapshot fallback"
require_evidence "$ROOT/mcp-server/server.mjs" 'app-api-unreachable' "MCP Status fallback"
require_evidence "$ROOT/mcp-server/server.mjs" 'terminal_brain_doctor_markdown' "MCP Doctor"
require_evidence "$ROOT/mcp-server/server.mjs" 'terminal_brain_audit_markdown' "MCP Audit"
require_evidence "$ROOT/mcp-server/server.mjs" 'terminal_brain_runtime_status' "MCP Runtime Status"
require_evidence "$ROOT/mcp-server/server.mjs" 'terminal_brain_commit_outcome' "MCP Outcome Commit"
require_evidence "$ROOT/mcp-server/server.mjs" 'oracleAskMarkdown' "MCP Oracle Ask fallback"
require_evidence "$ROOT/mcp-server/server.mjs" 'localOracleCommit' "MCP Oracle Commit fallback"
require_evidence "$ROOT/mcp-server/server.mjs" 'localOutcomeCommit' "MCP Outcome Commit fallback"
require_evidence "$ROOT/mcp-server/server.mjs" 'captureIdea' "MCP Idea Capture fallback"
require_evidence "$ROOT/mcp-server/server.mjs" 'terminal_brain_review_queue_markdown' "MCP Review Queue"
require_evidence "$ROOT/mcp-server/server.mjs" 'setReviewStatus' "MCP Review Status fallback"
require_evidence "$ROOT/mcp-server/server.mjs" 'terminal_brain_bubble_up_markdown' "MCP Bubble Up"
require_evidence "$ROOT/mcp-server/server.mjs" 'terminal_brain_work_block_markdown' "MCP Work Block"
echo

echo "## Safety And Reliability"
echo
require_evidence "$ROOT/mac-app/scripts/check-no-foreground.zsh" 'Foreground app launch|AppleScript|automation is not allowed' "foreground guard"
require_evidence "$ROOT/mac-app/scripts/processes.zsh" 'This command did not launch, foreground, quit, kill, or control anything' "process map guard"
require_evidence "$ROOT/mac-app/scripts/cleanup-plan.zsh" 'This command did not launch, foreground, quit, kill, or control anything' "cleanup plan guard"
require_evidence "$ROOT/mac-app/scripts/support-bundle.zsh" 'did not launch, foreground, quit, kill, or control anything' "support bundle guard"
require_evidence "$ROOT/mac-app/scripts/handoff.zsh" 'local closed-app handoff' "handoff closed-app fallback"
require_evidence "$ROOT/mac-app/scripts/doctor.zsh" 'Prompt Safety' "prompt safety doctor section"
require_evidence "$ROOT/mac-app/scripts/doctor.zsh" 'Runtime Noise' "runtime noise doctor section"
require_evidence "$ROOT/mac-app/scripts/doctor.zsh" 'legacy local-brain/terminal-brain MCP auto-start entries' "legacy MCP auto-start guard"
require_evidence "$ROOT/mac-app/scripts/doctor.zsh" 'duplicate Terminal Brain MCP/kernel Node children detected' "duplicate MCP/kernel process warning"
require_evidence "$ROOT/mac-app/scripts/doctor.zsh" 'installed app executable matches current build' "installed app freshness"
require_evidence "$ROOT/mac-app/scripts/check-entrypoints.zsh" 'terminal_brain_value_now_markdown' "closed-API entrypoint regression"
require_evidence "$ROOT/mac-app/scripts/check-entrypoints.zsh" 'terminal_brain_capture_idea' "closed idea fallback regression"
require_evidence "$ROOT/mac-app/scripts/check-entrypoints.zsh" 'terminal_brain_review_queue_markdown' "closed review queue regression"
require_evidence "$ROOT/mac-app/scripts/check-entrypoints.zsh" 'terminal_brain_oracle_review_status' "closed review status regression"
require_evidence "$ROOT/mac-app/scripts/check-entrypoints.zsh" 'terminal_brain_bubble_up_markdown' "closed Bubble Up regression"
require_evidence "$ROOT/mac-app/scripts/check-entrypoints.zsh" 'terminal_brain_work_block_markdown' "closed Work Block regression"
require_evidence "$ROOT/mac-app/scripts/check-entrypoints.zsh" 'memory-promote.zsh.*--dry-run' "closed memory promote dry-run regression"
require_evidence "$ROOT/mac-app/scripts/check-entrypoints.zsh" 'terminal_brain_memory_promote' "MCP memory promote regression"
require_evidence "$ROOT/mac-app/scripts/check-entrypoints.zsh" 'terminal_brain_recent_work_promote' "MCP recent work promote regression"
require_evidence "$ROOT/mac-app/scripts/check-entrypoints.zsh" 'terminal_brain_first_minute_markdown' "MCP first minute regression"
require_evidence "$ROOT/mac-app/scripts/check-entrypoints.zsh" 'terminal_brain_value_proof_markdown' "MCP value proof regression"
require_evidence "$ROOT/mac-app/scripts/check-entrypoints.zsh" 'terminal_brain_demo_markdown' "MCP demo regression"
require_evidence "$ROOT/mac-app/scripts/check-entrypoints.zsh" 'terminal_brain_playbook_markdown' "MCP playbook regression"
require_evidence "$ROOT/mac-app/scripts/check-entrypoints.zsh" 'terminal_brain_value_audit_markdown' "MCP value audit regression"
require_evidence "$ROOT/mac-app/scripts/check-entrypoints.zsh" 'reviewStatus":"accepted' "closed outcome fallback regression"
require_evidence "$ROOT/mac-app/scripts/check-entrypoints.zsh" 'Terminal Brain Value Proof' "value proof regression"
require_evidence "$ROOT/mac-app/scripts/verify-static.zsh" 'check-entrypoints.zsh' "entrypoint guard in static verifier"
echo

echo "## Non-Launching Commands"
echo
echo "- make now"
echo "- make sources"
echo "- make memory"
echo "- make memory-promote"
echo "- make recent-work"
echo "- make first-minute"
echo "- make demo"
echo "- make playbook"
echo "- make value-audit"
echo "- make design-audit"
echo "- make value"
echo "- make prove-value"
echo "- make idea"
echo "- make review"
echo "- make review-status"
echo "- make bubble-up"
echo "- make work-block"
echo "- make oracle-brief"
echo "- make agent-prompt"
echo "- make next"
echo "- make doctor"
echo "- make audit"
echo "- make status"
echo "- make processes"
echo "- make cleanup-plan"
echo "- make support-bundle"
echo "- make verify"
echo
echo "Guardrail: audit did not launch or foreground Terminal Brain."

if (( missing_count > 0 )); then
  echo
  echo "Audit failed: $missing_count required evidence item(s) missing." >&2
  exit 1
fi
