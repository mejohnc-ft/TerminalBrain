#!/usr/bin/env zsh
set -euo pipefail

API="${TERMINAL_BRAIN_API:-http://127.0.0.1:8765}"
COPY="0"
QUESTION="${QUERY:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --copy)
      COPY="1"
      ;;
    --help|-h)
      cat <<'EOF'
Usage: ./mac-app/scripts/oracle.zsh [--copy] QUESTION

Asks Terminal Brain Oracle through an already-running app and prints Markdown.
This script never launches or foregrounds Terminal Brain.

Options:
  --copy  Copy the Markdown answer to the clipboard as well as printing it.
  --help  Show this help.
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
  TERMINAL_BRAIN_API="$API" ruby -rjson -rnet/http -ruri -e '
    api = ENV.fetch("TERMINAL_BRAIN_API")
    question = ARGV.join(" ").strip
    uri = URI.join(api, "/oracle/ask")
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = JSON.dump({ question: question })
    response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(request) }
    abort("Oracle request failed: HTTP #{response.code}") unless response.code.to_i == 200
    payload = JSON.parse(response.body)
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
  ' "$QUESTION"
)"

if [[ "$COPY" == "1" ]]; then
  printf "%s\n" "$OUTPUT" | pbcopy
fi

printf "%s\n" "$OUTPUT"
