# Terminal Brain Start Here

Terminal Brain is useful when it turns scattered local context into one work block with a written outcome.

## One-Block Loop

1. Read the current value path:

   ```zsh
   make now
   ```

   `make now` is the fastest orientation: bottom line, next action, process truth, readiness, and the outcome close loop.

   ```zsh
   make value
   ```

   If the app is already reachable, `make value` prints the live Value Brief. If it is closed, it explains what the system is useful for without starting anything. To read the next concrete move, run:

   ```zsh
   make next
   ```

   To read only status, run:

   ```zsh
   make status
   ```

   To see what is still running without killing anything, run:

   ```zsh
   make processes
   ```

   To get a cleanup plan without killing anything, run:

   ```zsh
   make cleanup-plan
   ```

   To write one troubleshooting file, run:

   ```zsh
   make support-bundle
   ```

   To audit setup wiring without launching the app, run:

   ```zsh
   make doctor
   ```

2. If an agent needs the task, copy the focused execution prompt:

   ```zsh
   make agent-prompt
   ```

3. If the task needs local memory, build or read the latest context pack:

   ```zsh
   make latest-pack
   ```

4. End the block by committing what changed:

   ```zsh
   make outcome TITLE="..." OUTCOME="..." PROJECT="..." NEXT="..."
   ```

## What To Look For

- `Start Here` gives the shortest path from signal to action to outcome.
- `Now` gives one page with bottom line, next action, process truth, readiness, and close loop.
- `Value` says what Terminal Brain is useful for right now.
- `Status` shows repo, CI, process, launchctl, and API state without touching app focus.
- `Processes` separates app/runtime focus stealers from Codex, MCP, kernel, brain-console, and Drafts background noise.
- `Cleanup Plan` prints stale MCP/kernel candidates and manual review commands without terminating anything.
- `Support Bundle` writes Now, Doctor, Audit, Process Map, Cleanup Plan, and Git state into one Markdown file.
- `Doctor` checks app install, MCP contract, agent config references, and runtime readiness.
- `Oracle Digest` says what to notice, decide, test, create, and avoid.
- `Agent Prompt` turns the current signal into a bounded Codex/Claude task.
- `Outcome` writeback saves what changed as accepted durable memory.

## Guardrail

These commands never launch or foreground Terminal Brain. If the app is not already running, they tell you to start it yourself.
