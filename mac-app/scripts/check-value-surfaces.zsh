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
require_in_file "$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift" 'Value Now' "Value Now app surface"
require_in_file "$ROOT/mac-app/Sources/TerminalBrain/ContentView.swift" 'selectedSection = "value"' "Value Now default app section"
require_in_file "$ROOT/mac-app/Sources/TerminalBrain/TerminalBrainApp.swift" 'Copy Start Here' "Start Here menu bar/menu command"
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
require_in_file "$ROOT/mac-app/scripts/status.zsh" 'App process' "non-launching status process check"
require_in_file "$ROOT/mac-app/scripts/next.zsh" 'make start-here' "non-launching next move handoff"
require_in_file "$ROOT/mac-app/scripts/value.zsh" 'Terminal Brain Value Now' "non-launching value read"
require_in_file "$ROOT/mac-app/scripts/doctor.zsh" 'MCP tool contract valid' "non-launching doctor MCP check"
require_in_file "$ROOT/mac-app/scripts/doctor.zsh" 'Prompt Safety' "doctor prompt safety check"
require_in_file "$ROOT/mac-app/scripts/check-entrypoints.zsh" 'terminal_brain_value_now_markdown' "entrypoint fallback verifier"
require_in_file "$ROOT/Makefile" '^start-here:' "Start Here Make target"
require_in_file "$ROOT/Makefile" '^outcome:' "Outcome Make target"
require_in_file "$ROOT/Makefile" '^status:' "Status Make target"
require_in_file "$ROOT/Makefile" '^next:' "Next Make target"
require_in_file "$ROOT/Makefile" '^value:' "Value Make target"
require_in_file "$ROOT/Makefile" '^doctor:' "Doctor Make target"

require_in_file "$ROOT/mcp-server/server.mjs" 'terminal_brain_runtime_status' "Runtime Status MCP tool"
require_in_file "$ROOT/mcp-server/server.mjs" 'terminal_brain_next_markdown' "Next Move MCP tool"
require_in_file "$ROOT/mcp-server/server.mjs" 'terminal_brain_doctor_markdown' "Doctor MCP tool"
require_in_file "$ROOT/mcp-server/server.mjs" 'terminal_brain_value_now_markdown' "Value Now MCP tool"
require_in_file "$ROOT/mcp-server/server.mjs" 'terminal_brain_start_here_markdown' "Start Here MCP tool"
require_in_file "$ROOT/mcp-server/server.mjs" 'terminal_brain_oracle_digest_markdown' "Oracle Digest MCP tool"
require_in_file "$ROOT/mcp-server/server.mjs" 'terminal_brain_commit_outcome' "Outcome MCP tool"
require_in_file "$ROOT/mcp-server/expected-tools.json" 'terminal_brain_runtime_status' "Runtime Status MCP contract"
require_in_file "$ROOT/mcp-server/expected-tools.json" 'terminal_brain_next_markdown' "Next Move MCP contract"
require_in_file "$ROOT/mcp-server/expected-tools.json" 'terminal_brain_doctor_markdown' "Doctor MCP contract"
require_in_file "$ROOT/mcp-server/expected-tools.json" 'terminal_brain_value_now_markdown' "Value Now MCP contract"
require_in_file "$ROOT/mcp-server/expected-tools.json" 'terminal_brain_start_here_markdown' "Start Here MCP contract"
require_in_file "$ROOT/mcp-server/expected-tools.json" 'terminal_brain_oracle_digest_markdown' "Oracle Digest MCP contract"

require_in_file "$ROOT/AGENTS.md" 'Do not use Computer Use' "UI automation guardrail"
require_in_file "$ROOT/AGENTS.md" 'terminal_brain_value_now_markdown' "agent value instruction"
require_in_file "$ROOT/AGENTS.md" 'terminal_brain_next_markdown' "agent next move instruction"
require_in_file "$ROOT/AGENTS.md" 'terminal_brain_doctor_markdown' "agent doctor instruction"
require_in_file "$ROOT/AGENTS.md" 'terminal_brain_runtime_status' "agent runtime status instruction"
require_in_file "$ROOT/AGENTS.md" 'terminal_brain_start_here_markdown' "agent Start Here instruction"
require_in_file "$ROOT/README.md" 'START-HERE.md' "README Start Here link"
require_in_file "$ROOT/START-HERE.md" 'make value' "repo value command"
require_in_file "$ROOT/START-HERE.md" 'make next' "repo next command"
require_in_file "$ROOT/START-HERE.md" 'make status' "repo status command"
require_in_file "$ROOT/START-HERE.md" 'make outcome' "repo outcome close loop"

if [[ "$missing" != "0" ]]; then
  exit 1
fi

echo "value surfaces ok"
