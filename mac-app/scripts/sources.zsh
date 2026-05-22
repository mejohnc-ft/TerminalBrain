#!/usr/bin/env zsh
set -euo pipefail

WORKSPACE="${TERMINAL_BRAIN_WORKSPACE:-$HOME/mejohnwc}"

case "${1:-}" in
  --help|-h)
    cat <<'EOF'
Usage: ./mac-app/scripts/sources.zsh

Prints a non-launching source inventory for Terminal Brain:
  - Obsidian workspace and Oracle Inbox counts
  - Codex and Claude history store counts and sizes
  - derived agent-memory stats
  - a guarded import plan that avoids dumping raw transcripts

This script never launches, foregrounds, quits, kills, or controls Terminal Brain.
EOF
    exit 0
    ;;
  "")
    ;;
  *)
    echo "Unknown option: $1" >&2
    echo "Run ./mac-app/scripts/sources.zsh --help" >&2
    exit 64
    ;;
esac

count_files() {
  local target="$1"
  local pattern="${2:-*}"
  if [[ -d "$target" ]]; then
    find "$target" -type f -name "$pattern" 2>/dev/null | wc -l | tr -d ' '
  else
    echo "0"
  fi
}

line_count() {
  local target="$1"
  if [[ -f "$target" ]]; then
    wc -l < "$target" | tr -d ' '
  else
    echo "0"
  fi
}

size_of() {
  local target="$1"
  if [[ -e "$target" ]]; then
    du -sh "$target" 2>/dev/null | awk '{print $1}'
  else
    echo "missing"
  fi
}

json_value() {
  local target="$1"
  local key="$2"
  if [[ -f "$target" ]]; then
    ruby -rjson -e '
      path = ARGV[0]
      key = ARGV[1]
      data = JSON.parse(File.read(path)) rescue {}
      puts(data[key] || 0)
    ' "$target" "$key"
  else
    echo "0"
  fi
}

exists_label() {
  local target="$1"
  if [[ -e "$target" ]]; then
    echo "available"
  else
    echo "missing"
  fi
}

stats_json="$WORKSPACE/.brain/agent-history-stats.json"
codex_root="$HOME/.codex"
claude_root="$HOME/.claude"
claude_app="$HOME/Library/Application Support/Claude"
meeting_records_dir="${TERMINAL_BRAIN_MEETING_RECORDS_DIR:-$WORKSPACE/Meeting Records}"

obsidian_notes="$(count_files "$WORKSPACE" "*.md")"
oracle_items="$(count_files "$WORKSPACE/Oracle Inbox" "*.md")"
context_packs="$(count_files "$WORKSPACE/.brain/context-packs" "*.md")"

agent_records="$(json_value "$stats_json" "records")"
agent_sessions="$(json_value "$stats_json" "sessions")"

codex_archived="$(count_files "$codex_root/archived_sessions" "*.jsonl")"
codex_session_files="$(count_files "$codex_root/sessions" "*.jsonl")"
codex_history_lines="$(line_count "$codex_root/history.jsonl")"
codex_session_index_lines="$(line_count "$codex_root/session_index.jsonl")"
codex_ambient="$(count_files "$codex_root/ambient-suggestions" "ambient-suggestions.json")"

claude_history_lines="$(line_count "$claude_root/history.jsonl")"
claude_project_files="$(count_files "$claude_root/projects" "*.jsonl")"
claude_session_files="$(count_files "$claude_root/sessions" "*.jsonl")"
claude_todos="$(count_files "$claude_root/todos" "*")"
meeting_records="$(count_files "$meeting_records_dir" "*")"

cat <<EOF
# Terminal Brain Source Inventory

Checked: $(date '+%Y-%m-%d %H:%M:%S %Z')

## Direct Read

- Obsidian workspace: $(exists_label "$WORKSPACE"), $obsidian_notes Markdown notes, $oracle_items Oracle Inbox items.
- Derived agent memory: $agent_records records across $agent_sessions summarized Codex/Claude sessions.
- Codex local history: $(exists_label "$codex_root"), $codex_archived archived sessions, $codex_session_files active session files, $codex_history_lines history lines, $codex_session_index_lines session-index lines.
- Claude local history: $(exists_label "$claude_root"), $claude_history_lines history lines, $claude_project_files project transcript files, $claude_session_files session files.
- Claude desktop support store: $(exists_label "$claude_app"), $(size_of "$claude_app") on disk.
- Meeting records: $(exists_label "$meeting_records_dir"), $meeting_records local transcript/recording file(s).

## Source Map

| Source | Path | Current Evidence | Policy |
| --- | --- | --- | --- |
| Obsidian | \`$WORKSPACE\` | $obsidian_notes notes, $context_packs context packs | Durable memory and operator-edited truth |
| Oracle Inbox | \`$WORKSPACE/Oracle Inbox\` | $oracle_items review items | Review, accept, delegate, dismiss, or outcome |
| Derived agent memory | \`$stats_json\` | $agent_records records / $agent_sessions sessions | Search summaries, not raw transcripts |
| Codex histories | \`$codex_root\` | $codex_archived archived, $codex_session_files active, $codex_ambient ambient suggestion files | Derive outcomes and decisions only |
| Claude histories | \`$claude_root\` | $claude_project_files project files, $claude_session_files sessions, $claude_todos todo files | Derive outcomes and decisions only |
| Claude app support | \`$claude_app\` | $(size_of "$claude_app") | Inventory only unless explicitly imported |
| Meeting records | \`$meeting_records_dir\` | $meeting_records local file(s) | Manual/export-first; no microphone or app control |

## Guarded Import Plan

1. Keep raw Codex and Claude transcripts out of normal search.
2. Derive compact session memory: project, user goal, files touched, decisions, unresolved questions, durable outcomes.
3. Promote only useful findings into Obsidian or Oracle Inbox.
4. Use \`make work-block\` after import so old history turns into action instead of more archive.

## Commands

\`\`\`zsh
make sources
make meeting-records
make agent-prompt
make outcome TITLE="History import decision" OUTCOME="..." PROJECT="Terminal Brain" NEXT="..."
\`\`\`

## Next Useful Build

- Add a transcript summarizer that reads Codex/Claude stores, writes derived records to \`$stats_json\`, and creates reviewable Oracle Inbox notes for high-signal unresolved decisions.
- Add a privacy gate before importing any raw transcript body.
- Add project filters so histories can feed specific work surfaces instead of a generic memory pile.

## Guardrail

- This command did not launch, foreground, quit, kill, or control Terminal Brain.
- This command prints counts, sizes, and paths; it does not dump raw transcript content.
EOF
