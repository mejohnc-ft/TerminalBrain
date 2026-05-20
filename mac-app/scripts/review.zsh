#!/usr/bin/env zsh
set -euo pipefail

WORKSPACE="${TERMINAL_BRAIN_WORKSPACE:-$HOME/mejohnwc}"
LIMIT="${LIMIT:-12}"
STATUS="${STATUS:-}"
PROJECT="${PROJECT:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --limit)
      LIMIT="${2:-12}"
      shift
      ;;
    --limit=*)
      LIMIT="${1#--limit=}"
      ;;
    --status)
      STATUS="${2:-}"
      shift
      ;;
    --status=*)
      STATUS="${1#--status=}"
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
Usage: ./mac-app/scripts/review.zsh [--limit N] [--status STATUS] [--project PROJECT]

Prints a closed-app Oracle Inbox review queue as Markdown.
This script never launches, foregrounds, quits, kills, or controls Terminal Brain.

Environment:
  TERMINAL_BRAIN_WORKSPACE  Workspace/vault path. Default: ~/mejohnwc
  LIMIT                     Number of items to show. Default: 12
  STATUS                    Optional status filter: new, accepted, linked, delegated, dismissed
  PROJECT                   Optional project filter.
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Run ./mac-app/scripts/review.zsh --help" >&2
      exit 64
      ;;
  esac
  shift
done

WORKSPACE="$WORKSPACE" LIMIT="$LIMIT" STATUS="$STATUS" PROJECT="$PROJECT" ruby -rtime -e '
  workspace = ENV.fetch("WORKSPACE")
  inbox = File.join(workspace, "Oracle Inbox")
  limit = Integer(ENV.fetch("LIMIT", "12")) rescue 12
  status_filter = ENV.fetch("STATUS", "").strip.downcase
  project_filter = ENV.fetch("PROJECT", "").strip.downcase

  def parse_note(text)
    frontmatter = {}
    tags = []
    body = text.dup
    if body.start_with?("---")
      parts = body.split("---", 3)
      if parts.length >= 3
        parts[1].lines.each do |line|
          if line =~ /^([A-Za-z0-9_-]+):\s*(.*)$/
            frontmatter[$1] = $2.strip
          elsif line =~ /^\s*-\s*(.+)$/
            tags << $1.strip
          end
        end
        body = parts[2]
      end
    end
    title = body.lines.find { |line| line.start_with?("# ") }.to_s.sub(/^#\s*/, "").strip
    question = body[/## Question\s*(.*?)(?=\n## |\z)/m, 1].to_s.strip
    read = body[/## Read\s*(.*?)(?=\n## |\z)/m, 1].to_s.strip
    outcome = body[/## Outcome\s*(.*?)(?=\n## |\z)/m, 1].to_s.strip
    preview_source = [read, outcome, question].find { |value| !value.empty? } || body.lines.reject { |line| line.strip.empty? || line.start_with?("#") }.join(" ")
    preview = preview_source.gsub(/\s+/, " ").strip[0, 260].to_s
    {
      title: title.empty? ? "Untitled Oracle note" : title,
      question: question,
      preview: preview,
      status: (frontmatter["reviewStatus"] || frontmatter["status"] || "new").downcase,
      project: (frontmatter["project"] || "General Brain").strip,
      source: (frontmatter["source"] || "Oracle Inbox").strip,
      created: frontmatter["created"].to_s.strip,
      tags: tags
    }
  end

  puts "# Terminal Brain Review Queue"
  puts
  puts "Workspace: #{workspace}"
  puts "Inbox: #{inbox}"
  puts

  unless Dir.exist?(inbox)
    puts "## No Inbox Yet"
    puts
    puts "No Oracle Inbox exists. Capture an idea without opening the app:"
    puts
    puts "```zsh"
    puts "make idea IDEA=\"...\" PROJECT=\"Terminal Brain\""
    puts "```"
    puts
    puts "## Guardrail"
    puts
    puts "- This command did not launch, foreground, quit, kill, or control Terminal Brain."
    exit 0
  end

  items = Dir.children(inbox)
    .select { |name| name.end_with?(".md") }
    .map do |name|
      path = File.join(inbox, name)
      text = File.read(path)
      parsed = parse_note(text)
      modified = File.mtime(path)
      created_time = begin
        parsed[:created].empty? ? modified : Time.iso8601(parsed[:created])
      rescue
        modified
      end
      parsed.merge(path: path, created_time: created_time)
    rescue
      nil
    end
    .compact
    .select { |item| status_filter.empty? || item[:status] == status_filter }
    .select { |item| project_filter.empty? || item[:project].downcase == project_filter }
    .sort_by { |item| item[:created_time] }
    .reverse

  counts = items.each_with_object(Hash.new(0)) { |item, memo| memo[item[:status]] += 1 }
  puts "## Summary"
  puts
  if items.empty?
    puts "- No matching review items."
  else
    puts "- Items: #{items.length}"
    puts "- New: #{counts["new"]}"
    puts "- Delegated: #{counts["delegated"]}"
    puts "- Accepted: #{counts["accepted"]}"
    puts "- Linked: #{counts["linked"]}"
    puts "- Dismissed: #{counts["dismissed"]}"
  end
  puts

  if items.empty?
    puts "## Next"
    puts
    puts "Capture a thought:"
    puts
    puts "```zsh"
    puts "make idea IDEA=\"...\" PROJECT=\"Terminal Brain\""
    puts "```"
  else
    puts "## Review Items"
    puts
    items.first(limit).each_with_index do |item, index|
      puts "### #{index + 1}. #{item[:title]}"
      puts
      puts "- Status: #{item[:status]}"
      puts "- Project: #{item[:project].empty? ? "General Brain" : item[:project]}"
      puts "- Source: #{item[:source]}"
      puts "- Created: #{item[:created_time].utc.iso8601}"
      puts "- Path: #{item[:path]}"
      puts
      puts item[:preview].empty? ? "(no preview)" : item[:preview]
      puts
      puts "#### Actions"
      puts
      puts "```zsh"
      puts "make review-status ID=#{item[:path].inspect} STATUS=accepted"
      puts "make review-status ID=#{item[:path].inspect} STATUS=delegated"
      puts "make review-status ID=#{item[:path].inspect} STATUS=dismissed"
      puts "```"
      puts
    end
  end

  puts "## Guardrail"
  puts
  puts "- This command did not launch, foreground, quit, kill, or control Terminal Brain."
'
