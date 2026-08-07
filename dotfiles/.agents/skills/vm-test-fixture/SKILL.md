---
name: vm-test-fixture
description: Use when designing or revising reusable test fixtures, especially fixtures that start applications, manage dependencies, expose public test boundaries, or clean up asynchronous resources.
---

# VM Test Fixtures

## Core principle

Build a fixture as the lifecycle owner of an isolated test environment, not as a bag of unrelated helpers. Make realistic tests easy to arrange, safe to run in parallel, and unable to leak resources.

Start the real production entrypoint and let tests interact through the same public boundary as a real client.

## Separate prepared and running state

Use two explicit lifecycle types:

- `Fixture` owns configuration, prepared dependencies, seed state, temporary paths, and optional dependency overrides. It is not running yet.
- `RunningFixture` owns the live application, clients, background tasks, containers, sockets, logs, and every resource required for cleanup.

Accept required configuration and dependencies when creating the fixture. Use a builder when tests need readable optional overrides. Provide useful canonical defaults without hiding behavior that matters to the test.

```rust
let fixture = Fixture::builder()
    .platform(TestPlatform::Local)
    .config(test_config)
    .build()
    .await?;

fixture.seed(seed_data).await?;

let running = fixture.start().await?;
let response = running.client().request(input).await?;

assert_eq!(response.status(), ExpectedStatus);
running.stop().await?;
```

Keep preparation and startup separate. `start()` should consume or exclusively borrow the prepared fixture so the same environment cannot be started twice accidentally.

## Run the real system

- Boot the production application entrypoint rather than duplicating startup in the fixture.
- Prefer real local dependencies: temporary filesystems, databases, sockets, message buses, metrics receivers, and containers when stronger fidelity is needed.
- Replace only dependencies that cannot reasonably run locally, such as unavailable hardware or external production services. Do not add production traits or interfaces solely to enable mocks.
- Expose narrow test-facing capabilities such as public clients, proxies, metrics, logs, seed operations, and observable persisted state. Do not expose application internals for the test's action.

## Keep every fixture hermetic

Give each fixture unique temporary directories, database state, ports, socket paths, bus names, and cancellation tokens. Default to one independently owned fixture per test.

Compose smaller resource owners inside one top-level fixture when needed. Share immutable build artifacts or container images when useful, but do not share live mutable infrastructure unless isolation and reset behavior are explicit and verified.

## Wait for readiness

Return from `start()` only after an observable readiness condition succeeds. Poll a health endpoint, acquire the expected bus name, connect a client, observe a socket, or await an explicit startup signal.

Use a bounded timeout and include logs or status in the failure. Never use an arbitrary sleep as proof that startup completed.

## Own all cleanup

Register ownership immediately after each resource is created so partial setup and partial startup can be cleaned safely.

Make cleanup idempotent and release resources in reverse creation order:

1. Signal cancellation and stop accepting work.
2. Join supervised background tasks.
3. Close clients, buses, sockets, and database connections.
4. Stop processes and containers.
5. Remove temporary state.

Provide explicit asynchronous `stop()` for deterministic cleanup and a destructor, scope guard, or framework finalizer as a fallback. Cleanup must still run after assertion failures, panics, startup errors, and incomplete startup. Tests must not need handwritten cleanup.

## Keep fixture code honest

- Keep fixture and seed helpers in test code.
- Return contextual setup, readiness, and teardown errors.
- Avoid detached tasks, global mutable fixtures, fixed infrastructure addresses, production credentials, and test-order dependencies.
- Keep scenario-specific behavior in the test. Promote setup into the fixture only when several tests need the same lifecycle operation.
