#!/usr/bin/env zsh
set -euo pipefail

WORKSPACE="${TERMINAL_BRAIN_WORKSPACE:-$HOME/mejohnwc}"
LIMIT="${LIMIT:-200}"
SINCE_HOURS="${SINCE_HOURS:-168}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --limit)
      LIMIT="${2:-200}"
      shift
      ;;
    --limit=*)
      LIMIT="${1#--limit=}"
      ;;
    --since-hours)
      SINCE_HOURS="${2:-168}"
      shift
      ;;
    --since-hours=*)
      SINCE_HOURS="${1#--since-hours=}"
      ;;
    --help|-h)
      cat <<'EOF'
Usage: ./mac-app/scripts/refresh-memory.zsh [--limit N] [--since-hours H]

Refreshes derived Codex/Claude work memory from recent local history files.
It writes compact summaries to:
  - $TERMINAL_BRAIN_WORKSPACE/.brain/agent-work-memory.json
  - $TERMINAL_BRAIN_WORKSPACE/.brain/agent-history-stats.json
  - $TERMINAL_BRAIN_WORKSPACE/.brain/project-dossiers.json

This reads local agent transcripts but stores derived metadata only: project,
goal hint, outcome hint, timestamps, counts, touched paths, and tool counts.
It does not dump raw transcript bodies.

This script never launches, foregrounds, screenshots, quits, kills, or controls Terminal Brain.
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Run ./mac-app/scripts/refresh-memory.zsh --help" >&2
      exit 64
      ;;
  esac
  shift
done

WORKSPACE="$WORKSPACE" LIMIT="$LIMIT" SINCE_HOURS="$SINCE_HOURS" ruby -rjson -rfind -rfileutils -rdigest -rtime -e '
  workspace = ENV.fetch("WORKSPACE")
  limit = Integer(ENV.fetch("LIMIT", "200")) rescue 200
  since_hours = Integer(ENV.fetch("SINCE_HOURS", "168")) rescue 168
  brain_dir = File.join(workspace, ".brain")
  memory_path = File.join(brain_dir, "agent-work-memory.json")
  stats_path = File.join(brain_dir, "agent-history-stats.json")
  dossiers_path = File.join(brain_dir, "project-dossiers.json")
  cutoff = Time.now - since_hours * 3600

  def load_json(path)
    JSON.parse(File.read(path))
  rescue
    {}
  end

  def compact(value, max = 260)
    text = value.to_s
      .gsub(/data:image\/[A-Za-z0-9.+-]+;base64,[A-Za-z0-9+\/=]+/m, "[image data omitted]")
      .gsub(/<image name=.*?>/m, "[image omitted]")
      .gsub(/\u0000/, "")
      .gsub(/\s+/, " ")
      .strip
    return "(none)" if text.empty?
    text.length > max ? "#{text[0, max - 1]}..." : text
  end

  def parse_time(value)
    Time.parse(value.to_s)
  rescue
    nil
  end

  def rel_home(path)
    path.to_s.sub(Dir.home, "~")
  end

  def project_from_cwd(cwd)
    value = File.basename(cwd.to_s)
    value.empty? ? "General Brain" : value
  end

  def path_signals(text)
    text.to_s.scan(%r{(?:~|/Users/[^\s`)"\]]+|[A-Za-z0-9_.-]+/[A-Za-z0-9_./-]+\.(?:swift|ts|tsx|js|mjs|zsh|md|json|sql|py|html|css))})
      .map { |path| path.gsub(/[.,;:]\z/, "") }
      .uniq
      .first(20)
  end

  def content_text(value)
    case value
    when String
      value
    when Array
      value.map { |item| content_text(item) }.join(" ")
    when Hash
      return value["text"].to_s if value["text"]
      return value["content"].to_s if value["content"].is_a?(String)
      return value["output_text"].to_s if value["type"].to_s == "output_text" && value["text"]
      return value.dig("input", "command").to_s if value.dig("input", "command")
      return value["arguments"].to_s if value["arguments"].is_a?(String)
      ""
    else
      ""
    end
  end

  def collect_files(root, pattern)
    return [] unless File.directory?(root)
    files = []
    Find.find(root) do |path|
      next unless File.file?(path)
      next unless File.basename(path).match?(pattern)
      mtime = File.mtime(path) rescue Time.at(0)
      next if mtime < cutoff = ($terminal_brain_cutoff || Time.at(0))
      files << path
    end
    files
  rescue
    []
  end

  $terminal_brain_cutoff = cutoff
  codex_files = []
  [File.join(Dir.home, ".codex", "sessions"), File.join(Dir.home, ".codex", "archived_sessions")].each do |root|
    next unless File.directory?(root)
    Find.find(root) do |path|
      next unless File.file?(path) && path.end_with?(".jsonl")
      mtime = File.mtime(path) rescue Time.at(0)
      codex_files << path if mtime >= cutoff
    end
  end
  claude_files = []
  root = File.join(Dir.home, ".claude", "projects")
  if File.directory?(root)
    Find.find(root) do |path|
      next unless File.file?(path) && path.end_with?(".jsonl")
      mtime = File.mtime(path) rescue Time.at(0)
      claude_files << path if mtime >= cutoff
    end
  end

  candidates = (codex_files.map { |path| ["codex", path] } + claude_files.map { |path| ["claude", path] })
    .sort_by { |(_, path)| -(File.mtime(path).to_i rescue 0) }
    .first(limit)

  memories = []
  candidates.each do |source, path|
    records = 0
    text_chars = 0
    started = nil
    ended_at = nil
    cwd = nil
    model = nil
    git_branch = nil
    first_user = nil
    last_assistant = nil
    tools = Hash.new(0)
    paths = []

    File.foreach(path) do |line|
      records += 1
      text_chars += line.bytesize
      obj = JSON.parse(line) rescue nil
      next unless obj
      ts = parse_time(obj["timestamp"] || obj["created_at"] || obj["timestamp_ms"])
      started = ts if ts && (!started || ts < started)
      ended_at = ts if ts && (!ended_at || ts > ended_at)

      if source == "codex"
        payload = obj["payload"].is_a?(Hash) ? obj["payload"] : {}
        cwd ||= payload["cwd"] || payload.dig("metadata", "cwd")
        model ||= payload["model"] || payload["model_slug"]
        git_branch ||= payload["git_branch"] || payload["gitBranch"]
        item = payload["item"].is_a?(Hash) ? payload["item"] : payload
        role = item["role"] || payload["role"]
        type = item["type"] || payload["type"]
        text = [content_text(item["content"]), content_text(payload["content"]), item["text"], payload["text"]].compact.map(&:to_s).join(" ")
        first_user ||= compact(text, 260) if role == "user" && !text.empty?
        last_assistant = compact(text, 320) if role == "assistant" && !text.empty?
        tool_name = item["name"] || payload["tool_name"] || payload["name"]
        tools[tool_name] += 1 if type.to_s.include?("tool") && tool_name
        paths.concat(path_signals(text))
      else
        cwd ||= obj["cwd"]
        model ||= obj.dig("message", "model")
        git_branch ||= obj["gitBranch"]
        msg = obj["message"].is_a?(Hash) ? obj["message"] : {}
        role = msg["role"] || obj["type"]
        content = msg["content"]
        text = content_text(content)
        first_user ||= compact(text, 260) if role == "user" && !text.empty?
        last_assistant = compact(text, 320) if role == "assistant" && !text.empty?
        if content.is_a?(Array)
          content.each do |part|
            next unless part.is_a?(Hash)
            name = part["name"] || part.dig("input", "command")&.split&.first
            tools[name] += 1 if part["type"].to_s.include?("tool")
          end
        end
        paths.concat(path_signals(text))
      end
    end

    cwd ||= File.dirname(path)
    started ||= File.mtime(path) rescue Time.now
    ended_at ||= File.mtime(path) rescue started
    fingerprint = Digest::SHA256.hexdigest("#{source}:#{path}:#{records}:#{ended_at}")
    memories << {
      "id" => fingerprint[0, 16],
      "source" => source,
      "project" => project_from_cwd(cwd),
      "cwd" => cwd,
      "gitBranch" => git_branch,
      "model" => model,
      "startedAt" => started&.utc&.iso8601,
      "endedAt" => ended_at&.utc&.iso8601,
      "records" => records,
      "textChars" => text_chars,
      "taskHint" => first_user || "Recent #{source} session",
      "outcomeHint" => last_assistant || "No assistant outcome text detected in derived pass.",
      "outcome" => "derived",
      "tools" => tools.sort_by { |_, count| -count }.first(10).map { |name, count| { "name" => name, "count" => count } },
      "pathSignals" => paths.uniq.first(25),
      "contentFingerprint" => fingerprint,
      "sourceFile" => rel_home(path)
    }
  rescue => e
    warn "Skipping #{path}: #{e.message}"
  end

  old_payload = load_json(memory_path)
  old_memories = old_payload["memories"].is_a?(Array) ? old_payload["memories"] : []
  by_source_file = {}
  old_memories.each { |item| by_source_file[item["sourceFile"].to_s] = item }
  memories.each { |item| by_source_file[item["sourceFile"].to_s] = item }
  merged = by_source_file.values.sort_by { |item| item["endedAt"].to_s }.reverse

  dossiers = merged.group_by { |item| item["cwd"].to_s.empty? ? item["project"].to_s : item["cwd"].to_s }.map do |cwd, items|
    latest = items.max_by { |item| item["endedAt"].to_s }
    sources = items.group_by { |item| item["source"] }.map { |name, group| { "name" => name, "count" => group.length } }
    {
      "key" => cwd.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, ""),
      "title" => project_from_cwd(cwd),
      "cwd" => cwd,
      "sessions" => items.length,
      "firstSeen" => items.map { |item| item["startedAt"].to_s }.min,
      "lastSeen" => latest["endedAt"],
      "pathSignals" => items.flat_map { |item| Array(item["pathSignals"]) }.uniq.first(30),
      "sources" => sources
    }
  end.sort_by { |item| item["lastSeen"].to_s }.reverse

  FileUtils.mkdir_p(brain_dir)
  File.write(memory_path, JSON.pretty_generate({ "generatedAt" => Time.now.utc.iso8601, "count" => merged.length, "memories" => merged }) + "\n")
  File.write(stats_path, JSON.pretty_generate({
    "generatedAt" => Time.now.utc.iso8601,
    "sessions" => merged.length,
    "records" => merged.sum { |item| item["records"].to_i },
    "bySource" => merged.group_by { |item| item["source"] }.transform_values(&:length),
    "refreshedFiles" => memories.length,
    "sinceHours" => since_hours,
    "guardrail" => "derived summaries only; raw transcript bodies were not stored"
  }) + "\n")
  File.write(dossiers_path, JSON.pretty_generate({ "generatedAt" => Time.now.utc.iso8601, "count" => dossiers.length, "dossiers" => dossiers }) + "\n")

  puts "# Terminal Brain Refresh Memory"
  puts
  puts "Checked: #{Time.now.strftime("%Y-%m-%d %H:%M:%S %Z")}"
  puts
  puts "## Direct Read"
  puts
  puts "- Refreshed recent files: #{memories.length}"
  puts "- Total derived memories: #{merged.length}"
  puts "- Total derived records: #{merged.sum { |item| item["records"].to_i }}"
  puts "- Project dossiers: #{dossiers.length}"
  puts "- Window: last #{since_hours} hours, limit #{limit} files"
  puts
  puts "## Written"
  puts
  puts "- `#{memory_path}`"
  puts "- `#{stats_path}`"
  puts "- `#{dossiers_path}`"
  puts
  puts "## Next"
  puts
  puts "```zsh"
  puts "make freshness"
  puts "make action-cards"
  puts "make memory"
  puts "```"
  puts
  puts "## Guardrail"
  puts
  puts "- This command did not launch, foreground, screenshot, quit, kill, or control Terminal Brain."
  puts "- This command stored derived summaries only; it did not dump raw Codex or Claude transcript bodies."
'
