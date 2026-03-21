---
name: workstream-about
description: Use when working with repository workstreams stored under `.workstreams/` and you need to understand their structure, files, and lifecycle.
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

`plan.md` captures discovery work:

- phases
- task waves
- behavioral specs
- acceptance criteria
- scenarios
- verification
- completion gates

`tasks.json` captures the execution structure:

They strictly follow this type definition:
```typescript
type Task = {
  name: string;
  category: "setup" | "feature" | "testing";
  description: string;
  steps: string[];
  done: boolean;
};

type Wave = {
  name: string;
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

```typescript
type ActivityFile = ActivityEntry[];

type ActivityEntry = {
  at: string; // ISO 8601
  task: string; // the relevant task to this message
  message: string;
};
```

## Workstream Lifecycle

Workstreams usually move through this sequence:

1. understand the workstream concept
2. brainstorm the workstream and write findings into `design.md`
3. build or refine the execution track in `tasks.json` taking into acount `design.md` and `review.md` if review exists
4. execute the tasks phase by phase
5. review, if review wants changes, user will most likely start a new agent session to rebuild `tasks.json` based on `review.md`

The design file informs the tasks.

`tasks.json` is the source of truth for execution.

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
