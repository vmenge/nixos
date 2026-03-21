---
name: workstream-execute
description: Use when executing a workstream from `.workstreams/<name>/tasks.json`, completing all waves serially and tasks within a wave in parallel. Trigger phrases: "ws execute", "workstream execute".
---

# Overview

Use workstream-about skill to understand workstreams.

First read `activity.json` to see what was recently accomplished. If it does not exist, create it with `[]`.

Open `design.md` and `plan.md` for context, and `review.md` if there exists one.
Then open `tasks.json` and choose the next highest-priority wave that has any elements with `done` set to `false`.
Continue until all waves are complete.

For every task, you **must** use the workstream-tdd skill to implement it.

Every task inside a wave is fully parallelizable. Dispatch a subagent for each task inside a wave.
Once the sub-agents are done, make sure there are no conflicts between their work and that it works together.

You must **NEVER** work on more than one wave at a time.
Finish the current wave completely before starting the next wave.

As soon as an individual task is finished and its task-local verification is green, mark that task as done in `tasks.json`.
Do not wait for the whole wave to finish before updating task completion state.

After you integrate and verify the current wave, complete that wave's review gate before starting the next wave.
A wave review gate means:
- the wave's listed verification is green
- the integrated result of the wave works together
- the next wave's prerequisites are satisfied

After you complete and verify a wave, make one git commit for that wave with a clear message summarizing the completed task ids.

Append a dated progress entry to `activity.json` after each completed wave describing what changed, what was verified, and what wave comes next.

Do not git init, do not change remotes, do not push.

When ALL tasks in ALL waves have `done` set to `true`, output <promise>READY_FOR_REVIEW</promise>
