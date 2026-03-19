---
name: workstream-about
description: Use when working with repository workstreams stored under `.workstreams/` and you need to understand their structure, files, and lifecycle.
---

# Workstream About

## Overview

Use this skill to understand the workstream model used in a repository.

A workstream is a unit of work stored under:

- `<repo>/.workstreams/<workstream-name>/`

Each workstream has two core files:

- `.workstreams/<workstream-name>/research.md`
- `.workstreams/<workstream-name>/track.md`

Treat the workstream folder as the durable planning surface for that unit of work.

## What the Files Mean

`research.md` captures discovery work:

- what is being built
- user intent
- constraints
- relevant architecture notes
- research findings that will help define the track

`track.md` captures the execution structure:

- phases
- task waves
- behavioral specs
- acceptance criteria
- scenarios
- verification
- completion gates

## Workstream Lifecycle

Workstreams usually move through this sequence:

1. understand the workstream concept
2. research the workstream and write findings into `research.md`
3. build or refine the execution track in `track.md`
4. execute the track phase by phase

The research file informs the track.

The track is the source of truth for execution.

## When to Use

Use this skill when:

- the user refers to a workstream
- you need to create or update `.workstreams/<name>/research.md`
- you need to create or update `.workstreams/<name>/track.md`
- you need to execute a workstream from its track
- the structure or meaning of workstreams is unclear

Do not use this skill when:

- the work is unrelated to the repository's `.workstreams/` system
- you already have the full workstream model in context and do not need to reload it

## Rules

- Keep all workstream-specific context inside the matching workstream folder.
- Do not treat ad hoc notes outside `.workstreams/<name>/` as the source of truth over `research.md` or `track.md`.
- If another workstream skill applies, use this skill first or alongside it when the workstream model needs clarification.
