# Terminal Brain Start Here

Terminal Brain is useful when it turns scattered local context into one work block with a written outcome.

If you open the native app manually, start in the simple operator sidebar. The default path is `Use Now` -> `Oracle` -> `Review` -> `Start Work`, with `Ideas` for anything you do not want to lose. Use `Show All Surfaces` only when you need the deeper dashboard.

On `Use Now`, use the inline `Ask, Decide, Remember` panel before browsing: ask what you may be missing, ask for the cheapest useful test, delegate a bounded agent task, or commit the useful read into the review queue.

## One-Block Loop

1. Start with the one-command path:

   ```zsh
   make start
   make easy
   make answer
   make check-in
   make use-now
   make daily-brief
   ```

   `make answer` gives the shortest direct read. When nothing is obviously bubbling up, it routes to `make check-in`, which asks for one real sentence and can capture it with `make check-in IDEA="..."`. Captured check-ins print the exact ask and outcome commands for that sentence, so a clean queue still becomes a concrete loop. `make start`, `make easy`, and `make use-now` start with a no-choice path: one executable move, a fallback ask/capture/check-in path if that move does not fit, and the outcome writeback command before the detailed context.
   `make daily-brief` is the proactive start-of-day path: it checks source freshness, ranks action cards, asks the Oracle, and gives the close-loop command.

   The native signal loop is: Radar surfaces a signal, Blindspots challenges it, and Ideas captures the follow-up if the counter-signal should become durable work. In the app this is exposed as `Check Blindspots`, `Capture as Idea`, and the Ideas capture lane. From the terminal, use:

   ```zsh
   make bubble-up
   make idea IDEA="The counter-signal I need to track is ..." PROJECT="Terminal Brain"
   ```

   If you already know you only want the pull-forward block, run:

   ```zsh
   make work-block
   ```

   ```zsh
   make next
   ```

   `make next` gives the safest current path without launching or foregrounding the app.

   If you need the plain answer to "what is happening now?", run:

   ```zsh
   make what-now
   ```

   `make what-now` reports app focus state, repo/CI state, runtime noise, what the counts mean, the current blocker, and the next value command without launching or foregrounding the app.

   To prove the loop in a temporary workspace, run:

   ```zsh
   make prove-value
   ```

   `make prove-value` demonstrates the full closed-app loop without touching the real vault.

   To see the loop with realistic seeded ideas, run:

   ```zsh
   make demo
   ```

   `make demo` creates a temporary workspace, seeds ideas and an outcome, then shows Review Queue, Bubble Up, Work Block, and the real commands to keep using the system.

   To choose the right command for a real situation, run:

   ```zsh
   make playbook
   ```

   `make playbook` maps common work situations to exact commands, the first five-minute loop, daily cadence, agent cadence, and current readiness.

   To audit what is covered and what is still weak, run:

   ```zsh
   make value-audit
   ```

   `make value-audit` maps the first-use value objective to concrete artifacts, evidence, and remaining gaps.

   To audit native macOS shell and liquid glass design evidence without opening the app, run:

   ```zsh
   make design-audit
   ```

   To prepare the manual visual certification pass without opening the app, run:

   ```zsh
   make visual-review-plan
   ```

   ```zsh
   make now
   ```

   `make now` is the fastest orientation: Use Now-first action, why it matters, process truth, readiness, and the outcome close loop.

   ```zsh
   make value
   ```

   If the app is already reachable, `make value` prints the live Value Brief. If it is closed, it explains what the system is useful for without starting anything. To read the next concrete move, run:

   ```zsh
   make oracle-brief
   ```

   `make oracle-brief` gives the direct read: what to do next, what may be missing, the cheapest test, and the agent handoff.

   ```zsh
   make bubble-up
   ```

   `make bubble-up` surfaces neglected ideas, delegated loops, and repeated project pressure from the Oracle Inbox.

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

   If the app is closed, `make agent-prompt` returns a safe fallback prompt instead of launching Terminal Brain.

3. If the task needs local memory, build or read the latest context pack:

   ```zsh
   make latest-pack
   ```

4. End the block by committing what changed:

   ```zsh
   make outcome TITLE="..." OUTCOME="..." PROJECT="..." NEXT="..."
   ```

   If the app is closed, `make outcome` writes the accepted note directly into the workspace Oracle Inbox.

## What To Look For

- `Start Here` gives the shortest path from signal to action to outcome.
- `Now` gives one page with bottom line, next action, process truth, readiness, and close loop.
- `Value` says what Terminal Brain is useful for right now.
- `Value Proof` demonstrates Oracle Brief -> Agent Prompt -> accepted Outcome without touching the real workspace.
- `Demo` shows ideas becoming a review queue, bubbled-up signals, and one work block in a temporary workspace.
- `Playbook` tells you which command to use for capture, Oracle reads, agent handoff, outcomes, and runtime checks.
- `Check In` turns a clean queue into one real sentence: a decision, loose end, or useful artifact to create next. When captured, it immediately shows how to ask Terminal Brain against that sentence and save the outcome.
- `Value Audit` proves which first-use value requirements are covered and names the remaining gaps.
- `Oracle Brief` gives the direct read, missing signal, cheap test, and agent handoff.
- `Status` shows repo, CI, process, launchctl, and API state without touching app focus.
- `Processes` separates app/runtime focus stealers from Codex, MCP, kernel, brain-console, and Drafts background noise.
- `Cleanup Plan` prints stale MCP/kernel candidates and manual review commands without terminating anything.
- `Bubble Up` surfaces neglected ideas, delegated loops, repeated project pressure, and recent repo work that still needs a reviewed outcome.
- `Recent Work` promotes a shipped git change into the Oracle Inbox with `make recent-work INDEX=1`.
- `Work Block` combines Bubble Up, Review Queue, and outcome writeback into one immediate work surface.
- `Support Bundle` writes Now, Oracle Brief, Bubble Up, Doctor, Audit, Process Map, Cleanup Plan, and Git state into one Markdown file.
- `Doctor` checks app install, MCP contract, agent config references, and runtime readiness.
- `Oracle Digest` says what to notice, decide, test, create, and avoid.
- `Agent Prompt` turns the current signal into a bounded Codex/Claude task.
- `Outcome` writeback saves what changed as accepted durable memory.

## Guardrail

These commands never launch or foreground Terminal Brain. If the app is not already running, they tell you to start it yourself.
