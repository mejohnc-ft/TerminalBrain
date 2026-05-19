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
node --check "$ROOT/mcp-server/server.mjs" >/dev/null
node --check "$ROOT/mcp-server/check-tools.mjs" >/dev/null
node "$ROOT/mcp-server/check-tools.mjs"
swiftc -typecheck "$ROOT"/mac-app/Sources/TerminalBrain/*.swift
"$ROOT/mac-app/scripts/build-app.zsh" >/dev/null

! grep -RInE '(gho_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9]{20,}|BEGIN [A-Z ]*PRIVATE KEY|api[_-]?key[[:space:]]*[=:]|password[[:space:]]*[=:]|bearer[[:space:]]+[A-Za-z0-9._-]{20,})' \
  --exclude-dir=.git \
  --exclude-dir=build \
  --exclude-dir=node_modules \
  --exclude=ci.yml \
  "$ROOT" >/dev/null

echo "terminal brain static verification passed"
