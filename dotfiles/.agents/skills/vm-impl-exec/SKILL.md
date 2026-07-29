---
name: vm-impl-exec
description: Use only when the user explicitly invokes vm-impl-exec for an approved implementation-plan artifact.
---

# VM Implementation Execute

Execute an approved `.vm/<topic>/*.impl.md` through strict TDD and two review gates.

**TDD is mandatory.** Load `test-driven-development` when available; the rules below remain binding without it.

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

For each approved failing behavior, write minimum production code, verify GREEN, then refactor while all approved tests remain green. Continue unsupervised unless blocked by plan drift or a test/fixture change. Preserve the plan's vertical boundary, locality of behavior, documentation, and public API.

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

## Separate branching from side effects

Prefer a pure decision followed by interpretation when this has no significant performance downside:

```text
decision = decide(input, state)
match decision:
    Reject(error) -> return error
    Accept(change) -> persist(change)
```

Combine branching with effects only to avoid a relevant cost such as an extra query, allocation, or traversal. Explain the concrete cost.

## Keep side effects at callsites

Make I/O visible in orchestration:

```text
change = calculate_change(input)
repository.save(change)
publisher.publish(change.event)
```

Avoid helpers such as `process(input)` that secretly persist or publish.

## Final review gate

Run focused and broader tests plus applicable formatting, lint, type, and build checks. Review the diff against the plan. Present changed files, RED–GREEN evidence, verification results, and deviations. Ask the user to approve the implementation; apply requested corrections through the same gates.

Never commit unless explicitly asked.
