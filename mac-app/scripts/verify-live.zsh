#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
API="${TERMINAL_BRAIN_API:-http://127.0.0.1:8765}"
APP="$ROOT/mac-app/build/Terminal Brain.app"

"$ROOT/mac-app/scripts/build-app.zsh" >/dev/null

osascript -e 'tell application "Terminal Brain" to quit' >/dev/null 2>&1 || true
sleep 1
open -a "$APP"

for _ in {1..30}; do
  if curl -fsS "$API/health" >/dev/null 2>&1; then
    break
  fi
  sleep 0.5
done

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

node --check "$ROOT/mcp-server/server.mjs" >/dev/null
swiftc -typecheck "$ROOT"/mac-app/Sources/TerminalBrain/*.swift

echo "terminal brain live verification passed"
