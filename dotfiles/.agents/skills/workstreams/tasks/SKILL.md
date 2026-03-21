---
name: workstream-tasks
description: "Used to build a task.json. Usually invoked by the workstream-design or the workstream-review skill"
user-invocable: true
---

# Writing a `tasks.json` for guided workstream execution

Use the workstream-about skill to understand how workstreams work.
Your goal is to read the workstream `design.md` and `plan.md`, and if there exists a `review.md` or `activity.json` file, read that as well.
These files you just read are of EXTREME importance and will drive the writing of `tasks.json`.
`plan.md` in particular is your north star.

Then you will create a `tasks.json` in the workstream's directory with the format that is specified in the workstream-about skill.

Each item inside a wave in `task.json` should be parallelizable with each other. The waves themselves SHOULD be ordered as they will be executed sequentially later on.

Do NOT invoke any skill to execute anything.
