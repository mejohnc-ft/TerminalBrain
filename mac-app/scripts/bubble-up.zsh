#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORKSPACE="${TERMINAL_BRAIN_WORKSPACE:-$HOME/mejohnwc}"
LIMIT="${LIMIT:-7}"
PROJECT="${PROJECT:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --limit)
      LIMIT="${2:-7}"
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
Usage: ./mac-app/scripts/bubble-up.zsh [--limit N] [--project PROJECT]

Surfaces neglected, delegated, and repeated Oracle Inbox signals as Markdown.
This script never launches, foregrounds, quits, kills, or controls Terminal Brain.

Environment:
  TERMINAL_BRAIN_WORKSPACE  Workspace/vault path. Default: ~/mejohnwc
  LIMIT                     Number of items to show. Default: 7
  PROJECT                   Optional project filter.
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Run ./mac-app/scripts/bubble-up.zsh --help" >&2
      exit 64
      ;;
  esac
  shift
done

WORKSPACE="$WORKSPACE" ROOT="$ROOT" LIMIT="$LIMIT" PROJECT="$PROJECT" ruby -rtime -rshellwords -e '
  workspace = ENV.fetch("WORKSPACE")
  root = ENV.fetch("ROOT")
  inbox = File.join(workspace, "Oracle Inbox")
  limit = Integer(ENV.fetch("LIMIT", "7")) rescue 7
  project_filter = ENV.fetch("PROJECT", "").strip.downcase
  now = Time.now.utc

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
    follow_up = body[/## Follow Up\s*(.*?)(?=\n## |\z)/m, 1].to_s.strip
    preview_source = [read, outcome, question, follow_up].find { |value| !value.empty? } || body.lines.reject { |line| line.strip.empty? || line.start_with?("#") }.join(" ")
    {
      title: title.empty? ? "Untitled Oracle note" : title,
      question: question,
      read: read,
      outcome: outcome,
      follow_up: follow_up,
      preview: preview_source.gsub(/\s+/, " ").strip[0, 280].to_s,
      status: (frontmatter["reviewStatus"] || frontmatter["status"] || "new").downcase,
      project: (frontmatter["project"] || "General Brain").strip,
      source: (frontmatter["source"] || "Oracle Inbox").strip,
      created: frontmatter["created"].to_s.strip,
      tags: tags
    }
  end

  def age_label(hours)
    return "just now" if hours < 1
    return "#{hours.round}h" if hours < 48
    "#{(hours / 24.0).round}d"
  end

  def score_item(item)
    status_score = {
      "new" => 90,
      "delegated" => 82,
      "linked" => 44,
      "accepted" => 30,
      "dismissed" => 3
    }.fetch(item[:status], 55)
    urgency_terms = [item[:title], item[:question], item[:read], item[:outcome], item[:follow_up]].join(" ").downcase
    urgency = urgency_terms.scan(/risk|blocked|stuck|urgent|miss|blindspot|should|maybe|what if|cheap test|follow up|decision|delegate|review/).length * 4
    age_bonus = [[item[:age_hours] / 8.0, 34].min, 0].max
    status_score + urgency + age_bonus
  end

  def reason_for(item)
    return "new and unreviewed" if item[:status] == "new" && item[:age_hours] < 24
    return "new and aging" if item[:status] == "new"
    return "delegated and needs closure" if item[:status] == "delegated"
    return "linked but may need a next action" if item[:status] == "linked"
    return "accepted but worth converting into an artifact" if item[:status] == "accepted"
    "possible weak signal"
  end

  def recent_work_signals(root, limit)
    return [] unless Dir.exist?(File.join(root, ".git"))
    output = IO.popen(["git", "-C", root, "log", "-#{[limit, 5].max}", "--pretty=format:%h%x09%H%x09%cr%x09%s"], &:read).to_s
    output.lines.map do |line|
      sha, full_sha, age, subject = line.chomp.split("\t", 4)
      next if subject.to_s.strip.empty?
      {
        sha: sha.to_s,
        full_sha: full_sha.to_s,
        age: age.to_s,
        title: subject.to_s.strip,
        project: "Terminal Brain"
      }
    end.compact
  rescue
    []
  end

  def meaningful_words(value)
    stop = %w[the and for with from this that into after before because should what when where were was are has have had queue clean fresh work recent follow outcome action terminal brain]
    value.to_s.downcase.scan(/[a-z0-9]+/).reject { |word| word.length < 3 || stop.include?(word) }.uniq
  end

  def memory_covers_signal?(signal, items)
    subject_words = meaningful_words(signal[:title])
    items.any? do |item|
      next false unless ["accepted", "linked"].include?(item[:status])
      memory_text = [item[:title], item[:question], item[:read], item[:outcome], item[:follow_up], item[:preview]].join(" ").downcase
      return true if !signal[:sha].to_s.empty? && memory_text.include?(signal[:sha].downcase)
      return true if !signal[:full_sha].to_s.empty? && memory_text.include?(signal[:full_sha].downcase)
      next false if subject_words.empty?
      memory_words = meaningful_words(memory_text)
      overlap = subject_words & memory_words
      overlap.length >= [3, subject_words.length].min && (overlap.length.to_f / subject_words.length) >= 0.55
    end
  end

  def print_recent_work_fallback(signals, limit, intro = nil)
    return false if signals.empty?

    puts "## Recent Work Signals"
    puts
    puts intro || "The Oracle Inbox has no reviewable items, so Bubble Up is using recent repo history as the fallback signal."
    puts
    signals.first(limit).each_with_index do |signal, index|
      puts "### #{index + 1}. #{signal[:title]}"
      puts
      puts "- Why now: recent implementation work without a matching reviewed Oracle outcome"
      puts "- Project: #{signal[:project]}"
      puts "- Age: #{signal[:age]}"
      puts "- Commit: #{signal[:sha]}"
      puts
      puts "#### Turn It Into Memory"
      puts
      puts "```zsh"
      puts "make recent-work INDEX=#{index + 1}"
      puts "# Equivalent manual capture:"
      puts "make idea TITLE=#{("Follow up: " + signal[:title]).shellescape} IDEA=#{("What should change because we shipped " + signal[:title] + "? Capture the outcome, remaining risk, and next action.").shellescape} PROJECT=#{signal[:project].shellescape}"
      puts "make work-block"
      puts "```"
      puts
    end
    true
  end

  puts "# Terminal Brain Bubble Up"
  puts
  puts "Workspace: #{workspace}"
  puts "Inbox: #{inbox}"
  puts

  unless Dir.exist?(inbox)
    puts "## Direct Read"
    puts
    puts "- No Oracle Inbox exists yet."
    puts "- Recent repo work can still be converted into reviewable memory."
    puts
    print_recent_work_fallback(recent_work_signals(root, limit), limit, "No Oracle Inbox exists yet, so Bubble Up is using recent repo history as the fallback signal.")
    puts
    puts "## Prime The Brain"
    puts
    puts "Pick the line that feels most true right now. The goal is not perfect capture; it is to create one reviewable signal the system can work with."
    puts
    puts "```zsh"
    puts "make idea TITLE=\"Decision pressure\" IDEA=\"The decision I keep circling is ...\" PROJECT=\"Terminal Brain\""
    puts "make idea TITLE=\"Neglected idea\" IDEA=\"The idea I do not want to lose is ...\" PROJECT=\"Terminal Brain\""
    puts "make idea TITLE=\"Open loop\" IDEA=\"The loose end that will cost me later is ...\" PROJECT=\"Terminal Brain\""
    puts "make bubble-up"
    puts "```"
    puts
    puts "## Done Criteria"
    puts
    puts "- One idea is captured."
    puts "- Bubble Up shows a highest-signal item."
    puts "- The next work block has something concrete to accept, delegate, dismiss, or turn into an outcome."
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
      modified = File.mtime(path).utc
      created_time = begin
        parsed[:created].empty? ? modified : Time.iso8601(parsed[:created]).utc
      rescue
        modified
      end
      age_hours = [(now - created_time) / 3600.0, 0].max
      parsed.merge(path: path, created_time: created_time, age_hours: age_hours)
    rescue
      nil
    end
    .compact
    .select { |item| project_filter.empty? || item[:project].downcase == project_filter }

  reviewable = items.reject { |item| item[:status] == "dismissed" }
  unclosed = reviewable.select { |item| ["new", "delegated", "linked"].include?(item[:status]) }
  completed = reviewable.select { |item| ["accepted"].include?(item[:status]) }.sort_by { |item| item[:created_time] }.reverse
  ranked = unclosed.map { |item| item.merge(score: score_item(item)) }.sort_by { |item| [-item[:score], item[:created_time]] }
  counts = items.each_with_object(Hash.new(0)) { |item, memo| memo[item[:status]] += 1 }
  projects = unclosed.each_with_object(Hash.new(0)) { |item, memo| memo[item[:project].empty? ? "General Brain" : item[:project]] += 1 }
  repeated_project = projects.sort_by { |_, count| -count }.first
  oldest_new = unclosed.select { |item| item[:status] == "new" }.sort_by { |item| item[:created_time] }.first
  delegated = unclosed.select { |item| item[:status] == "delegated" }.sort_by { |item| item[:created_time] }.first
  top = ranked.first
  fallback_signals = recent_work_signals(root, [limit * 4, 12].max).reject { |signal| memory_covers_signal?(signal, reviewable) }
  fallback_top = fallback_signals.first

  puts "## Direct Read"
  puts
  if reviewable.empty? && fallback_top
    puts "- No Oracle Inbox items are reviewable yet."
    puts "- Pull forward recent work instead: #{fallback_top[:title]} (#{fallback_top[:age]}, #{fallback_top[:sha]})."
    puts "- Convert one shipped change into reviewed memory so the system knows why it mattered."
  elsif reviewable.empty?
    puts "- No Oracle Inbox items or repo fallback signals are currently available."
    puts "- Prime the brain with one current question, decision pressure, or loose end."
  else
    puts "- Reviewable items: #{reviewable.length}"
    puts "- New: #{counts["new"]}; delegated: #{counts["delegated"]}; linked: #{counts["linked"]}; accepted: #{counts["accepted"]}"
    if top
      puts "- Highest open signal: #{top[:title]} (#{top[:status]}, #{top[:project]}, score #{top[:score].round})"
    elsif completed.any?
      puts "- Open pull-forward items: 0"
      puts "- Completed evidence: #{completed.length} accepted item#{completed.length == 1 ? "" : "s"}"
    end
  end
  puts

  puts "## What You May Not Be Considering"
  puts
  if reviewable.empty? && fallback_top
    puts "- Recent implementation work is not the same as durable memory."
    puts "- If you do not capture outcome, remaining risk, and next action, future agents will see commits but miss judgment."
  elsif reviewable.empty?
    puts "- There is no local signal to challenge you yet. That is a setup problem, not a thinking problem."
    puts "- Capture the pressure point you would otherwise keep in your head."
  else
    if oldest_new
      puts "- Old unreviewed thought: #{oldest_new[:title]} has been sitting for #{age_label(oldest_new[:age_hours])}."
    end
    if delegated
      puts "- Delegated loop to close: #{delegated[:title]} has been waiting for #{age_label(delegated[:age_hours])}."
    end
    if repeated_project && repeated_project[1] > 1
      puts "- Repeated pressure: #{repeated_project[0]} has #{repeated_project[1]} open signals. Treat it as a project theme, not isolated notes."
    end
    if unclosed.empty? && completed.any?
      puts "- There is no open review pressure right now. That is good: the next useful move is to start from completed evidence or capture a new pressure point."
      puts "- Fresh implementation work may still need durable memory even when the review queue is clean."
      puts "- Do not keep reworking accepted notes unless they reveal a new decision, artifact, or risk."
    end
  end
  puts

  puts "## Items To Pull Forward"
  puts
  if ranked.empty?
    if completed.any?
      puts "No open items matched."
      puts
      puts "## Completed Evidence"
      puts
      completed.first(limit).each_with_index do |item, index|
        puts "### #{index + 1}. #{item[:title]}"
        puts
        puts "- Status: #{item[:status]}"
        puts "- Project: #{item[:project].empty? ? "General Brain" : item[:project]}"
        puts "- Age: #{age_label(item[:age_hours])}"
        puts "- Source: #{item[:source]}"
        puts "- Path: #{item[:path]}"
        puts
        puts item[:preview].empty? ? "(no preview)" : item[:preview]
        puts
      end
      print_recent_work_fallback(fallback_signals, limit, "There are no open review items, so Bubble Up is showing recent shipped work as the next memory/action signal.")
    elsif fallback_signals.empty?
      puts "No items matched."
      puts
    else
      print_recent_work_fallback(fallback_signals, limit)
      puts
    end
    if completed.empty?
      puts "## Prime The Brain"
      puts
      puts "Use one of these starter captures to create the first useful signal:"
      puts
      puts "```zsh"
      puts "make idea TITLE=\"Decision pressure\" IDEA=\"The decision I keep circling is ...\" PROJECT=\"Terminal Brain\""
      puts "make idea TITLE=\"Neglected idea\" IDEA=\"The idea I do not want to lose is ...\" PROJECT=\"Terminal Brain\""
      puts "make idea TITLE=\"Open loop\" IDEA=\"The loose end that will cost me later is ...\" PROJECT=\"Terminal Brain\""
      puts "make work-block"
      puts "```"
    end
  else
    ranked.first(limit).each_with_index do |item, index|
      puts "### #{index + 1}. #{item[:title]}"
      puts
      puts "- Why now: #{reason_for(item)}"
      puts "- Score: #{item[:score].round}"
      puts "- Status: #{item[:status]}"
      puts "- Project: #{item[:project].empty? ? "General Brain" : item[:project]}"
      puts "- Age: #{age_label(item[:age_hours])}"
      puts "- Source: #{item[:source]}"
      puts "- Path: #{item[:path]}"
      puts
      puts item[:preview].empty? ? "(no preview)" : item[:preview]
      puts
      puts "#### Actions"
      puts
      puts "```zsh"
      puts "NOTE=#{item[:path].shellescape}"
      puts "make review-status ID=\"$NOTE\" STATUS=accepted"
      puts "make review-status ID=\"$NOTE\" STATUS=delegated"
      puts "make review-status ID=\"$NOTE\" STATUS=dismissed"
      puts "```"
      puts
    end
  end

  puts "## Guardrail"
  puts
  puts "- This command did not launch, foreground, quit, kill, or control Terminal Brain."
'
