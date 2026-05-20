# Terminal Brain Agent Rules

This repository builds a local macOS app used during active work. Do not steal the operator's focus.

## Safe Defaults

- Use `make work-block` or MCP `terminal_brain_work_block_markdown` first when the operator needs one concrete closed-app work surface: pull forward, triage, do the smallest useful work, and close the loop.
- Use `make start-here`, MCP `terminal_brain_start_here_markdown`, or `make next` as the safest first commands when you need the one-block value path without launching the app; when the app is closed, they include local Oracle and Work Block paths.
- Use `make first-minute` or MCP `terminal_brain_first_minute_markdown` when the operator needs the fastest explanation of what Terminal Brain is, why it matters, and proof the loop works.
- Use `make demo` or MCP `terminal_brain_demo_markdown` when the operator needs a temporary seeded walkthrough that proves Review Queue, Bubble Up, Work Block, and outcome writeback without touching the real workspace.
- Use `make prove-value` or MCP `terminal_brain_value_proof_markdown` when you need to prove the closed-app loop works without touching the real workspace.
- Use `make idea IDEA="..." PROJECT="..."` or MCP `terminal_brain_capture_idea` when a thought needs to be saved immediately; both have a closed-app fallback into the Oracle Inbox.
- Use `make review` or MCP `terminal_brain_review_queue_markdown` when you need to see captured ideas, delegated reads, and outcome notes without opening the app.
- Use `make review-status ID="..." STATUS=accepted` or MCP `terminal_brain_oracle_review_status` when a review item needs to be accepted, linked, delegated, dismissed, or reopened without opening the app.
- Use `make bubble-up` or MCP `terminal_brain_bubble_up_markdown` when the operator needs neglected ideas, delegated loops, or repeated project pressure surfaced without opening the app.
- Use `make value` when the operator needs a plain-language read on why Terminal Brain is useful right now.
- Use `make oracle-brief` or MCP `terminal_brain_oracle_brief_markdown` when the operator needs a direct read: what to do next, what may be missing, the cheapest test, and the agent handoff.
- Use `make ask QUERY="..."`, `make ask-commit QUERY="..." PROJECT="..."`, MCP `terminal_brain_oracle_ask`, or MCP `terminal_brain_oracle_ask_commit` when the operator wants to interact with the Oracle; these use local Oracle Brief fallbacks when the app is closed.
- Use MCP `terminal_brain_oracle_commit` or `terminal_brain_commit_outcome` when agents need to write durable memory; both fall back to local Oracle Inbox writes when the app is closed.
- Use `make agent-prompt` or MCP `terminal_brain_agent_prompt_markdown` when you need a bounded execution prompt; both have closed-app fallbacks and do not launch Terminal Brain.
- Use `make now` or MCP `terminal_brain_now_markdown` as the fastest single orientation when the operator needs value, next action, process truth, readiness, and close-loop guidance.
- Use `make doctor` when setup readiness is unclear; it audits repo, CI, app install freshness, MCP contract, agent config, prompt-prone Apple Notes/Drafts bridges, process state, launchctl, API reachability, and a readiness verdict without launching the app.
- Use `make audit` when you need a non-launching evidence checklist for value, MCP, safety, and readiness surfaces.
- Use `make processes` or MCP `terminal_brain_process_map_markdown` when the operator asks what is still running; it maps Terminal Brain, launchctl, API, Codex, MCP, brain-kernel, brain-console, and Drafts state without launching, foregrounding, quitting, or killing anything.
- Use `make cleanup-plan` or MCP `terminal_brain_cleanup_plan_markdown` when runtime noise needs cleanup guidance; it prints stale MCP/kernel candidates and manual commands without killing anything.
- Use `make support-bundle` or MCP `terminal_brain_support_bundle_markdown` when you need one Markdown artifact with Now, Doctor, Audit, Process Map, Cleanup Plan, and Git state.
- Use `./mac-app/scripts/verify-static.zsh` for normal verification.
- Use `./mac-app/scripts/build-app.zsh` for build-only checks.
- Use `./mac-app/scripts/verify-static.zsh` for Swift type-checking because the app now depends on SwiftUI, AppKit, Network, and AppIntents framework flags.
- Use `node --check mcp-server/server.mjs` for MCP syntax checks.

## Fast Context Path

When Terminal Brain may not be running, use `make work-block`, `make next`, `make first-minute`, `make demo`, `make now`, `make value`, `make prove-value`, `make idea IDEA="..."`, `make review`, `make review-status ID="..." STATUS=accepted`, `make bubble-up`, `make oracle-brief`, `make status`, `make processes`, `make cleanup-plan`, `make support-bundle`, `make doctor`, `make audit`, MCP `terminal_brain_work_block_markdown`, MCP `terminal_brain_next_markdown`, MCP `terminal_brain_first_minute_markdown`, MCP `terminal_brain_demo_markdown`, MCP `terminal_brain_now_markdown`, MCP `terminal_brain_value_now_markdown`, MCP `terminal_brain_value_proof_markdown`, MCP `terminal_brain_capture_idea`, MCP `terminal_brain_review_queue_markdown`, MCP `terminal_brain_oracle_review_status`, MCP `terminal_brain_bubble_up_markdown`, MCP `terminal_brain_oracle_brief_markdown`, MCP `terminal_brain_process_map_markdown`, MCP `terminal_brain_cleanup_plan_markdown`, MCP `terminal_brain_support_bundle_markdown`, MCP `terminal_brain_doctor_markdown`, MCP `terminal_brain_audit_markdown`, or MCP `terminal_brain_runtime_status` first. These checks do not launch or foreground the app.

When Terminal Brain is already running and the user asks for useful work, start from the handoff instead of re-discovering the system:

```zsh
./mac-app/scripts/handoff.zsh --output /tmp/terminal-brain-handoff.md
```

The handoff combines Start Here, Oracle Brief, the Oracle Digest, Value Brief, Operator Brief, Blindspot Brief, Idea Pulse, Decision Lane, Operator Deck, Project Memory, and latest context pack. It never launches or foregrounds Terminal Brain. If using MCP, prefer `terminal_brain_start_here_markdown` when you need the shortest value path, `terminal_brain_oracle_brief_markdown` when you need the clearest direct read, `terminal_brain_agent_prompt_markdown` when you need one focused execution prompt, or `terminal_brain_handoff_markdown` when you need the broader state. `make agent-prompt` is the terminal equivalent and falls back to safe local reads when the app is closed. Then use `terminal_brain_oracle_digest_markdown`, `terminal_brain_value_brief_markdown`, Idea Pulse ask/commit, Blindspot ask/commit, Decision Lane, Project Memory, Operator Deck, and Start Work tools for follow-up actions. When work produces a durable result, close the loop with `terminal_brain_commit_outcome` or `make outcome TITLE="..." OUTCOME="..." PROJECT="..." NEXT="..."`; `make outcome` writes an accepted Oracle Inbox note directly if the app is closed.

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
