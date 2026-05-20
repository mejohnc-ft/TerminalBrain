#!/usr/bin/env zsh
set -euo pipefail

WORKSPACE="${TERMINAL_BRAIN_WORKSPACE:-$HOME/mejohnwc}"
LIMIT="${LIMIT:-6}"
PROJECT="${PROJECT:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --limit)
      LIMIT="${2:-6}"
      shift
      ;;
    --limit=*)
      LIMIT="${1#--limit=}"
      ;;
    --project)
      PROJECT="${2:-}"
      shift
      ;;
    --project=*)
      PROJECT="${1#--project=}"
      ;;
    --help|-h)
      cat <<'EOF'
Usage: ./mac-app/scripts/memory.zsh [--limit N] [--project PROJECT]

Prints a non-launching memory brief from derived Codex/Claude work memory:
  - current agent-memory coverage
  - recent continuity leads
  - active project dossiers
  - commands to promote useful history into Oracle Inbox

This script reads derived summaries, not raw transcript bodies. It never launches,
foregrounds, quits, kills, or controls Terminal Brain.
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Run ./mac-app/scripts/memory.zsh --help" >&2
      exit 64
      ;;
  esac
  shift
done

WORKSPACE="$WORKSPACE" LIMIT="$LIMIT" PROJECT="$PROJECT" ruby -rjson -rtime -e '
  workspace = ENV.fetch("WORKSPACE")
  limit = Integer(ENV.fetch("LIMIT", "6")) rescue 6
  project_filter = ENV.fetch("PROJECT", "").strip.downcase
  memory_path = File.join(workspace, ".brain", "agent-work-memory.json")
  history_path = File.join(workspace, ".brain", "agent-history-stats.json")
  dossiers_path = File.join(workspace, ".brain", "project-dossiers.json")

  def load_json(path)
    JSON.parse(File.read(path))
  rescue
    {}
  end

  def sanitize(value)
    value.to_s
      .gsub(/data:image\/[A-Za-z0-9.+-]+;base64,[A-Za-z0-9+\/=]+/m, "[image data omitted]")
      .gsub(/input_imagedata:\[image data omitted\]/m, "[image omitted]")
      .gsub(/<image name=.*?>/m, "[image omitted]")
      .gsub(/\u0000/, "")
  end

  def compact(value, max = 220)
    value = sanitize(value)
    text = value.to_s.gsub(/\s+/, " ").strip
    return "(none)" if text.empty?
    text.length > max ? "#{text[0, max - 1]}..." : text
  end

  def project_name(item)
    raw = item["cwd"].to_s.split("/").last
    raw = item["project"].to_s if raw.empty? || raw == "unknown"
    raw.empty? ? "General Brain" : raw
  end

  def lead_title(item, max = 90)
    title = compact(item["taskHint"], max)
    if title.include?("[image omitted]") || title.include?("[image data omitted]") || title == "(none)"
      outcome = compact(item["outcomeHint"], max - 22)
      return outcome == "(none)" ? "Image-heavy agent session" : "Image-heavy session: #{outcome}"
    end
    title
  end

  def shell_quote(value)
    quote = 39.chr
    double_quote = 34.chr
    quote + sanitize(value).gsub(quote, quote + double_quote + quote + double_quote + quote) + quote
  end

  memories_payload = load_json(memory_path)
  stats = load_json(history_path)
  dossiers_payload = load_json(dossiers_path)
  memories = memories_payload["memories"].is_a?(Array) ? memories_payload["memories"] : []
  dossiers = dossiers_payload["dossiers"].is_a?(Array) ? dossiers_payload["dossiers"] : []

  if !project_filter.empty?
    memories = memories.select do |item|
      [item["project"], item["cwd"], item["taskHint"], item["outcomeHint"]].join(" ").downcase.include?(project_filter)
    end
    dossiers = dossiers.select do |item|
      [item["title"], item["cwd"], item["key"]].join(" ").downcase.include?(project_filter)
    end
  end

  recent = memories.sort_by { |item| item["endedAt"].to_s }.reverse.first(limit)
  active_dossiers = dossiers.sort_by { |item| item["lastSeen"].to_s }.reverse.first(limit)
  richest = memories.sort_by { |item| -(item["textChars"].to_i + item["records"].to_i * 10) }.first(limit)

  puts "# Terminal Brain Memory Brief"
  puts
  puts "Checked: #{Time.now.strftime("%Y-%m-%d %H:%M:%S %Z")}"
  puts
  puts "## Direct Read"
  puts
  if memories.empty?
    puts "- No derived agent memories matched#{project_filter.empty? ? "" : " project filter #{project_filter.inspect}"}."
    puts "- Run `make sources` to inspect available Codex/Claude stores."
  else
    puts "- Derived memory available: #{stats["records"] || memories_payload["count"] || memories.length} records across #{stats["sessions"] || memories.length} sessions."
    puts "- Filtered memories in this brief: #{memories.length}."
    puts "- Most recent project: #{project_name(recent.first)}." if recent.first
    puts "- Strongest next move: pick one continuity lead below and promote it into Oracle Inbox if it still matters."
  end
  puts

  puts "## Continuity Leads"
  puts
  if recent.empty?
    puts "- No recent derived memories to show."
  else
    recent.each_with_index do |item, index|
      title = lead_title(item, 90)
      project = project_name(item)
      outcome = compact(item["outcomeHint"], 260)
      source = item["source"].to_s.empty? ? "agent" : item["source"]
      puts "### #{index + 1}. #{title}"
      puts
      puts "- Project: #{project}"
      puts "- Source: #{source}"
      puts "- Ended: #{item["endedAt"] || "unknown"}"
      puts "- Size: #{item["records"].to_i} records, #{item["textChars"].to_i} chars"
      puts "- Outcome signal: #{outcome}"
      puts
      puts "#### Promote If Useful"
      puts
      idea = "Derived agent-memory follow-up. Prior task: #{compact(item["taskHint"], 180)}. Outcome signal: #{compact(item["outcomeHint"], 320)}"
      puts "```zsh"
      puts "make idea TITLE=#{shell_quote("Follow up: #{title}")} IDEA=#{shell_quote(idea)} PROJECT=#{shell_quote(project)}"
      puts "```"
      puts
    end
  end

  puts "## Active Project Memory"
  puts
  if active_dossiers.empty?
    puts "- No project dossiers matched."
  else
    active_dossiers.each do |item|
      sources = Array(item["sources"]).map { |source| "#{source["name"]}:#{source["count"]}" }.join(", ")
      puts "- #{item["title"] || item["key"]}: #{item["sessions"].to_i} sessions, last seen #{item["lastSeen"] || "unknown"}#{sources.empty? ? "" : " (#{sources})"}"
    end
  end
  puts

  puts "## Heavy Work Sessions"
  puts
  if richest.empty?
    puts "- No heavy sessions matched."
  else
    richest.each do |item|
      puts "- #{project_name(item)}: #{compact(item["taskHint"], 120)} (#{item["records"].to_i} records, #{item["textChars"].to_i} chars)"
    end
  end
  puts

  puts "## Use It"
  puts
  puts "```zsh"
  puts "make memory"
  puts "make memory PROJECT=#{shell_quote(project_filter.empty? ? "TerminalBrain" : project_filter)}"
  puts "make work-block"
  puts "```"
  puts
  puts "## Guardrail"
  puts
  puts "- This command did not launch, foreground, quit, kill, or control Terminal Brain."
  puts "- This command reads derived summaries and project dossiers; it does not dump raw Codex or Claude transcript bodies."
'
