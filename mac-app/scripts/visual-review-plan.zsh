#!/usr/bin/env zsh
set -euo pipefail

case "${1:-}" in
  --help|-h)
    cat <<'EOF'
Usage: ./mac-app/scripts/visual-review-plan.zsh

Prints a non-launching visual review plan for Terminal Brain.
This script never launches, foregrounds, screenshots, quits, kills, or controls the app.
EOF
    exit 0
    ;;
  "")
    ;;
  *)
    echo "Unknown option: $1" >&2
    echo "Run ./mac-app/scripts/visual-review-plan.zsh --help" >&2
    exit 64
    ;;
esac

echo "# Terminal Brain Visual Review Plan"
echo
echo "Purpose: certify the remaining world-class native UX gap only when the operator explicitly chooses to open the app."
echo
echo "## Before Opening"
echo
echo '```zsh'
echo "make doctor"
echo "make design-audit"
echo "make value-audit"
echo '```'
echo
echo "- Confirm doctor says package ready."
echo "- Confirm design-audit has no static design warnings."
echo "- Confirm value-audit has zero evidence gaps."
echo
echo "## Manual Review"
echo
echo "Open Terminal Brain manually only when you want the UI/API active. Do not use automation to open, foreground, screenshot, quit, kill, or control it."
echo
echo "Check these first-viewport items:"
echo
echo "1. Titlebar and window controls feel integrated with the content, not glued on."
echo "2. Sidebar reads as a true floating liquid-glass navigation surface."
echo "3. Simple operator navigation is the default: Use Now, Work Block, Oracle, Review, Ideas, and Start Work are visible before deeper surfaces."
echo "4. Show All Surfaces is visible as the escape hatch, and Settings can restore Simple operator navigation."
echo "5. Use Now opens first and shows one move, why that move matters, Ask, Capture, Delegate, and Close paths."
echo "6. Use Now includes the Ask, Decide, Remember panel with Missing, Cheap Test, Delegate, and Commit Read actions."
echo "7. Radar shows a Check Blindspots counter-signal path before action."
echo "8. Blindspots can become tracked ideas through Capture as Idea."
echo "9. Ideas has a direct capture lane and makes the cheap-test loop obvious."
echo "10. Buttons have comfortable hit targets and do not feel sparse or ambiguous."
echo "11. Text does not overlap, truncate badly, or resize the layout at normal and narrow widths."
echo "12. Theme, profile menu, settings, and reduce-glass controls are discoverable."
echo "13. No permissions prompts or focus-stealing relaunch behavior appears during normal viewing."
echo
echo "## Acceptance"
echo
echo "- A new operator can answer: what should I do now, why, what might I be missing, and where do I capture the follow-up."
echo "- A new operator does not need to understand the full surface map before using the app."
echo "- Every visible advisory path ends in one of: act, ask, capture, delegate, commit, or dismiss."
echo "- If any visual flaw appears, capture the note with:"
echo
echo '```zsh'
echo 'make idea TITLE="Visual review issue" IDEA="..." PROJECT="Terminal Brain"'
echo '```'
echo
echo "## After Review"
echo
echo '```zsh'
echo "make processes"
echo "make outcome TITLE=\"Visual review\" OUTCOME=\"...\" PROJECT=\"Terminal Brain\" NEXT=\"...\""
echo '```'
echo
echo "## Guardrail"
echo
echo "- This command did not launch, foreground, screenshot, quit, kill, or control Terminal Brain."
