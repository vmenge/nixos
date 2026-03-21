---
name: workstream-plan
description: Use when creating or updating a workstream plan in `.workstreams/<name>/plan.md` that must break the workstream into ordered execution waves, parallel tasks within a wave, per-task behavioral specs, and meaningful review gates between waves. Trigger phrases: "ws plan", "workstream plan".
---

# Building Workstream Wave Plans

## Overview

Use this skill to create workstream planning pages in `.workstreams/<name>/plan.md` that turn a workstream into ordered waves with explicit behavioral expectations and meaningful completion criteria.

Use `workstream-about` when needed to understand the workstream model itself.

Each wave must:
- have a clear goal
- have a stable wave-scoped tag
- contain only tasks that are parallelizable within that wave
- give every task a behavioral spec, acceptance criteria, scenarios, and verification evidence
- end with a real review gate that must be satisfied before the next wave begins
- use review gates that matter for TDD-heavy development

This skill is for workstream planning, not internal scratch notes.

Once `plan.md` is complete, invoke workstream-tasks to build or refresh `tasks.json`.

## When to Use

Use this skill when:

- a workstream in `.workstreams/<name>/` needs its own `plan.md`
- the workstream needs to be broken into ordered waves
- each wave needs tagged tasks, per-task specs, and a review gate
- wave boundaries must reflect real dependency edges
- tasks inside a wave should be parallelizable
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

### 1. Waves Are Sequential

Waves are ordered. Later waves may depend on earlier waves.

A wave should exist only when it represents a real dependency boundary or a meaningful review boundary.

### 2. Waves Need Stable Tags, and Tasks Must Be Parallelizable Within a Wave

Every wave must have a unique workstream-scoped id. Every task must have a unique task id under that wave.

Recommended format:

- `WS-W2` Wave Name
- `WS-W2-TA` Task Name

Tags must be unique within the workstream and stable enough to reference in reviews, status updates, follow-on planning, and `tasks.json`.

Interpret the tag as:

- `WS` = workstream
- `W2` = wave 2
- `TA` = task A inside that wave

Tasks in the same wave can be worked in parallel.

- `WS-W2-TA`, `WS-W2-TB`, and `WS-W2-TC` may run in parallel
- `WS-W3-*` must wait until wave `WS-W2` is complete and its review gate is satisfied

Generated tracks should explain this rule near the beginning so readers can immediately understand the execution model.

Within a wave:

- tasks in the same wave must be able to proceed in parallel without blocking each other on unfinished work from the same wave
- later waves should exist only when there is a real dependency edge or a meaningful review gate
- if all work is truly parallel and shares the same gate, keep it in one wave rather than inventing fake sequencing

Good task splits:

- separate subdomains of one capability
- separate artifacts with a shared stable interface
- separate test groups against the same target contract

Bad task splits:

- one lane in a wave depends on another unfinished lane from that same wave
- task list is really a sequential checklist disguised as parallel work
- one task is "implement everything" and the others are cleanup
- a task is listed without a concrete behavioral contract

If tasks are not truly parallelizable, split the wave differently or introduce another wave.

### 3. Every Task Must Be Specified, and Wave Review Gates Must Matter

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

If something matters for execution order, dependency readiness, or planning context, express it in wave structure, task dependencies, artifacts, or review gates instead of pretending it is a task acceptance criterion.

When the agent creates or rewrites a task, it must show that task individually to the user. Its proposed acceptance criteria and proposed scenarios are suggestions until the user approves them. The agent must ask for approval of that task, including the suggested acceptance criteria and suggested scenarios, before moving on to the next task or finalizing the plan.

Every wave ends with a review gate.

A review gate is not "docs written" or "code exists."

A review gate must prove that the integrated wave output is ready for the next wave.

Default per-task verification style is:

- the task contract is explicit
- the listed acceptance criteria are covered by scenarios
- the relevant tests or checks are identified
- the verification named for that task surface is green

Default review gate style is:

- contract or spec updated where needed
- tests exist for the wave capability
- verification is green
- outputs are stable enough for downstream waves

### 4. TDD Changes What Verification and Review Gates Mean

Because the project intends to use TDD broadly, per-task verification and review gates should explicitly reflect evidence, not progress theater.

Good evidence:

- failing tests existed and now pass
- task-scoped verification is green
- wave verification suite is green
- invalid cases are covered
- downstream modules can now rely on the wave contract

Weak evidence:

- implementation started
- main happy path exists
- most tests pass
- manual confidence only
- previous tracks or earlier tasks were "checked"

### 5. Workstream Plan, Not Internal Scratch Notes

Keep tracks readable and strategic.

Include:

- wave goals
- ordered waves
- per-task behavioral specs
- per-task acceptance criteria
- per-task scenarios
- per-task verification
- artifacts
- review gates
- module or package alignment
- out-of-scope boundaries

Do not include:

- minute implementation steps
- commit-by-commit instructions
- private execution notes
- agent-only workflow details
- checkboxes for execution tracking; `tasks.json` is the execution checklist

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

Waves use the form `WS-W<number>`.
Tasks use the form `WS-W<number>-T<lane>`.

- tasks in the same wave can be worked in parallel
- later waves start only after all tasks in earlier waves are complete and the earlier wave's review gate is satisfied

## Wave 1: <Name>

### Goal

<What this wave enables.>

### Tasks

#### `WS-W1-TA` <task name>

Behavioral spec:
<What behavior or contract this task must establish.>

Acceptance criteria:
- <criterion>
- <criterion>
- <criterion>

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

#### `WS-W1-TB` <task name>

...

### Review Gate

- <integrated condition proving this wave is complete and safe for the next wave>
```

## Handoff To `tasks.json`

When this skill finishes, each wave id and task id must be carried into `tasks.json` unchanged.
`plan.md` is authoritative for planning intent.
`tasks.json` is the durable execution ledger derived from the approved plan.
