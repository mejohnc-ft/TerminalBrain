#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

case "${1:-}" in
  --help|-h)
    cat <<'EOF'
Usage: ./mac-app/scripts/verify-static.zsh

Runs non-launching local QA:
  - shell script syntax
  - MCP server syntax
  - Swift typecheck
  - macOS app build
  - misleading static UI copy guard
  - value surface regression guard
  - secret pattern scan

This script never launches or foregrounds Terminal Brain.
EOF
    exit 0
    ;;
  "")
    ;;
  *)
    echo "Unknown option: $1" >&2
    echo "Run ./mac-app/scripts/verify-static.zsh --help" >&2
    exit 64
    ;;
esac

zsh -n "$ROOT"/mac-app/scripts/*.zsh
for script in \
  "$ROOT/mac-app/scripts/oracle.zsh" \
  "$ROOT/mac-app/scripts/outcome.zsh" \
  "$ROOT/mac-app/scripts/snapshot.zsh" \
  "$ROOT/mac-app/scripts/now.zsh" \
  "$ROOT/mac-app/scripts/status.zsh" \
  "$ROOT/mac-app/scripts/processes.zsh" \
  "$ROOT/mac-app/scripts/cleanup-plan.zsh" \
  "$ROOT/mac-app/scripts/support-bundle.zsh" \
  "$ROOT/mac-app/scripts/next.zsh" \
  "$ROOT/mac-app/scripts/value.zsh" \
  "$ROOT/mac-app/scripts/doctor.zsh" \
  "$ROOT/mac-app/scripts/audit.zsh" \
  "$ROOT/mac-app/scripts/handoff.zsh" \
  "$ROOT/mac-app/scripts/install-app.zsh" \
  "$ROOT/mac-app/scripts/verify-live.zsh"; do
  "$script" --help >/dev/null
done
"$ROOT/mac-app/scripts/check-api-routes.zsh"
"$ROOT/mac-app/scripts/check-no-foreground.zsh"
"$ROOT/mac-app/scripts/check-ui-copy.zsh"
"$ROOT/mac-app/scripts/check-value-surfaces.zsh"
"$ROOT/mac-app/scripts/check-entrypoints.zsh"
node --check "$ROOT/mcp-server/server.mjs" >/dev/null
node --check "$ROOT/mcp-server/check-tools.mjs" >/dev/null
node "$ROOT/mcp-server/check-tools.mjs"
swiftc \
  -framework SwiftUI \
  -framework AppKit \
  -framework Network \
  -framework AppIntents \
  -typecheck "$ROOT"/mac-app/Sources/TerminalBrain/*.swift
"$ROOT/mac-app/scripts/build-app.zsh" >/dev/null

! grep -RInE '(gho_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9]{20,}|BEGIN [A-Z ]*PRIVATE KEY|api[_-]?key[[:space:]]*[=:]|password[[:space:]]*[=:]|bearer[[:space:]]+[A-Za-z0-9._-]{20,})' \
  --exclude-dir=.git \
  --exclude-dir=build \
  --exclude-dir=node_modules \
  --exclude=ci.yml \
  "$ROOT" >/dev/null

echo "terminal brain static verification passed"
