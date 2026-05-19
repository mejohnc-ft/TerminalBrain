# Terminal Brain

Terminal Brain is a native macOS control surface for a local-first personal brain system. It connects local memory, Obsidian-backed writeback, Mission Control retrieval/synthesis, and MCP-accessible agent workflows.

## Components

- `mac-app/` - SwiftUI macOS app with the local control API on `127.0.0.1:8765`.
- `mcp-server/` - MCP proxy that lets agents call Terminal Brain tools.

## Current Capabilities

- Local status, source, permission, briefing, and sync checks.
- One-call operator snapshot for agents: Focus, Radar, setup gaps, Today, memory trail, and suggested next actions.
- Setup readiness checklist for app, MCP config, workspace paths, sync, memory, Mission Control, prompt safety, and Oracle writeback.
- Oracle ask flow with deterministic local fallback and a Focus-grounded ask flow for the current best action.
- Mission-backed retrieval and synthesis when Mission Control is reachable.
- Oracle commit/writeback into the Obsidian-backed `Oracle Inbox`.
- Quick idea capture from Focus or MCP into the same durable review queue.
- Review Queue for committed Oracle reads with triage states.
- Project Memory pages derived from context packs and Oracle commits.
- Project-aware actions for asking Oracle, building packs, committing updates, filtering Review, and delegating reads into Start Work.
- Proactive Radar for delegated reads, stale reviews, quiet project risks, open loops, and ideas worth testing, with scores, evidence, and persistent watch/acted/snooze/dismiss triage.
- Focus Mode that opens to one recommended action, why it won, the fastest next move, and inline Oracle follow-up prompts.
- Daily Command Center with ranked actions for reviews, delegations, projects, system attention, and fresh context.
- MCP tools for status, snapshot, setup, focus, focus ask, radar, sources, briefing, permissions, sync, Start Work, Oracle ask, idea capture, Oracle items, and Oracle commits.

## Build

```zsh
./mac-app/scripts/build-app.zsh
```

## Live Verification

```zsh
./mac-app/scripts/verify-live.zsh
```

The live verifier builds the app, launches it, checks `/health`, `/snapshot`, `/snapshot/markdown`, the MCP snapshot tool, MCP syntax, and Swift type-checking.

The built app is emitted to:

```text
mac-app/build/Terminal Brain.app
```

## MCP Server

```zsh
node mcp-server/server.mjs
```

By default the MCP server targets:

```text
http://127.0.0.1:8765
```

Override with:

```zsh
TERMINAL_BRAIN_API=http://127.0.0.1:8765 node mcp-server/server.mjs
```

## Configuration

The app reads integration settings from its native Settings window, with environment variables available for automation:

| Setting | Environment Variable |
| --- | --- |
| Workspace path | `TERMINAL_BRAIN_WORKSPACE` |
| Mission URL | `TERMINAL_BRAIN_MISSION_URL` |
| Mission SSH host | `TERMINAL_BRAIN_MISSION_SSH_HOST` |
| Brain CLI path | `TERMINAL_BRAIN_CLI` |
| Sync script path | `TERMINAL_BRAIN_SYNC_SCRIPT` |
| Sync log path | `TERMINAL_BRAIN_SYNC_LOG` |

Environment variables take precedence over saved Settings values.

## Notes

This repo intentionally excludes generated app builds, local environment files, secrets, and runtime logs.
