# Terminal Brain

Terminal Brain is the native macOS control surface for the local Franklin Brain stack.

It is intentionally passive on startup:

- It checks MCP process state.
- It verifies Codex and workspace MCP config.
- It reads local derived Brain index metadata.
- It checks Mission Control reachability.
- It does not read Apple Notes unless you press **Check Notes Permission** or run a manual sync with Apple Notes enabled.
- It can build Start Work context packs from the first-party local brain kernel.

## Build

```zsh
./scripts/build-app.zsh
```

The built app is written to:

```text
build/Terminal Brain.app
```

## First-Run Permission Model

macOS grants Apple Events permissions to the app bundle identity:

```text
com.franklin.terminal-brain
```

That means Apple Notes prompts should say **Terminal Brain**, not `node`, once Notes access is moved behind this app. The v0.1 app only probes Notes when explicitly requested.

## Controls

- **Refresh**: Re-check local MCP, config, index, and Mission Control status.
- **Run Sync**: Execute the Edge Brain sync wrapper with Apple Notes disabled unless the manual toggle is on.
- **Check Notes Permission**: Ask Apple Notes for a note count using the Terminal Brain app identity.
- **Mission**: Open Mission Control.
- **Logs**: Open the Edge Brain sync log.
- **Vault**: Open the local Obsidian vault folder.

## Views

- **Cockpit**: Current health across MCP, config, indexes, sync, and Mission Control.
- **Focus**: The default working surface with a plain-language Operator Brief, one recommended action, score, evidence, immediate next moves, inline Oracle follow-up prompts, and quick thought capture.
- **Setup**: Readiness checklist for app, MCP config, workspace, sync, memory, Mission Control, prompt safety, and Oracle writeback.
- **Radar**: Proactive inbox for delegated reads, stale reviews, quiet project risks, open loops, and ideas worth testing. Radar signals include score/evidence, can be watched, marked acted, snoozed, dismissed, or committed back into the Oracle Inbox as durable memory.
- **Sources**: Permission-aware status for Obsidian, agent histories, Drafts, Apple Notes, and Mission Control.
- **Today**: Daily Command Center with ranked actions from review state, delegated reads, projects, source health, and fresh context.
- **Start Work**: Creates a context pack from the local brain kernel before handing work to an agent.
- **Oracle**: Ask Terminal Brain for grounded synthesis from local signals and Mission retrieval.
- **Review**: Triage committed Oracle reads as new, accepted, linked, delegated, or dismissed.
- **Projects**: Durable project memory pages derived from context packs and Oracle commits.
- **System**: Tracks native macOS surfaces such as menu bar extra, settings, local API, widgets, login item, and shortcuts.

Project pages include direct actions for asking a project-scoped Oracle question, building a project context pack, committing a project update, and opening the latest pack. Review can be filtered by project, and delegated reads can be sent straight into Start Work.
Today turns those signals into a short command queue so the app opens on what to do first.

## macOS Shell

Terminal Brain uses a native macOS window shell:

- `NavigationSplitView` for the sidebar/detail structure.
- Transparent full-size titlebar configured through AppKit.
- Native toolbar items for sidebar toggle, back, search, status, refresh, sync, and profile.
- Command palette entries for asking the current Focus, copying the operator snapshot, Operator Brief, Decision Lane, Project Memory, or Operator Deck, asking Oracle from typed text, drafting captured ideas, and building context packs.
- One-click operator snapshot, Operator Brief, and Operator Deck copy for pasting current Focus, Radar, suggested actions, memory trail, or handoff into another agent or work surface.
- App Shortcuts for Ask Oracle, Capture Idea, Copy Handoff, Copy Brief, Copy Decision Lane, Copy Project Memory, Copy Deck, Copy Snapshot, Run Sync, Start Work, Open Latest Context Pack, and Copy Latest Context Pack in Spotlight, Siri, and automation.
- Menu bar extra with current Focus, Ask Current Focus, Build Focus Pack, Open/Copy Latest Context Pack, Copy Agent Handoff, Copy Operator Brief, Copy Decision Lane, Copy Project Memory, refresh, sync, copy, Mission, and logs.
- Floating rounded sidebar surface over the main background.
- Dense Music/Reeder-style dark content lists instead of equal-weight dashboard cards.

Start Work uses the local brain kernel configured in `Paths.brainCLI` and writes context packs under the local workspace `.brain/context-packs` folder.

Run the static verifier after normal integration changes. It does not launch or foreground Terminal Brain:

```zsh
./mac-app/scripts/verify-static.zsh
```

Run the live verifier only when Terminal Brain is already running and API/MCP behavior needs to be checked:

```zsh
./mac-app/scripts/verify-live.zsh
```

The verifier checks an already-running app. It never launches or foregrounds Terminal Brain.

Print or copy the current operator snapshot from an already-running app:

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

The Oracle and snapshot helpers never launch or foreground Terminal Brain. Use `oracle.zsh` for a prompt-ready answer, `--brief-markdown` for the plain-language value read, `--today` for the ranked Decision Lane, `--projects` for Project Memory, `--deck` for app-aligned action-card JSON, `--deck-markdown` for paste-ready cards, `--latest-pack` for the newest context pack Markdown, and `--output` for handoff files.
The handoff helper also never launches or foregrounds Terminal Brain. It writes the Operator Brief, Decision Lane, Operator Deck, Project Memory, and latest context pack into one Markdown file.

Install the app into `~/Applications`:

```zsh
./mac-app/scripts/install-app.zsh
```

The installer never launches or foregrounds Terminal Brain.

Integration paths are editable in the native Settings window. Environment variables can override saved settings for automation:

- `TERMINAL_BRAIN_WORKSPACE`
- `TERMINAL_BRAIN_MISSION_URL`
- `TERMINAL_BRAIN_MISSION_SSH_HOST`
- `TERMINAL_BRAIN_CLI`
- `TERMINAL_BRAIN_SYNC_SCRIPT`
- `TERMINAL_BRAIN_SYNC_LOG`

## Local Control API

When Terminal Brain is running, it exposes a localhost-only control API:

```text
http://127.0.0.1:8765
```

Routes:

- `GET /health`
- `GET /status`
- `GET /snapshot`
- `GET /snapshot/markdown`
- `GET /handoff/markdown`
- `GET /sources`
- `GET /setup`
- `GET /focus`
- `GET /operator-brief`
- `GET /operator-brief/markdown`
- `GET /context-packs/latest`
- `GET /context-packs/latest/markdown`
- `GET /operator-deck`
- `GET /operator-deck/markdown`
- `POST /operator-deck/action`
- `POST /focus/ask`
- `GET /radar`
- `POST /radar/disposition`
- `GET /today`
- `GET /today/markdown`
- `GET /projects`
- `GET /projects/markdown`
- `GET /briefing`
- `GET /permissions`
- `GET /oracle/brief`
- `GET /oracle/items`
- `GET /oracle/commits`
- `POST /oracle/ask`
- `POST /oracle/commit`
- `POST /ideas/capture`
- `POST /sync`
- `POST /start-work`

`expected-api-routes.json` is the checked local API contract. Run `./mac-app/scripts/check-api-routes.zsh` or `./mac-app/scripts/verify-static.zsh` after changing routes.

Agents should use this API through the Terminal Brain MCP instead of starting
separate Apple Notes or Drafts bridges.

## Native macOS Roadmap

Implemented:

- Menu bar extra.
- Native Settings scene.
- Sidebar commands and custom Brain menu.
- Liquid Glass-aware controls with readable material panels.
- Theme picker with System, Arctic Glass, Graphite, and Midnight.
- Profile menu for operator identity, settings, theme, and logs.
- Local-only control API for MCP/agent access.
- Mission-backed Oracle synthesis with deterministic local fallback.
- Obsidian-backed Oracle commit and Review Queue.
- App Shortcuts for Ask Oracle, Capture Idea, Run Sync, Start Work, context pack handoff, Operator Brief, Decision Lane, Project Memory, Operator Deck, and Agent Handoff.

Next:

- WidgetKit extension for prompt-safety, sync age, and Mission Control points.
- Login item via ServiceManagement after a stable signed app bundle.
- Notification summaries for sync failures and stale source state.
- Quick Look / Share extension for sending selected files or text into Brain.
- Spotlight indexing for context packs and briefing summaries.
