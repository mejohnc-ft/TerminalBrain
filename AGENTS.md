# Terminal Brain Agent Rules

This repository builds a local macOS app used during active work. Do not steal the operator's focus.

## Safe Defaults

- Use `make next` as the safest first command when you need to know the next move without launching the app.
- Use `make value` when the operator needs a plain-language read on why Terminal Brain is useful right now.
- Use `make doctor` when setup readiness is unclear; it audits repo, CI, app install freshness, MCP contract, agent config, prompt-prone Apple Notes/Drafts bridges, process state, launchctl, API reachability, and a readiness verdict without launching the app.
- Use `make audit` when you need a non-launching evidence checklist for value, MCP, safety, and readiness surfaces.
- Use `make processes` when the operator asks what is still running; it maps Terminal Brain, launchctl, API, Codex, MCP, brain-kernel, brain-console, and Drafts state without launching, foregrounding, quitting, or killing anything.
- Use `./mac-app/scripts/verify-static.zsh` for normal verification.
- Use `./mac-app/scripts/build-app.zsh` for build-only checks.
- Use `./mac-app/scripts/verify-static.zsh` for Swift type-checking because the app now depends on SwiftUI, AppKit, Network, and AppIntents framework flags.
- Use `node --check mcp-server/server.mjs` for MCP syntax checks.

## Fast Context Path

When Terminal Brain may not be running, use `make value`, `make next`, `make status`, `make processes`, `make doctor`, `make audit`, MCP `terminal_brain_value_now_markdown`, MCP `terminal_brain_next_markdown`, MCP `terminal_brain_doctor_markdown`, MCP `terminal_brain_audit_markdown`, or MCP `terminal_brain_runtime_status` first. These checks do not launch or foreground the app.

When Terminal Brain is already running and the user asks for useful work, start from the handoff instead of re-discovering the system:

```zsh
./mac-app/scripts/handoff.zsh --output /tmp/terminal-brain-handoff.md
```

The handoff combines Start Here, the Oracle Digest, Value Brief, Operator Brief, Blindspot Brief, Idea Pulse, Decision Lane, Operator Deck, Project Memory, and latest context pack. It never launches or foregrounds Terminal Brain. If using MCP, prefer `terminal_brain_start_here_markdown` when you need the shortest value path, `terminal_brain_agent_prompt_markdown` when you need one focused execution prompt, or `terminal_brain_handoff_markdown` when you need the broader state. Then use `terminal_brain_oracle_digest_markdown`, `terminal_brain_value_brief_markdown`, Idea Pulse ask/commit, Blindspot ask/commit, Decision Lane, Project Memory, Operator Deck, and Start Work tools for follow-up actions. When work produces a durable result, close the loop with `terminal_brain_commit_outcome` or `make outcome TITLE="..." OUTCOME="..." PROJECT="..." NEXT="..."`.

## Foregrounding Policy

Do not run commands that launch, relaunch, quit, or foreground Terminal Brain unless the user explicitly asks for that behavior in the current turn.

Do not use Computer Use, AppleScript UI control, or any other UI automation against Terminal Brain unless the user explicitly asks for a visual/UI inspection in the current turn.

Do not run these without explicit user approval:

```zsh
open -a ...
osascript -e 'tell application "Terminal Brain" to quit'
```

`install-app.zsh` and `verify-live.zsh` never launch or foreground the app. Their old `--launch` mode is intentionally disabled.

## Verification

Before committing code, run:

```zsh
./mac-app/scripts/verify-static.zsh
```

The static verifier includes a foreground guard that rejects script-level `open -a`, app-bundle `open`, AppleScript control, and Computer Use automation hooks in scripts and MCP tooling.

Run live API/MCP verification only when Terminal Brain is already running and the user has not objected to localhost checks:

```zsh
./mac-app/scripts/verify-live.zsh
```

If the live verifier says the app is not reachable, stop. Do not try to start the app.
