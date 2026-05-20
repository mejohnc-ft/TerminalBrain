#!/usr/bin/env zsh
set -euo pipefail

API="${TERMINAL_BRAIN_API:-http://127.0.0.1:8765}"
WORKSPACE="${TERMINAL_BRAIN_WORKSPACE:-$HOME/mejohnwc}"
TITLE="${TITLE:-Captured Idea}"
PROJECT="${PROJECT:-}"
SOURCE="${SOURCE:-Terminal Brain CLI}"
IDEA_TEXT="${IDEA:-}"
TAGS=()

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
    --help|-h)
      cat <<'EOF'
Usage: ./mac-app/scripts/idea.zsh [--title TITLE] [--project PROJECT] [--tag TAG] IDEA

Captures an idea, open loop, or rough thought into Terminal Brain's Oracle Inbox.
If the app is reachable, this uses the local API. If it is closed, it writes
a new reviewable idea note directly to the workspace Oracle Inbox.
This script never launches or foregrounds Terminal Brain.

Environment:
  TERMINAL_BRAIN_API        Override API URL. Default: http://127.0.0.1:8765
  TERMINAL_BRAIN_WORKSPACE  Workspace/vault path. Default: ~/mejohnwc
  IDEA                      Idea text if no positional text is supplied.
  TITLE                     Idea title if --title is omitted.
  PROJECT                   Project name if --project is omitted.

Options:
  --title       Short title.
  --project     Project name.
  --tag         Additional tag. Repeatable.
  --source      Source label. Default: Terminal Brain CLI.
  --help        Show this help.
EOF
      exit 0
      ;;
    *)
      if [[ -z "$IDEA_TEXT" ]]; then
        IDEA_TEXT="$1"
      else
        IDEA_TEXT="$IDEA_TEXT $1"
      fi
      ;;
  esac
  shift
done

TITLE="${TITLE:-Captured Idea}"
IDEA_TEXT="${IDEA_TEXT:-}"

if [[ -z "$IDEA_TEXT" ]]; then
  echo "Idea text is required. Pass IDEA=... or positional text." >&2
  exit 64
fi

json_payload() {
  TITLE="$TITLE" \
  IDEA_TEXT="$IDEA_TEXT" \
  PROJECT="$PROJECT" \
  SOURCE="$SOURCE" \
  TAGS_JOINED="${(j:,:)TAGS}" \
  ruby -rjson -e '
    tags = ENV.fetch("TAGS_JOINED", "").split(",").map(&:strip).reject(&:empty?)
    puts JSON.generate({
      title: ENV.fetch("TITLE", "Captured Idea"),
      content: ENV.fetch("IDEA_TEXT", ""),
      project: ENV.fetch("PROJECT", ""),
      source: ENV.fetch("SOURCE", "Terminal Brain CLI"),
      tags: tags
    })
  '
}

write_local_idea() {
  TITLE="$TITLE" \
  IDEA_TEXT="$IDEA_TEXT" \
  PROJECT="$PROJECT" \
  SOURCE="$SOURCE" \
  WORKSPACE="$WORKSPACE" \
  TAGS_JOINED="${(j:,:)TAGS}" \
  ruby -rjson -rfileutils -rtime -e '
    def slug(value)
      value.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, "")[0, 80]
    end

    title = ENV.fetch("TITLE", "Captured Idea").strip
    title = "Captured Idea" if title.empty?
    idea = ENV.fetch("IDEA_TEXT", "").strip
    project = ENV.fetch("PROJECT", "").strip
    project = "General Brain" if project.empty?
    source = ENV.fetch("SOURCE", "Terminal Brain CLI").strip
    workspace = ENV.fetch("WORKSPACE")
    inbox = File.join(workspace, "Oracle Inbox")
    FileUtils.mkdir_p(inbox)
    created = Time.now.utc.iso8601
    file_stamp = created.tr(":", "-")
    safe_title = slug(title)
    path = File.join(inbox, "#{file_stamp}-#{safe_title.empty? ? "captured-idea" : safe_title}.md")
    tags = (ENV.fetch("TAGS_JOINED", "").split(",").map(&:strip).reject(&:empty?) + ["terminal-brain", "idea", "capture"]).map { |tag| slug(tag) }.reject(&:empty?).uniq.sort
    tag_lines = tags.map { |tag| "  - #{tag}" }.join("\n")
    note = <<~MARKDOWN
      ---
      type: oracle_commit
      source: #{source}
      project: #{project}
      created: #{created}
      reviewStatus: new
      tags:
      #{tag_lines}
      ---

      # #{title}

      ## Question

      Captured from Terminal Brain CLI.

      ## Read

      #{idea}

      ## Follow Up

      - [ ] Review, link, delegate, dismiss, or turn into a cheap test.
    MARKDOWN
    File.write(path, note)
    puts JSON.generate({
      ok: true,
      mode: "local-fallback",
      path: path,
      title: title,
      project: project,
      reviewStatus: "new",
      tags: tags,
      created: created,
      guardrail: "idea fallback did not launch or foreground Terminal Brain"
    })
  '
}

health="$(curl -fsS --max-time 0.5 "$API/health" 2>/dev/null || true)"
if [[ -n "$health" ]]; then
  curl -fsS \
    -H 'content-type: application/json' \
    -d "$(json_payload)" \
    "$API/ideas/capture"
  exit 0
fi

write_local_idea
