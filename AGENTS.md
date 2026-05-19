# Terminal Brain Agent Rules

This repository builds a local macOS app used during active work. Do not steal the operator's focus.

## Safe Defaults

- Use `./mac-app/scripts/verify-static.zsh` for normal verification.
- Use `./mac-app/scripts/build-app.zsh` for build-only checks.
- Use `swiftc -typecheck mac-app/Sources/TerminalBrain/*.swift` for fast Swift checks.
- Use `node --check mcp-server/server.mjs` for MCP syntax checks.

## Foregrounding Policy

Do not run commands that launch, relaunch, quit, or foreground Terminal Brain unless the user explicitly asks for that behavior in the current turn.

Do not run these without explicit user approval:

```zsh
open -a ...
./mac-app/scripts/install-app.zsh --launch
./mac-app/scripts/verify-live.zsh --launch
osascript -e 'tell application "Terminal Brain" to quit'
```

`install-app.zsh` and `verify-live.zsh` are safe by default, but their `--launch` mode is not.

## Verification

Before committing code, run:

```zsh
./mac-app/scripts/verify-static.zsh
```

Run live API/MCP verification only when Terminal Brain is already running and the user has not objected to localhost checks:

```zsh
./mac-app/scripts/verify-live.zsh
```

If the live verifier says the app is not reachable, stop. Do not rerun with `--launch` unless the user explicitly asks.
