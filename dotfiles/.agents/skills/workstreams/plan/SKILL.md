---
name: workstream-plan
description: Use when creating or updating a workstream plan in `.workstreams/<name>/plan.md` that must break the workstream into sequential phases, parallel task waves, per-task behavioral specs, and meaningful phase gates. Usuall invocable by "ws plan"
user-invocable: true
---

# Building Workstream Tracks

## Overview

Use this skill to create workstream track pages in `.workstreams/<name>/plan.md` that turn a workstream into ordered phases with wave-structured tasks, explicit behavioral expectations, and meaningful completion criteria.

Use `workstream-about` when needed to understand the workstream model itself.

Each phase must:
- have a clear goal
- assign each task a distinct workstream-scoped tag and short name
- explain parallel work through task-wave naming
- contain only tasks that are parallelizable within the same wave
- give every task a behavioral spec, acceptance criteria, scenarios, and verification evidence
- end with a real gate
- use gates that matter for TDD-heavy development

This skill is for workstream planning, not internal scratch notes.

Once `plan.md` is completely one, we **MUST** invoke the workstream-tasks skill to build `tasks.json`

## When to Use

Use this skill when:

- a workstream in `.workstreams/<name>/` needs its own `plan.md`
- the workstream needs to be broken into phases
- each phase needs tagged tasks, per-task specs, and a completion gate
- phase boundaries must reflect real dependency edges
- tasks inside a phase should be parallelizable
- the document should be suitable for humans planning work, not just for an internal agent

Do not use this skill for:

- internal task execution plans outside the workstream folder
- high-level research capture in `design.md`
- architecture boundary documents that are not the workstream track itself

## Required Inputs

First resolve the exact workstream folder. If the target is ambiguous, confirm it with the user. If the workstream does not exist yet and the user is starting one, create `.workstreams/<name>/` before writing.

Before writing the track, read:

- `.workstreams/<name>/design.md`
- the most relevant architecture, spec, or package documents for the workstream

Use them to determine:

- workstream goal
- implementation language
- primary modules or packages
- dependency direction
- readiness expectations

## Output Location

Create the plan in:

- `.workstreams/<name>/plan.md`

## Core Rules

### 0. Resolve the Workstream and Keep the Track Authoritative

- Resolve the exact workstream folder before writing.
- If the target is ambiguous, confirm it with the user.
- If the workstream does not exist yet and the user is starting one, create `.workstreams/<name>/`.
- `plan.md` is the primary planning artifact for the workstream.

### 1. Phases Are Sequential

Phases are ordered. Later phases may depend on earlier phases.

A phase should exist only when it represents a real capability boundary or dependency boundary.

### 2. Tasks Need Stable Tags, Must Be Parallelizable, and Must Use Task Waves

Every task must start with a unique workstream-scoped tag and short name, similar to a Jira issue key.

Recommended format:

- `WS-P2-T1A` Task Name

Tags must be unique within the workstream and stable enough to reference in reviews, status updates, and follow-on planning.

Interpret the tag as:

- `WS` = workstream
- `P2` = phase
- `T1A` = task wave 1, lane A

Tasks that share the same wave number can be worked in parallel.

- `T1A`, `T1B`, and `T1C` may run in parallel
- `T2A` and `T2B` must wait until all `T1x` tasks in that phase are complete

Generated tracks should explain this rule near the beginning so readers can immediately understand the execution model.

Within a phase:

- tasks in the same wave must be able to proceed in parallel without blocking each other on unfinished work from the same wave
- later waves should exist only when there is a real dependency edge between task groups
- if all work is truly parallel, keep it in one wave rather than inventing fake sequencing

Good task splits:

- separate subdomains of one capability
- separate artifacts with a shared stable interface
- separate test groups against the same target contract

Bad task splits:

- one lane in a wave depends on another unfinished lane from that same wave
- task list is really a sequential checklist disguised as parallel work
- one task is "implement everything" and the others are cleanup
- a task is listed without a concrete behavioral contract

If tasks are not truly parallelizable, split the phase differently or introduce another wave.

### 3. Every Task Must Be Specified, and Phase Gates Must Matter

Every task must include:

- a `Behavioral spec`
- `Acceptance criteria`
- `Scenarios`
- `Verification`

There must be at least one scenario for every acceptance criterion. Always. A task is incomplete if any acceptance criterion lacks its own supporting scenario coverage.

Acceptance criteria must describe concrete task-local outcomes, behaviors, or observable constraints.

Do not write acceptance criteria that are only bookkeeping, planning hygiene, or references to other tracks or prior tasks.

Bad acceptance criteria include things like:

- "previous tracks were checked"
- "prior tasks were reviewed"
- "implementation aligns with earlier work"
- "the agent verified context"

Those may be planning steps or review checks, but they are not acceptance criteria.

If something matters for execution order, dependency readiness, or planning context, express it in phase structure, task dependencies, artifacts, or phase gates instead of pretending it is a task acceptance criterion.

When the agent creates or rewrites a task, it must show that task individually to the user. Its proposed acceptance criteria and proposed scenarios are suggestions until the user approves them. The agent must ask for approval of that task, including the suggested acceptance criteria and suggested scenarios, before moving on to the next task or finalizing the track.

Every phase ends with a phase gate.

A gate is not "docs written" or "code exists."

A phase gate must prove that the integrated phase output is ready for the next phase.

Default per-task verification style is:

- the task contract is explicit
- the listed acceptance criteria are covered by scenarios
- the relevant tests or checks are identified
- the verification named for that task surface is green

Default phase gate style is:

- contract or spec updated where needed
- tests exist for the phase capability
- verification is green
- outputs are stable enough for downstream phases

### 4. TDD Changes What Verification and Gates Mean

Because the project intends to use TDD broadly, per-task verification and phase gates should explicitly reflect evidence, not progress theater.

Good evidence:

- failing tests existed and now pass
- task-scoped verification is green
- phase verification suite is green
- invalid cases are covered
- downstream modules can now rely on the phase contract

Weak evidence:

- implementation started
- main happy path exists
- most tests pass
- manual confidence only
- previous tracks or earlier tasks were "checked"

### 5. Workstream Track, Not Internal Plan

Keep tracks readable and strategic.

Include:

- phase goals
- task waves
- per-task behavioral specs
- per-task acceptance criteria
- per-task scenarios
- per-task verification
- artifacts
- phase gates
- module or package alignment
- out-of-scope boundaries
- unchecked checkboxes for phases, tasks, and acceptance criteria in the generated track

Do not include:

- minute implementation steps
- commit-by-commit instructions
- private execution notes
- agent-only workflow details

## Recommended Page Structure

Use this structure:

```md
# Workstream: <Title>

## Goal

<One paragraph describing what capability this workstream should deliver.>

## Implementation Language

- `<language>`

## Primary Modules

- `path/...`
- `path/...`

## Success Criteria

- <criterion>
- <criterion>
- <criterion>

## Out of Scope

- <boundary>
- <boundary>

## Task Wave Model

Tasks use the form `WS-P<phase>-T<wave><lane>`.

- tasks sharing the same wave number can be worked in parallel
- later waves start only after all tasks in earlier waves in that phase are complete

## Phase 1: [ ] <Name>

### Goal

<What this phase enables.>

### Tasks

#### [ ] `WS-P1-T1A` <task name>

Behavioral spec:
<What behavior or contract this task must establish.>

Acceptance criteria:
- [ ] <criterion>
- [ ] <criterion>
- [ ] <criterion>

Scenarios:
Scenario: <name>
Given <context>
When <action>
Then <observable result>

Scenario: <name>
Given <context>
When <action>
Then <observable result>

Verification:
- <test suite, checks, or concrete evidence that proves this task is complete>

Artifacts:
- <files, modules, docs, or interfaces touched by this task>

#### [ ] `WS-P1-T1B` <task name>

...

### Phase Gate

- [ ] <integrated condition proving this phase is complete and safe for the next phase>
```
