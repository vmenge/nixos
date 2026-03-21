---
name: workstream-tasks
description: Use when building or refreshing `.workstreams/<name>/tasks.json` from `plan.md` and optional `review.md` while preserving execution state across the review loop. Trigger phrases: "ws tasks", "workstream tasks".
---

# Writing a `tasks.json` for guided workstream execution

Use the workstream-about skill to understand how workstreams work.
Your goal is to read the workstream `design.md` and `plan.md`, and if there exists a `review.md` or `activity.json` file, read that as well.
These files you just read are of EXTREME importance and will drive the writing of `tasks.json`.
`plan.md` in particular is your north star.

Then create or update `tasks.json` in the workstream's directory with the format specified in workstream-about.

Each item inside a wave in `tasks.json` must be parallelizable with the others in that wave. The waves themselves must be ordered as they will be executed serially later on.

You must preserve stable `wave.id` and `task.id` values from `plan.md`.

If `tasks.json` already exists:
- preserve every completed task by matching on stable `id`
- never reset `done: true` to `false` unless the user explicitly asks
- keep unfinished planned tasks unless they are intentionally replaced
- add follow-up work from `review.md` as new undone tasks or new undone waves
- keep completed history intact even if remaining work is regrouped

If `review.md` does not exist, build `tasks.json` only from `design.md` and `plan.md`.

Do NOT invoke any skill to execute anything.
