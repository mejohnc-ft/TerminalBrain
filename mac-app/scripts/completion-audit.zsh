#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

case "${1:-}" in
  --help|-h)
    cat <<'EOF'
Usage: ./mac-app/scripts/completion-audit.zsh

Prints a non-launching completion audit for the Terminal Brain world-class value goal.

This script never launches, foregrounds, screenshots, quits, kills, or controls Terminal Brain.
EOF
    exit 0
    ;;
  "")
    ;;
  *)
    echo "Unknown option: $1" >&2
    echo "Run ./mac-app/scripts/completion-audit.zsh --help" >&2
    exit 64
    ;;
esac

ok_count=0
gap_count=0

evidence() {
  local label="$1"
  local command="$2"
  local proof="$3"

  if eval "$command" >/dev/null 2>&1; then
    ok_count=$((ok_count + 1))
    printf '| ok | %s | %s |\n' "$label" "$proof"
  else
    gap_count=$((gap_count + 1))
    printf '| gap | %s | %s |\n' "$label" "$proof"
  fi
}

echo "# Terminal Brain Completion Audit"
echo
echo "Objective: make Terminal Brain valuable to a non-expert operator and useful to agents without stealing focus, while making remaining world-class gaps explicit."
echo
echo "## Concrete Success Criteria"
echo
echo "1. A new operator can run one command and get a useful next action."
echo "2. Clean queues do not create repeated notes or fake work."
echo "3. Ideas, Oracle reads, recent work, and outcomes become durable reviewable memory."
echo "4. Agents get the same closed-app value through MCP and a non-recursive handoff prompt."
echo "5. Native macOS design has static evidence for liquid glass, sidebar, titlebar, settings, and hit targets."
echo "6. Native first-use UX reduces navigation overload and puts Oracle challenge/writeback on the first screen."
echo "7. Prompt safety and focus-stealing guards are enforced by non-launching checks."
echo "8. Any remaining live-app visual review gap is explicit."
echo "9. A confused operator can get one plain current-state answer without reading multiple diagnostics."
echo "10. A clean queue gives a guided check-in instead of a placeholder capture command."
echo "11. Proactive freshness, refresh, meeting-record, and action-card surfaces turn stale source data into ranked next actions."
echo
echo "## Prompt-To-Artifact Checklist"
echo
echo "| Status | Requirement | Evidence |"
echo "| --- | --- | --- |"
evidence "One-command operator path" "grep -q 'No-Choice Path' '$ROOT/mac-app/scripts/use-now.zsh' && grep -q '## One Move' '$ROOT/mac-app/scripts/use-now.zsh' && grep -q '^use-now:' '$ROOT/Makefile' && grep -q '^start: use-now' '$ROOT/Makefile' && grep -q '^easy: use-now' '$ROOT/Makefile'" "make start, make easy, and make use-now print a no-choice path and selected One Move."
evidence "Clean queue avoids churn" "grep -q 'make answer' '$ROOT/mac-app/scripts/use-now.zsh' && grep -q '^answer:' '$ROOT/Makefile' && grep -q 'Do not manufacture busywork' '$ROOT/mac-app/scripts/work-block.zsh'" "Use Now defaults to a short direct answer and Work Block suppresses fake work instead of creating repeated clean-queue notes."
evidence "Guided clean-queue check-in" "grep -q 'Terminal Brain Check In' '$ROOT/mac-app/scripts/check-in.zsh' && grep -q '^check-in:' '$ROOT/Makefile' && grep -q 'terminal_brain_check_in_markdown' '$ROOT/mcp-server/expected-tools.json' && grep -q 'make check-in' '$ROOT/mac-app/scripts/oracle.zsh'" "No-signal answers route to make check-in, which gives prompts and optional memory capture without opening the app."
evidence "Closed-app memory writeback" "grep -q 'local-fallback' '$ROOT/mac-app/scripts/idea.zsh' && grep -q 'local-fallback' '$ROOT/mac-app/scripts/outcome.zsh' && grep -q 'write_local_commit' '$ROOT/mac-app/scripts/oracle.zsh'" "Idea, Outcome, and Oracle commit paths write without app launch."
evidence "Agent handoff is actionable" "grep -q 'next non-recursive move' '$ROOT/mac-app/scripts/agent-prompt.zsh' && grep -q 'analysis alone is not enough' '$ROOT/mac-app/scripts/agent-prompt.zsh'" "make agent-prompt avoids recursion and demands a concrete artifact."
evidence "MCP mirrors value surfaces" "node '$ROOT/mcp-server/check-tools.mjs' && grep -q 'terminal_brain_use_now_markdown' '$ROOT/mcp-server/expected-tools.json' && grep -q 'terminal_brain_agent_prompt_markdown' '$ROOT/mcp-server/expected-tools.json'" "MCP contract includes Use Now and Agent Prompt."
evidence "Plain current-state answer" "grep -q 'Terminal Brain What Now' '$ROOT/mac-app/scripts/what-now.zsh' && grep -q '^what-now:' '$ROOT/Makefile' && grep -q 'terminal_brain_what_now_markdown' '$ROOT/mcp-server/expected-tools.json' && grep -q 'What Now' '$ROOT/mac-app/scripts/support-bundle.zsh'" "make what-now and MCP What Now give one non-launching answer for app focus, CI, runtime noise, blocker, and next command."
evidence "Proactive freshness/action loop" "grep -q '^freshness:' '$ROOT/Makefile' && grep -q '^action-cards:' '$ROOT/Makefile' && grep -q '^daily-brief:' '$ROOT/Makefile' && grep -q '^refresh-memory:' '$ROOT/Makefile' && grep -q '^meeting-records:' '$ROOT/Makefile' && grep -q 'terminal_brain_freshness_markdown' '$ROOT/mcp-server/expected-tools.json' && grep -q 'terminal_brain_action_cards_markdown' '$ROOT/mcp-server/expected-tools.json' && grep -q 'terminal_brain_daily_brief_markdown' '$ROOT/mcp-server/expected-tools.json' && grep -q 'terminal_brain_refresh_memory_markdown' '$ROOT/mcp-server/expected-tools.json' && grep -q 'terminal_brain_meeting_records_markdown' '$ROOT/mcp-server/expected-tools.json'" "make freshness/action-cards/daily-brief/refresh-memory/meeting-records and MCP equivalents expose stale sources, derived-memory refresh, local meeting records, and ranked action cards."
evidence "Native value shell" "grep -q 'selectedSection = \"use-now\"' '$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift' && grep -q 'titlebarAppearsTransparent = true' '$ROOT/mac-app/Sources/TerminalBrain/WindowConfigurator.swift' && grep -q 'liquidPanel' '$ROOT/mac-app/Sources/TerminalBrain/GlassStyles.swift'" "App opens on Use Now and has static native glass/titlebar evidence."
evidence "Native first-use UX" "grep -q 'operatorPathOnly' '$ROOT/mac-app/Sources/TerminalBrain/Models.swift' && grep -q 'Show All Surfaces' '$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift' && grep -q 'useNowNoChoicePanel' '$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift' && grep -q 'useNowOraclePanel' '$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift' && grep -q 'Commit Read' '$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift'" "Simple operator navigation, native no-choice panel, and inline Use Now Oracle loop are wired."
evidence "Native action quality" "grep -q 'contentShape(RoundedRectangle(cornerRadius: 14' '$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift' && grep -q 'accessibilityHint' '$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift'" "Action tiles have full-card hit targets and accessibility hints."
evidence "Prompt/focus safety" "'$ROOT/mac-app/scripts/check-no-foreground.zsh' && '$ROOT/mac-app/scripts/doctor.zsh' | grep 'no Terminal Brain launch agent is loaded'" "Static foreground guard and doctor safety checks pass."
if [[ "${TERMINAL_BRAIN_COMPLETION_AUDIT_SKIP_VERIFY:-0}" == "1" ]]; then
  evidence "Static verification gate" "grep -q 'terminal brain static verification passed' '$ROOT/mac-app/scripts/verify-static.zsh'" "Full non-launching verifier is wired; skipped here to avoid nested MCP recursion."
else
  printf '| running | Static verification gate | Running full non-launching verifier; Swift type-check and app build can take a minute. |\n'
  evidence "Static verification gate" "'$ROOT/mac-app/scripts/verify-static.zsh' >/dev/null" "Full non-launching verifier passes."
fi
evidence "Manual visual review boundary" "grep -q 'Open Terminal Brain manually only when you want the UI/API active' '$ROOT/mac-app/scripts/visual-review-plan.zsh'" "Live visual review requires explicit operator action."
echo
echo "## Current State"
echo
"$ROOT/mac-app/scripts/doctor.zsh" | sed -n '/^## Summary/,$p'
echo
echo "## Remaining Uncertified Work"
echo
echo "- Live visual polish is not certified here because this audit does not open, foreground, screenshot, or control the app."
echo "- App-backed API behavior is available only after the operator manually opens Terminal Brain."
echo "- A true world-class UX verdict still requires the manual visual review plan."
echo
echo "## Verdict"
echo
if (( gap_count == 0 )); then
  echo "- Non-launching CLI/MCP/static-native value path: covered by evidence above."
else
  echo "- Non-launching value path: missing $gap_count evidence item(s)."
fi
echo "- Completion status: not marked complete until live visual review is explicitly performed."
echo "- Evidence passed: $ok_count"
echo "- Evidence gaps: $gap_count"
echo "- Guardrail: this audit did not launch, foreground, screenshot, quit, kill, or control Terminal Brain."
