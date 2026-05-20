#!/usr/bin/env node

const API = process.env.TERMINAL_BRAIN_API || "http://127.0.0.1:8765";

const serverInfo = {
  name: "terminal-brain",
  version: "0.1.0"
};

const tools = [
  {
    name: "terminal_brain_status",
    description: "Read Terminal Brain app status, including MCP, sync, index, Mission Control, and prompt-safety state.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_snapshot",
    description: "Get one operator snapshot with Focus, top Radar signals, setup gaps, today's queue, memory trail, and suggested next actions.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_snapshot_markdown",
    description: "Get the current Terminal Brain operator snapshot as prompt-ready Markdown.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_handoff_markdown",
    description: "Get a prompt-ready Terminal Brain handoff combining the Operator Deck and latest context pack.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_sources",
    description: "List Terminal Brain source modes for Obsidian, agent histories, Drafts, Apple Notes, and Mission Control.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_setup",
    description: "Read Terminal Brain readiness setup: app, MCP config, workspace, sync, memory, Mission Control, prompt safety, and Oracle writeback.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_briefing",
    description: "Get the current deterministic Terminal Brain briefing.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_today",
    description: "Get the Daily Command Center queue: what to do first, stale reviews, delegated reads, and project actions.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_today_markdown",
    description: "Get the Daily Command Center as a prompt-ready Decision Lane with ranked actions and project signals.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_focus",
    description: "Get the single best current Terminal Brain focus item: one action, reason, score, and candidates.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_blindspots",
    description: "Get Terminal Brain's Blindspot Brief: ignored, stale, under-tested, or unresolved work to consider before planning.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_blindspots_markdown",
    description: "Get Terminal Brain's Blindspot Brief as prompt-ready Markdown.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_blindspot_ask",
    description: "Ask Terminal Brain Oracle about the top Blindspot Brief item or a selected blindspot id.",
    inputSchema: {
      type: "object",
      properties: {
        id: {
          type: "string",
          description: "Optional blindspot id, sourceID, or title. Defaults to the top blindspot."
        },
        question: {
          type: "string",
          description: "Optional question. Defaults to the blindspot's own question."
        }
      },
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_blindspot_ask_commit",
    description: "Ask Terminal Brain Oracle about a Blindspot Brief item, then commit the answer into the Oracle Inbox.",
    inputSchema: {
      type: "object",
      properties: {
        id: {
          type: "string",
          description: "Optional blindspot id, sourceID, or title. Defaults to the top blindspot."
        },
        question: {
          type: "string",
          description: "Optional question. Defaults to the blindspot's own question."
        },
        project: {
          type: "string",
          description: "Optional project override for the committed read."
        },
        tags: {
          type: "array",
          items: { type: "string" },
          description: "Optional additional tags."
        }
      },
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_blindspot_action",
    description: "Resolve a directly actionable Blindspot Brief source, such as accepting an Oracle commit or marking a Radar signal acted.",
    inputSchema: {
      type: "object",
      properties: {
        id: {
          type: "string",
          description: "Blindspot id, sourceID, or title."
        },
        status: {
          type: "string",
          enum: ["new", "accepted", "linked", "delegated", "dismissed"],
          description: "Oracle commit review status. Defaults to accepted for Oracle commit blindspots."
        },
        disposition: {
          type: "string",
          enum: ["fresh", "watching", "acted", "snoozed", "dismissed"],
          description: "Radar disposition. Defaults to acted for Radar blindspots."
        }
      },
      required: ["id"],
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_operator_brief",
    description: "Get the plain-language Operator Brief: what matters, why it matters, what not to miss, and the next artifact.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_operator_brief_markdown",
    description: "Get the current Terminal Brain Operator Brief as prompt-ready Markdown.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_operator_deck",
    description: "Get the same four-card Operator Deck shown in the app: do first, ask about, review or capture, and project/start-work card.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_operator_deck_markdown",
    description: "Get the current Terminal Brain Operator Deck as prompt-ready Markdown.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_operator_deck_action",
    description: "Apply a triage action to a directly actionable Operator Deck card, such as marking Radar acted/watching/snoozed/dismissed or setting Oracle commit review status.",
    inputSchema: {
      type: "object",
      properties: {
        sourceType: {
          type: "string",
          enum: ["radar", "oracleCommit"],
          description: "Directly triageable Operator Deck sourceType from the card."
        },
        sourceID: {
          type: "string",
          description: "Operator Deck sourceID from the card."
        },
        disposition: {
          type: "string",
          enum: ["fresh", "watching", "acted", "snoozed", "dismissed"],
          description: "Radar/focus disposition. Defaults to acted when sourceType is focus or radar."
        },
        status: {
          type: "string",
          enum: ["new", "accepted", "linked", "delegated", "dismissed"],
          description: "Oracle commit review status. Defaults to accepted when sourceType is oracleCommit."
        }
      },
      required: ["sourceType", "sourceID"],
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_focus_ask",
    description: "Ask Terminal Brain Oracle a question grounded in the current Focus item and its scoring evidence.",
    inputSchema: {
      type: "object",
      properties: {
        question: {
          type: "string",
          description: "Optional follow-up question. Defaults to asking what to do next about the current focus."
        }
      },
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_focus_ask_commit",
    description: "Ask Terminal Brain Oracle about the current Focus item, then commit the answer into the Oracle Inbox.",
    inputSchema: {
      type: "object",
      properties: {
        question: {
          type: "string",
          description: "Optional follow-up question. Defaults to asking what to do next about the current focus."
        },
        project: {
          type: "string",
          description: "Optional project override for the committed read."
        },
        tags: {
          type: "array",
          items: { type: "string" },
          description: "Optional additional tags."
        }
      },
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_radar",
    description: "Get proactive Terminal Brain radar signals: delegated reads, stale reviews, project risks, open loops, and ideas worth testing.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_radar_triage",
    description: "Persist triage state for a Radar signal so agents can watch, mark acted, snooze, dismiss, or reset it.",
    inputSchema: {
      type: "object",
      properties: {
        id: {
          type: "string",
          description: "Radar item id."
        },
        disposition: {
          type: "string",
          enum: ["fresh", "watching", "acted", "snoozed", "dismissed"],
          description: "Disposition to persist for the Radar item."
        }
      },
      required: ["id", "disposition"],
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_projects",
    description: "List Terminal Brain project memory pages derived from context packs and Oracle commits.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_projects_markdown",
    description: "Get Terminal Brain project memory as prompt-ready Markdown with recommended actions, context packs, and Oracle reads.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_latest_context_pack",
    description: "Get the newest Terminal Brain context pack path and metadata for opening or handing to an agent.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_latest_context_pack_markdown",
    description: "Get the newest Terminal Brain context pack as Markdown for direct agent handoff.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_oracle_brief",
    description: "Get Terminal Brain Oracle narrative brief lines and current operating signals.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_oracle_items",
    description: "List Oracle surfaced items, including bubbling ideas, open loops, decisions, and opportunities.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_oracle_ask",
    description: "Ask Terminal Brain Oracle a question using the local Oracle query endpoint.",
    inputSchema: {
      type: "object",
      properties: {
        question: {
          type: "string",
          description: "Question for the Oracle, such as 'What am I missing?' or 'What should I work on next?'"
        }
      },
      required: ["question"],
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_oracle_commit",
    description: "Commit an Oracle answer, decision, or outcome into the Obsidian-backed Oracle Inbox.",
    inputSchema: {
      type: "object",
      properties: {
        title: {
          type: "string",
          description: "Title for the committed Oracle note."
        },
        content: {
          type: "string",
          description: "Markdown content to persist."
        },
        question: {
          type: "string",
          description: "Optional question or prompt that produced this answer."
        },
        source: {
          type: "string",
          description: "Optional source label. Defaults to Terminal Brain MCP."
        },
        project: {
          type: "string",
          description: "Optional project name to attach to the committed read."
        },
        tags: {
          type: "array",
          items: { type: "string" },
          description: "Optional additional tags."
        }
      },
      required: ["title", "content"],
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_oracle_ask_commit",
    description: "Ask Terminal Brain Oracle, then commit the answer into the Obsidian-backed Oracle Inbox in one call.",
    inputSchema: {
      type: "object",
      properties: {
        question: {
          type: "string",
          description: "Question for the Oracle."
        },
        project: {
          type: "string",
          description: "Optional project name to attach to the committed read."
        },
        tags: {
          type: "array",
          items: { type: "string" },
          description: "Optional additional tags."
        }
      },
      required: ["question"],
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_capture_idea",
    description: "Capture an idea, open loop, or rough thought into Terminal Brain's Obsidian-backed Oracle Inbox.",
    inputSchema: {
      type: "object",
      properties: {
        content: {
          type: "string",
          description: "The idea or thought to capture."
        },
        title: {
          type: "string",
          description: "Optional short title. Defaults to Captured Idea."
        },
        project: {
          type: "string",
          description: "Optional project name to attach."
        },
        tags: {
          type: "array",
          items: { type: "string" },
          description: "Optional extra tags."
        }
      },
      required: ["content"],
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_oracle_commits",
    description: "List committed Oracle reads waiting for review, linking, delegation, or dismissal.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_oracle_review_status",
    description: "Set the review status for a committed Oracle read.",
    inputSchema: {
      type: "object",
      properties: {
        id: {
          type: "string",
          description: "Oracle commit id, currently the note path returned by terminal_brain_oracle_commits."
        },
        status: {
          type: "string",
          enum: ["new", "accepted", "linked", "delegated", "dismissed"],
          description: "Review state to apply."
        }
      },
      required: ["id", "status"],
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_permissions",
    description: "Read Terminal Brain permission policy for local sources.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_sync",
    description: "Run the Edge Brain sync through the Terminal Brain app. Apple Notes is excluded unless explicitly enabled.",
    inputSchema: {
      type: "object",
      properties: {
        includeAppleNotes: {
          type: "boolean",
          description: "Whether to include Apple Notes in this manual sync. Defaults to false."
        }
      },
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_start_work",
    description: "Build a first-party local brain context pack for a project, task, repo, or question.",
    inputSchema: {
      type: "object",
      properties: {
        query: {
          type: "string",
          description: "Project, task, repo, or question to build context for."
        }
      },
      required: ["query"],
      additionalProperties: false
    }
  }
];

function send(message) {
  process.stdout.write(`${JSON.stringify(message)}\n`);
}

function respond(id, result) {
  send({ jsonrpc: "2.0", id, result });
}

function respondError(id, code, message, data) {
  send({ jsonrpc: "2.0", id, error: { code, message, data } });
}

function toolText(value, isError = false) {
  const text = typeof value === "string" ? value : JSON.stringify(value, null, 2);
  return { content: [{ type: "text", text }], isError };
}

async function api(path, { method = "GET", body, rawText = false } = {}) {
  const response = await fetch(`${API}${path}`, {
    method,
    headers: body ? { "content-type": "application/json" } : undefined,
    body: body ? JSON.stringify(body) : undefined
  });
  const text = await response.text();
  if (rawText) {
    if (!response.ok) return toolText(text, true);
    return toolText(text);
  }
  let json;
  try {
    json = JSON.parse(text);
  } catch {
    json = { text };
  }
  if (!response.ok) {
    throw new Error(`${response.status} ${response.statusText}: ${JSON.stringify(json)}`);
  }
  return json;
}

async function callTool(name, args = {}) {
  switch (name) {
    case "terminal_brain_status":
      return api("/status");
    case "terminal_brain_snapshot":
      return api("/snapshot");
    case "terminal_brain_snapshot_markdown":
      return api("/snapshot/markdown", { rawText: true });
    case "terminal_brain_handoff_markdown":
      return api("/handoff/markdown", { rawText: true });
    case "terminal_brain_sources":
      return api("/sources");
    case "terminal_brain_setup":
      return api("/setup");
    case "terminal_brain_briefing":
      return api("/briefing");
    case "terminal_brain_today":
      return api("/today");
    case "terminal_brain_today_markdown":
      return api("/today/markdown", { rawText: true });
    case "terminal_brain_focus":
      return api("/focus");
    case "terminal_brain_blindspots":
      return api("/blindspots");
    case "terminal_brain_blindspots_markdown":
      return api("/blindspots/markdown", { rawText: true });
    case "terminal_brain_blindspot_ask":
      return api("/blindspots/ask", { method: "POST", body: { id: args.id || "", question: args.question || "" } });
    case "terminal_brain_blindspot_ask_commit": {
      const asked = await api("/blindspots/ask", {
        method: "POST",
        body: { id: args.id || "", question: args.question || "" }
      });
      const suggestion = asked.commitSuggestion || {};
      const committed = await api("/oracle/commit", {
        method: "POST",
        body: {
          title: suggestion.title || `Blindspot - ${asked.question || "Oracle Read"}`,
          content: asked.answer || "",
          question: asked.groundedQuestion || asked.question || "",
          source: "Terminal Brain MCP",
          project: args.project || suggestion.project || "",
          tags: (Array.isArray(suggestion.tags) ? suggestion.tags : ["terminal-brain", "blindspot", "oracle"])
            .concat(Array.isArray(args.tags) ? args.tags : [])
        }
      });
      return { ok: true, ask: asked, commit: committed };
    }
    case "terminal_brain_blindspot_action":
      return api("/blindspots/action", {
        method: "POST",
        body: {
          id: args.id,
          status: args.status || "",
          disposition: args.disposition || ""
        }
      });
    case "terminal_brain_operator_brief":
      return api("/operator-brief");
    case "terminal_brain_operator_brief_markdown":
      return api("/operator-brief/markdown", { rawText: true });
    case "terminal_brain_operator_deck":
      return api("/operator-deck");
    case "terminal_brain_operator_deck_markdown":
      return api("/operator-deck/markdown", { rawText: true });
    case "terminal_brain_operator_deck_action":
      return api("/operator-deck/action", {
        method: "POST",
        body: {
          sourceType: args.sourceType,
          sourceID: args.sourceID,
          disposition: args.disposition || "",
          status: args.status || ""
        }
      });
    case "terminal_brain_focus_ask":
      return api("/focus/ask", { method: "POST", body: { question: args.question || "" } });
    case "terminal_brain_focus_ask_commit": {
      const asked = await api("/focus/ask", { method: "POST", body: { question: args.question || "" } });
      const suggestion = asked.commitSuggestion || {};
      const committed = await api("/oracle/commit", {
        method: "POST",
        body: {
          title: suggestion.title || `Focus - ${asked.question || "Oracle Read"}`,
          content: asked.answer || "",
          question: asked.question || args.question || "",
          source: "Terminal Brain MCP",
          project: args.project || suggestion.project || "",
          tags: (Array.isArray(suggestion.tags) ? suggestion.tags : ["terminal-brain", "focus", "oracle"])
            .concat(Array.isArray(args.tags) ? args.tags : [])
        }
      });
      return { ok: true, ask: asked, commit: committed };
    }
    case "terminal_brain_radar":
      return api("/radar");
    case "terminal_brain_radar_triage":
      return api("/radar/disposition", { method: "POST", body: { id: args.id, disposition: args.disposition } });
    case "terminal_brain_projects":
      return api("/projects");
    case "terminal_brain_projects_markdown":
      return api("/projects/markdown", { rawText: true });
    case "terminal_brain_latest_context_pack":
      return api("/context-packs/latest");
    case "terminal_brain_latest_context_pack_markdown":
      return api("/context-packs/latest/markdown", { rawText: true });
    case "terminal_brain_oracle_brief":
      return api("/oracle/brief");
    case "terminal_brain_oracle_items":
      return api("/oracle/items");
    case "terminal_brain_oracle_ask":
      return api("/oracle/ask", { method: "POST", body: { question: args.question } });
    case "terminal_brain_oracle_commit":
      return api("/oracle/commit", {
        method: "POST",
        body: {
          title: args.title,
          content: args.content,
          question: args.question || "",
          source: args.source || "Terminal Brain MCP",
          project: args.project || "",
          tags: Array.isArray(args.tags) ? args.tags : []
        }
      });
    case "terminal_brain_oracle_ask_commit": {
      const asked = await api("/oracle/ask", { method: "POST", body: { question: args.question } });
      const committed = await api("/oracle/commit", {
        method: "POST",
        body: {
          title: `Oracle - ${args.question}`,
          content: asked.answer || "",
          question: args.question,
          source: "Terminal Brain MCP",
          project: args.project || "",
          tags: ["terminal-brain", "oracle", "mcp", asked.mode || "oracle"].concat(Array.isArray(args.tags) ? args.tags : [])
        }
      });
      return { ok: true, ask: asked, commit: committed };
    }
    case "terminal_brain_capture_idea":
      return api("/ideas/capture", {
        method: "POST",
        body: {
          title: args.title || "Captured Idea",
          content: args.content,
          project: args.project || "",
          tags: Array.isArray(args.tags) ? args.tags : []
        }
      });
    case "terminal_brain_oracle_commits":
      return api("/oracle/commits");
    case "terminal_brain_oracle_review_status":
      return api("/oracle/review-status", {
        method: "POST",
        body: { id: args.id, status: args.status }
      });
    case "terminal_brain_permissions":
      return api("/permissions");
    case "terminal_brain_sync":
      return api("/sync", { method: "POST", body: { includeAppleNotes: Boolean(args.includeAppleNotes) } });
    case "terminal_brain_start_work":
      return api("/start-work", { method: "POST", body: { query: args.query } });
    default:
      throw new Error(`Unknown tool: ${name}`);
  }
}

async function handle(message) {
  const { id, method, params } = message;
  try {
    if (method === "initialize") {
      respond(id, {
        protocolVersion: params?.protocolVersion || "2024-11-05",
        capabilities: { tools: {} },
        serverInfo
      });
      return;
    }
    if (method === "notifications/initialized") {
      return;
    }
    if (method === "tools/list") {
      respond(id, { tools });
      return;
    }
    if (method === "tools/call") {
      const result = await callTool(params?.name, params?.arguments || {});
      respond(id, toolText(result));
      return;
    }
    respondError(id, -32601, `Method not found: ${method}`);
  } catch (error) {
    respond(id, toolText(error instanceof Error ? error.message : String(error), true));
  }
}

let buffer = "";
process.stdin.setEncoding("utf8");
process.stdin.on("data", (chunk) => {
  buffer += chunk;
  let index;
  while ((index = buffer.indexOf("\n")) >= 0) {
    const line = buffer.slice(0, index).trim();
    buffer = buffer.slice(index + 1);
    if (!line) {
      continue;
    }
    try {
      handle(JSON.parse(line));
    } catch (error) {
      respondError(null, -32700, "Parse error", error instanceof Error ? error.message : String(error));
    }
  }
});
