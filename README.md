# Terminal Brain

Terminal Brain is a native macOS control surface for a local-first personal brain system. It connects local memory, Obsidian-backed writeback, Mission Control retrieval/synthesis, and MCP-accessible agent workflows.

Agent contributors should read `AGENTS.md` before running local commands. The default verification path is non-launching and should not foreground the app.

Common commands:

```zsh
make
make verify
make live
make ask QUERY="what should I work on next?"
make build
make install
make snapshot
make handoff
```

Plain `make` prints help. `make verify`, `make live`, `make build`, and `make install` do not launch or foreground Terminal Brain. `make live` expects the app to already be running.

## Components

- `mac-app/` - SwiftUI macOS app with the local control API on `127.0.0.1:8765`.
- `mcp-server/` - MCP proxy that lets agents call Terminal Brain tools.

## Current Capabilities

- Local status, source, permission, briefing, and sync checks.
- One-call operator snapshot for agents: Focus, Operator Brief, Operator Deck, Radar, setup gaps, Today, memory trail, and suggested next actions.
- Plain-language Operator Brief that says what matters, why it matters, what not to miss, and what artifact to create next.
- Operator Deck for app and agents: do first, ask about, review or capture, and project/start-work cards.
- Prompt-ready Operator Deck Markdown for agent handoffs and quick paste workflows.
- Operator Deck action tool for agents to mark directly actionable Radar and Oracle commit cards without opening the app.
- Latest context pack API/MCP/CLI/Shortcut surface for opening, copying, or handing off the newest agent-ready artifact.
- Prompt-ready Decision Lane Markdown for the ranked Today action queue and project signals.
- Prompt-ready Project Memory Markdown for active work surfaces, recommended actions, context packs, and Oracle reads.
- Single-file handoff API/MCP/CLI generator that combines the Operator Brief, Decision Lane, Operator Deck, Project Memory, and latest context pack.
- Setup readiness checklist for app, MCP config, workspace paths, sync, memory, Mission Control, prompt safety, and Oracle writeback.
- Oracle ask flow with deterministic local fallback and a Focus-grounded ask flow for the current best action.
- Mission-backed retrieval and synthesis when Mission Control is reachable.
- Oracle commit/writeback into the Obsidian-backed `Oracle Inbox`.
- Quick idea capture from Focus or MCP into the same durable review queue.
- Review Queue for committed Oracle reads with triage states.
- Project Memory pages derived from context packs and Oracle commits.
- Project-aware actions for asking Oracle, building packs, committing updates, filtering Review, and delegating reads into Start Work.
- Non-launching Oracle CLI for terminal and agent workflows: `make ask QUERY="what am I missing?"`.
- Proactive Radar for delegated reads, stale reviews, quiet project risks, open loops, and ideas worth testing, with scores, evidence, and persistent watch/acted/snooze/dismiss triage.
- Focus Mode that opens to one recommended action, why it won, the fastest next move, and inline Oracle follow-up prompts.
- Daily Command Center with ranked actions for reviews, delegations, projects, system attention, and fresh context.
- MCP tools for status, snapshot, snapshot Markdown, setup, focus, Operator Brief, focus ask, radar, sources, briefing, permissions, sync, Start Work, Oracle ask, idea capture, Oracle items, and Oracle commits.

## Build

```zsh
./mac-app/scripts/build-app.zsh
```

## Install Locally

```zsh
./mac-app/scripts/install-app.zsh
```

The installer builds the app and copies it to `~/Applications/Terminal Brain.app`. It never launches or foregrounds the app.

## Live Verification

For non-launching local QA:

```zsh
./mac-app/scripts/verify-static.zsh
```

The static verifier checks shell syntax, MCP syntax, Swift type-checking, app build, and secret patterns without launching or foregrounding Terminal Brain.

For API/MCP checks against an already-running app:

```zsh
./mac-app/scripts/verify-live.zsh
```

The live verifier builds the app and checks an already-running Terminal Brain instance: `/health`, `/snapshot`, `/snapshot/markdown`, `/handoff/markdown`, MCP snapshot/handoff tools, MCP syntax, and Swift type-checking. It never launches or foregrounds the app.

To print or copy the current operator snapshot from an already-running app:

```zsh
./mac-app/scripts/oracle.zsh "what should I work on next?"
./mac-app/scripts/snapshot.zsh --markdown
./mac-app/scripts/snapshot.zsh --json
./mac-app/scripts/snapshot.zsh --brief-markdown
./mac-app/scripts/snapshot.zsh --today
./mac-app/scripts/snapshot.zsh --projects
./mac-app/scripts/snapshot.zsh --deck
./mac-app/scripts/snapshot.zsh --deck-markdown
./mac-app/scripts/snapshot.zsh --latest-pack
./mac-app/scripts/snapshot.zsh --markdown --copy
./mac-app/scripts/snapshot.zsh --markdown --output /tmp/terminal-brain-snapshot.md
./mac-app/scripts/handoff.zsh --output /tmp/terminal-brain-handoff.md
```

The Oracle and snapshot helpers never launch or foreground Terminal Brain. `oracle.zsh` prints a prompt-ready Oracle answer, `--brief-markdown` prints the plain-language Operator Brief, `--today` prints the ranked Decision Lane, `--projects` prints Project Memory, `--deck` returns the four Operator Deck cards as JSON, and `--deck-markdown` prints the same deck in prompt-ready Markdown. `--output` is useful for handoffs without touching the clipboard.
The handoff helper also never launches or foregrounds Terminal Brain. It writes the Operator Brief, Decision Lane, Operator Deck, Project Memory, and latest context pack into one Markdown file.

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
