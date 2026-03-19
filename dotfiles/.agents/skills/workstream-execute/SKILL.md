---
name: workstream-execute
description: Use when executing a workstream track from `.workstreams/<name>/track.md` phase-by-phase, where tasks are organized into waves and completion depends on acceptance criteria and scenarios being fulfilled.
---

# Executing Workstreams

## Overview

Use this skill to execute a workstream track from `.workstreams/<name>/track.md` one phase at a time.

Use `workstream-about` when needed to understand the workstream model itself.

This skill treats the workstream track as the source of truth for:

- phase order
- task-wave parallelism
- per-task behavioral expectations
- acceptance criteria
- scenarios
- completion checkboxes for phases, tasks, and acceptance criteria
- phase gates

Do not treat workstream tracks as loose guidance. They define what must be built and what counts as done.

`track.md` remains the source of truth throughout execution.

Derived artifacts in `docs/plans/` may be created for lower-level brainstorming, design, or implementation, but they are supporting artifacts only and must not override the workstream.

## When to Use

Use this skill when:

- a workstream track in `.workstreams/<name>/track.md` is ready to be executed
- the track uses task tags like `WS-P2-T1A`
- work must proceed phase-by-phase
- task completion depends on acceptance criteria and scenarios, not informal judgment

Do not use this skill when:

- you are still writing or revising the track itself
- you only need an internal implementation plan with no workstream execution
- the track is missing per-task specs or phase gates

## Required Inputs

First resolve the exact workstream folder. If the target is ambiguous, confirm it with the user. If the folder does not exist yet and the user is starting a new workstream, create `.workstreams/<name>/`. If `track.md` is missing, do not improvise execution; switch to `workstream-track` first.

Before executing, read:

- the target workstream track in `.workstreams/<name>/track.md`
- `.workstreams/<name>/research.md`
- any architecture or spec documents directly referenced by the track

Use them to determine:

- the current phase to execute
- affected modules or packages
- dependency boundaries
- architectural constraints
- verification expectations

## Workstream Tag Semantics

Workstream tasks use the form `WS-P<phase>-T<wave><lane>`.

Interpret the tag as:

- `WS` = workstream
- `P2` = phase
- `T1A` = task wave 1, lane A

This implies:

- tasks sharing the same wave number can be worked in parallel
- `T1A`, `T1B`, and `T1C` may run at the same time
- `T2A` and `T2B` must wait until all `T1x` tasks in that phase are complete
- later phases may not start until the current phase gate is satisfied

Default unit of execution is one phase.

Do not execute work from a later phase until the current phase is complete.

## What Counts as Done

A task is done only when:

- its behavioral spec is implemented
- its acceptance criteria are satisfied
- the related scenarios are fulfilled
- the verification evidence for that task is green
- the track checkboxes for that task and its completed acceptance criteria are marked

Acceptance criteria define what must be true.

Scenarios provide evidence that those things are true.

Do not mark a task done because:

- code exists
- the happy path works
- a partial implementation seems close
- some tests pass

If any acceptance criterion is not fulfilled, the task is not done.

If the related scenarios are not fulfilled, the task is not done.

If the track checkboxes are not updated, the task is not done.

## Required Workflow

You MUST follow this sequence:

1. Use `brainstorming`
2. Use `software architecture and domain modeling`
3. Use `software-testing`
4. Confirm the testing strategy with the user
5. Show a small tree view of the modules or files you expect to change
6. Use `writing-plans`
7. Use `executing-plans`

Use `dispatching-parallel-agents` during implementation when the current task wave contains 2 or more truly independent tasks that can proceed concurrently without shared-state conflicts.

Use `software-testing` to shape the testing strategy for the phase, confirm that strategy with the user, and then use `test-driven-development` during implementation for every task.

Any plan written in `docs/plans/` is a derived artifact from `track.md` and must stay aligned with it.

## Human Approval Boundaries

The human is in the loop during:

- `brainstorming`
- `software architecture and domain modeling`
- testing-strategy confirmation
- planned-change tree review

During those stages, explicit human approval is required before proceeding.

After that approval is complete:

- proceed autonomously through planning and implementation
- do not pause for routine approvals
- ask the human only if blocked, if the track is unclear, or if architectural assumptions materially change

If design or scope changes in a meaningful way during execution, return to the relevant design step and request explicit approval again.

## Phase Execution Process

### 1. Select the Current Phase

Start with the earliest incomplete phase in the track unless the user explicitly directs otherwise.

Review:

- the phase goal
- all task waves in that phase
- per-task behavioral specs
- acceptance criteria
- scenarios
- verification sections
- the phase gate

### 2. Brainstorm the Phase

Use `brainstorming` to explore the phase, constraints, risks, and success conditions.

When presenting different approaches during brainstorming or design:

- give enough project and task context for the comparison to make sense
- explain the main pros and cons of each approach, not just the recommendation
- include brief concrete examples when they make the tradeoff easier to understand

Stop and require explicit human approval before continuing.

### 3. Design the Phase

Use `software architecture and domain modeling` to shape the implementation approach.

Stop and require explicit human approval before continuing.

### 4. Confirm the Testing Strategy

Before planning or implementation, use `software-testing` to develop the testing strategy, then confirm it with the user.

Do not assume one default testing style fits the project.

The testing approach may depend heavily on the stack, boundaries, runtime model, deployment shape, and repository conventions.

Review the current codebase and phase scope, then propose a concise testing strategy that covers:

- primary test level or levels
- major test tools or frameworks
- where tests should live
- what verification evidence will be required per task and per phase

Use the project's `software-testing` skill to ground this recommendation in the repository's preferred testing approach.

Require explicit human approval before continuing.

### 5. Show the Planned Change Surface

Before planning or implementation, show a small tree view of the modules or files you expect to change so the user has a good grasp of the architecture and planned impact surface.

Keep it short and structural. Show only the likely touched paths and enough surrounding hierarchy to orient the user.

Example:

```text
src/
  parser/
    mod.rs
    tokens.rs
  runtime/
    scheduler.rs
tests/
  integration/
    parser_flow.rs
```

Require explicit human approval before continuing.

### 6. Sync the Track Before Planning

If the approved testing strategy or planned change surface materially changes the workstream's verification, artifacts, out-of-scope boundaries, or sequencing assumptions, update `track.md` before writing any derived plan.

Do not let a `docs/plans/` artifact carry execution assumptions that are missing from or inconsistent with the track.

### 7. Write the Plan

Use `writing-plans` to create an implementation plan for the approved phase.

The plan must:

- respect phase ordering
- preserve wave semantics
- map tasks to exact files and tests
- reflect TDD
- derive implementation work from the task specs

Any plan created in `docs/plans/` is a derived artifact only.

It must be derived from the approved `track.md`.

If planning reveals that scope, sequencing, verification, or touched surfaces need to change, update `track.md` first and obtain any necessary user approval before continuing.

### 8. Execute the Plan

Use `executing-plans` to implement the written plan.

Within a wave:

- independent tasks may proceed in parallel
- use `dispatching-parallel-agents` when parallel execution is real and safe
- do not invent parallelism where tasks depend on each other

Across waves:

- complete all tasks in the current wave before starting the next wave

Across phases:

- satisfy the phase gate before starting the next phase

### 9. Mark Completion Checkboxes

As work completes, update the track directly.

- mark each completed acceptance criterion checkbox as `[x]` as soon as that acceptance criterion is truly satisfied
- mark each completed task checkbox as `[x]` only after the task truly satisfies its spec, criteria, scenarios, verification, and reviewer loop
- mark the phase checkbox as `[x]` only after every task in the phase is complete and the phase gate is satisfied

Do not leave track checkboxes stale.

Do not wait until the end of the task to mark an acceptance criterion that is already truly complete.

### 10. Run a Reviewer Loop After Every Task

After finishing a task, but before continuing to the next task or wave:

1. spawn a reviewer subagent to review the completed task against the track, affected code, tests, and task verification
2. wait for the reviewer result before proceeding
3. for every issue the reviewer raises, add or extend tests so the issue is covered, then fix the implementation
4. rerun the relevant verification
5. spawn another reviewer subagent
6. repeat until the reviewer explicitly says it is ok to continue

Do not continue to the next task, the next wave, or the phase gate while the latest reviewer subagent still has unresolved issues.

## TDD From Scenarios

Use the task scenarios to drive TDD.

For each scenario:

- write one or more failing tests that prove the scenario is not yet satisfied
- run the tests and verify they fail for the expected reason
- implement the minimum code needed to satisfy the scenario
- run the tests again and verify they pass
- refactor only after green

The number of tests is not fixed.

One scenario may require:

- one focused test
- multiple tests for variants or edge cases
- additional regression tests needed to prove the acceptance criteria fully

Use as many tests per scenario as necessary.

A scenario is not complete merely because one nominal example passes if the acceptance criteria still lack evidence.

Reviewer findings must also become test coverage. If a reviewer identifies a missing case, regression risk, or spec gap, add tests that capture it before claiming the task is complete.

## Parallel Execution Rules

Use wave semantics honestly.

Good parallel execution:

- parser surface and parser failure coverage that target the same stable domain model
- independent packages or modules with clear interfaces
- separate test surfaces against a shared approved contract

Bad parallel execution:

- one lane depends on unfinished output from another lane in the same wave
- one task is the real implementation and the others are cleanup
- work is parallelized only on paper while actual dependencies remain sequential
