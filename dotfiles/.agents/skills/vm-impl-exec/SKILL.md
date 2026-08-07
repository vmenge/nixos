---
name: vm-impl-exec
description: Use only when the user explicitly invokes vm-impl-exec for an approved implementation-plan artifact.
---

# VM Implementation Execute

Execute an approved `.vm/<topic>/*.impl.md` through strict TDD and two review gates.

**TDD is mandatory.** Load `test-driven-development` when available; the rules below remain binding without it.

**REQUIRED SUB-SKILL:** Use vm-test-fixture whenever the plan adds or changes reusable test fixtures.

## Resolve the plan

Use a supplied `.impl.md`; otherwise select the only relevant plan under `.vm/<topic>/` or ask. Read it with the source slice, design, repository instructions, code, and tests. Treat the gitignored plan as read-only. Stop when repository drift invalidates planned modules, public APIs, or test strategy; never silently replan.

## Test and fixture gate

Before production code:

1. Implement planned tests and fixtures only.
2. Give every test explicit `// Arrange`, `// Act`, and `// Assert` sections using native comment syntax.
3. Build reusable fixtures that accept dependencies and configuration at creation.
4. Give fixtures `start()` and `stop()` lifecycle operations. `start()` must boot the production entrypoint. `stop()` must clean up after success, failure, or partial startup.
5. Allow per-test or shared fixtures. Shared fixtures need deliberate state reset or isolation between tests.
6. Exercise the real public boundary.
7. Run each new test. Confirm it fails for missing behavior, not broken setup.
8. Present the test/fixture diff and RED evidence. Wait for explicit approval.

Review tests and fixtures in one batch unless size requires smaller batches. Production code requires approval for its batch.

After approval, tests and fixtures are frozen. Any change requires pausing, showing the exact diff and reason, and obtaining explicit approval. Never weaken, delete, rename, reinterpret, or mechanically “fix” an approved test without approval.

## Implement autonomously with TDD

For each approved failing behavior, write minimum production code, verify GREEN, then refactor while all approved tests remain green. Continue unsupervised unless blocked by plan drift or a test/fixture change. Preserve the plan's vertical boundary, locality of behavior, documentation, and public API. Write doc comments in plain, human-readable language. Prefer familiar words and direct explanations. Use specialized domain terms only when readers need them to understand or use the API; do not copy jargon or grandiose wording merely because it appears in source material or sounds impressive.

## Preserve slice-local design

- Keep each business use case as an isolated, one-directional vertical slice. Default each external flow—such as an HTTP request, D-Bus handler, command, or job—to one implementation file. Split it only for a concrete framework constraint or a stable concept used elsewhere.
- Keep behavior, types, helpers, and tests in the slice or package that owns them. Do not promote code to shared modules without a specific current need and more than one consumer. Prefer small local duplication.
- Parse external representations into explicit input or domain types. Report syntax, shape, and decoding errors while parsing; keep business rules and validation in the domain decision.
- Model the domain with explicit records (“AND” types) and choices (“OR” types) so the code mirrors the domain and invalid states are difficult to represent. Avoid inheritance, factories, proxies, primitive flags or strings, and generic containers when a domain type can state the meaning directly.
- Do not add getters or setters mechanically. Expose data according to the language's conventions; add accessors or controlled mutation only when needed to protect an invariant or necessary abstraction boundary.
- Do not introduce traits or interfaces solely for testing. Prefer configurable fixtures and tests against real dependencies. Add an abstraction only for a concrete production need, such as multiple real implementations, and explain that need.

## Resolve branches early

Settle decisions before the effectful flow. Guards are one form:

```text
if invalid(input):
    return error
continue(validated_input)
```

Expression-based branches are equally valid:

```text
mode = if cached then Reuse(existing) else Create(new_value)
execute(mode)
```

Branch into a clear value or decision, then continue linearly. Do not scatter the same condition across later effects.

## Keep a functional core inside an imperative shell

Keep database queries, API calls, clock reads, and other I/O at the edges of the flow. Parse and gather required inputs at the beginning, pass plain values through a pure deterministic decision, then perform writes and publication at the end. Keep the center testable without mocks:

```text
request = parse(input)
state = repository.load(request.id)
decision = decide(request, state)
repository.save(decision.change)
publisher.publish(decision.event)
```

Do not interleave business decisions with hidden I/O. When an external protocol genuinely requires multiple I/O rounds, keep every call visible at the orchestration callsite, place a pure decision between rounds, and explain why the extra round is necessary.

## Final review gate

Run focused and broader tests plus applicable formatting, lint, type, and build checks. Review the diff against the plan. Present changed files, RED–GREEN evidence, verification results, and deviations. Ask the user to approve the implementation; apply requested corrections through the same gates.

Never commit unless explicitly asked.
