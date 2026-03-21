---
name: workstream-execute
description: "Used to execute a workstream"
user-invocable: true
---

# Overview

Use workstream-about skill to understand workstreams.

First read `activity.json` to see what was recently accomplished.

Open `design.md` and `plan.md` for context, and `review.md` if there exists one.
Then open `tasks.json` and choose the single highest priority task wave that has any elements with `done` set to `false`.

For every task, you **must** use the workstream-tdd skill to implement it.

Every task inside a wave is fully parallelizable. Dispatch a subagent for each task inside a wave. 
Once the sub-agents are done, make sure there are no conflicts between their work and that it works together.

You must **NEVER** work at more than a single wave at a time.

**IMMEDIATELY** after you complete a task you **MUST** mark it as complete in `tasks.json` and make one git commit for that task only with a clear message.

Append a dated progress entry to `activity.json` describing what you changed.

Do not git init, do not change remotes, do not push.

When ALL tasks have `done` set to `true`, output <promise>COMPLETE</promise>
