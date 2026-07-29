---
name: vm-impl-plan
description: Use only when the user explicitly invokes vm-impl-plan for one vertical slice.
---

# VM Implementation Plan

Plan one vertical slice at file/module level. Never modify implementation files, tests, configuration, migrations, or source documents.

## Resolve the slice

Prefer a named slice. Otherwise read `.vm/<topic>/slices.md`; select the only unambiguous slice or ask. Read the topic design, repository instructions, code, architecture, and tests. Use adjacent slices only for contracts. Do not expand scope.

## Review the module structure first

Before writing, present every changed artifact's path or module name, change type, responsibility, boundary, changed public declarations, and tests.

Show a focused file tree when useful. Trace important **execution and data flows** from public entrypoint through validation, decisions, explicit side effects, and observable result. Name data entering and leaving each step.

Revise until the user approves. Do not write the plan first.

## Apply architectural defaults

- Preserve the vertical slice; never plan layers as sequential phases.
- Enforce **locality of behavior**: keep a slice's behavior, transformations, tests, and support together. Do not move slice-only code into generic `services`, `parsers`, or `utils` buckets.
- Call persistence, network, clock, and publication adapters directly from orchestration. A documented service call still hides its nested I/O. Prefer pure nested functions returning values or explicit decisions.
- Share code only for a stable concept or behavior needed by multiple consumers. Prefer small local duplication over premature coupling.
- Explain deviations required by the language, framework, or existing architecture.

## Plan documentation and APIs

For every touched hand-written source or test file, propose a native file/module doc comment stating responsibility and boundary. Exempt generated or unsupported files.

Show exact bodyless declarations for changed public types and functions. Use native doc comments covering meaning, invariants, lifecycle, inputs, outputs, errors, and side effects. Only reference unchanged APIs.

## Plan tests and execution

For each concrete test, state its behavior, level, public boundary, setup, action, observable assertions, and covered acceptance criteria.

Default to outside-in tests through the real boundary. Add unit tests only for pure logic needing isolated edge-case coverage.

Organize execution by behavioral increments, not files:

1. Add one failing behavioral test.
2. Make the smallest coordinated changes across relevant files.
3. Add required documentation and public declarations.
4. Refactor while tests stay green.
5. Run focused verification.

## Write and approve the plan

Write `.vm/<topic>/<slice-id>-<kebab-case-title>.impl.md` unless requested otherwise. Include the slice scope, approved module map, useful file tree, architecture decisions, flows, documented public declarations, behavioral increments, concrete tests, acceptance coverage, verification, and out-of-scope boundaries.

When reconciling, preserve approved decisions and notes, update stale details, add missing tests, and remove obsolete steps. Reapprove material module changes before rewriting.

Files under `.vm/` are gitignored local planning artifacts. Write only the `.impl.md`; never stage or commit it. Present the complete plan and revise it until the user approves it.
