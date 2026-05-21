#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
API="${TERMINAL_BRAIN_API:-http://127.0.0.1:8765}"
WORKSPACE="${TERMINAL_BRAIN_WORKSPACE:-$HOME/mejohnwc}"
COPY="0"
COMMIT="0"
PROJECT=""
QUERY_FROM_ENV="${QUERY:-}"
ARG_QUESTION=""
QUESTION=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --copy)
      COPY="1"
      ;;
    --commit)
      COMMIT="1"
      ;;
    --project)
      if [[ $# -lt 2 || -z "${2:-}" ]]; then
        echo "--project requires a project name" >&2
        exit 64
      fi
      PROJECT="$2"
      shift
      ;;
    --project=*)
      PROJECT="${1#--project=}"
      if [[ -z "$PROJECT" ]]; then
        echo "--project requires a project name" >&2
        exit 64
      fi
      ;;
    --help|-h)
      cat <<'EOF'
Usage: ./mac-app/scripts/oracle.zsh [--copy] [--commit] [--project NAME] QUESTION

Asks Terminal Brain Oracle and prints Markdown.
This script never launches or foregrounds Terminal Brain.

If the app API is closed, this uses the local Oracle Brief fallback.

Options:
  --copy          Copy the Markdown answer to the clipboard as well as printing it.
  --commit        Commit the Oracle answer into the Oracle Inbox.
  --project NAME  Project name to attach when committing.
  --help          Show this help.
EOF
      exit 0
      ;;
    *)
      if [[ -z "$ARG_QUESTION" ]]; then
        ARG_QUESTION="$1"
      else
        ARG_QUESTION="$ARG_QUESTION $1"
      fi
      ;;
  esac
  shift
done

if [[ -n "$ARG_QUESTION" ]]; then
  QUESTION="$ARG_QUESTION"
else
  QUESTION="$QUERY_FROM_ENV"
fi

QUESTION="${QUESTION#"${QUESTION%%[![:space:]]*}"}"
QUESTION="${QUESTION%"${QUESTION##*[![:space:]]}"}"

if [[ -z "$QUESTION" ]]; then
  echo "Provide a question or set QUERY=..." >&2
  exit 64
fi

local_answer_read() {
  local work_block
  work_block="$(TERMINAL_BRAIN_API="$API" TERMINAL_BRAIN_WORKSPACE="$WORKSPACE" "$ROOT/mac-app/scripts/work-block.zsh" --limit 1)"

  WORK_BLOCK="$work_block" QUESTION="$QUESTION" PROJECT="${PROJECT:-Terminal Brain}" ruby -rshellwords -e '
    text = ENV.fetch("WORK_BLOCK")
    question = ENV.fetch("QUESTION", "").strip
    project = ENV.fetch("PROJECT", "Terminal Brain").strip
    project = "Terminal Brain" if project.empty?

    def section(text, name)
      text[/^## #{Regexp.escape(name)}\n(.*?)(?=^## |\z)/m, 1].to_s.strip
    end

    def first_heading(markdown)
      markdown[/^###\s+\d+\.\s+([^\n]+)$/m, 1].to_s.strip
    end

    def first_code_command(markdown, pattern)
      markdown.lines.map(&:strip).find { |line| line.match?(pattern) }.to_s
    end

    def shell_assignment(name, value)
      escaped = value.to_s.gsub(/["\\$`]/) { |char| "\\#{char}" }
      %(#{name}="#{escaped}")
    end

    project_assignment = shell_assignment("PROJECT", project)

    recent = section(text, "Recent Work Signals")
    items = section(text, "Items To Pull Forward")
    missing = section(text, "What You May Not Be Considering")
    clean_move = section(text, "Next Clean Move")

    command = nil
    signal = nil
    why = nil
    blindspot = nil

    if !recent.empty?
      signal = first_heading(recent)
      command = first_code_command(recent, /^make recent-work INDEX=1\b/)
      command = "#{command} #{project_assignment}" if !command.empty? && !command.include?(" PROJECT=")
      why = "Fresh shipped work needs to become durable memory, or future agents will see the commit but miss the judgment behind it."
      blindspot = "A clean review queue can still hide uncaptured implementation context."
    elsif !items.empty? && items !~ /^No (open )?items matched\./
      signal = first_heading(items)
      note = first_code_command(items, /^NOTE=/)
      review_command = first_code_command(items, /^make review-status ID=.* STATUS=accepted/)
      command = [note, review_command].reject(&:empty?).join("\n")
      why = "The strongest open signal needs a disposition before more browsing creates noise."
      blindspot = "The useful work may be accepting, delegating, or dismissing an existing signal rather than creating a new one."
    elsif !clean_move.empty?
      command = first_code_command(clean_move, /^make (idea|outcome) /)
      why = "There is no dominant open item, so the next valuable move is to capture a real pressure point or intentionally stop."
      blindspot = "Do not manufacture review work just because the system is available."
    end

    command = "make idea TITLE=\"Decision pressure\" IDEA=\"The decision I keep circling is ...\" #{project_assignment}" if command.to_s.empty?
    signal = "No dominant open signal" if signal.to_s.empty?
    why ||= "The system needs one concrete artifact: a decision, memory note, delegated task, or outcome."
    blindspot ||= missing.lines.map(&:strip).find { |line| line.start_with?("- ") }.to_s.sub(/^- /, "")
    blindspot = "The next useful move is probably smaller than another dashboard scan." if blindspot.empty?
    display_command = command.lines.map(&:strip).reject(&:empty?).last || command

    puts "## Direct Answer"
    puts
    puts "- Do next: `#{display_command}`"
    puts "- Why: #{why}"
    puts "- What you may be missing: #{blindspot}"
    puts "- Cheap test: run the command, then save one sentence about what changed."
    puts
    puts "## One Command"
    puts
    puts "```zsh"
    puts command
    puts "```"
    puts
    puts "## Source Signal"
    puts
    puts "- #{signal}"
    puts "- Question answered: #{question}"
    puts
    puts "## Save The Result"
    puts
    puts "```zsh"
    puts "make outcome TITLE=\"...\" OUTCOME=\"What changed, why it mattered, and what evidence exists.\" #{project_assignment} NEXT=\"The next concrete action.\""
    puts "```"
  '
}

write_local_commit() {
  local answer_file="$1"
  QUESTION="$QUESTION" \
  ANSWER_FILE="$answer_file" \
  PROJECT="$PROJECT" \
  WORKSPACE="$WORKSPACE" \
  ruby -rjson -rfileutils -rtime -e '
    def slug(value)
      value.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, "")[0, 80]
    end

    question = ENV.fetch("QUESTION", "").strip
    answer = File.read(ENV.fetch("ANSWER_FILE")).strip
    project = ENV.fetch("PROJECT", "").strip
    project = "General Brain" if project.empty?
    workspace = ENV.fetch("WORKSPACE")
    inbox = File.join(workspace, "Oracle Inbox")
    FileUtils.mkdir_p(inbox)
    created = Time.now.utc.iso8601
    title = "Oracle - #{question.empty? ? "Local Read" : question}"
    safe_title = slug(title)
    path = File.join(inbox, "#{created.tr(":", "-")}-#{safe_title.empty? ? "oracle-read" : safe_title}.md")
    tags = ["local-fallback", "oracle", "terminal-brain"].sort
    tag_lines = tags.map { |tag| "  - #{tag}" }.join("\n")
    note = <<~MARKDOWN
      ---
      type: oracle_commit
      source: Terminal Brain Oracle CLI
      project: #{project}
      created: #{created}
      reviewStatus: new
      tags:
      #{tag_lines}
      ---

      # #{title}

      ## Question

      #{question}

      ## Read

      #{answer}

      ## Follow Up

      - [ ] Review and link this note to the relevant project or daily note.
      - [ ] Run Terminal Brain sync after edits are final.
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
      guardrail: "oracle fallback did not launch or foreground Terminal Brain"
    })
  '
}

if ! curl -fsS "$API/health" >/dev/null 2>&1; then
  answer_file="$(mktemp)"
  {
    echo "Terminal Brain is not reachable at $API, so this answer uses the local closed-app Oracle fallback."
    echo
    echo "The question was:"
    echo
    echo "> $QUESTION"
    echo
    local_answer_read
  } > "$answer_file"

  OUTPUT="$(
    echo "# Terminal Brain Oracle"
    echo
    echo "Question: $QUESTION"
    echo "Mode: local-fallback"
    echo
    cat "$answer_file"
    if [[ "$COMMIT" == "1" ]]; then
      echo
      echo "## Commit"
      write_local_commit "$answer_file"
    fi
  )"

  rm -f "$answer_file"

  if [[ "$COPY" == "1" ]]; then
    printf "%s\n" "$OUTPUT" | pbcopy
  fi

  printf "%s\n" "$OUTPUT"
  exit 0
fi

OUTPUT="$(
  TERMINAL_BRAIN_API="$API" TERMINAL_BRAIN_ORACLE_COMMIT="$COMMIT" TERMINAL_BRAIN_ORACLE_PROJECT="$PROJECT" ruby -rjson -rnet/http -ruri -e '
    api = ENV.fetch("TERMINAL_BRAIN_API")
    should_commit = ENV.fetch("TERMINAL_BRAIN_ORACLE_COMMIT", "0") == "1"
    project = ENV.fetch("TERMINAL_BRAIN_ORACLE_PROJECT", "")
    question = ARGV.join(" ").strip
    def post_json(api, path, body)
      uri = URI.join(api, path)
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request.body = JSON.dump(body)
      response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(request) }
      abort("#{path} failed: HTTP #{response.code}") unless response.code.to_i == 200
      JSON.parse(response.body)
    end

    payload = post_json(api, "/oracle/ask", { question: question })
    answer = payload["answer"].to_s
    abort("Oracle returned an empty answer") if answer.empty?

    commit = nil
    if should_commit
      commit = post_json(api, "/oracle/commit", {
        title: "Oracle - #{question}",
        question: question,
        content: answer,
        source: "Terminal Brain Oracle CLI",
        project: project,
        tags: ["terminal-brain", "oracle", "cli", payload["mode"].to_s]
      })
    end

    puts "# Terminal Brain Oracle"
    puts
    puts "Question: #{payload["question"] || question}"
    puts "Mode: #{payload["mode"] || "unknown"}"
    puts
    puts payload["answer"].to_s
    actions = payload["suggestedActions"] || []
    unless actions.empty?
      puts
      puts "## Suggested Actions"
      actions.each { |action| puts "- #{action}" }
    end
    citations = payload["citations"] || []
    unless citations.empty?
      puts
      puts "## Citations"
      citations.each { |citation| puts "- #{citation}" }
    end
    if commit
      puts
      puts "## Commit"
      puts "- Path: #{commit["path"] || "unknown"}"
    end
  ' "$QUESTION"
)"

if [[ "$COPY" == "1" ]]; then
  printf "%s\n" "$OUTPUT" | pbcopy
fi

printf "%s\n" "$OUTPUT"
