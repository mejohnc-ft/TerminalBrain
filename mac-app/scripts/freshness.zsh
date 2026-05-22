#!/usr/bin/env zsh
set -euo pipefail

WORKSPACE="${TERMINAL_BRAIN_WORKSPACE:-$HOME/mejohnwc}"
MODE="markdown"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json)
      MODE="json"
      ;;
    --help|-h)
      cat <<'EOF'
Usage: ./mac-app/scripts/freshness.zsh [--json]

Updates and prints Terminal Brain's non-launching source freshness registry:
  - Obsidian and Oracle Inbox freshness
  - derived Codex/Claude memory freshness
  - Codex and Claude local history freshness
  - whether the derived memory is stale compared with source histories

Writes the registry to $TERMINAL_BRAIN_WORKSPACE/.brain/source-freshness.json.
This script never launches, foregrounds, screenshots, quits, kills, or controls Terminal Brain.
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Run ./mac-app/scripts/freshness.zsh --help" >&2
      exit 64
      ;;
  esac
  shift
done

WORKSPACE="$WORKSPACE" MODE="$MODE" ruby -rjson -rfind -rfileutils -rtime -e '
  workspace = ENV.fetch("WORKSPACE")
  mode = ENV.fetch("MODE", "markdown")
  brain_dir = File.join(workspace, ".brain")
  registry_path = File.join(brain_dir, "source-freshness.json")
  now = Time.now

  def load_json(path)
    JSON.parse(File.read(path))
  rescue
    {}
  end

  def count_files(root, pattern = nil)
    return 0 unless File.directory?(root)
    count = 0
    Find.find(root) do |path|
      next unless File.file?(path)
      next if pattern && File.basename(path) !~ pattern
      count += 1
    end
    count
  rescue
    0
  end

  def latest_mtime(root, pattern = nil)
    return nil unless File.exist?(root)
    if File.file?(root)
      return File.mtime(root)
    end
    latest = File.mtime(root) rescue nil
    Find.find(root) do |path|
      next unless File.file?(path)
      next if pattern && File.basename(path) !~ pattern
      mtime = File.mtime(path) rescue nil
      latest = mtime if mtime && (!latest || mtime > latest)
    end
    latest
  rescue
    latest
  end

  def iso(time)
    time&.utc&.iso8601
  end

  def age_seconds(time, now)
    return nil unless time
    [(now - time).to_i, 0].max
  end

  def age_label(seconds)
    return "unknown" unless seconds
    return "just now" if seconds < 60
    return "#{seconds / 60}m" if seconds < 3600
    return "#{seconds / 3600}h" if seconds < 86_400
    "#{seconds / 86_400}d"
  end

  def parse_time(value)
    Time.parse(value.to_s)
  rescue
    nil
  end

  def source(name:, path:, count:, latest:, status:, note:, next_due: nil)
    {
      "name" => name,
      "path" => path,
      "count" => count,
      "latestSeenAt" => iso(latest),
      "ageSeconds" => latest ? [(Time.now - latest).to_i, 0].max : nil,
      "status" => status,
      "note" => note,
      "nextScanDue" => next_due
    }
  end

  stats_path = File.join(brain_dir, "agent-history-stats.json")
  memory_path = File.join(brain_dir, "agent-work-memory.json")
  dossiers_path = File.join(brain_dir, "project-dossiers.json")
  stats = load_json(stats_path)
  memory = load_json(memory_path)
  memories = memory["memories"].is_a?(Array) ? memory["memories"] : []
  latest_memory_end = memories.map { |item| parse_time(item["endedAt"]) }.compact.max
  generated_times = [parse_time(stats["generatedAt"]), parse_time(memory["generatedAt"])].compact
  derived_generated = generated_times.max

  oracle_dir = File.join(workspace, "Oracle Inbox")
  oracle_files = Dir.glob(File.join(oracle_dir, "*.md"))
  oracle_latest = oracle_files.map { |path| File.mtime(path) rescue nil }.compact.max
  oracle_new = oracle_files.count do |path|
    File.read(path, 2048).include?("reviewStatus: new") rescue false
  end

  obsidian_latest = latest_mtime(workspace, /\.md\z/)
  codex_root = File.join(Dir.home, ".codex")
  claude_root = File.join(Dir.home, ".claude")
  claude_app = File.join(Dir.home, "Library", "Application Support", "Claude")
  codex_latest = [
    latest_mtime(File.join(codex_root, "sessions"), /\.jsonl\z/),
    latest_mtime(File.join(codex_root, "archived_sessions"), /\.jsonl\z/),
    latest_mtime(File.join(codex_root, "history.jsonl")),
    latest_mtime(File.join(codex_root, "session_index.jsonl"))
  ].compact.max
  claude_latest = [
    latest_mtime(File.join(claude_root, "projects"), /\.jsonl\z/),
    latest_mtime(File.join(claude_root, "history.jsonl")),
    latest_mtime(File.join(claude_root, "todos"))
  ].compact.max
  transcript_latest = [codex_latest, claude_latest].compact.max

  derived_stale = false
  stale_reason = nil
  if !derived_generated
    derived_stale = true
    stale_reason = "derived memory has no generatedAt timestamp"
  elsif transcript_latest && transcript_latest > derived_generated + 6 * 3600
    derived_stale = true
    stale_reason = "Codex/Claude histories are newer than derived memory"
  elsif age_seconds(derived_generated, now).to_i > 24 * 3600
    derived_stale = true
    stale_reason = "derived memory is older than 24h"
  end

  sources = []
  sources << source(
    name: "Obsidian workspace",
    path: workspace,
    count: count_files(workspace, /\.md\z/),
    latest: obsidian_latest,
    status: File.directory?(workspace) ? "available" : "missing",
    note: "durable operator-edited truth"
  )
  sources << source(
    name: "Oracle Inbox",
    path: oracle_dir,
    count: oracle_files.length,
    latest: oracle_latest,
    status: oracle_new.positive? ? "needs-review" : "clean",
    note: "#{oracle_new} new review item(s)"
  )
  sources << source(
    name: "Derived agent memory",
    path: memory_path,
    count: stats["records"] || memories.length,
    latest: derived_generated || latest_memory_end,
    status: derived_stale ? "stale" : "fresh",
    note: stale_reason || "#{stats["sessions"] || memories.length} summarized sessions"
  )
  sources << source(
    name: "Codex histories",
    path: codex_root,
    count: count_files(File.join(codex_root, "sessions"), /\.jsonl\z/) + count_files(File.join(codex_root, "archived_sessions"), /\.jsonl\z/),
    latest: codex_latest,
    status: File.directory?(codex_root) ? "available" : "missing",
    note: "source history; derive outcomes only"
  )
  sources << source(
    name: "Claude histories",
    path: claude_root,
    count: count_files(File.join(claude_root, "projects"), /\.jsonl\z/),
    latest: claude_latest,
    status: File.directory?(claude_root) ? "available" : "missing",
    note: "source history; derive outcomes only"
  )
  sources << source(
    name: "Claude app support",
    path: claude_app,
    count: nil,
    latest: File.exist?(claude_app) ? File.mtime(claude_app) : nil,
    status: File.exist?(claude_app) ? "inventory-only" : "missing",
    note: "inventory only unless explicitly imported"
  )
  sources << source(
    name: "Apple Notes",
    path: "macOS Notes",
    count: nil,
    latest: nil,
    status: ENV["EDGE_BRAIN_INCLUDE_APPLE_NOTES"] == "1" ? "opt-in-enabled" : "opt-in-disabled",
    note: "disabled unless EDGE_BRAIN_INCLUDE_APPLE_NOTES=1"
  )

  registry = {
    "generatedAt" => now.utc.iso8601,
    "workspace" => workspace,
    "registryPath" => registry_path,
    "derivedMemoryStale" => derived_stale,
    "staleReason" => stale_reason,
    "latestTranscriptAt" => iso(transcript_latest),
    "derivedMemoryGeneratedAt" => iso(derived_generated),
    "latestDerivedSessionAt" => iso(latest_memory_end),
    "oracleNewItems" => oracle_new,
    "sources" => sources
  }

  FileUtils.mkdir_p(brain_dir)
  File.write(registry_path, JSON.pretty_generate(registry) + "\n")

  if mode == "json"
    puts JSON.pretty_generate(registry)
    exit
  end

  puts "# Terminal Brain Freshness"
  puts
  puts "Checked: #{now.strftime("%Y-%m-%d %H:%M:%S %Z")}"
  puts
  puts "## Direct Read"
  puts
  puts "- Registry written: `#{registry_path}`"
  puts "- Derived memory: #{derived_stale ? "stale" : "fresh"}#{stale_reason ? " - #{stale_reason}" : ""}."
  puts "- Latest source transcript: #{iso(transcript_latest) || "unknown"}."
  puts "- Derived memory generated: #{iso(derived_generated) || "unknown"}."
  puts "- Oracle Inbox new items: #{oracle_new}."
  puts
  puts "## Source Freshness"
  puts
  puts "| Source | Status | Age | Count | Note |"
  puts "| --- | --- | ---: | ---: | --- |"
  sources.each do |item|
    age = age_label(item["ageSeconds"])
    count = item["count"].nil? ? "-" : item["count"]
    puts "| #{item["name"]} | #{item["status"]} | #{age} | #{count} | #{item["note"]} |"
  end
  puts
  puts "## Use It"
  puts
  puts "```zsh"
  puts "make freshness"
  puts "make action-cards"
  puts "make daily-brief"
  puts "```"
  puts
  puts "## Guardrail"
  puts
  puts "- This command did not launch, foreground, screenshot, quit, kill, or control Terminal Brain."
  puts "- This command writes source freshness metadata only; it does not import raw transcripts."
'
