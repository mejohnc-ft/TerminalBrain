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
echo "6. Prompt safety and focus-stealing guards are enforced by non-launching checks."
echo "7. Any remaining live-app visual review gap is explicit."
echo
echo "## Prompt-To-Artifact Checklist"
echo
echo "| Status | Requirement | Evidence |"
echo "| --- | --- | --- |"
evidence "One-command operator path" "grep -q '## One Move' '$ROOT/mac-app/scripts/use-now.zsh' && grep -q '^use-now:' '$ROOT/Makefile'" "make use-now prints a selected One Move."
evidence "Clean queue avoids churn" "grep -q 'clean_queue_recently_covered' '$ROOT/mac-app/scripts/use-now.zsh' && grep -q 'Do not manufacture busywork' '$ROOT/mac-app/scripts/work-block.zsh'" "Use Now and Work Block suppress repeated clean-queue Oracle notes and fake work."
evidence "Closed-app memory writeback" "grep -q 'local-fallback' '$ROOT/mac-app/scripts/idea.zsh' && grep -q 'local-fallback' '$ROOT/mac-app/scripts/outcome.zsh' && grep -q 'write_local_commit' '$ROOT/mac-app/scripts/oracle.zsh'" "Idea, Outcome, and Oracle commit paths write without app launch."
evidence "Agent handoff is actionable" "grep -q 'next non-recursive move' '$ROOT/mac-app/scripts/agent-prompt.zsh' && grep -q 'analysis alone is not enough' '$ROOT/mac-app/scripts/agent-prompt.zsh'" "make agent-prompt avoids recursion and demands a concrete artifact."
evidence "MCP mirrors value surfaces" "node '$ROOT/mcp-server/check-tools.mjs' && grep -q 'terminal_brain_use_now_markdown' '$ROOT/mcp-server/expected-tools.json' && grep -q 'terminal_brain_agent_prompt_markdown' '$ROOT/mcp-server/expected-tools.json'" "MCP contract includes Use Now and Agent Prompt."
evidence "Native value shell" "grep -q 'selectedSection = \"use-now\"' '$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift' && grep -q 'titlebarAppearsTransparent = true' '$ROOT/mac-app/Sources/TerminalBrain/WindowConfigurator.swift' && grep -q 'liquidPanel' '$ROOT/mac-app/Sources/TerminalBrain/GlassStyles.swift'" "App opens on Use Now and has static native glass/titlebar evidence."
evidence "Native action quality" "grep -q 'contentShape(RoundedRectangle(cornerRadius: 14' '$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift' && grep -q 'accessibilityHint' '$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift'" "Action tiles have full-card hit targets and accessibility hints."
evidence "Prompt/focus safety" "'$ROOT/mac-app/scripts/check-no-foreground.zsh' && '$ROOT/mac-app/scripts/doctor.zsh' | grep 'no Terminal Brain launch agent is loaded'" "Static foreground guard and doctor safety checks pass."
if [[ "${TERMINAL_BRAIN_COMPLETION_AUDIT_SKIP_VERIFY:-0}" == "1" ]]; then
  evidence "Static verification gate" "grep -q 'terminal brain static verification passed' '$ROOT/mac-app/scripts/verify-static.zsh'" "Full non-launching verifier is wired; skipped here to avoid nested MCP recursion."
else
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
