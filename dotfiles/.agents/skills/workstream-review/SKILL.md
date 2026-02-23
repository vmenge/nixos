---
name: workstream review
description: "Review a workstream's changes and suggest PLAN.md additions and new tasks. Triggers on: workstream review, ws review, review workstream."
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash(git diff *), Bash(git log *), Bash(git branch *), Bash(ls *)
---

# Workstream Review

Review the work done so far in a workstream and suggest additions to PLAN.md and new tasks.

Triggered by `ws review <name>` or `workstream review <name>`.

## Workstream system

Workstreams are managed by the `ws` CLI tool. `ws run <name>` creates a git worktree and branch, then loops Claude in headless mode — each iteration picks the next incomplete task, implements it, tests, and commits.

Each workstream lives under `.workstreams/<name>/` with these files:

| File / Dir      | Purpose |
|-----------------|---------|
| `PLAN.md`       | Design doc with context, approach, and success criteria. |
| `tasks.json`    | Task list with `passes` booleans tracking completion. |
| `ACTIVITY.md`   | Dated progress log (created during runs). |
| `log`           | Real-time agent thought log. |
| `worktree/`     | Git worktree (created by `ws run`). |
| `is_running`    | Marker file present while running. |

## Steps

1. Ask the user which workstream to review (or accept it as an argument).
2. Read `.workstreams/<name>/PLAN.md` for the original design intent.
3. Read `.workstreams/<name>/tasks.json` to see current task status.
4. Read `.workstreams/<name>/ACTIVITY.md` for recent progress.
5. Diff the workstream branch against the main branch (`git diff main...<branch>`) and review the commit log (`git log main...<branch> --oneline`).
6. Analyze the diff for:
   - Missing edge cases or error handling
   - Gaps in test coverage
   - Incomplete or fragile implementations
   - Things that work but could be more robust
   - Anything that diverges from the original plan
7. Present findings to the user as:
   - Suggested additions to PLAN.md (new sections, amended scope, etc.)
   - New tasks to append to tasks.json (with `passes: false`)
8. Ask the user for feedback. They may have their own observations, want to adjust suggestions, or add things you missed.
9. Apply the approved changes: update PLAN.md and append new tasks to tasks.json.

## Review guidelines

- Focus on substance, not style. Don't nitpick formatting or naming unless it's genuinely confusing.
- New tasks should be scoped the same way existing tasks are — one logical unit of work each.
- Every new task must have `"passes": false`.
- Don't duplicate work already covered by existing tasks.
- Don't rewrite PLAN.md wholesale. Suggest targeted additions or amendments.
- Be concrete. "Add error handling for X when Y happens" is useful. "Improve error handling" is not.
