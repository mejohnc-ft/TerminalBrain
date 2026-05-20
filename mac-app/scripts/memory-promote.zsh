#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORKSPACE="${TERMINAL_BRAIN_WORKSPACE:-$HOME/mejohnwc}"
INDEX="${INDEX:-}"
PROJECT="${PROJECT:-}"
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --index)
      INDEX="${2:-}"
      shift
      ;;
    --index=*)
      INDEX="${1#--index=}"
      ;;
    --project)
      PROJECT="${2:-}"
      shift
      ;;
    --project=*)
      PROJECT="${1#--project=}"
      ;;
    --dry-run)
      DRY_RUN=1
      ;;
    --help|-h)
      cat <<'EOF'
Usage: ./mac-app/scripts/memory-promote.zsh --index N [--project PROJECT] [--dry-run]

Promotes one derived Codex/Claude memory lead into Oracle Inbox as a reviewable
idea. The ranking matches `make memory`: most recent derived memories first,
optionally filtered by project substring.

This script reads derived summaries, not raw transcript bodies. It never launches,
foregrounds, quits, kills, or controls Terminal Brain.

Environment:
  TERMINAL_BRAIN_WORKSPACE  Workspace/vault path. Default: ~/mejohnwc
  INDEX                     One-based continuity lead index to promote.
  PROJECT                   Optional project substring filter.
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Run ./mac-app/scripts/memory-promote.zsh --help" >&2
      exit 64
      ;;
  esac
  shift
done

if [[ -z "$INDEX" ]]; then
  echo "Set INDEX=1 or pass --index 1." >&2
  exit 64
fi

selection_json="$(
  WORKSPACE="$WORKSPACE" INDEX="$INDEX" PROJECT="$PROJECT" ruby -rjson -e '
    workspace = ENV.fetch("WORKSPACE")
    index = Integer(ENV.fetch("INDEX"))
    project_filter = ENV.fetch("PROJECT", "").strip.downcase
    memory_path = File.join(workspace, ".brain", "agent-work-memory.json")

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
      text = sanitize(value).gsub(/\s+/, " ").strip
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

    payload = load_json(memory_path)
    memories = payload["memories"].is_a?(Array) ? payload["memories"] : []
    if !project_filter.empty?
      memories = memories.select do |item|
        [item["project"], item["cwd"], item["taskHint"], item["outcomeHint"]].join(" ").downcase.include?(project_filter)
      end
    end
    ranked = memories.sort_by { |item| item["endedAt"].to_s }.reverse
    item = ranked[index - 1]
    unless item
      warn "No memory lead at index #{index}. Run make memory to see available leads."
      exit 66
    end

    title = "Follow up: #{lead_title(item, 90)}"
    project = project_name(item)
    idea = [
      "Derived agent-memory follow-up.",
      "Prior task: #{compact(item["taskHint"], 260)}.",
      "Outcome signal: #{compact(item["outcomeHint"], 420)}.",
      "Source: #{item["source"] || "agent"}; ended: #{item["endedAt"] || "unknown"}; records: #{item["records"].to_i}; chars: #{item["textChars"].to_i}.",
      "Review whether this should become a project update, delegated work, dismissal, or a concrete outcome."
    ].join(" ")

    puts JSON.generate({
      ok: true,
      index: index,
      title: title,
      project: project,
      idea: idea,
      source: item["source"] || "agent",
      endedAt: item["endedAt"],
      guardrail: "selection uses derived summaries only; raw transcript bodies are not dumped"
    })
  '
)"

if (( DRY_RUN == 1 )); then
  printf '%s\n' "$selection_json"
  exit 0
fi

title="$(printf '%s' "$selection_json" | ruby -rjson -e 'puts JSON.parse(STDIN.read).fetch("title")')"
project="$(printf '%s' "$selection_json" | ruby -rjson -e 'puts JSON.parse(STDIN.read).fetch("project")')"
idea="$(printf '%s' "$selection_json" | ruby -rjson -e 'puts JSON.parse(STDIN.read).fetch("idea")')"

"$ROOT/mac-app/scripts/idea.zsh" \
  --title "$title" \
  --project "$project" \
  --source "Terminal Brain Memory Brief" \
  --tag agent-memory \
  --tag memory-promotion \
  "$idea"
