#!/usr/bin/env node

import { execFileSync } from "node:child_process";
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const API = process.env.TERMINAL_BRAIN_API || "http://127.0.0.1:8765";
const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));

const serverInfo = {
  name: "terminal-brain",
  version: "0.1.0"
};

const tools = [
  {
    name: "terminal_brain_runtime_status",
    description: "Read non-launching runtime status for agents: repo, latest CI, local process, launchctl, and API reachability without requiring the app to be running.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_now_markdown",
    description: "Get the fastest non-launching Terminal Brain orientation: bottom line, next action, process truth, readiness, and outcome close loop.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_what_now_markdown",
    description: "Get a concise non-launching situation read for humans and agents: what is running, repo/CI state, runtime noise, current blocker, and the next value command.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_use_now_markdown",
    description: "Get the one-command non-launching Terminal Brain path for a new or overwhelmed operator: one executable move first, compact pull-forward context, ask, capture, delegate, and close the loop.",
    inputSchema: {
      type: "object",
      properties: {
        limit: {
          type: "number",
          description: "Maximum surfaced items to show in the embedded work block. Defaults to 1."
        },
        project: {
          type: "string",
          description: "Optional project label for capture and outcome commands. Defaults to Terminal Brain."
        },
        idea: {
          type: "string",
          description: "Optional rough thought to capture into the Oracle Inbox before returning the Use Now work block."
        },
        title: {
          type: "string",
          description: "Optional title for the captured idea when idea is supplied."
        }
      },
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_first_minute_markdown",
    description: "Get one non-launching first-minute artifact: what Terminal Brain is, what value is available, what to do first, and a working closed-app proof.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_now",
    description: "Get the structured app-backed Terminal Brain Now payload with bottom line, focus, do-this steps, process truth, and close loop. Requires the app API to be reachable.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_process_map_markdown",
    description: "Get a non-launching process map for Terminal Brain, Codex sessions, MCP children, brain-kernel children, brain-console helpers, Drafts, launchctl, and API reachability.",
    inputSchema: {
      type: "object",
      properties: {
        details: {
          type: "boolean",
          description: "Include matching process rows for debugging. Defaults to false."
        }
      },
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_cleanup_plan_markdown",
    description: "Get a non-destructive cleanup plan for stale Terminal Brain MCP/kernel runtime noise. Prints candidates and manual review commands without killing anything.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_support_bundle_markdown",
    description: "Get a non-launching Markdown support bundle with What Now, Now, Doctor, Audit, Process Map, Cleanup Plan, and Git state.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_next_markdown",
    description: "Get the safest next move as Markdown. Returns Start Here when the app is reachable, otherwise returns non-launching runtime status and the manual next step.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_doctor_markdown",
    description: "Run the non-launching Terminal Brain readiness doctor and return app install, MCP contract, agent config, process, launchctl, and API status as Markdown.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_value_now_markdown",
    description: "Get the current Terminal Brain value read as Markdown. Returns the live Value Brief when reachable, otherwise explains the value path and safe next commands.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_value_proof_markdown",
    description: "Run the non-launching Terminal Brain value proof: Oracle Brief, Agent Prompt, temporary accepted outcome note, and note preview.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_demo_markdown",
    description: "Run a non-launching temporary Terminal Brain demo with seeded ideas, Review Queue, Bubble Up, Work Block, and real-use commands.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_playbook_markdown",
    description: "Get the non-launching operator playbook: what command to run for common situations, first five-minute loop, daily cadence, agent cadence, and readiness.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_value_audit_markdown",
    description: "Run the non-launching value audit: success criteria, prompt-to-artifact checklist, evidence, current state, and remaining gaps.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_completion_audit_markdown",
    description: "Run the non-launching world-class completion audit: objective, prompt-to-artifact checklist, evidence, current state, and explicit uncertified visual-review gap.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_visual_review_plan_markdown",
    description: "Get the non-launching manual visual review plan for certifying the remaining native UX gate when the operator explicitly opens the app.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_review_queue_markdown",
    description: "Read the non-launching Oracle Inbox review queue as Markdown without opening Terminal Brain.",
    inputSchema: {
      type: "object",
      properties: {
        limit: {
          type: "number",
          description: "Maximum review items to show. Defaults to 12."
        },
        status: {
          type: "string",
          description: "Optional status filter: new, accepted, linked, delegated, dismissed."
        },
        project: {
          type: "string",
          description: "Optional exact project filter."
        }
      },
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_bubble_up_markdown",
    description: "Read the non-launching Bubble Up brief: neglected ideas, delegated loops, repeated project pressure, and exact triage commands.",
    inputSchema: {
      type: "object",
      properties: {
        limit: {
          type: "number",
          description: "Maximum surfaced items to show. Defaults to 7."
        },
        project: {
          type: "string",
          description: "Optional exact project filter."
        }
      },
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_work_block_markdown",
    description: "Get one non-launching work block: pull forward signals, review queue, and close-loop command shape.",
    inputSchema: {
      type: "object",
      properties: {
        limit: {
          type: "number",
          description: "Maximum surfaced items to show in each section. Defaults to 3."
        },
        project: {
          type: "string",
          description: "Optional exact project filter."
        }
      },
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_audit_markdown",
    description: "Run the non-launching Terminal Brain capability audit and return evidence for value, MCP, safety, readiness, and first commands as Markdown.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
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
    name: "terminal_brain_agent_prompt_markdown",
    description: "Get a concise execution prompt for Codex/Claude from the current Value Brief, Focus, Idea Pulse, and guardrails.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_start_here_markdown",
    description: "Get the one-block Terminal Brain Start Here path: digest, current move, context, non-launching commands, and done criteria.",
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
    name: "terminal_brain_sources_markdown",
    description: "Get a non-launching source inventory with Obsidian, Codex, Claude, derived agent memory, and guarded import guidance.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_memory_brief_markdown",
    description: "Get a non-launching brief from derived Codex/Claude work memory with continuity leads and commands to promote useful follow-ups.",
    inputSchema: {
      type: "object",
      properties: {
        limit: {
          type: "number",
          description: "Maximum continuity leads to show. Defaults to 6."
        },
        project: {
          type: "string",
          description: "Optional project substring filter."
        }
      },
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_memory_promote",
    description: "Promote one derived Codex/Claude memory lead into Oracle Inbox as a reviewable idea. Use dryRun first to preview without writing.",
    inputSchema: {
      type: "object",
      properties: {
        index: {
          type: "number",
          description: "One-based continuity lead index from the Memory Brief."
        },
        project: {
          type: "string",
          description: "Optional project substring filter matching the Memory Brief."
        },
        dryRun: {
          type: "boolean",
          description: "Preview the selected memory lead without writing. Defaults to false."
        }
      },
      required: ["index"],
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_recent_work_promote",
    description: "Promote one recent git commit from Bubble Up's Recent Work Signals into Oracle Inbox as reviewable memory. Use dryRun first to preview without writing.",
    inputSchema: {
      type: "object",
      properties: {
        index: {
          type: "number",
          description: "One-based recent work index from Bubble Up's Recent Work Signals. Defaults to 1."
        },
        project: {
          type: "string",
          description: "Project name for the captured memory. Defaults to Terminal Brain."
        },
        dryRun: {
          type: "boolean",
          description: "Preview the selected recent work item without writing. Defaults to false."
        }
      },
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
    name: "terminal_brain_ideas",
    description: "Get Terminal Brain's Idea Pulse: captured thoughts and resurfaced opportunities ranked by cheap-test value.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_ideas_markdown",
    description: "Get Terminal Brain's Idea Pulse as prompt-ready Markdown for pressure-testing ideas.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_idea_ask",
    description: "Ask Terminal Brain Oracle to pressure-test the top Idea Pulse item or a selected idea id.",
    inputSchema: {
      type: "object",
      properties: {
        id: {
          type: "string",
          description: "Optional idea id, title, or path. Defaults to the top Idea Pulse item."
        },
        question: {
          type: "string",
          description: "Optional question. Defaults to the idea's cheap-test prompt."
        }
      },
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_idea_ask_commit",
    description: "Pressure-test an Idea Pulse item, then commit the answer into the Oracle Inbox.",
    inputSchema: {
      type: "object",
      properties: {
        id: {
          type: "string",
          description: "Optional idea id, title, or path. Defaults to the top Idea Pulse item."
        },
        question: {
          type: "string",
          description: "Optional question. Defaults to the idea's cheap-test prompt."
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
    name: "terminal_brain_value_brief",
    description: "Get Terminal Brain's compact value brief: why the current move is worth attention and what artifact to create.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_value_brief_markdown",
    description: "Get Terminal Brain's Value Brief as prompt-ready Markdown.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_oracle_digest",
    description: "Get Terminal Brain's Oracle Digest: notice, decide, test, create, and avoid lanes for the next work block.",
    inputSchema: {
      type: "object",
      properties: {},
      additionalProperties: false
    }
  },
  {
    name: "terminal_brain_oracle_digest_markdown",
    description: "Get Terminal Brain's Oracle Digest as prompt-ready Markdown.",
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
    name: "terminal_brain_oracle_brief_markdown",
    description: "Get Terminal Brain Oracle Brief as prompt-ready Markdown with direct read, next moves, missing signal, cheap test, and agent handoff.",
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
    name: "terminal_brain_commit_outcome",
    description: "Commit a structured outcome into Terminal Brain memory: what changed, evidence, and the next action.",
    inputSchema: {
      type: "object",
      properties: {
        title: {
          type: "string",
          description: "Short outcome title."
        },
        outcome: {
          type: "string",
          description: "What changed and why it matters."
        },
        nextAction: {
          type: "string",
          description: "Recommended next concrete action."
        },
        project: {
          type: "string",
          description: "Optional project name."
        },
        evidence: {
          type: "array",
          items: { type: "string" },
          description: "Evidence, files, commands, links, or verification notes."
        },
        tags: {
          type: "array",
          items: { type: "string" },
          description: "Optional additional tags."
        }
      },
      required: ["title", "outcome"],
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
    description: "Capture an idea, open loop, or rough thought into Terminal Brain's Obsidian-backed Oracle Inbox. Uses the app API when reachable and a local fallback when closed.",
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
    description: "Set the review status for a committed Oracle read. Works without the app open by editing the local Oracle Inbox note safely.",
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

function runCommand(command, args, { cwd = ROOT, timeout = 3000, env = {} } = {}) {
  try {
    return {
      ok: true,
      text: execFileSync(command, args, {
        cwd,
        timeout,
        env: { ...process.env, ...env },
        encoding: "utf8",
        stdio: ["ignore", "pipe", "pipe"]
      }).trim()
    };
  } catch (error) {
    return {
      ok: false,
      text: typeof error?.stdout === "string" ? error.stdout.trim() : "",
      error: typeof error?.stderr === "string" ? error.stderr.trim() : String(error)
    };
  }
}

async function apiHealth() {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 500);
  try {
    const response = await fetch(`${API}/health`, { signal: controller.signal });
    const text = await response.text();
    let body = text;
    try {
      body = JSON.parse(text);
    } catch {
      // Keep raw body.
    }
    return { reachable: response.ok, status: response.status, body };
  } catch (error) {
    return { reachable: false, error: error instanceof Error ? error.message : String(error) };
  } finally {
    clearTimeout(timer);
  }
}

function runtimeStatusMarkdown(status) {
  const lines = [
    "# Terminal Brain Runtime Status",
    "",
    `Checked: ${status.checkedAt}`,
    "",
    "## Repo",
    "",
    `- Branch: ${status.repo.branch}`,
    `- Upstream: ${status.repo.upstream}`,
    `- Head: ${status.repo.head}`,
    `- Working tree: ${status.repo.clean ? "clean" : "dirty"}`
  ];

  if (status.repo.changes.length > 0) {
    lines.push(...status.repo.changes.map((change) => `  ${change}`));
  }

  lines.push(
    "",
    "## CI",
    "",
    status.ci.latest ? `- ${status.ci.latest}` : `- ${status.ci.available ? "No run found." : "GitHub CLI unavailable."}`,
    "",
    "## Local Runtime",
    "",
    `- App process: ${status.runtime.appProcessRunning ? "running" : "not running"}`,
    `- launchctl: ${status.runtime.launchctlRegistered ? "registered" : "no matching loaded service"}`,
    `- API: ${status.runtime.apiReachable ? `reachable at ${status.api}` : `not reachable at ${status.api}`}`,
    "",
    "## Guardrails",
    "",
    "- This MCP tool did not launch or foreground Terminal Brain.",
    "- App-backed tools should be used only when the app is reachable."
  );

  return lines.join("\n");
}

async function runtimeStatus() {
  const branch = runCommand("git", ["branch", "--show-current"]);
  const upstream = runCommand("git", ["rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}"]);
  const head = runCommand("git", ["log", "-1", "--oneline"]);
  const dirty = runCommand("git", ["status", "--short"]);
  const appPids = runCommand("pgrep", ["-x", "TerminalBrain"]);
  const launchctl = runCommand("launchctl", ["list"]);
  const ci = runCommand("gh", ["run", "list", "--branch", branch.text || "main", "--limit", "1"], { timeout: 5000 });
  const pidList = appPids.ok && appPids.text ? appPids.text.split("\n").filter(Boolean) : [];
  const processDetails = pidList.length > 0
    ? runCommand("ps", ["-p", pidList.join(","), "-o", "pid=,comm=,args="])
    : { ok: true, text: "" };
  const processes = processDetails.text
    ? processDetails.text.split("\n").map((line) => line.trim()).filter(Boolean)
    : [];
  const launchItems = launchctl.ok
    ? launchctl.text
      .split("\n")
      .map((line) => line.trim())
      .filter((line) => /terminalbrain|terminal brain/i.test(line))
    : [];
  const health = await apiHealth();
  return {
    checkedAt: new Date().toISOString(),
    api: API,
    repo: {
      branch: branch.text || "unknown",
      upstream: upstream.text || "none",
      head: head.text || "unknown",
      clean: dirty.ok && dirty.text.length === 0,
      changes: dirty.text ? dirty.text.split("\n") : []
    },
    ci: {
      available: ci.ok,
      latest: ci.text || "",
      error: ci.ok ? "" : ci.error || ""
    },
    runtime: {
      appProcessRunning: processes.length > 0,
      processes,
      launchctlRegistered: launchItems.length > 0,
      launchItems,
      apiReachable: health.reachable,
      health
    },
    guardrails: [
      "This MCP tool does not launch, foreground, quit, or control Terminal Brain.",
      "Use app-backed tools only when apiReachable is true or the operator has opened the app."
    ]
  };
}

async function nextMarkdown() {
  const result = runCommand("zsh", [join(ROOT, "mac-app", "scripts", "next.zsh")], { timeout: 15000 });
  if (result.ok) return result.text;
  return [
    "# Terminal Brain Next",
    "",
    "Next Move failed before completing.",
    "",
    "## Error",
    "",
    result.error || "Unknown error",
    "",
    "## Output",
    "",
    result.text || "(no output)"
  ].join("\n");
}

function doctorMarkdown() {
  const result = runCommand("zsh", [join(ROOT, "mac-app", "scripts", "doctor.zsh")], { timeout: 10000 });
  if (result.ok) return result.text;
  return [
    "# Terminal Brain Doctor",
    "",
    "Doctor failed before completing.",
    "",
    "## Error",
    "",
    result.error || "Unknown error",
    "",
    "## Output",
    "",
    result.text || "(no output)"
  ].join("\n");
}

function auditMarkdown() {
  const result = runCommand("zsh", [join(ROOT, "mac-app", "scripts", "audit.zsh")], { timeout: 10000 });
  if (result.ok) return result.text;
  return [
    "# Terminal Brain Capability Audit",
    "",
    "Audit failed before completing.",
    "",
    "## Error",
    "",
    result.error || "Unknown error",
    "",
    "## Output",
    "",
    result.text || "(no output)"
  ].join("\n");
}

function processMapMarkdown({ details = false } = {}) {
  const args = [join(ROOT, "mac-app", "scripts", "processes.zsh")];
  if (details === true) {
    args.push("--details");
  }
  const result = runCommand("zsh", args, { timeout: 10000 });
  if (result.ok) return result.text;
  return [
    "# Terminal Brain Process Map",
    "",
    "Process map failed before completing.",
    "",
    "## Error",
    "",
    result.error || "Unknown error",
    "",
    "## Output",
    "",
    result.text || "(no output)"
  ].join("\n");
}

function nowMarkdown() {
  const result = runCommand("zsh", [join(ROOT, "mac-app", "scripts", "now.zsh")], { timeout: 15000 });
  if (result.ok) return result.text;
  return [
    "# Terminal Brain Now",
    "",
    "Now orientation failed before completing.",
    "",
    "## Error",
    "",
    result.error || "Unknown error",
    "",
    "## Output",
    "",
    result.text || "(no output)"
  ].join("\n");
}

function whatNowMarkdown() {
  const result = runCommand("zsh", [join(ROOT, "mac-app", "scripts", "what-now.zsh")], { timeout: 15000 });
  if (result.ok) return result.text;
  return [
    "# Terminal Brain What Now",
    "",
    "What Now failed before completing.",
    "",
    "## Error",
    "",
    result.error || "Unknown error",
    "",
    "## Output",
    "",
    result.text || "(no output)"
  ].join("\n");
}

function useNowMarkdown(args = {}) {
  const commandArgs = [join(ROOT, "mac-app", "scripts", "use-now.zsh")];
  if (Number.isFinite(args.limit)) {
    commandArgs.push("--limit", String(Math.max(1, Math.floor(args.limit))));
  }
  if (typeof args.project === "string" && args.project.trim()) {
    commandArgs.push("--project", args.project.trim());
  }
  if (typeof args.idea === "string" && args.idea.trim()) {
    commandArgs.push("--idea", args.idea.trim());
  }
  if (typeof args.title === "string" && args.title.trim()) {
    commandArgs.push("--title", args.title.trim());
  }
  const result = runCommand("zsh", commandArgs, { timeout: 25000 });
  if (result.ok) return result.text;
  return [
    "# Terminal Brain Use Now",
    "",
    "Use Now failed before completing.",
    "",
    "## Error",
    "",
    result.error || "Unknown error",
    "",
    "## Output",
    "",
    result.text || "(no output)"
  ].join("\n");
}

function startHereMarkdown() {
  const result = runCommand("zsh", [join(ROOT, "mac-app", "scripts", "snapshot.zsh"), "--start-here"], { timeout: 15000 });
  if (result.ok) return result.text;
  return [
    "# Terminal Brain Start Here",
    "",
    "Start Here failed before completing.",
    "",
    "## Error",
    "",
    result.error || "Unknown error",
    "",
    "## Output",
    "",
    result.text || "(no output)"
  ].join("\n");
}

function handoffMarkdown() {
  const output = "/tmp/terminal-brain-mcp-handoff.md";
  const result = runCommand("zsh", [join(ROOT, "mac-app", "scripts", "handoff.zsh"), "--output", output], { timeout: 30000 });
  if (!result.ok) {
    return [
      "# Terminal Brain Handoff",
      "",
      "Handoff failed before completing.",
      "",
      "## Error",
      "",
      result.error || "Unknown error",
      "",
      "## Output",
      "",
      result.text || "(no output)"
    ].join("\n");
  }
  try {
    return readFileSync(output, "utf8");
  } catch {
    return result.text;
  }
}

async function localSnapshot() {
  return {
    ok: true,
    mode: "local-fallback",
    checkedAt: new Date().toISOString(),
    startHereMarkdown: startHereMarkdown(),
    processMapMarkdown: processMapMarkdown({ details: false }),
    runtimeStatus: await runtimeStatus(),
    guardrail: "MCP snapshot fallback did not launch or foreground Terminal Brain"
  };
}

function localSnapshotMarkdown() {
  return [
    "# Terminal Brain Snapshot",
    "",
    `Generated: ${new Date().toISOString()}`,
    "",
    "Terminal Brain is not reachable, so this is a local closed-app snapshot.",
    "",
    "## Start Here",
    "",
    startHereMarkdown().replace(/^# Terminal Brain Start Here\n+/, ""),
    "",
    "## Process Map",
    "",
    processMapMarkdown({ details: false }).replace(/^# Terminal Brain Process Map\n+/, ""),
    "",
    "## Guardrail",
    "",
    "- This snapshot did not launch or foreground Terminal Brain."
  ].join("\n");
}

function firstMinuteMarkdown() {
  const result = runCommand("zsh", [join(ROOT, "mac-app", "scripts", "first-minute.zsh")], { timeout: 25000 });
  if (result.ok) return result.text;
  return [
    "# Terminal Brain First Minute",
    "",
    "First-minute artifact failed before completing.",
    "",
    "## Error",
    "",
    result.error || "Unknown error",
    "",
    "## Output",
    "",
    result.text || "(no output)"
  ].join("\n");
}

function oracleBriefMarkdown() {
  const result = runCommand("zsh", [join(ROOT, "mac-app", "scripts", "oracle-brief.zsh")], { timeout: 15000 });
  if (result.ok) return result.text;
  return [
    "# Terminal Brain Oracle Brief",
    "",
    "Oracle Brief failed before completing.",
    "",
    "## Error",
    "",
    result.error || "Unknown error",
    "",
    "## Output",
    "",
    result.text || "(no output)"
  ].join("\n");
}

function agentPromptMarkdown() {
  const result = runCommand("zsh", [join(ROOT, "mac-app", "scripts", "agent-prompt.zsh")], { timeout: 15000 });
  if (result.ok) return result.text;
  return [
    "# Terminal Brain Agent Prompt",
    "",
    "Agent Prompt failed before completing.",
    "",
    "## Error",
    "",
    result.error || "Unknown error",
    "",
    "## Output",
    "",
    result.text || "(no output)"
  ].join("\n");
}

function valueProofMarkdown() {
  const result = runCommand("zsh", [join(ROOT, "mac-app", "scripts", "prove-value.zsh")], { timeout: 20000 });
  if (result.ok) return result.text;
  return [
    "# Terminal Brain Value Proof",
    "",
    "Value proof failed before completing.",
    "",
    "## Error",
    "",
    result.error || "Unknown error",
    "",
    "## Output",
    "",
    result.text || "(no output)"
  ].join("\n");
}

function demoMarkdown() {
  const result = runCommand("zsh", [join(ROOT, "mac-app", "scripts", "demo.zsh")], { timeout: 25000 });
  if (result.ok) return result.text;
  return [
    "# Terminal Brain Demo",
    "",
    "Demo failed before completing.",
    "",
    "## Error",
    "",
    result.error || "Unknown error",
    "",
    "## Output",
    "",
    result.text || "(no output)"
  ].join("\n");
}

function playbookMarkdown() {
  const result = runCommand("zsh", [join(ROOT, "mac-app", "scripts", "playbook.zsh")], { timeout: 15000 });
  if (result.ok) return result.text;
  return [
    "# Terminal Brain Playbook",
    "",
    "Playbook failed before completing.",
    "",
    "## Error",
    "",
    result.error || "Unknown error",
    "",
    "## Output",
    "",
    result.text || "(no output)"
  ].join("\n");
}

function valueAuditMarkdown() {
  const result = runCommand("zsh", [join(ROOT, "mac-app", "scripts", "value-audit.zsh")], { timeout: 60000 });
  if (result.ok) return result.text;
  return [
    "# Terminal Brain Value Audit",
    "",
    "Value audit failed before completing.",
    "",
    "## Error",
    "",
    result.error || "Unknown error",
    "",
    "## Output",
    "",
    result.text || "(no output)"
  ].join("\n");
}

function completionAuditMarkdown() {
  const result = runCommand("zsh", [join(ROOT, "mac-app", "scripts", "completion-audit.zsh")], {
    timeout: 30000,
    env: { TERMINAL_BRAIN_COMPLETION_AUDIT_SKIP_VERIFY: "1" }
  });
  if (result.ok) return result.text;
  return [
    "# Terminal Brain Completion Audit",
    "",
    "Completion audit failed before completing.",
    "",
    "## Error",
    "",
    result.error || "Unknown error",
    "",
    "## Output",
    "",
    result.text || "(no output)"
  ].join("\n");
}

function visualReviewPlanMarkdown() {
  const result = runCommand("zsh", [join(ROOT, "mac-app", "scripts", "visual-review-plan.zsh")], { timeout: 15000 });
  if (result.ok) return result.text;
  return [
    "# Terminal Brain Visual Review Plan",
    "",
    "Visual review plan failed before completing.",
    "",
    "## Error",
    "",
    result.error || "Unknown error",
    "",
    "## Output",
    "",
    result.text || "(no output)"
  ].join("\n");
}

function reviewQueueMarkdown(args = {}) {
  const commandArgs = [join(ROOT, "mac-app", "scripts", "review.zsh")];
  if (Number.isFinite(args.limit)) {
    commandArgs.push("--limit", String(Math.max(1, Math.floor(args.limit))));
  }
  if (typeof args.status === "string" && args.status.trim()) {
    commandArgs.push("--status", args.status.trim());
  }
  if (typeof args.project === "string" && args.project.trim()) {
    commandArgs.push("--project", args.project.trim());
  }
  const result = runCommand("zsh", commandArgs, { timeout: 15000 });
  if (result.ok) return result.text;
  return [
    "# Terminal Brain Review Queue",
    "",
    "Review queue failed before completing.",
    "",
    "## Error",
    "",
    result.error || "Unknown error",
    "",
    "## Output",
    "",
    result.text || "(no output)"
  ].join("\n");
}

function bubbleUpMarkdown(args = {}) {
  const commandArgs = [join(ROOT, "mac-app", "scripts", "bubble-up.zsh")];
  if (Number.isFinite(args.limit)) {
    commandArgs.push("--limit", String(Math.max(1, Math.floor(args.limit))));
  }
  if (typeof args.project === "string" && args.project.trim()) {
    commandArgs.push("--project", args.project.trim());
  }
  const result = runCommand("zsh", commandArgs, { timeout: 15000 });
  if (result.ok) return result.text;
  return [
    "# Terminal Brain Bubble Up",
    "",
    "Bubble Up failed before completing.",
    "",
    "## Error",
    "",
    result.error || "Unknown error",
    "",
    "## Output",
    "",
    result.text || "(no output)"
  ].join("\n");
}

function workBlockMarkdown(args = {}) {
  const commandArgs = [join(ROOT, "mac-app", "scripts", "work-block.zsh")];
  if (Number.isFinite(args.limit)) {
    commandArgs.push("--limit", String(Math.max(1, Math.floor(args.limit))));
  }
  if (typeof args.project === "string" && args.project.trim()) {
    commandArgs.push("--project", args.project.trim());
  }
  const result = runCommand("zsh", commandArgs, { timeout: 20000 });
  if (result.ok) return result.text;
  return [
    "# Terminal Brain Work Block",
    "",
    "Work Block failed before completing.",
    "",
    "## Error",
    "",
    result.error || "Unknown error",
    "",
    "## Output",
    "",
    result.text || "(no output)"
  ].join("\n");
}

function sourcesMarkdown() {
  const result = runCommand("zsh", [join(ROOT, "mac-app", "scripts", "sources.zsh")], { timeout: 20000 });
  if (result.ok) return result.text;
  return [
    "# Terminal Brain Source Inventory",
    "",
    "Source inventory failed before completing.",
    "",
    "## Error",
    "",
    result.error || "Unknown error",
    "",
    "## Output",
    "",
    result.text || "(no output)"
  ].join("\n");
}

function memoryBriefMarkdown(args = {}) {
  const commandArgs = [join(ROOT, "mac-app", "scripts", "memory.zsh")];
  if (Number.isFinite(args.limit)) {
    commandArgs.push("--limit", String(Math.max(1, Math.floor(args.limit))));
  }
  if (typeof args.project === "string" && args.project.trim()) {
    commandArgs.push("--project", args.project.trim());
  }
  const result = runCommand("zsh", commandArgs, { timeout: 20000 });
  if (result.ok) return result.text;
  return [
    "# Terminal Brain Memory Brief",
    "",
    "Memory brief failed before completing.",
    "",
    "## Error",
    "",
    result.error || "Unknown error",
    "",
    "## Output",
    "",
    result.text || "(no output)"
  ].join("\n");
}

function promoteMemory(args = {}) {
  if (!Number.isFinite(args.index)) {
    throw new Error("index is required");
  }
  const commandArgs = [
    join(ROOT, "mac-app", "scripts", "memory-promote.zsh"),
    "--index",
    String(Math.max(1, Math.floor(args.index)))
  ];
  if (typeof args.project === "string" && args.project.trim()) {
    commandArgs.push("--project", args.project.trim());
  }
  if (args.dryRun === true) {
    commandArgs.push("--dry-run");
  }
  const result = runCommand("zsh", commandArgs, { timeout: 20000 });
  if (!result.ok) {
    return {
      ok: false,
      error: result.error || "Memory promotion failed.",
      output: result.text || "",
      guardrail: "memory promotion did not launch or foreground Terminal Brain"
    };
  }
  try {
    return JSON.parse(result.text);
  } catch {
    return {
      ok: true,
      output: result.text,
      guardrail: "memory promotion did not launch or foreground Terminal Brain"
    };
  }
}

function promoteRecentWork(args = {}) {
  const index = Number.isFinite(args.index) ? Math.max(1, Math.floor(args.index)) : 1;
  const commandArgs = [
    join(ROOT, "mac-app", "scripts", "recent-work.zsh"),
    "--index",
    String(index)
  ];
  if (typeof args.project === "string" && args.project.trim()) {
    commandArgs.push("--project", args.project.trim());
  }
  if (args.dryRun === true) {
    commandArgs.push("--dry-run");
  }
  const result = runCommand("zsh", commandArgs, { timeout: 20000 });
  if (!result.ok) {
    return {
      ok: false,
      error: result.error || "Recent work promotion failed.",
      output: result.text || "",
      guardrail: "recent work promotion did not launch or foreground Terminal Brain"
    };
  }
  try {
    return JSON.parse(result.text);
  } catch {
    return {
      ok: true,
      output: result.text,
      guardrail: "recent work promotion did not launch or foreground Terminal Brain"
    };
  }
}

function setReviewStatus(args = {}) {
  const id = typeof args.id === "string" ? args.id.trim() : "";
  const status = typeof args.status === "string" ? args.status.trim() : "";
  if (!id || !status) {
    throw new Error("id and status are required");
  }
  const result = runCommand("zsh", [
    join(ROOT, "mac-app", "scripts", "review-status.zsh"),
    "--id",
    id,
    "--status",
    status
  ], { timeout: 10000 });
  if (!result.ok) {
    return {
      ok: false,
      error: result.error || "Review status update failed.",
      output: result.text || ""
    };
  }
  try {
    return JSON.parse(result.text);
  } catch {
    return { ok: true, output: result.text };
  }
}

function captureIdea(args = {}) {
  const content = typeof args.content === "string" ? args.content.trim() : "";
  if (!content) {
    throw new Error("content is required");
  }
  const commandArgs = [join(ROOT, "mac-app", "scripts", "idea.zsh")];
  if (typeof args.title === "string" && args.title.trim()) {
    commandArgs.push("--title", args.title.trim());
  }
  if (typeof args.project === "string" && args.project.trim()) {
    commandArgs.push("--project", args.project.trim());
  }
  if (Array.isArray(args.tags)) {
    for (const tag of args.tags) {
      if (typeof tag === "string" && tag.trim()) {
        commandArgs.push("--tag", tag.trim());
      }
    }
  }
  commandArgs.push(content);
  const result = runCommand("zsh", commandArgs, { timeout: 15000 });
  if (!result.ok) {
    return {
      ok: false,
      error: result.error || "Idea capture failed.",
      output: result.text || ""
    };
  }
  try {
    return JSON.parse(result.text);
  } catch {
    return { ok: true, output: result.text };
  }
}

function cleanupPlanMarkdown() {
  const result = runCommand("zsh", [join(ROOT, "mac-app", "scripts", "cleanup-plan.zsh")], { timeout: 10000 });
  if (result.ok) return result.text;
  return [
    "# Terminal Brain Cleanup Plan",
    "",
    "Cleanup plan failed before completing.",
    "",
    "## Error",
    "",
    result.error || "Unknown error",
    "",
    "## Output",
    "",
    result.text || "(no output)"
  ].join("\n");
}

function oracleAskMarkdown(args = {}, { commit = false } = {}) {
  const question = typeof args.question === "string" ? args.question.trim() : "";
  if (!question) {
    return {
      ok: false,
      error: "question is required"
    };
  }
  const commandArgs = [join(ROOT, "mac-app", "scripts", "oracle.zsh")];
  if (commit) commandArgs.push("--commit");
  if (typeof args.project === "string" && args.project.trim()) {
    commandArgs.push("--project", args.project.trim());
  }
  commandArgs.push(question);
  const result = runCommand("zsh", commandArgs, { timeout: 15000 });
  if (result.ok) return result.text;
  return [
    "# Terminal Brain Oracle",
    "",
    "Oracle ask failed before completing.",
    "",
    "## Error",
    "",
    result.error || "Unknown error",
    "",
    "## Output",
    "",
    result.text || "(no output)"
  ].join("\n");
}

function slug(value) {
  return String(value || "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "")
    .slice(0, 80);
}

function localOracleCommit(args = {}) {
  const title = typeof args.title === "string" && args.title.trim() ? args.title.trim() : "Oracle Read";
  const content = typeof args.content === "string" ? args.content.trim() : "";
  if (!content) {
    return { ok: false, error: "content is required" };
  }
  const question = typeof args.question === "string" ? args.question.trim() : "";
  const source = typeof args.source === "string" && args.source.trim() ? args.source.trim() : "Terminal Brain MCP";
  const project = typeof args.project === "string" && args.project.trim() ? args.project.trim() : "General Brain";
  const workspace = process.env.TERMINAL_BRAIN_WORKSPACE || join(process.env.HOME || "", "mejohnwc");
  const inbox = join(workspace, "Oracle Inbox");
  mkdirSync(inbox, { recursive: true });
  const created = new Date().toISOString();
  const tags = Array.from(new Set(["terminal-brain", "oracle", "mcp", "local-fallback"]
    .concat(Array.isArray(args.tags) ? args.tags : [])
    .map(slug)
    .filter(Boolean))).sort();
  const tagLines = tags.map((tag) => `  - ${tag}`).join("\n");
  const safeTitle = slug(title) || "oracle-read";
  const path = join(inbox, `${created.replaceAll(":", "-")}-${safeTitle}.md`);
  const questionBlock = question ? `\n## Question\n\n${question}\n` : "";
  const note = [
    "---",
    "type: oracle_commit",
    `source: ${source}`,
    `project: ${project}`,
    `created: ${created}`,
    "reviewStatus: new",
    "tags:",
    tagLines,
    "---",
    "",
    `# ${title}`,
    questionBlock,
    "## Read",
    "",
    content,
    "",
    "## Follow Up",
    "",
    "- [ ] Review and link this note to the relevant project or daily note.",
    "- [ ] Run Terminal Brain sync after edits are final.",
    ""
  ].join("\n");
  writeFileSync(path, note, "utf8");
  return {
    ok: true,
    mode: "local-fallback",
    path,
    title,
    project,
    reviewStatus: "new",
    tags,
    created,
    guardrail: "MCP oracle commit fallback did not launch or foreground Terminal Brain"
  };
}

function localOutcomeCommit(args = {}) {
  const outcome = typeof args.outcome === "string" ? args.outcome.trim() : "";
  if (!outcome) {
    return { ok: false, error: "outcome is required" };
  }
  const commandArgs = [join(ROOT, "mac-app", "scripts", "outcome.zsh")];
  if (typeof args.title === "string" && args.title.trim()) commandArgs.push("--title", args.title.trim());
  if (typeof args.project === "string" && args.project.trim()) commandArgs.push("--project", args.project.trim());
  if (typeof args.nextAction === "string" && args.nextAction.trim()) commandArgs.push("--next", args.nextAction.trim());
  if (Array.isArray(args.evidence)) {
    for (const evidence of args.evidence) {
      if (typeof evidence === "string" && evidence.trim()) commandArgs.push("--evidence", evidence.trim());
    }
  }
  if (Array.isArray(args.tags)) {
    for (const tag of args.tags) {
      if (typeof tag === "string" && tag.trim()) commandArgs.push("--tag", tag.trim());
    }
  }
  commandArgs.push(outcome);
  const result = runCommand("zsh", commandArgs, { timeout: 15000 });
  if (!result.ok) {
    return { ok: false, error: result.error || "Outcome commit failed.", output: result.text || "" };
  }
  try {
    return JSON.parse(result.text);
  } catch {
    return { ok: true, mode: "local-fallback", output: result.text };
  }
}

function supportBundleMarkdown() {
  const output = "/tmp/terminal-brain-mcp-support-bundle.md";
  const result = runCommand("zsh", [join(ROOT, "mac-app", "scripts", "support-bundle.zsh")], {
    timeout: 20000,
    env: { OUTPUT: output }
  });
  if (result.ok) {
    try {
      return readFileSync(output, "utf8").trim();
    } catch (error) {
      return [
        "# Terminal Brain Support Bundle",
        "",
        "Support bundle command completed, but the output file could not be read.",
        "",
        "## Error",
        "",
        error instanceof Error ? error.message : String(error)
      ].join("\n");
    }
  }
  return [
    "# Terminal Brain Support Bundle",
    "",
    "Support bundle failed before completing.",
    "",
    "## Error",
    "",
    result.error || "Unknown error",
    "",
    "## Output",
    "",
    result.text || "(no output)"
  ].join("\n");
}

async function valueNowMarkdown() {
  const health = await apiHealth();
  if (health.reachable) {
    const response = await fetch(`${API}/value-brief/markdown`);
    const text = await response.text();
    if (response.ok) return text;
  }

  const status = await runtimeStatus();
  return [
    "# Terminal Brain Value Now",
    "",
    "Terminal Brain is built to turn scattered local work context into one useful next move and a durable written outcome.",
    "",
    "## What You Can Get From It",
    "",
    "- A one-block work path: what to notice, decide, test, create, and avoid.",
    "- Agent-ready prompts grounded in local project memory.",
    "- Obsidian-backed writeback for ideas, reads, outcomes, and next actions.",
    "- Runtime checks that prove whether the app, MCP, config, and API are actually ready.",
    "- Guardrails that prevent background agents from launching or stealing focus.",
    "",
    "## Fastest Useful Path",
    "",
    "Open Terminal Brain manually when you want the UI/API active, then run:",
    "",
    "```zsh",
    "make start-here",
    "```",
    "",
    "If you only want to inspect readiness without opening the app:",
    "",
    "```zsh",
    "make doctor",
    "```",
    "",
    runtimeStatusMarkdown(status)
  ].join("\n");
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
    case "terminal_brain_runtime_status":
      return runtimeStatus();
    case "terminal_brain_now_markdown":
      return nowMarkdown();
    case "terminal_brain_what_now_markdown":
      return whatNowMarkdown();
    case "terminal_brain_use_now_markdown":
      return useNowMarkdown(args);
    case "terminal_brain_first_minute_markdown":
      return firstMinuteMarkdown();
    case "terminal_brain_now":
      return api("/now");
    case "terminal_brain_process_map_markdown":
      return processMapMarkdown(args);
    case "terminal_brain_cleanup_plan_markdown":
      return cleanupPlanMarkdown();
    case "terminal_brain_support_bundle_markdown":
      return supportBundleMarkdown();
    case "terminal_brain_next_markdown":
      return nextMarkdown();
    case "terminal_brain_doctor_markdown":
      return doctorMarkdown();
    case "terminal_brain_value_now_markdown":
      return valueNowMarkdown();
    case "terminal_brain_value_proof_markdown":
      return valueProofMarkdown();
    case "terminal_brain_demo_markdown":
      return demoMarkdown();
    case "terminal_brain_playbook_markdown":
      return playbookMarkdown();
    case "terminal_brain_value_audit_markdown":
      return valueAuditMarkdown();
    case "terminal_brain_completion_audit_markdown":
      return completionAuditMarkdown();
    case "terminal_brain_visual_review_plan_markdown":
      return visualReviewPlanMarkdown();
    case "terminal_brain_review_queue_markdown":
      return reviewQueueMarkdown(args);
    case "terminal_brain_bubble_up_markdown":
      return bubbleUpMarkdown(args);
    case "terminal_brain_work_block_markdown":
      return workBlockMarkdown(args);
    case "terminal_brain_oracle_brief_markdown":
      return oracleBriefMarkdown();
    case "terminal_brain_audit_markdown":
      return auditMarkdown();
    case "terminal_brain_status":
      try {
        return await api("/status");
      } catch {
        return {
          ok: true,
          mode: "local-fallback",
          status: "app-api-unreachable",
          runtimeStatus: await runtimeStatus(),
          guardrail: "MCP status fallback did not launch or foreground Terminal Brain"
        };
      }
    case "terminal_brain_snapshot":
      try {
        return await api("/snapshot");
      } catch {
        return localSnapshot();
      }
    case "terminal_brain_snapshot_markdown":
      try {
        return await api("/snapshot/markdown", { rawText: true });
      } catch {
        return localSnapshotMarkdown();
      }
    case "terminal_brain_handoff_markdown":
      return handoffMarkdown();
    case "terminal_brain_agent_prompt_markdown":
      return agentPromptMarkdown();
    case "terminal_brain_start_here_markdown":
      return startHereMarkdown();
    case "terminal_brain_sources":
      try {
        return await api("/sources");
      } catch {
        return {
          ok: true,
          mode: "local-fallback",
          markdown: sourcesMarkdown(),
          guardrail: "MCP sources fallback did not launch or foreground Terminal Brain"
        };
      }
    case "terminal_brain_sources_markdown":
      return sourcesMarkdown();
    case "terminal_brain_memory_brief_markdown":
      return memoryBriefMarkdown(args);
    case "terminal_brain_memory_promote":
      return promoteMemory(args);
    case "terminal_brain_recent_work_promote":
      return promoteRecentWork(args);
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
    case "terminal_brain_ideas":
      return api("/ideas");
    case "terminal_brain_ideas_markdown":
      return api("/ideas/markdown", { rawText: true });
    case "terminal_brain_idea_ask":
      return api("/ideas/ask", { method: "POST", body: { id: args.id || "", question: args.question || "" } });
    case "terminal_brain_idea_ask_commit": {
      const asked = await api("/ideas/ask", {
        method: "POST",
        body: { id: args.id || "", question: args.question || "" }
      });
      const suggestion = asked.commitSuggestion || {};
      const committed = await api("/oracle/commit", {
        method: "POST",
        body: {
          title: suggestion.title || `Idea Test - ${asked.question || "Oracle Read"}`,
          content: asked.answer || "",
          question: asked.groundedQuestion || asked.question || "",
          source: "Terminal Brain MCP",
          project: args.project || suggestion.project || "",
          tags: (Array.isArray(suggestion.tags) ? suggestion.tags : ["terminal-brain", "idea", "pressure-test", "oracle"])
            .concat(Array.isArray(args.tags) ? args.tags : [])
        }
      });
      return { ok: true, ask: asked, commit: committed };
    }
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
    case "terminal_brain_value_brief":
      return api("/value-brief");
    case "terminal_brain_value_brief_markdown":
      return api("/value-brief/markdown", { rawText: true });
    case "terminal_brain_oracle_digest":
      return api("/oracle-digest");
    case "terminal_brain_oracle_digest_markdown":
      return api("/oracle-digest/markdown", { rawText: true });
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
      try {
        return await api("/oracle/ask", { method: "POST", body: { question: args.question } });
      } catch {
        return oracleAskMarkdown(args);
      }
    case "terminal_brain_oracle_commit":
      try {
        return await api("/oracle/commit", {
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
      } catch {
        return localOracleCommit(args);
      }
    case "terminal_brain_commit_outcome":
      try {
        return await api("/outcomes/commit", {
          method: "POST",
          body: {
            title: args.title,
            outcome: args.outcome,
            nextAction: args.nextAction || "",
            project: args.project || "",
            evidence: Array.isArray(args.evidence) ? args.evidence : [],
            tags: Array.isArray(args.tags) ? args.tags : []
          }
        });
      } catch {
        return localOutcomeCommit(args);
      }
    case "terminal_brain_oracle_ask_commit": {
      try {
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
      } catch {
        return oracleAskMarkdown(args, { commit: true });
      }
    }
    case "terminal_brain_capture_idea":
      return captureIdea(args);
    case "terminal_brain_oracle_commits":
      return api("/oracle/commits");
    case "terminal_brain_oracle_review_status":
      return setReviewStatus(args);
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
