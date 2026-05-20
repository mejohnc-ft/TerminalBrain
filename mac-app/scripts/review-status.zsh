#!/usr/bin/env zsh
set -euo pipefail

WORKSPACE="${TERMINAL_BRAIN_WORKSPACE:-$HOME/mejohnwc}"
ID="${ID:-}"
STATUS="${STATUS:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --id)
      ID="${2:-}"
      shift
      ;;
    --id=*)
      ID="${1#--id=}"
      ;;
    --status)
      STATUS="${2:-}"
      shift
      ;;
    --status=*)
      STATUS="${1#--status=}"
      ;;
    --help|-h)
      cat <<'EOF'
Usage: ./mac-app/scripts/review-status.zsh --id NOTE_PATH --status STATUS

Sets reviewStatus on an Oracle Inbox note without opening Terminal Brain.
Allowed statuses: new, accepted, linked, delegated, dismissed.

This script never launches, foregrounds, quits, kills, or controls Terminal Brain.
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Run ./mac-app/scripts/review-status.zsh --help" >&2
      exit 64
      ;;
  esac
  shift
done

if [[ -z "$ID" || -z "$STATUS" ]]; then
  echo "--id and --status are required." >&2
  exit 64
fi

WORKSPACE="$WORKSPACE" ID="$ID" STATUS="$STATUS" ruby -rjson -e '
  workspace = File.expand_path(ENV.fetch("WORKSPACE"))
  inbox = File.expand_path(File.join(workspace, "Oracle Inbox"))
  id = File.expand_path(ENV.fetch("ID"))
  status = ENV.fetch("STATUS").strip.downcase
  allowed = ["new", "accepted", "linked", "delegated", "dismissed"]

  unless allowed.include?(status)
    warn "Invalid status: #{status}. Allowed: #{allowed.join(", ")}"
    exit 64
  end

  unless id.start_with?(inbox + File::SEPARATOR) && id.end_with?(".md")
    warn "Review note must be a Markdown file inside #{inbox}"
    exit 64
  end

  unless File.file?(id)
    warn "Review note does not exist: #{id}"
    exit 66
  end

  text = File.read(id)
  if text.start_with?("---\n") && (finish = text.index("\n---\n", 4))
    frontmatter = text[0...finish]
    remainder = text[(finish + 5)..-1] || ""
    replaced = false
    next_lines = frontmatter.lines.map do |line|
      if line.start_with?("reviewStatus:")
        replaced = true
        "reviewStatus: #{status}\n"
      else
        line
      end
    end
    next_text = next_lines.join
    next_text += "reviewStatus: #{status}\n" unless replaced
    text = "#{next_text}---\n#{remainder}"
  else
    text = "---\nreviewStatus: #{status}\n---\n\n#{text}"
  end

  File.write(id, text)
  puts JSON.generate({
    ok: true,
    mode: "local-fallback",
    id: id,
    status: status,
    guardrail: "review status fallback did not launch or foreground Terminal Brain"
  })
'
