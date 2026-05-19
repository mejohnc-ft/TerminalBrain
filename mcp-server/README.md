# Terminal Brain MCP

MCP proxy for the native Terminal Brain macOS app.

This server does not touch Apple Notes, Drafts, Obsidian, or Mission Control
directly. It talks to the trusted local app API:

```text
http://127.0.0.1:8765
```

Start Terminal Brain before using this MCP.

Oracle commits accept an optional `project` argument. When provided, Terminal Brain writes that project into note frontmatter so Review filters and Project Memory pages can attach the read to the correct work surface.

Codex/workspace config can register this server as:

```json
{
  "command": "node",
  "args": [
    "/Users/jchristensen/Git/TerminalBrain/mcp-server/server.mjs"
  ],
  "env": {
    "TERMINAL_BRAIN_API": "http://127.0.0.1:8765"
  }
}
```

## Tools

- `terminal_brain_status`
- `terminal_brain_sources`
- `terminal_brain_setup`
- `terminal_brain_briefing`
- `terminal_brain_today`
- `terminal_brain_focus`
- `terminal_brain_radar`
- `terminal_brain_radar_triage`
- `terminal_brain_projects`
- `terminal_brain_oracle_brief`
- `terminal_brain_oracle_items`
- `terminal_brain_oracle_ask`
- `terminal_brain_oracle_commit`
- `terminal_brain_oracle_commits`
- `terminal_brain_permissions`
- `terminal_brain_sync`
- `terminal_brain_start_work`
