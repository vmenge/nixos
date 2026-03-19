---
name: workstream-research
description: Use when starting or refining a workstream and you need to understand what is being built, research the problem, and capture planning context in `.workstreams/<name>/research.md`.
---

# Workstream Research

## Overview

Use this skill when the agent needs to be inquisitive about a workstream and understand what is actually being built before planning the track.

The goal is to ask the user what is being worked on, research the surrounding problem, and write useful planning context into `.workstreams/<workstream-name>/research.md`.

Use `workstream-about` when needed to understand the workstream model itself.

## When to Use

Use this skill when:

- a workstream exists but its goal is still fuzzy
- the user wants to start a new workstream
- `research.md` is missing, stale, or too shallow to support planning
- you need to gather constraints before building `track.md`

Do not use this skill when:

- the workstream already has sufficient research and the user wants execution
- the main task is building or revising `track.md`

## Required Behavior

Be inquisitive.

Do not jump straight to planning.

Ask what is being built, why it matters, what constraints exist, and what success looks like.

Identify the likely risks and blast radius of the workstream yourself, explain concisely how you reached those conclusions, and confirm them with the user before treating them as settled.

Research any relevant code, architecture, docs, or external constraints that help define the workstream.

Then write down the information that will help plan `track.md`.

## Research Output

Write findings to:

- `.workstreams/<workstream-name>/research.md`

Capture:

- problem statement
- user goal
- constraints
- affected systems, modules, or packages
- open questions
- architectural notes
- risks
- blast radius
- assumptions
- rough implementation directions if they help later planning

Do not turn `research.md` into an execution checklist. Its purpose is to make track-building easier and better informed.

## Suggested Flow

1. Identify the target workstream folder.
2. Use `workstream-about` if the workstream structure needs clarification.
3. Ask the user focused questions about what is being built.
4. Read only the most relevant local files and docs.
5. Identify the likely risks and blast radius of the workstream.
6. Explain those conclusions concisely and confirm them with the user.
7. Summarize the findings into `research.md`.
8. Highlight open questions or decisions that still affect `track.md`.

## Quality Bar

Good research makes the future track easier to write.

Bad research is vague, generic, or missing the constraints that will shape the work.

Good research should make the likely risks and blast radius clear, with concise reasoning and explicit user confirmation before later planning depends on them.

Good research should also help clarify the plausible implementation approaches and the main tradeoffs between them.

Before finishing, make sure `research.md` gives enough context to break the work into meaningful phases and tasks later.
