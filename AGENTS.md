# Terminal Brain Agent Rules

This repository builds a local macOS app used during active work. Do not steal the operator's focus.

## Safe Defaults

- Use `./mac-app/scripts/verify-static.zsh` for normal verification.
- Use `./mac-app/scripts/build-app.zsh` for build-only checks.
- Use `./mac-app/scripts/verify-static.zsh` for Swift type-checking because the app now depends on SwiftUI, AppKit, Network, and AppIntents framework flags.
- Use `node --check mcp-server/server.mjs` for MCP syntax checks.

## Fast Context Path

When Terminal Brain is already running and the user asks for useful work, start from the handoff instead of re-discovering the system:

```zsh
./mac-app/scripts/handoff.zsh --output /tmp/terminal-brain-handoff.md
```

The handoff combines the Operator Brief, Decision Lane, Operator Deck, and latest context pack. It never launches or foregrounds Terminal Brain. If using MCP, prefer `terminal_brain_handoff_markdown` as the first read, then use the Decision Lane, Operator Deck, and Start Work tools for follow-up actions.

## Foregrounding Policy

Do not run commands that launch, relaunch, quit, or foreground Terminal Brain unless the user explicitly asks for that behavior in the current turn.

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

The static verifier includes a foreground guard that rejects script-level `open -a` calls.

Run live API/MCP verification only when Terminal Brain is already running and the user has not objected to localhost checks:

```zsh
./mac-app/scripts/verify-live.zsh
```

If the live verifier says the app is not reachable, stop. Do not try to start the app.
