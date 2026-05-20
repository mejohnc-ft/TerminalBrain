#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

missing=0

require_in_file() {
  local file="$1"
  local pattern="$2"
  local label="$3"

  if ! grep -qE -- "$pattern" "$file"; then
    echo "Missing value surface: $label in $file" >&2
    missing=1
  fi
}

require_in_file "$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift" 'Start Here' "Start Here app surface"
require_in_file "$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift" 'Commit Outcome' "in-app outcome close loop"
require_in_file "$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift" 'Oracle Digest' "Oracle Digest app surface"
require_in_file "$ROOT/mac-app/Sources/TerminalBrain/BrainStatusModel.swift" 'func commitOutcome' "in-app structured outcome writer"
require_in_file "$ROOT/mac-app/Sources/TerminalBrain/AppShortcuts.swift" 'CommitBrainOutcomeIntent' "Commit Outcome App Shortcut"
require_in_file "$ROOT/mac-app/Sources/TerminalBrain/AppShortcuts.swift" 'CopyStartHereIntent' "Copy Start Here App Shortcut"
require_in_file "$ROOT/mac-app/Sources/TerminalBrain/AppShortcuts.swift" 'CopyOracleDigestIntent' "Copy Oracle Digest App Shortcut"

require_in_file "$ROOT/mac-app/Sources/TerminalBrain/LocalControlServer.swift" '"/start-here/markdown"' "Start Here API route"
require_in_file "$ROOT/mac-app/Sources/TerminalBrain/LocalControlServer.swift" '"/oracle-digest/markdown"' "Oracle Digest API route"
require_in_file "$ROOT/mac-app/Sources/TerminalBrain/LocalControlServer.swift" '"/outcomes/commit"' "Outcome commit API route"
require_in_file "$ROOT/mac-app/Sources/TerminalBrain/LocalControlServer.swift" 'reviewStatus: "accepted"' "outcomes close as accepted"
require_in_file "$ROOT/mac-app/Sources/TerminalBrain/LocalControlServer.swift" 'enum StartHereSnapshot' "Start Here Markdown artifact"
require_in_file "$ROOT/mac-app/Sources/TerminalBrain/LocalControlServer.swift" 'enum OracleDigestSnapshot' "Oracle Digest artifact"

require_in_file "$ROOT/mac-app/scripts/snapshot.zsh" '--start-here' "Start Here CLI flag"
require_in_file "$ROOT/mac-app/scripts/snapshot.zsh" '--digest' "Oracle Digest CLI flag"
require_in_file "$ROOT/mac-app/scripts/outcome.zsh" '/outcomes/commit' "Outcome CLI writeback"
require_in_file "$ROOT/Makefile" '^start-here:' "Start Here Make target"
require_in_file "$ROOT/Makefile" '^outcome:' "Outcome Make target"

require_in_file "$ROOT/mcp-server/server.mjs" 'terminal_brain_start_here_markdown' "Start Here MCP tool"
require_in_file "$ROOT/mcp-server/server.mjs" 'terminal_brain_oracle_digest_markdown' "Oracle Digest MCP tool"
require_in_file "$ROOT/mcp-server/server.mjs" 'terminal_brain_commit_outcome' "Outcome MCP tool"
require_in_file "$ROOT/mcp-server/expected-tools.json" 'terminal_brain_start_here_markdown' "Start Here MCP contract"
require_in_file "$ROOT/mcp-server/expected-tools.json" 'terminal_brain_oracle_digest_markdown' "Oracle Digest MCP contract"

require_in_file "$ROOT/AGENTS.md" 'Do not use Computer Use' "UI automation guardrail"
require_in_file "$ROOT/AGENTS.md" 'terminal_brain_start_here_markdown' "agent Start Here instruction"

if [[ "$missing" != "0" ]]; then
  exit 1
fi

echo "value surfaces ok"
