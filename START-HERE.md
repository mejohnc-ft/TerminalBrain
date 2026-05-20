# Terminal Brain Start Here

Terminal Brain is useful when it turns scattered local context into one work block with a written outcome.

## One-Block Loop

1. Read the current value path:

   ```zsh
   make start-here
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
- `Oracle Digest` says what to notice, decide, test, create, and avoid.
- `Agent Prompt` turns the current signal into a bounded Codex/Claude task.
- `Outcome` writeback saves what changed as accepted durable memory.

## Guardrail

These commands never launch or foreground Terminal Brain. If the app is not already running, they tell you to start it yourself.
