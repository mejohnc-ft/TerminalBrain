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
  abort("markdown missing blindspot brief") unless text.include?("## Blindspot Brief")
  abort("markdown missing idea pulse") unless text.include?("## Idea Pulse")
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

curl -fsS "$API/value-brief/markdown" | ruby -e '
  text = STDIN.read
  abort("value brief missing title") unless text.include?("# Terminal Brain Value Brief")
  abort("value brief missing immediate value") unless text.include?("## Immediate value:")
  abort("value brief missing artifact") unless text.include?("## Artifact to create:")
  puts "value brief ok chars=#{text.length}"
'

curl -fsS "$API/today/markdown" | ruby -e '
  text = STDIN.read
  abort("decision lane missing title") unless text.include?("# Terminal Brain Decision Lane")
  abort("decision lane missing ranked decisions") unless text.include?("## Ranked Decisions")
  puts "decision lane ok chars=#{text.length}"
'

curl -fsS "$API/blindspots/markdown" | ruby -e '
  text = STDIN.read
  abort("blindspot brief missing title") unless text.include?("# Terminal Brain Blindspot Brief")
  abort("blindspot brief missing scoring") unless text.include?("- Score:")
  puts "blindspot brief ok chars=#{text.length}"
'

curl -fsS "$API/ideas/markdown" | ruby -e '
  text = STDIN.read
  abort("idea pulse missing title") unless text.include?("# Terminal Brain Idea Pulse")
  abort("idea pulse missing scoring") unless text.include?("- Score:")
  abort("idea pulse missing next prompt") unless text.include?("- Next prompt:")
  puts "idea pulse ok chars=#{text.length}"
'

curl -fsS -X POST "$API/ideas/ask" \
  -H "content-type: application/json" \
  -d '{"question":"What is the cheapest test for the top idea?"}' \
  | ruby -rjson -e '
      j=JSON.parse(STDIN.read)
      abort("idea ask failed") if j["ok"] == false
      abort("idea ask missing answer") if j["answer"].to_s.empty?
      abort("idea ask missing grounded question") if j["groundedQuestion"].to_s.empty?
      abort("idea ask missing item") unless j["idea"].is_a?(Hash)
      puts "idea ask ok mode=#{j["mode"]}"
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
  abort("handoff missing value brief") unless text.include?("# Terminal Brain Value Brief")
  abort("handoff missing operator brief") unless text.include?("# Terminal Brain Operator Brief")
  abort("handoff missing blindspot brief") unless text.include?("# Terminal Brain Blindspot Brief")
  abort("handoff missing idea pulse") unless text.include?("# Terminal Brain Idea Pulse")
  abort("handoff missing decision lane") unless text.include?("# Terminal Brain Decision Lane")
  abort("handoff missing operator deck") unless text.include?("# Terminal Brain Operator Deck")
  abort("handoff missing project memory") unless text.include?("# Terminal Brain Project Memory")
  abort("handoff missing latest context pack") unless text.include?("# Latest Context Pack")
  puts "handoff ok chars=#{text.length}"
'

curl -fsS "$API/agent-prompt/markdown" | ruby -e '
  text = STDIN.read
  abort("agent prompt missing title") unless text.include?("# Terminal Brain Agent Prompt")
  abort("agent prompt missing task") unless text.include?("## Task")
  abort("agent prompt missing acceptance criteria") unless text.include?("## Acceptance Criteria")
  abort("agent prompt missing guardrails") unless text.include?("## Guardrails")
  puts "agent prompt ok chars=#{text.length}"
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
      abort("mcp markdown missing blindspot brief") unless text.include?("## Blindspot Brief")
      abort("mcp markdown missing idea pulse") unless text.include?("## Idea Pulse")
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

printf '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"terminal_brain_value_brief_markdown","arguments":{}}}\n' \
  | node "$ROOT/mcp-server/server.mjs" \
  | ruby -rjson -e '
      line = STDIN.each_line.find { |l| l.include?("\"result\"") } || "{}"
      response = JSON.parse(line)
      text = response.dig("result", "content", 0, "text").to_s
      abort("mcp value brief missing title") unless text.include?("# Terminal Brain Value Brief")
      abort("mcp value brief missing immediate value") unless text.include?("## Immediate value:")
      puts "mcp value brief ok chars=#{text.length}"
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

printf '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"terminal_brain_blindspots_markdown","arguments":{}}}\n' \
  | node "$ROOT/mcp-server/server.mjs" \
  | ruby -rjson -e '
      line = STDIN.each_line.find { |l| l.include?("\"result\"") } || "{}"
      response = JSON.parse(line)
      text = response.dig("result", "content", 0, "text").to_s
      abort("mcp blindspot brief missing title") unless text.include?("# Terminal Brain Blindspot Brief")
      abort("mcp blindspot brief missing scoring") unless text.include?("- Score:")
      puts "mcp blindspot brief ok chars=#{text.length}"
    '

printf '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"terminal_brain_ideas_markdown","arguments":{}}}\n' \
  | node "$ROOT/mcp-server/server.mjs" \
  | ruby -rjson -e '
      line = STDIN.each_line.find { |l| l.include?("\"result\"") } || "{}"
      response = JSON.parse(line)
      text = response.dig("result", "content", 0, "text").to_s
      abort("mcp idea pulse missing title") unless text.include?("# Terminal Brain Idea Pulse")
      abort("mcp idea pulse missing scoring") unless text.include?("- Score:")
      abort("mcp idea pulse missing next prompt") unless text.include?("- Next prompt:")
      puts "mcp idea pulse ok chars=#{text.length}"
    '

printf '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"terminal_brain_idea_ask","arguments":{"question":"What is the cheapest test for the top idea?"}}}\n' \
  | node "$ROOT/mcp-server/server.mjs" \
  | ruby -rjson -e '
      line = STDIN.each_line.find { |l| l.include?("\"result\"") } || "{}"
      response = JSON.parse(line)
      text = response.dig("result", "content", 0, "text").to_s
      payload = JSON.parse(text)
      abort("mcp idea ask missing answer") if payload["answer"].to_s.empty?
      abort("mcp idea ask missing item") unless payload["idea"].is_a?(Hash)
      puts "mcp idea ask ok mode=#{payload["mode"]}"
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
      abort("mcp handoff missing value brief") unless text.include?("# Terminal Brain Value Brief")
      abort("mcp handoff missing operator brief") unless text.include?("# Terminal Brain Operator Brief")
      abort("mcp handoff missing blindspot brief") unless text.include?("# Terminal Brain Blindspot Brief")
      abort("mcp handoff missing idea pulse") unless text.include?("# Terminal Brain Idea Pulse")
      abort("mcp handoff missing decision lane") unless text.include?("# Terminal Brain Decision Lane")
      abort("mcp handoff missing operator deck") unless text.include?("# Terminal Brain Operator Deck")
      abort("mcp handoff missing project memory") unless text.include?("# Terminal Brain Project Memory")
      puts "mcp handoff ok chars=#{text.length}"
    '

printf '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"terminal_brain_agent_prompt_markdown","arguments":{}}}\n' \
  | node "$ROOT/mcp-server/server.mjs" \
  | ruby -rjson -e '
      line = STDIN.each_line.find { |l| l.include?("\"result\"") } || "{}"
      response = JSON.parse(line)
      text = response.dig("result", "content", 0, "text").to_s
      abort("mcp agent prompt missing title") unless text.include?("# Terminal Brain Agent Prompt")
      abort("mcp agent prompt missing acceptance criteria") unless text.include?("## Acceptance Criteria")
      abort("mcp agent prompt missing guardrails") unless text.include?("## Guardrails")
      puts "mcp agent prompt ok chars=#{text.length}"
    '

node --check "$ROOT/mcp-server/server.mjs" >/dev/null
swiftc \
  -framework SwiftUI \
  -framework AppKit \
  -framework Network \
  -framework AppIntents \
  -typecheck "$ROOT"/mac-app/Sources/TerminalBrain/*.swift

echo "terminal brain live verification passed"
