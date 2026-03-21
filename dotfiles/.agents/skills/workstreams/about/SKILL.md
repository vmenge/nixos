---
name: workstream-about
description: Use when working with repository workstreams stored under `.workstreams/` and you need to understand their structure, files, lifecycle, and execution loop. Trigger phrases: "workstream about".
---

# Workstream About

## Overview

Use this skill to understand the workstream model used in a repository.

A workstream is a unit of work stored under:

- `<repo>/.workstreams/<workstream-name>/`

Each workstream has a few files:

- `.workstreams/<workstream-name>/design.md`
- `.workstreams/<workstream-name>/plan.md`
- `.workstreams/<workstream-name>/tasks.json`
- `.workstreams/<workstream-name>/activity.json`
- `.workstreams/<workstream-name>/review.md`

Treat the workstream folder as the durable planning surface for that unit of work.

Workstreams are the primary planning surface for this unit of work.
`.workstreams` folder is usually gitignored in projects.

## What the Files Mean

`design.md` captures discovery work:

- what is being built
- user intent
- constraints
- relevant architecture notes
- research findings that will help execute tasks

`plan.md` captures the approved execution design:

- ordered waves
- behavioral specs
- acceptance criteria
- scenarios
- verification
- per-wave review gates

`tasks.json` captures the durable execution ledger:

They strictly follow this type definition:
```typescript
type Task = {
  id: string; // stable task id carried from plan.md, e.g. WS-W2-TA
  name: string;
  category: "setup" | "feature" | "testing";
  description: string;
  acceptance_criteria: string[];
  verification: string[];
  steps: string[];
  done: boolean;
};

type Wave = {
  id: string; // stable wave id, e.g. WS-W2
  name: string;
  review_gate: string[];
  checklist: Task[];
};

type Tasks = {
  // full file paths for files that MUST be read before executing tasks
  must_read_files: string[];
  // every item in a wave can be run in parallel
  // waves MUST be completed in order, only work at ONE wave at a time
  waves: Wave[];
};
```

There is a task example in `tasks.example.json`


`review.md` captures the execution review:

- contains details from a separate agent that reviewed recently completed work for this workstream

`activity.json` captures the execution's history:
- used by the agent as a memory of accomplished things during a workstream execution
- updated whenever agent does something meaningful or has an important thought or important finding
- initialize it to `[]` if it does not exist yet

```typescript
type ActivityFile = ActivityEntry[];

type ActivityEntry = {
  agent: string;
  at: string; // ISO 8601
  task: string; // the relevant task to this message
  message: string;
  next_step: string;
};
```

There is a task example in `activity.example.json`

## Workstream Lifecycle

Workstreams usually move through this sequence:

1. understand the workstream concept
2. brainstorm the workstream and write findings into `design.md`
3. build the ordered wave plan in `plan.md`
4. build or refresh `tasks.json` from `plan.md` and `review.md` if it exists
5. execute all waves serially from `tasks.json`, while completing tasks inside each wave in parallel
6. after each wave, satisfy that wave's review gate before starting the next wave
7. run a fresh `workstream-review` session after execution completes
8. if review finds follow-up work, refresh `tasks.json` and repeat the loop

Execution and review are both manually triggered by the user, typically in separate headless agent sessions.
Do not assume `workstream-execute` automatically invokes `workstream-review`.
Do not assume `workstream-review` automatically follows execution unless the user starts that session.

`design.md` informs `plan.md`.
`plan.md` is the source of truth for planning intent.
`tasks.json` is the source of truth for execution state.

## When to Use

Use this skill when:

- the user refers to a workstream
- you need to brainstorm a workstream, execute a workstream or review a workstream.
- you need to execute a workstream from its track
- the structure or meaning of workstreams is unclear

Do not use this skill when:

- the work is unrelated to the repository's `.workstreams/` system
- you already have the full workstream model in context and do not need to reload it

## Rules

- Keep all workstream-specific context inside the matching workstream folder.
- Agents may create `.workstreams/<name>/` when starting a new workstream.
- If the intended workstream name or path is ambiguous, resolve it with the user before writing.
- Do not treat ad hoc notes outside `.workstreams/<name>/` as the source of truth over `design.md`, `tasks.json`, `activity.json` or `review.md`.
- If another workstream skill applies, use this skill first or alongside it when the workstream model needs clarification.
- Treat `workstream-execute` and `workstream-review` as user-invoked headless-session steps in the loop, not as automatic nested handoffs.
