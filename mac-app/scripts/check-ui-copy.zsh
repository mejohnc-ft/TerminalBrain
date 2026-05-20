#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

violations=0
pattern='10028|4231|1\.62M|Jonathan Christensen|value: "Prompt safe"'

if grep -RInE "$pattern" \
  --exclude-dir=.git \
  --exclude-dir=build \
  --exclude-dir=node_modules \
  "$ROOT/mac-app/Sources" "$ROOT/README.md" "$ROOT/AGENTS.md" "$ROOT/mcp-server" >/tmp/terminal-brain-ui-copy-violations.txt; then
  echo "Misleading static UI copy or fake metric found:" >&2
  cat /tmp/terminal-brain-ui-copy-violations.txt >&2
  violations=1
fi

rm -f /tmp/terminal-brain-ui-copy-violations.txt

if [[ "$violations" != "0" ]]; then
  exit 1
fi

echo "ui copy guard ok"
