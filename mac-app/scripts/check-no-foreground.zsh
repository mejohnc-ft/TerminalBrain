#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
violations=0
watch_files=(
  "$ROOT/Makefile"
  "$ROOT/mcp-server/server.mjs"
)

while IFS= read -r -d '' script; do
  watch_files+=("$script")
done < <(find "$ROOT/mac-app/scripts" -type f -name '*.zsh' -print0)

for file in "${watch_files[@]}"; do
  [[ -f "$file" ]] || continue
  if [[ "$file" == "$ROOT/mac-app/scripts/check-no-foreground.zsh" ]]; then
    continue
  fi

  if grep -nE '(^|[[:space:]])open[[:space:]]+-a[[:space:]]+("Terminal Brain"|Terminal\ Brain)' "$file" >/dev/null; then
    echo "Foreground app launch command is not allowed in $file" >&2
    grep -nE '(^|[[:space:]])open[[:space:]]+-a[[:space:]]+("Terminal Brain"|Terminal\ Brain)' "$file" >&2
    violations=1
  fi

  if grep -nE 'osascript.*Terminal Brain|tell application "Terminal Brain"' "$file" >/dev/null; then
    echo "Terminal Brain AppleScript control is not allowed in $file" >&2
    grep -nE 'osascript.*Terminal Brain|tell application "Terminal Brain"' "$file" >&2
    violations=1
  fi
done

if [[ "$violations" != "0" ]]; then
  exit 1
fi

echo "foreground guard ok"
