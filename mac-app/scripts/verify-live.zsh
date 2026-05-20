#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
API="${TERMINAL_BRAIN_API:-http://127.0.0.1:8765}"

case "${1:-}" in
  --help|-h)
    cat <<'EOF'
Usage: ./mac-app/scripts/verify-live.zsh

Builds Terminal Brain, then checks API and MCP behavior against a running app.
This script never launches, relaunches, quits, or foregrounds Terminal Brain.

Options:
  --help  Show this help.
EOF
    exit 0
    ;;
  --launch)
    echo "--launch is disabled. Start Terminal Brain manually when you want it in focus." >&2
    exit 64
    ;;
  "")
    ;;
  *)
    echo "Unknown option: $1" >&2
    echo "Run ./mac-app/scripts/verify-live.zsh --help" >&2
    exit 64
    ;;
esac

"$ROOT/mac-app/scripts/build-app.zsh" >/dev/null

if ! curl -fsS "$API/health" >/dev/null 2>&1; then
  echo "Terminal Brain is not reachable at $API." >&2
  echo "Start the app yourself only when you want it in focus, then rerun this command." >&2
  exit 2
fi

curl -fsS "$API/health" | ruby -rjson -e 'j=JSON.parse(STDIN.read); abort("health failed") unless j["ok"]; puts "health ok"'

curl -fsS "$API/snapshot" | ruby -rjson -e '
  j=JSON.parse(STDIN.read)
  focus = j.dig("focus", "item", "title").to_s
  radar = (j["radar"] || []).length
  actions = (j["suggestedActions"] || []).length
  abort("snapshot missing focus") if focus.empty?
  abort("snapshot missing suggested actions") if actions == 0
  puts "snapshot ok focus=#{focus.inspect} radar=#{radar} actions=#{actions}"
'

curl -fsS "$API/snapshot/markdown" | ruby -e '
  text = STDIN.read
  abort("markdown missing title") unless text.include?("# Terminal Brain Snapshot")
  abort("markdown missing focus") unless text.include?("## Focus")
  abort("markdown missing radar") unless text.include?("## Radar")
  puts "markdown ok chars=#{text.length}"
'

curl -fsS "$API/operator-brief" | ruby -rjson -e '
  j=JSON.parse(STDIN.read)
  items = j["items"] || []
  abort("operator brief missing items") if items.empty?
  abort("operator brief missing headline") if j["headline"].to_s.empty?
  puts "operator brief ok items=#{items.length}"
'

curl -fsS "$API/operator-brief/markdown" | ruby -e '
  text = STDIN.read
  abort("operator brief markdown missing title") unless text.include?("# Terminal Brain Operator Brief")
  abort("operator brief markdown missing value section") unless text.include?("## What matters:")
  puts "operator brief markdown ok chars=#{text.length}"
'

curl -fsS "$API/today/markdown" | ruby -e '
  text = STDIN.read
  abort("decision lane missing title") unless text.include?("# Terminal Brain Decision Lane")
  abort("decision lane missing ranked decisions") unless text.include?("## Ranked Decisions")
  puts "decision lane ok chars=#{text.length}"
'

curl -fsS "$API/projects/markdown" | ruby -e '
  text = STDIN.read
  abort("project memory missing title") unless text.include?("# Terminal Brain Project Memory")
  abort("project memory missing purpose line") unless text.include?("active work surfaces")
  puts "project memory ok chars=#{text.length}"
'

curl -fsS "$API/handoff/markdown" | ruby -e '
  text = STDIN.read
  abort("handoff missing title") unless text.include?("# Terminal Brain Handoff")
  abort("handoff missing operating instructions") unless text.include?("## How To Use This")
  abort("handoff missing contents") unless text.include?("## Contents")
  abort("handoff missing operator brief") unless text.include?("# Terminal Brain Operator Brief")
  abort("handoff missing decision lane") unless text.include?("# Terminal Brain Decision Lane")
  abort("handoff missing operator deck") unless text.include?("# Terminal Brain Operator Deck")
  abort("handoff missing project memory") unless text.include?("# Terminal Brain Project Memory")
  abort("handoff missing latest context pack") unless text.include?("# Latest Context Pack")
  puts "handoff ok chars=#{text.length}"
'

printf '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"terminal_brain_snapshot","arguments":{}}}\n' \
  | node "$ROOT/mcp-server/server.mjs" \
  | ruby -rjson -e '
      line = STDIN.each_line.find { |l| l.include?("\"result\"") } || "{}"
      response = JSON.parse(line)
      text = response.dig("result", "content", 0, "text").to_s
      snapshot = JSON.parse(text)
      focus = snapshot.dig("focus", "item", "title").to_s
      abort("mcp snapshot missing focus") if focus.empty?
      puts "mcp snapshot ok focus=#{focus.inspect}"
    '

printf '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"terminal_brain_snapshot_markdown","arguments":{}}}\n' \
  | node "$ROOT/mcp-server/server.mjs" \
  | ruby -rjson -e '
      line = STDIN.each_line.find { |l| l.include?("\"result\"") } || "{}"
      response = JSON.parse(line)
      text = response.dig("result", "content", 0, "text").to_s
      abort("mcp markdown missing title") unless text.include?("# Terminal Brain Snapshot")
      abort("mcp markdown missing focus") unless text.include?("## Focus")
      puts "mcp markdown ok chars=#{text.length}"
    '

printf '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"terminal_brain_operator_brief_markdown","arguments":{}}}\n' \
  | node "$ROOT/mcp-server/server.mjs" \
  | ruby -rjson -e '
      line = STDIN.each_line.find { |l| l.include?("\"result\"") } || "{}"
      response = JSON.parse(line)
      text = response.dig("result", "content", 0, "text").to_s
      abort("mcp operator brief missing title") unless text.include?("# Terminal Brain Operator Brief")
      abort("mcp operator brief missing value section") unless text.include?("## What matters:")
      puts "mcp operator brief ok chars=#{text.length}"
    '

printf '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"terminal_brain_today_markdown","arguments":{}}}\n' \
  | node "$ROOT/mcp-server/server.mjs" \
  | ruby -rjson -e '
      line = STDIN.each_line.find { |l| l.include?("\"result\"") } || "{}"
      response = JSON.parse(line)
      text = response.dig("result", "content", 0, "text").to_s
      abort("mcp decision lane missing title") unless text.include?("# Terminal Brain Decision Lane")
      abort("mcp decision lane missing ranked decisions") unless text.include?("## Ranked Decisions")
      puts "mcp decision lane ok chars=#{text.length}"
    '

printf '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"terminal_brain_projects_markdown","arguments":{}}}\n' \
  | node "$ROOT/mcp-server/server.mjs" \
  | ruby -rjson -e '
      line = STDIN.each_line.find { |l| l.include?("\"result\"") } || "{}"
      response = JSON.parse(line)
      text = response.dig("result", "content", 0, "text").to_s
      abort("mcp project memory missing title") unless text.include?("# Terminal Brain Project Memory")
      puts "mcp project memory ok chars=#{text.length}"
    '

printf '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"terminal_brain_handoff_markdown","arguments":{}}}\n' \
  | node "$ROOT/mcp-server/server.mjs" \
  | ruby -rjson -e '
      line = STDIN.each_line.find { |l| l.include?("\"result\"") } || "{}"
      response = JSON.parse(line)
      text = response.dig("result", "content", 0, "text").to_s
      abort("mcp handoff missing title") unless text.include?("# Terminal Brain Handoff")
      abort("mcp handoff missing contents") unless text.include?("## Contents")
      abort("mcp handoff missing operator brief") unless text.include?("# Terminal Brain Operator Brief")
      abort("mcp handoff missing decision lane") unless text.include?("# Terminal Brain Decision Lane")
      abort("mcp handoff missing operator deck") unless text.include?("# Terminal Brain Operator Deck")
      abort("mcp handoff missing project memory") unless text.include?("# Terminal Brain Project Memory")
      puts "mcp handoff ok chars=#{text.length}"
    '

node --check "$ROOT/mcp-server/server.mjs" >/dev/null
swiftc \
  -framework SwiftUI \
  -framework AppKit \
  -framework Network \
  -framework AppIntents \
  -typecheck "$ROOT"/mac-app/Sources/TerminalBrain/*.swift

echo "terminal brain live verification passed"
