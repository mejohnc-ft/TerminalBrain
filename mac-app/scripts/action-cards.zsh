#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORKSPACE="${TERMINAL_BRAIN_WORKSPACE:-$HOME/mejohnwc}"
LIMIT="${LIMIT:-5}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --limit)
      LIMIT="${2:-5}"
      shift
      ;;
    --limit=*)
      LIMIT="${1#--limit=}"
      ;;
    --help|-h)
      cat <<'EOF'
Usage: ./mac-app/scripts/action-cards.zsh [--limit N]

Prints proactive Terminal Brain action cards from freshness, Oracle Inbox,
derived agent memory, repo state, and the current visual-review blocker.

This script never launches, foregrounds, screenshots, quits, kills, or controls Terminal Brain.
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Run ./mac-app/scripts/action-cards.zsh --help" >&2
      exit 64
      ;;
  esac
  shift
done

"$ROOT/mac-app/scripts/freshness.zsh" --json >/dev/null

ROOT="$ROOT" WORKSPACE="$WORKSPACE" LIMIT="$LIMIT" ruby -rjson -rtime -e '
  root = ENV.fetch("ROOT")
  workspace = ENV.fetch("WORKSPACE")
  limit = Integer(ENV.fetch("LIMIT", "5")) rescue 5
  freshness_path = File.join(workspace, ".brain", "source-freshness.json")
  memory_path = File.join(workspace, ".brain", "agent-work-memory.json")
  inbox = File.join(workspace, "Oracle Inbox")

  def load_json(path)
    JSON.parse(File.read(path))
  rescue
    {}
  end

  def compact(value, max = 180)
    text = value.to_s.gsub(/\s+/, " ").strip
    text.empty? ? "(none)" : (text.length > max ? "#{text[0, max - 1]}..." : text)
  end

  def shell_quote(value)
    quote = 39.chr
    double_quote = 34.chr
    quote + value.to_s.gsub(quote, quote + double_quote + quote + double_quote + quote) + quote
  end

  def review_status(path)
    File.read(path, 2048)[/^reviewStatus:\s*(\S+)/, 1] || "new"
  rescue
    "unknown"
  end

  cards = []
  add_card = lambda do |card|
    cards << {
      priority: card.fetch(:priority),
      title: card.fetch(:title),
      why: card.fetch(:why),
      evidence: card.fetch(:evidence),
      command: card.fetch(:command),
      success: card.fetch(:success),
      dismiss: card.fetch(:dismiss, "Dismiss only if this is no longer true.")
    }
  end

  freshness = load_json(freshness_path)
  if freshness["derivedMemoryStale"]
    add_card.call(
      priority: 100,
      title: "Refresh stale agent-memory synthesis",
      why: "Your Codex/Claude source histories are newer than the derived memory layer, so cross-project recommendations may miss recent work.",
      evidence: freshness["staleReason"].to_s.empty? ? "Derived memory stale." : freshness["staleReason"],
      command: "make refresh-memory\nmake freshness\nmake memory",
      success: "You know exactly which source is stale, which continuity lead matters, and whether to promote it into Oracle Inbox.",
      dismiss: "Dismiss only if you intentionally do not want recent agent histories influencing today."
    )
  end

  new_items = Dir.glob(File.join(inbox, "*.md")).select { |path| review_status(path) == "new" }.sort_by { |path| File.mtime(path) rescue Time.at(0) }.reverse
  if new_items.any?
    first = new_items.first
    title = File.basename(first, ".md").sub(/^\d{4}-\d{2}-\d{2}T\d{2}-\d{2}-\d{2}Z-/, "").split("-").map(&:capitalize).join(" ")
    add_card.call(
      priority: 90,
      title: "Review #{new_items.length} open Oracle item#{new_items.length == 1 ? "" : "s"}",
      why: "Open review items are the shortest path from captured thought to accepted, delegated, or dismissed memory.",
      evidence: "#{title} is waiting in #{first}.",
      command: "make review",
      success: "Every open item is accepted, delegated, linked, or dismissed.",
      dismiss: "Dismiss only after the item is no longer useful."
    )
  end

  memory = load_json(memory_path)
  memories = memory["memories"].is_a?(Array) ? memory["memories"] : []
  recent = memories.sort_by { |item| item["endedAt"].to_s }.reverse.first
  if recent
    project = recent["project"].to_s.empty? ? File.basename(recent["cwd"].to_s) : recent["project"].to_s
    project = "General Brain" if project.empty?
    add_card.call(
      priority: 80,
      title: "Promote the freshest continuity lead",
      why: "The latest derived memory may contain the next useful resume point, but it is not durable until promoted or intentionally ignored.",
      evidence: "#{project}: #{compact(recent["outcomeHint"], 220)}",
      command: "make memory",
      success: "One continuity lead is promoted, delegated, or explicitly ignored.",
      dismiss: "Dismiss if this project is not active this week."
    )
  end

  git_status = `git -C #{shell_quote(root)} status --short 2>/dev/null`
  unless git_status.strip.empty?
    add_card.call(
      priority: 70,
      title: "Resolve the dirty Terminal Brain repo",
      why: "Uncommitted product work is invisible to CI and easy to lose.",
      evidence: git_status.lines.first(5).map(&:strip).join("; "),
      command: "git status --short && make verify",
      success: "Changes are either committed and pushed with green CI or intentionally reverted by the operator.",
      dismiss: "Dismiss only if these are deliberate local-only notes."
    )
  end

  add_card.call(
    priority: 50,
    title: "Certify the native visual UX when you are ready",
    why: "The CLI/MCP/static path is covered, but world-class native UX still needs manual visual evidence.",
    evidence: "Completion audit explicitly leaves live visual review uncertified.",
    command: "make visual-review-plan",
    success: "A pass/fail visual outcome is written with evidence, or concrete visual defects are captured as ideas.",
    dismiss: "Dismiss only if you accept static verification without live UX certification."
  )

  cards = cards.sort_by { |card| -card[:priority] }.first(limit)

  puts "# Terminal Brain Action Cards"
  puts
  puts "Checked: #{Time.now.strftime("%Y-%m-%d %H:%M:%S %Z")}"
  puts
  puts "## Direct Read"
  puts
  if cards.empty?
    puts "- No action cards generated. Run `make check-in` to seed one real pressure point."
  else
    puts "- Generated #{cards.length} ranked card#{cards.length == 1 ? "" : "s"} from freshness, review queue, memory, repo state, and UX blockers."
    puts "- Do one card, then write an outcome. Do not browse all cards looking for certainty."
  end
  puts
  cards.each_with_index do |card, index|
    puts "## #{index + 1}. #{card[:title]}"
    puts
    puts "- Priority: #{card[:priority]}"
    puts "- Why: #{card[:why]}"
    puts "- Evidence: #{card[:evidence]}"
    puts "- Success looks like: #{card[:success]}"
    puts "- Dismiss if: #{card[:dismiss]}"
    puts
    puts "```zsh"
    puts card[:command]
    puts "```"
    puts
  end
  puts "## Close The Loop"
  puts
  puts "```zsh"
  puts "make outcome TITLE=\"Action card outcome\" OUTCOME=\"What changed, why it mattered, and what evidence exists.\" PROJECT=\"Terminal Brain\" NEXT=\"The next concrete action.\""
  puts "```"
  puts
  puts "## Guardrail"
  puts
  puts "- This command did not launch, foreground, screenshot, quit, kill, or control Terminal Brain."
  puts "- This command uses derived summaries and metadata; it does not dump raw transcripts."
'
