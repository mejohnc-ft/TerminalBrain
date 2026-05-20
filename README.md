# Terminal Brain

Terminal Brain is a native macOS control surface for a local-first personal brain system. It connects local memory, Obsidian-backed writeback, Mission Control retrieval/synthesis, and MCP-accessible agent workflows.

Agent contributors should read `AGENTS.md` before running local commands. The default verification path is non-launching and should not foreground the app.

For the shortest value path, start with [`START-HERE.md`](START-HERE.md).

Common commands:

```zsh
make
make value
make next
make doctor
make status
make verify
make live
make ask QUERY="what should I work on next?"
make ask-commit QUERY="what changed?" PROJECT="Terminal Brain"
make outcome TITLE="Shipped Review Queue" OUTCOME="Added triage for committed Oracle reads." PROJECT="Terminal Brain" NEXT="Review stale reads tomorrow."
make build
make install
make snapshot
make snapshot-value
make snapshot-digest
make snapshot-blindspots
make snapshot-ideas
make agent-prompt
make start-here
make handoff
```

Plain `make` prints help. `make verify`, `make status`, `make next`, `make value`, `make doctor`, `make live`, `make build`, and `make install` do not launch or foreground Terminal Brain. `make value` explains what value is available now and prints the live Value Brief when the app is reachable. `make next` prints Start Here when the app is reachable, or a safe status and manual next step when it is closed. `make doctor` audits repo, CI, app install freshness, MCP contract, agent config references, prompt-prone Apple Notes/Drafts bridges, process state, launchctl, API readiness, and an explicit readiness verdict. `make status` answers what is currently running across repo, CI, process, launchctl, and localhost API state. `make live` expects the app to already be running.

## Components

- `mac-app/` - SwiftUI macOS app with the local control API on `127.0.0.1:8765`.
- `mcp-server/` - MCP proxy that lets agents call Terminal Brain tools.

## Current Capabilities

- Local status, source, permission, briefing, and sync checks.
- One-call operator snapshot for agents: Focus, Operator Brief, Operator Deck, Blindspot Brief, Radar, setup gaps, Today, memory trail, and suggested next actions.
- Plain-language Operator Brief that says what matters, why it matters, what not to miss, and what artifact to create next.
- Value Brief that collapses Focus, Idea Pulse, Blindspots, and Project Memory into one compact value read.
- Oracle Digest that turns current signals into a Notice / Decide / Test / Create / Avoid read for the next work block, available in the app, command palette, App Shortcuts, CLI, API, and MCP.
- Start Here app/API/MCP/CLI/App Shortcut surface that gives a one-block path from digest to agent prompt to context pack to structured outcome writeback, with direct copy actions in the app, menu bar, command palette, and Shortcuts.
- Runtime Status, Doctor, Value, and Next Move for humans and agents: `make value`, `make next`, `make status`, `make doctor`, `terminal_brain_value_now_markdown`, `terminal_brain_next_markdown`, `terminal_brain_doctor_markdown`, and `terminal_brain_runtime_status` report what value is available, what to do, repo, CI, process, launchctl, app install, MCP contract, agent config, and API state without requiring or launching the app.
- Native Value Now landing surface so the app opens on the plain-language value read, fastest useful path, and outcome close loop instead of a metrics-first dashboard.
- Agent Prompt generator that turns the Oracle Digest and Value Brief into a concise Codex/Claude execution prompt with acceptance criteria and guardrails.
- Structured Outcome commit endpoint/tool/CLI so agents can write back what changed, evidence, and next action without launching the app; outcome notes enter memory as accepted instead of unresolved review items.
- Operator Deck for app and agents: do first, ask about, review or capture, and project/start-work cards.
- Prompt-ready Operator Deck Markdown for agent handoffs and quick paste workflows.
- Operator Deck action tool for agents to mark directly actionable Radar and Oracle commit cards without opening the app.
- Blindspot Brief that highlights ignored, stale, under-tested, or unresolved work before broad planning.
- Native app section, command palette entries, copy action, and App Shortcut for the Blindspot Brief.
- Blindspot Oracle ask and ask-and-commit tools for turning counter-signals into durable reads.
- Blindspot action tool for resolving directly actionable Oracle commit and Radar sources.
- Idea Pulse for captured thoughts and resurfaced opportunities ranked by cheap-test value, available in the app, handoff, menu bar, App Shortcuts, CLI, API, and MCP.
- Idea Pulse ask and ask-and-commit tools for pressure-testing ideas with cheap tests, kill criteria, and first actions.
- Latest context pack API/MCP/CLI/Shortcut surface for opening, copying, or handing off the newest agent-ready artifact.
- Prompt-ready Decision Lane Markdown for the ranked Today action queue and project signals.
- Prompt-ready Project Memory Markdown for active work surfaces, recommended actions, context packs, and Oracle reads.
- Single-file handoff API/MCP/CLI generator that combines Start Here, the Oracle Digest, Value Brief, Operator Brief, Blindspot Brief, Idea Pulse, Decision Lane, Operator Deck, Project Memory, and latest context pack.
- Focused agent prompt API/MCP/CLI generator for handing one concrete next task to Codex or Claude.
- Setup readiness checklist for app, MCP config, workspace paths, sync, memory, Mission Control, prompt safety, and Oracle writeback.
- Oracle ask flow with deterministic local fallback and a Focus-grounded ask flow for the current best action.
- Mission-backed retrieval and synthesis when Mission Control is reachable.
- Oracle commit/writeback into the Obsidian-backed `Oracle Inbox`.
- Quick idea capture from Focus or MCP into the same durable review queue.
- Review Queue for committed Oracle reads with triage states.
- Project Memory pages derived from context packs and Oracle commits.
- Project-aware actions for asking Oracle, building packs, committing updates, filtering Review, and delegating reads into Start Work.
- Non-launching Oracle and outcome CLIs for terminal and agent workflows: `make ask QUERY="what am I missing?"`, `make ask-commit QUERY="what changed?" PROJECT="Terminal Brain"`, or `make outcome TITLE="Shipped fix" OUTCOME="What changed and why it matters." PROJECT="Terminal Brain" NEXT="Next concrete action."`.
- Proactive Radar for delegated reads, stale reviews, quiet project risks, open loops, and ideas worth testing, with scores, evidence, and persistent watch/acted/snooze/dismiss triage.
- Focus Mode that opens to one recommended action, why it won, the fastest next move, and inline Oracle follow-up prompts.
- Daily Command Center with ranked actions for reviews, delegations, projects, system attention, and fresh context.
- MCP tools for next move, doctor, runtime status, app status, snapshot, snapshot Markdown, setup, focus, Start Here, Value Brief, Oracle Digest, Agent Prompt, Blindspot Brief, Idea Pulse, Idea ask, Idea ask-and-commit, Blindspot ask, Blindspot ask-and-commit, Blindspot action, Operator Brief, focus ask, focus ask-and-commit, radar, sources, briefing, permissions, sync, Start Work, Oracle ask, ask-and-commit, outcome commit, idea capture, Oracle items, Oracle commits, and Oracle review status.

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

The static verifier checks shell syntax, MCP syntax, Swift type-checking, app build, value-surface coverage, entrypoint fallbacks, no-foreground guardrails, and secret patterns without launching or foregrounding Terminal Brain. The foreground guard rejects `open -a`, direct app-bundle `open`, AppleScript app control, and Computer Use automation hooks in scripts and MCP tooling.

For a non-launching status check:

```zsh
make status
```

This prints the repo state, latest CI run, local process state, launchctl registration state, and localhost API health without starting the app.

For the safest first command:

```zsh
make next
```

This prints Start Here if Terminal Brain is already reachable. If it is closed, it prints the manual next step and status without starting anything.

For the value read:

```zsh
make value
```

This prints the live Value Brief if Terminal Brain is reachable. If it is closed, it explains what the system is useful for and what to run next.

For a non-launching readiness audit:

```zsh
make doctor
```

This checks repo and CI state, app build/install state and freshness, MCP syntax and tool contract, common agent config references, prompt-prone Apple Notes/Drafts bridges, process state, launchctl, localhost API readiness, and a single readiness verdict.

For API/MCP checks against an already-running app:

```zsh
./mac-app/scripts/verify-live.zsh
```

The live verifier builds the app and checks an already-running Terminal Brain instance: `/health`, `/snapshot`, `/snapshot/markdown`, `/handoff/markdown`, `/agent-prompt/markdown`, MCP snapshot/handoff/prompt tools, MCP syntax, and Swift type-checking. It never launches or foregrounds the app.

To print or copy the current operator snapshot from an already-running app:

```zsh
./mac-app/scripts/oracle.zsh "what should I work on next?"
./mac-app/scripts/oracle.zsh --commit --project "Terminal Brain" "what changed?"
./mac-app/scripts/outcome.zsh --title "Shipped Review Queue" --project "Terminal Brain" --next "Review stale reads tomorrow." "Added triage for committed Oracle reads."
./mac-app/scripts/snapshot.zsh --markdown
./mac-app/scripts/snapshot.zsh --json
./mac-app/scripts/snapshot.zsh --value
./mac-app/scripts/snapshot.zsh --digest
./mac-app/scripts/snapshot.zsh --brief-markdown
./mac-app/scripts/snapshot.zsh --today
./mac-app/scripts/snapshot.zsh --blindspots
./mac-app/scripts/snapshot.zsh --ideas
./mac-app/scripts/snapshot.zsh --projects
./mac-app/scripts/snapshot.zsh --deck
./mac-app/scripts/snapshot.zsh --deck-markdown
./mac-app/scripts/snapshot.zsh --latest-pack
./mac-app/scripts/snapshot.zsh --agent-prompt
./mac-app/scripts/snapshot.zsh --start-here
./mac-app/scripts/snapshot.zsh --markdown --copy
./mac-app/scripts/snapshot.zsh --markdown --output /tmp/terminal-brain-snapshot.md
./mac-app/scripts/handoff.zsh --output /tmp/terminal-brain-handoff.md
```

The Oracle, outcome, and snapshot helpers never launch or foreground Terminal Brain. `oracle.zsh` prints a prompt-ready Oracle answer and can commit it with `--commit`; `outcome.zsh` writes a structured result with title, outcome, evidence, next action, project, and source through an already-running app; `--value` prints the compact Value Brief, `--digest` prints the Notice / Decide / Test / Create / Avoid Oracle Digest, `--start-here` prints the one-block value path, `--agent-prompt` prints a focused Codex/Claude execution prompt, `--brief-markdown` prints the plain-language Operator Brief, `--today` prints the ranked Decision Lane, `--blindspots` prints the counter-signal brief, `--ideas` prints Idea Pulse, `--projects` prints Project Memory, `--deck` returns the four Operator Deck cards as JSON, and `--deck-markdown` prints the same deck in prompt-ready Markdown. `--output` is useful for handoffs without touching the clipboard.
The handoff helper also never launches or foregrounds Terminal Brain. It writes Start Here, the Oracle Digest, Value Brief, Operator Brief, Blindspot Brief, Idea Pulse, Decision Lane, Operator Deck, Project Memory, and latest context pack into one Markdown file.

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
