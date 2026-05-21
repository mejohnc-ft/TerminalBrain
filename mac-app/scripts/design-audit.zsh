#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

case "${1:-}" in
  --help|-h)
    cat <<'EOF'
Usage: ./mac-app/scripts/design-audit.zsh

Runs a non-launching static audit of Terminal Brain's native macOS design shell:
  - transparent titlebar / full-size content configuration
  - liquid glass panel primitives and reduce-glass setting
  - true NavigationSplitView sidebar and profile/settings menu
  - theme controls and native Settings scene
  - high-value command palette and Memory/Oracle action surfaces

This script never launches, foregrounds, quits, kills, screenshots, or controls Terminal Brain.
EOF
    exit 0
    ;;
  "")
    ;;
  *)
    echo "Unknown option: $1" >&2
    echo "Run ./mac-app/scripts/design-audit.zsh --help" >&2
    exit 64
    ;;
esac

ok_count=0
warn_count=0

ok() {
  ok_count=$((ok_count + 1))
  printf 'ok   %s\n' "$1"
}

warn() {
  warn_count=$((warn_count + 1))
  printf 'warn %s\n' "$1"
}

require_evidence() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if grep -qE "$pattern" "$file"; then
    ok "$label"
  else
    warn "$label"
    printf '     missing pattern %s in %s\n' "$pattern" "$file"
  fi
}

echo "# Terminal Brain Design Audit"
echo
echo "Checked: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo

echo "## Native Shell"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/TerminalBrainApp.swift" 'windowStyle\(\.titleBar\)' "native titlebar window style"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/WindowConfigurator.swift" 'titlebarAppearsTransparent = true' "transparent titlebar"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/WindowConfigurator.swift" 'fullSizeContentView' "full-size content view"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/WindowConfigurator.swift" 'toolbarStyle = \.unified' "unified toolbar"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/WindowConfigurator.swift" 'isMovableByWindowBackground = true' "background window dragging"
echo

echo "## Liquid Glass"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/GlassStyles.swift" 'liquidPanel' "liquid panel primitive"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/GlassStyles.swift" 'ultraThinMaterial' "material-backed glass"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/GlassStyles.swift" 'reduceGlass' "reduce-glass fallback"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/SettingsView.swift" 'Reduce glass effects' "settings reduce-glass toggle"
echo

echo "## Sidebar And Navigation"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift" 'NavigationSplitView' "native split-view shell"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift" 'private var sidebar' "dedicated sidebar"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift" 'profileMenu' "sidebar profile menu"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift" 'toolbarProfileMenu' "toolbar profile menu"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift" 'SettingsLink' "settings menu link"
echo

echo "## Themes And Surfaces"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/Models.swift" 'enum AppTheme' "theme model"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/SettingsView.swift" 'Picker\("Theme"' "settings theme picker"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift" 'CommandPalette' "command palette"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift" 'Promote Recent Work' "recent-work action in command palette"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift" 'Promote Work' "recent-work action on Memory surface"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift" 'Ask Terminal Brain' "Oracle interaction surface"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift" 'contentShape\(RoundedRectangle\(cornerRadius: 14' "full-card action hit targets"
require_evidence "$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift" 'accessibilityHint' "action card accessibility hints"
echo

echo "## Remaining Visual Gap"
echo "- Static design evidence is present, but screenshot-level polish still requires explicit permission to open the app."
echo "- Guardrail: this audit did not launch, foreground, screenshot, quit, kill, or control Terminal Brain."
echo
echo "## Summary"
echo "- ok: $ok_count"
echo "- warnings: $warn_count"
