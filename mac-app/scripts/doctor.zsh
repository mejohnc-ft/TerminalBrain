#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
API="${TERMINAL_BRAIN_API:-http://127.0.0.1:8765}"
BUILT_APP="$ROOT/mac-app/build/Terminal Brain.app"
INSTALLED_APP="$HOME/Applications/Terminal Brain.app"
BUILT_EXE="$BUILT_APP/Contents/MacOS/TerminalBrain"
INSTALLED_EXE="$INSTALLED_APP/Contents/MacOS/TerminalBrain"
MCP_SERVER="$ROOT/mcp-server/server.mjs"

case "${1:-}" in
  --help|-h)
    cat <<'EOF'
Usage: ./mac-app/scripts/doctor.zsh

Runs a non-launching Terminal Brain readiness audit:
  - repo and CI state
  - built and installed app bundles
  - installed app freshness against the current build
  - MCP server syntax and tool contract
  - likely Codex/agent MCP config references
  - prompt-prone Apple Notes/Drafts bridge checks
  - app process, launchctl, and API reachability

This script never launches, foregrounds, quits, or controls Terminal Brain.
EOF
    exit 0
    ;;
  "")
    ;;
  *)
    echo "Unknown option: $1" >&2
    echo "Run ./mac-app/scripts/doctor.zsh --help" >&2
    exit 64
    ;;
esac

ok_count=0
warn_count=0
repo_clean=0
ci_green=0
built_ready=0
installed_ready=0
installed_fresh=0
app_running=0
api_ready=0
mcp_syntax_ready=0
mcp_contract_ready=0
agent_config_ready=0
prompt_config_safe=0
bridge_process_safe=0
apple_notes_opt_in_safe=0
runtime_noise_safe=0

ok() {
  ok_count=$((ok_count + 1))
  printf 'ok   %s\n' "$1"
}

warn() {
  warn_count=$((warn_count + 1))
  printf 'warn %s\n' "$1"
}

echo "# Terminal Brain Doctor"
echo
echo "Checked: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo

echo "## Repo"
branch="$(git -C "$ROOT" branch --show-current 2>/dev/null || true)"
head="$(git -C "$ROOT" log -1 --oneline 2>/dev/null || true)"
dirty="$(git -C "$ROOT" status --short 2>/dev/null || true)"
ok "branch ${branch:-unknown}"
ok "head ${head:-unknown}"
if [[ -z "$dirty" ]]; then
  ok "working tree clean"
  repo_clean=1
else
  warn "working tree has uncommitted changes"
  printf '%s\n' "$dirty" | sed 's/^/     /'
fi
echo

echo "## CI"
if command -v gh >/dev/null 2>&1; then
  latest_run="$(gh run list --branch "${branch:-main}" --limit 1 2>/dev/null || true)"
  if [[ -n "$latest_run" ]]; then
    if grep -qE '^completed[[:space:]]+success' <<<"$latest_run"; then
      ok "latest GitHub CI succeeded"
      ci_green=1
    else
      warn "latest GitHub CI is not green"
    fi
    printf '     %s\n' "$latest_run"
  else
    warn "no GitHub CI run found for branch ${branch:-main}"
  fi
else
  warn "GitHub CLI unavailable; cannot read CI state"
fi
echo

echo "## App"
if [[ -d "$BUILT_APP" ]]; then
  ok "built app exists at $BUILT_APP"
  built_ready=1
else
  warn "built app missing; run make build"
fi

if [[ -d "$INSTALLED_APP" ]]; then
  ok "installed app exists at $INSTALLED_APP"
  installed_ready=1
else
  warn "installed app missing; run make install when you want to copy it to ~/Applications"
fi

if [[ -x "$BUILT_EXE" && -x "$INSTALLED_EXE" ]]; then
  if cmp -s "$BUILT_EXE" "$INSTALLED_EXE"; then
    ok "installed app executable matches current build"
    installed_fresh=1
  else
    warn "installed app executable differs from current build; run make install"
  fi
elif [[ -x "$BUILT_EXE" ]]; then
  warn "built app executable exists but installed executable is missing; run make install"
fi

process_pids="$(pgrep -x TerminalBrain 2>/dev/null || true)"
if [[ -n "$process_pids" ]]; then
  ok "TerminalBrain process is running"
  app_running=1
else
  warn "TerminalBrain process is not running; open it manually when you want the UI/API active"
fi

launch_items="$(launchctl list 2>/dev/null | grep -Ei 'terminalbrain|terminal brain' || true)"
if [[ -n "$launch_items" ]]; then
  ok "launchctl has a matching Terminal Brain item"
else
  ok "no Terminal Brain launch agent is loaded"
fi

if curl -fsS --max-time 0.5 "$API/health" >/dev/null 2>&1; then
  ok "API reachable at $API"
  api_ready=1
else
  warn "API not reachable at $API; app-backed tools need the app open"
fi
echo

echo "## MCP"
if [[ -f "$MCP_SERVER" ]]; then
  ok "MCP server exists"
else
  warn "MCP server missing at $MCP_SERVER"
fi

if node --check "$MCP_SERVER" >/dev/null 2>&1; then
  ok "MCP server syntax valid"
  mcp_syntax_ready=1
else
  warn "MCP server syntax check failed; run node --check mcp-server/server.mjs"
fi

if node "$ROOT/mcp-server/check-tools.mjs" >/dev/null 2>&1; then
  ok "MCP tool contract valid"
  mcp_contract_ready=1
else
  warn "MCP tool contract failed; run make mcp-test"
fi

config_hits=()
legacy_autostart_hits=()
config_files=(
  "$HOME/.codex/config.toml"
  "$HOME/.codex/config.json"
  "$HOME/.config/codex/config.toml"
  "$HOME/.config/claude/claude_desktop_config.json"
  "$HOME/Library/Application Support/Claude/claude_desktop_config.json"
)
for file in "${config_files[@]}"; do
  [[ -f "$file" ]] || continue
  if grep -qE 'mcp-server/server\.mjs|TerminalBrain' "$file"; then
    config_hits+=("$file")
  fi
  if grep -qE 'Software/(brain-kernel|terminal-brain-mcp)/server\.mjs|\[mcp_servers\.(local-brain|terminal-brain)\]' "$file"; then
    legacy_autostart_hits+=("$file")
  fi
done

if (( ${#config_hits[@]} > 0 )); then
  ok "agent config references packaged Terminal Brain MCP"
  agent_config_ready=1
  printf '     %s\n' "${config_hits[@]}"
else
  ok "no per-agent Terminal Brain MCP auto-start entries found"
  agent_config_ready=1
fi

if (( ${#legacy_autostart_hits[@]} > 0 )); then
  warn "legacy local-brain/terminal-brain MCP auto-start entries can spawn duplicate Node children"
  printf '     %s\n' "${legacy_autostart_hits[@]}"
else
  ok "no legacy local-brain/terminal-brain MCP auto-start entries found"
fi
echo

echo "## Runtime Noise"
terminal_brain_mcp_processes="$(ps ax -o pid=,args= | grep -E '/Users/.*/Software/terminal-brain-mcp/server\.mjs' | grep -Ev 'grep -E|doctor\.zsh|check-entrypoints\.zsh|verify-static\.zsh' || true)"
brain_kernel_processes="$(ps ax -o pid=,args= | grep -E '/Users/.*/Software/brain-kernel/server\.mjs' | grep -Ev 'grep -E|doctor\.zsh|check-entrypoints\.zsh|verify-static\.zsh' || true)"
terminal_brain_mcp_count="$(printf '%s\n' "$terminal_brain_mcp_processes" | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' ')"
brain_kernel_count="$(printf '%s\n' "$brain_kernel_processes" | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' ')"
if (( terminal_brain_mcp_count > 1 || brain_kernel_count > 1 )); then
  warn "duplicate Terminal Brain MCP/kernel Node children detected"
  [[ -z "$terminal_brain_mcp_processes" ]] || printf '%s\n' "$terminal_brain_mcp_processes" | sed 's/^/     /'
  [[ -z "$brain_kernel_processes" ]] || printf '%s\n' "$brain_kernel_processes" | sed 's/^/     /'
elif (( terminal_brain_mcp_count == 1 || brain_kernel_count == 1 )); then
  ok "single Terminal Brain MCP/kernel child detected"
  runtime_noise_safe=1
else
  ok "no Terminal Brain MCP/kernel Node children detected"
  runtime_noise_safe=1
fi
echo

echo "## Prompt Safety"
prompt_config_hits=()
for file in "${config_files[@]}"; do
  [[ -f "$file" ]] || continue
  if grep -qEi 'apple[-_ ]?notes|drafts[-_ ]?(obsidian|mcp|bridge)' "$file"; then
    prompt_config_hits+=("$file")
  fi
done

if (( ${#prompt_config_hits[@]} > 0 )); then
  warn "common agent config may auto-start prompt-prone Apple Notes/Drafts bridges"
  printf '     %s\n' "${prompt_config_hits[@]}"
else
  ok "no prompt-prone Apple Notes/Drafts MCP auto-start entries found in common configs"
  prompt_config_safe=1
fi

bridge_processes="$(ps ax -o pid=,args= | grep -Ei 'apple[-_ ]?notes|drafts[-_ ]?(obsidian|mcp|bridge)' | grep -Ev 'grep -Ei|doctor\.zsh|check-entrypoints\.zsh|verify-static\.zsh' || true)"
if [[ -n "$bridge_processes" ]]; then
  warn "prompt-prone Apple Notes/Drafts bridge process may be running"
  printf '%s\n' "$bridge_processes" | sed 's/^/     /'
else
  ok "no prompt-prone Apple Notes/Drafts bridge process detected"
  bridge_process_safe=1
fi

if [[ "${EDGE_BRAIN_INCLUDE_APPLE_NOTES:-0}" == "1" ]]; then
  warn "EDGE_BRAIN_INCLUDE_APPLE_NOTES=1; Apple Notes export is opt-in enabled for this shell"
else
  ok "Apple Notes export remains opt-in disabled for this shell"
  apple_notes_opt_in_safe=1
fi
echo

echo "## Summary"
core_ready=0
if (( repo_clean && ci_green && built_ready && installed_ready && installed_fresh && mcp_syntax_ready && mcp_contract_ready && agent_config_ready && runtime_noise_safe && prompt_config_safe && bridge_process_safe && apple_notes_opt_in_safe )); then
  core_ready=1
fi

if (( core_ready && api_ready )); then
  echo "- readiness: app-backed ready"
elif (( core_ready && app_running )); then
  echo "- readiness: package ready, but app API is not reachable"
elif (( core_ready )); then
  echo "- readiness: package ready; open Terminal Brain manually for app-backed tools"
else
  echo "- readiness: needs setup attention"
fi
echo "- ok: $ok_count"
echo "- warnings: $warn_count"
echo "- next: run make use-now for one move, compact context, ask, capture, delegate, and close-loop commands"
echo "- guardrail: doctor did not launch or foreground Terminal Brain"
