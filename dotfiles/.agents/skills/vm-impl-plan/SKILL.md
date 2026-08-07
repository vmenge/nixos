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

- Use **vertical slices rather than horizontal layers**. Plan each business use case as an isolated, one-directional pipeline instead of splitting work across generic API, service, and database layers.
- Default each external flow—such as an HTTP request, D-Bus handler, command, or job—to one implementation file. Split it only for a concrete framework constraint or a stable concept used elsewhere.
- Enforce **locality of behavior**. Keep behavior, types, helpers, and tests in the slice or package that owns them. Do not move slice-only code into generic `services`, `parsers`, or `utils` buckets.
- Do not share code without a specific current need and more than one consumer. Name those consumers in the plan. Prefer small local duplication over premature coupling.
- Use a **functional core inside an imperative shell**. Gather database, API, clock, and other I/O inputs at the beginning; pass plain values through pure deterministic business logic; perform writes and publication at the end. Keep all effects visible at orchestration callsites.
- Parse external representations into explicit input or domain types. Limit parsing errors to syntax, shape, and decoding; put business rules and validation in the pure domain decision.
- Use **algebraic domain modeling**: compose explicit records (“AND” types) and choices (“OR” types) so the code mirrors the business language and invalid states are difficult to represent. Avoid inheritance, factories, proxies, primitive flags or strings, and generic containers when a domain type can state the meaning directly.
- Do not plan getters or setters mechanically. Add accessors or controlled mutation only when needed to protect an invariant or necessary abstraction boundary.
- Do not introduce traits or interfaces solely for testing. Prefer configurable fixtures and tests against real dependencies. Add an abstraction only for a concrete production need, such as multiple real implementations, and explain that need.
- Explain deviations required by the language, framework, or existing architecture.

## Plan documentation and APIs

For every touched hand-written source or test file, propose a native file/module doc comment stating responsibility and boundary. Exempt generated or unsupported files.

Write doc comments in plain, human-readable language. Prefer familiar words and direct explanations. Use specialized domain terms only when readers need them to understand or use the API; do not copy jargon or grandiose wording merely because it appears in source material or sounds impressive.

Show exact bodyless declarations for changed public types and functions. Use native doc comments covering meaning, invariants, lifecycle, inputs, outputs, errors, and side effects. Only reference unchanged APIs.

## Plan tests and execution

**REQUIRED SUB-SKILL:** Use vm-test-fixture whenever the slice adds or changes reusable test fixtures.

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
