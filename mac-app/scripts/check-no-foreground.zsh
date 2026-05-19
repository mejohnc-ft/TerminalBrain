#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
allowed_open=(
  "$ROOT/mac-app/scripts/install-app.zsh"
  "$ROOT/mac-app/scripts/verify-live.zsh"
)
open_pattern='open -a'
quit_pattern='tell application "Terminal Brain" to quit'

violations=0

while IFS= read -r -d '' file; do
  if [[ "$file" == "$ROOT/mac-app/scripts/check-no-foreground.zsh" ]]; then
    continue
  fi

  if grep -n "$open_pattern" "$file" >/dev/null; then
    allowed=0
    for allowed_file in "${allowed_open[@]}"; do
      if [[ "$file" == "$allowed_file" ]]; then
        allowed=1
        break
      fi
    done
    if [[ "$allowed" != "1" ]]; then
      echo "Foreground launch command is not allowed in $file" >&2
      grep -n "$open_pattern" "$file" >&2
      violations=1
    fi
  fi

  if grep -n "$quit_pattern" "$file" >/dev/null; then
    echo "Terminal Brain quit command is not allowed in $file" >&2
    grep -n "$quit_pattern" "$file" >&2
    violations=1
  fi
done < <(find "$ROOT/mac-app/scripts" -type f -name '*.zsh' -print0)

if [[ "$violations" != "0" ]]; then
  exit 1
fi

echo "foreground guard ok"
