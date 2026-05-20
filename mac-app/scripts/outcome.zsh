#!/usr/bin/env zsh
set -euo pipefail

API="${TERMINAL_BRAIN_API:-http://127.0.0.1:8765}"
WORKSPACE="${TERMINAL_BRAIN_WORKSPACE:-$HOME/mejohnwc}"
TITLE="${TITLE:-}"
PROJECT="${PROJECT:-}"
NEXT_ACTION="${NEXT_ACTION:-${NEXT:-}}"
SOURCE="${SOURCE:-Terminal Brain CLI}"
TAGS=()
EVIDENCE=()
OUTCOME_TEXT="${OUTCOME:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --title)
      TITLE="${2:-}"
      shift
      ;;
    --title=*)
      TITLE="${1#--title=}"
      ;;
    --project)
      PROJECT="${2:-}"
      shift
      ;;
    --project=*)
      PROJECT="${1#--project=}"
      ;;
    --next|--next-action)
      NEXT_ACTION="${2:-}"
      shift
      ;;
    --next=*|--next-action=*)
      NEXT_ACTION="${1#*=}"
      ;;
    --source)
      SOURCE="${2:-}"
      shift
      ;;
    --source=*)
      SOURCE="${1#--source=}"
      ;;
    --tag)
      TAGS+=("${2:-}")
      shift
      ;;
    --tag=*)
      TAGS+=("${1#--tag=}")
      ;;
    --evidence)
      EVIDENCE+=("${2:-}")
      shift
      ;;
    --evidence=*)
      EVIDENCE+=("${1#--evidence=}")
      ;;
    --help|-h)
      cat <<'EOF'
Usage: ./mac-app/scripts/outcome.zsh --title TITLE [--project PROJECT] [--next TEXT] [--evidence TEXT] OUTCOME

Commits a structured outcome into Terminal Brain's Oracle Inbox.
If the app is reachable, this uses the local API. If it is closed, it writes
an accepted note directly to the workspace Oracle Inbox.
This script never launches or foregrounds Terminal Brain.

Environment:
  TERMINAL_BRAIN_API  Override API URL. Default: http://127.0.0.1:8765
  TERMINAL_BRAIN_WORKSPACE  Workspace/vault path. Default: ~/mejohnwc
  TITLE               Outcome title if --title is omitted.
  OUTCOME             Outcome body if no positional text is supplied.
  PROJECT             Project name if --project is omitted.
  NEXT_ACTION / NEXT  Next action if --next is omitted.

Options:
  --title       Short title.
  --project     Project name.
  --next        Recommended next action.
  --evidence    Evidence line. Repeatable.
  --tag         Additional tag. Repeatable.
  --source      Source label. Default: Terminal Brain CLI.
  --help        Show this help.
EOF
      exit 0
      ;;
    *)
      if [[ -z "$OUTCOME_TEXT" ]]; then
        OUTCOME_TEXT="$1"
      else
        OUTCOME_TEXT="$OUTCOME_TEXT $1"
      fi
      ;;
  esac
  shift
done

TITLE="${TITLE:-Outcome}"
OUTCOME_TEXT="${OUTCOME_TEXT:-}"

if [[ -z "$OUTCOME_TEXT" ]]; then
  echo "Outcome text is required. Pass OUTCOME=... or positional text." >&2
  exit 64
fi

write_local_outcome() {
  TITLE="$TITLE" \
  OUTCOME_TEXT="$OUTCOME_TEXT" \
  NEXT_ACTION="$NEXT_ACTION" \
  PROJECT="$PROJECT" \
  SOURCE="$SOURCE" \
  WORKSPACE="$WORKSPACE" \
  TAGS_JOINED="${(j:,:)TAGS}" \
  EVIDENCE_JOINED="${(j:||:)EVIDENCE}" \
  ruby -rjson -rfileutils -rtime -e '
    def slug(value)
      value.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, "")[0, 80]
    end

    title = ENV.fetch("TITLE", "Outcome").strip
    title = "Outcome" if title.empty?
    outcome = ENV.fetch("OUTCOME_TEXT", "").strip
    next_action = ENV.fetch("NEXT_ACTION", "").strip
    project = ENV.fetch("PROJECT", "").strip
    project = "General Brain" if project.empty?
    source = ENV.fetch("SOURCE", "Terminal Brain CLI").strip
    workspace = ENV.fetch("WORKSPACE")
    inbox = File.join(workspace, "Oracle Inbox")
    FileUtils.mkdir_p(inbox)
    created = Time.now.utc.iso8601
    file_stamp = created.tr(":", "-")
    safe_title = slug(title)
    path = File.join(inbox, "#{file_stamp}-#{safe_title.empty? ? "outcome" : safe_title}.md")
    tags = (ENV.fetch("TAGS_JOINED", "").split(",").map(&:strip).reject(&:empty?) + ["terminal-brain", "outcome"]).map { |tag| slug(tag) }.reject(&:empty?).uniq.sort
    evidence = ENV.fetch("EVIDENCE_JOINED", "").split("||").map(&:strip).reject(&:empty?)
    evidence_lines = evidence.empty? ? "- No evidence supplied." : evidence.map { |item| "- #{item}" }.join("\n")
    tag_lines = tags.map { |tag| "  - #{tag}" }.join("\n")
    note = <<~MARKDOWN
      ---
      type: oracle_commit
      source: #{source}
      project: #{project}
      created: #{created}
      reviewStatus: accepted
      tags:
      #{tag_lines}
      ---

      # Outcome - #{title}

      ## Question

      What changed, why does it matter, and what should happen next?

      ## Read

      ## Outcome

      #{outcome}

      ## Evidence

      #{evidence_lines}

      ## Next Action

      #{next_action.empty? ? "Review and decide the next concrete action." : next_action}

      ## Follow Up

      - [ ] Run Terminal Brain sync after edits are final.
    MARKDOWN
    File.write(path, note)
    puts JSON.generate({
      ok: true,
      mode: "local-fallback",
      path: path,
      title: "Outcome - #{title}",
      project: project,
      reviewStatus: "accepted",
      tags: tags,
      created: created,
      guardrail: "outcome fallback did not launch or foreground Terminal Brain"
    })
  '
}

if ! curl -fsS "$API/health" >/dev/null 2>&1; then
  write_local_outcome
  printf "\n"
  exit 0
fi

payload="$(
  TITLE="$TITLE" \
  OUTCOME_TEXT="$OUTCOME_TEXT" \
  NEXT_ACTION="$NEXT_ACTION" \
  PROJECT="$PROJECT" \
  SOURCE="$SOURCE" \
  TAGS_JOINED="${(j:,:)TAGS}" \
  EVIDENCE_JOINED="${(j:||:)EVIDENCE}" \
  ruby -rjson -e '
    tags = ENV.fetch("TAGS_JOINED", "").split(",").map(&:strip).reject(&:empty?)
    evidence = ENV.fetch("EVIDENCE_JOINED", "").split("||").map(&:strip).reject(&:empty?)
    puts JSON.generate({
      title: ENV.fetch("TITLE", "Outcome"),
      outcome: ENV.fetch("OUTCOME_TEXT", ""),
      nextAction: ENV.fetch("NEXT_ACTION", ""),
      project: ENV.fetch("PROJECT", ""),
      source: ENV.fetch("SOURCE", "Terminal Brain CLI"),
      tags: tags,
      evidence: evidence
    })
  '
)"

curl -fsS "$API/outcomes/commit" \
  -H "content-type: application/json" \
  -d "$payload"
printf "\n"
