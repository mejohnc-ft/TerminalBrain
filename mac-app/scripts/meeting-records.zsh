#!/usr/bin/env zsh
set -euo pipefail

WORKSPACE="${TERMINAL_BRAIN_WORKSPACE:-$HOME/mejohnwc}"
MEETING_DIR="${TERMINAL_BRAIN_MEETING_RECORDS_DIR:-$WORKSPACE/Meeting Records}"

case "${1:-}" in
  --help|-h)
    cat <<'EOF'
Usage: ./mac-app/scripts/meeting-records.zsh

Inventories local meeting transcript/recording records for Terminal Brain.

Default managed folder:
  $TERMINAL_BRAIN_WORKSPACE/Meeting Records

Optional env:
  TERMINAL_BRAIN_MEETING_RECORDS_DIR=/path/to/folder

This script creates the managed folder and writes metadata to:
  $TERMINAL_BRAIN_WORKSPACE/.brain/meeting-records.json

It does not record audio, start screen capture, request microphone access,
launch meeting apps, upload data, or read private calendar/mail APIs.
EOF
    exit 0
    ;;
  "")
    ;;
  *)
    echo "Unknown option: $1" >&2
    echo "Run ./mac-app/scripts/meeting-records.zsh --help" >&2
    exit 64
    ;;
esac

WORKSPACE="$WORKSPACE" MEETING_DIR="$MEETING_DIR" ruby -rjson -rfind -rfileutils -rdigest -rtime -e '
  workspace = ENV.fetch("WORKSPACE")
  meeting_dir = ENV.fetch("MEETING_DIR")
  brain_dir = File.join(workspace, ".brain")
  registry_path = File.join(brain_dir, "meeting-records.json")
  FileUtils.mkdir_p(meeting_dir)
  FileUtils.mkdir_p(brain_dir)

  extensions = {
    ".md" => "transcript",
    ".txt" => "transcript",
    ".vtt" => "transcript",
    ".srt" => "transcript",
    ".json" => "metadata",
    ".m4a" => "audio",
    ".mp3" => "audio",
    ".wav" => "audio",
    ".mp4" => "recording",
    ".mov" => "recording"
  }

  candidates = []
  Find.find(meeting_dir) do |path|
    next unless File.file?(path)
    ext = File.extname(path).downcase
    next unless extensions.key?(ext)
    stat = File.stat(path) rescue nil
    next unless stat
    candidates << {
      "id" => Digest::SHA256.hexdigest(path)[0, 16],
      "path" => path,
      "name" => File.basename(path),
      "kind" => extensions[ext],
      "extension" => ext,
      "bytes" => stat.size,
      "modifiedAt" => stat.mtime.utc.iso8601
    }
  end

  # Common local transcript evidence, inventoried by path only unless explicitly moved into Meeting Records.
  external_hints = [
    File.join(Dir.home, ".codex", "transcription-history.jsonl"),
    File.join(Dir.home, "Git", "MeetingOS", "tmp")
  ].select { |path| File.exist?(path) }.map do |path|
    {
      "path" => path,
      "status" => "available",
      "policy" => "inventory-only until explicitly imported"
    }
  end

  payload = {
    "generatedAt" => Time.now.utc.iso8601,
    "managedFolder" => meeting_dir,
    "count" => candidates.length,
    "records" => candidates.sort_by { |item| item["modifiedAt"].to_s }.reverse,
    "externalHints" => external_hints,
    "policy" => [
      "Local records only.",
      "No microphone, screen recording, app launch, upload, or calendar access.",
      "Store transcripts/recordings in the managed folder when you want Terminal Brain to inventory them.",
      "Use Granola or another recorder manually, then export/copy transcripts here for local indexing."
    ]
  }

  File.write(registry_path, JSON.pretty_generate(payload) + "\n")

  puts "# Terminal Brain Meeting Records"
  puts
  puts "Checked: #{Time.now.strftime("%Y-%m-%d %H:%M:%S %Z")}"
  puts
  puts "## Direct Read"
  puts
  puts "- Managed folder: `#{meeting_dir}`"
  puts "- Local records found: #{candidates.length}"
  puts "- Registry written: `#{registry_path}`"
  puts "- Recording stance: manual/export-first. Terminal Brain does not start recording or request microphone access."
  puts
  puts "## Records"
  puts
  if candidates.empty?
    puts "- No local meeting records found yet."
  else
    candidates.first(12).each do |item|
      puts "- #{item["kind"]}: `#{item["name"]}` (#{item["bytes"]} bytes, #{item["modifiedAt"]})"
    end
  end
  puts
  puts "## External Hints"
  puts
  if external_hints.empty?
    puts "- No common local transcript stores detected."
  else
    external_hints.each { |item| puts "- `#{item["path"]}` - #{item["policy"]}" }
  end
  puts
  puts "## Use It"
  puts
  puts "1. Record/transcribe manually in Granola or your chosen local meeting tool."
  puts "2. Export or copy the transcript/audio into `#{meeting_dir}`."
  puts "3. Rerun `make meeting-records`, then promote important decisions with `make idea` or `make outcome`."
  puts
  puts "```zsh"
  puts "make meeting-records"
  puts "make idea TITLE=\"Meeting follow-up\" IDEA=\"Decision / owner / next step from local meeting record.\" PROJECT=\"Meeting Records\""
  puts "```"
  puts
  puts "## Guardrail"
  puts
  puts "- This command did not launch, foreground, screenshot, record audio, request microphone access, quit, kill, or control Terminal Brain."
'
