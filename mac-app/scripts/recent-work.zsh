#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORKSPACE="${TERMINAL_BRAIN_WORKSPACE:-$HOME/mejohnwc}"
INDEX="${INDEX:-1}"
PROJECT="${PROJECT:-Terminal Brain}"
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --index)
      INDEX="${2:-1}"
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
Usage: ./mac-app/scripts/recent-work.zsh [--index N] [--project PROJECT] [--dry-run]

Promotes one recent git commit into the Oracle Inbox as reviewable memory.
The ranking matches Bubble Up's Recent Work Signals: newest commit first.

This script never launches, foregrounds, quits, kills, or controls Terminal Brain.

Environment:
  TERMINAL_BRAIN_WORKSPACE  Workspace/vault path. Default: ~/mejohnwc
  INDEX                     One-based recent commit index. Default: 1.
  PROJECT                   Project name for the captured note. Default: Terminal Brain.
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Run ./mac-app/scripts/recent-work.zsh --help" >&2
      exit 64
      ;;
  esac
  shift
done

selection_json="$(
  ROOT="$ROOT" WORKSPACE="$WORKSPACE" INDEX="$INDEX" PROJECT="$PROJECT" ruby -rjson -e '
    root = ENV.fetch("ROOT")
    workspace = ENV.fetch("WORKSPACE")
    index = Integer(ENV.fetch("INDEX", "1"))
    project = ENV.fetch("PROJECT", "Terminal Brain").strip
    project = "Terminal Brain" if project.empty?
    unless Dir.exist?(File.join(root, ".git"))
      warn "No git repository found at #{root}."
      exit 66
    end
    def meaningful_words(value)
      stop = %w[the and for with from this that into after before because should what when where were was are has have had queue clean fresh work recent follow outcome action terminal brain]
      value.to_s.downcase.scan(/[a-z0-9]+/)
        .map { |word| word.length > 3 ? word.sub(/s\z/, "") : word }
        .reject { |word| word.length < 3 || stop.include?(word) }
        .uniq
    end

    def normalized_phrase(value)
      value.to_s.downcase.scan(/[a-z0-9]+/).join(" ").strip
    end

    def operator_facing_commit?(subject)
      value = subject.to_s.downcase
      return true if value.match?(/\b(use now|start here|what now|oracle|idea|work block|sidebar|settings|menu|shortcut|native|no-choice|widget|visual|design|liquid|profile|source|memory|drafts|apple notes)\b/)
      return false if value.match?(/\b(verifier|verification|audit|coverage|entrypoint|regression|doctor|ci|timeout|guard|guardrail|matcher|recent work signals?|runtime noise|support bundle|prompt wording|first prompts|alias|guidance|contract|manifest)\b/)
      true
    end

    def parse_memory_notes(workspace)
      inbox = File.join(workspace, "Oracle Inbox")
      return [] unless Dir.exist?(inbox)
      Dir.children(inbox).select { |name| name.end_with?(".md") }.map do |name|
        text = File.read(File.join(inbox, name))
        status = text[/^reviewStatus:\s*(.+)$/i, 1].to_s.strip.downcase
        next unless ["accepted", "linked"].include?(status)
        text.downcase
      rescue
        nil
      end.compact
    end

    def memory_covers_commit?(commit, memory_texts)
      memory_texts.any? do |text|
        return true if !commit[:short].to_s.empty? && text.include?(commit[:short].downcase)
        return true if !commit[:full].to_s.empty? && text.include?(commit[:full].downcase)
        subject = normalized_phrase(commit[:subject])
        next false if subject.empty?
        normalized_text = normalized_phrase(text)
        normalized_text.include?(subject)
      end
    end

    memory_texts = parse_memory_notes(workspace)
    output = IO.popen(["git", "-C", root, "log", "-50", "--pretty=format:%h%x09%H%x09%cr%x09%ci%x09%s"], &:read).to_s
    commits = output.lines.map do |line|
      short, full, age, committed_at, subject = line.chomp.split("\t", 5)
      next if subject.to_s.strip.empty?
      {
        short: short.to_s,
        full: full.to_s,
        age: age.to_s,
        committedAt: committed_at.to_s,
        subject: subject.to_s.strip
      }
    end.compact
      .select { |commit| operator_facing_commit?(commit[:subject]) }
      .reject { |commit| memory_covers_commit?(commit, memory_texts) }
    commit = commits[index - 1]
    unless commit
      warn "No uncaptured recent work signal at index #{index}. Run make bubble-up to see available commits."
      exit 66
    end
    title = "Follow up: #{commit[:subject]}"
    idea = [
      "Recent shipped work needs durable review memory.",
      "Commit: #{commit[:short]} (#{commit[:full]}), #{commit[:age]}, committed #{commit[:committedAt]}.",
      "Change: #{commit[:subject]}.",
      "Capture what changed, why it mattered, remaining risk, and the next action so future agents do not see only the commit without the judgment behind it."
    ].join(" ")
    puts JSON.generate({
      ok: true,
      index: index,
      title: title,
      project: project,
      idea: idea,
      commit: commit,
      guardrail: "recent-work promotion did not launch or foreground Terminal Brain"
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

TERMINAL_BRAIN_WORKSPACE="$WORKSPACE" "$ROOT/mac-app/scripts/idea.zsh" \
  --title "$title" \
  --project "$project" \
  --source "Terminal Brain Recent Work" \
  --tag git \
  --tag recent-work \
  "$idea"
