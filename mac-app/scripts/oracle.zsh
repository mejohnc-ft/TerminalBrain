#!/usr/bin/env zsh
set -euo pipefail

API="${TERMINAL_BRAIN_API:-http://127.0.0.1:8765}"
COPY="0"
COMMIT="0"
PROJECT=""
QUESTION="${QUERY:-}"

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

Asks Terminal Brain Oracle through an already-running app and prints Markdown.
This script never launches or foregrounds Terminal Brain.

Options:
  --copy          Copy the Markdown answer to the clipboard as well as printing it.
  --commit        Commit the Oracle answer into the Oracle Inbox.
  --project NAME  Project name to attach when committing.
  --help          Show this help.
EOF
      exit 0
      ;;
    *)
      if [[ -z "$QUESTION" ]]; then
        QUESTION="$1"
      else
        QUESTION="$QUESTION $1"
      fi
      ;;
  esac
  shift
done

QUESTION="${QUESTION#"${QUESTION%%[![:space:]]*}"}"
QUESTION="${QUESTION%"${QUESTION##*[![:space:]]}"}"

if [[ -z "$QUESTION" ]]; then
  echo "Provide a question or set QUERY=..." >&2
  exit 64
fi

if ! curl -fsS "$API/health" >/dev/null 2>&1; then
  echo "Terminal Brain is not reachable at $API. Start it yourself, then rerun this command." >&2
  exit 2
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
