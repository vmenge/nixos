---
name: software-testing
description: Use when adding or revising automated tests in this project, especially when choosing test scope, fixtures, or application startup boundaries.
---

# Testing

## Philosophy

Prefer **integration tests** over unit tests. The default test should exercise the application the way a real user or client would: through its public interface, with the real configuration and dependencies wired together.

Unit tests are acceptable for pure logic such as parsers, transformers, and algorithms. If a behavior depends on routing, middleware, serialization, startup wiring, filesystem layout, or database integration, it should usually be an integration test.

For languages that require a `main` function, keep `main` minimal. Move startup and configuration into an importable entrypoint so tests can boot the real application without duplicating startup logic.

## Test from the outside

The most valuable tests avoid reaching into application internals. Instead, choose the **external tool** that exercises the application the way a real user would:

- **Backend services**: use an HTTP/gRPC client to hit the real API.
- **Frontend/web apps**: use **Playwright** or similar browser automation tools to interact with the UI as a user would — clicking buttons, filling forms, reading rendered output.
- **Mobile apps**: use **emulators** or **MCP servers** that expose device interaction to your test runner.
- **CLI tools**: invoke the compiled binary as a subprocess and assert on stdout, stderr, and exit codes.

The pattern is always the same: start the real application through its real startup path, interact with it through the same interface a user would, and assert on observable behavior. The specific tool changes by platform; the principle does not.

## Make the application configurable

Integration testing becomes much easier when the application is **configurable at startup**: ports, database URLs, storage paths, feature flags. If the app can be pointed at a test database, a temp directory, or a random port via arguments or a config file, each test can spin up an isolated instance without conflicts.

Avoid hardcoding infrastructure details. An application that accepts `--port 0` or `--db-url sqlite::memory:` is trivially testable. One that assumes port 8080 and a production database is not.

## Run the real startup path

Tests should execute the **real startup path**, not a mock, fake service layer, or hand-rolled harness. Depending on the platform, that may mean spawning the compiled binary or calling a shared entrypoint function from the test harness. What matters is that the test exercises the same configuration, middleware, and integrations that production uses.

This catches an entire class of bugs that unit tests miss: configuration wiring, middleware ordering, serialization mismatches, startup failures, and dependency injection mistakes.

```
test runner ──HTTP/browser/emulator──▶ application entrypoint
                                           ├── real database
                                           ├── real middleware
                                           └── real configuration
```

## Fixtures manage infrastructure

A **fixture** encapsulates setup and teardown for a test. It prepares the test environment and exposes a clean interface for the test to use. Starting the application is a separate step.

```rust
pub struct AppFixture {
    port: u16,
    db_url: String,
    temp_dir: TempDir,
    database: DatabaseHandle,
}

impl AppFixture {
    pub async fn new(port: u16) -> Result<Self, String> {
        // 1. Start dependencies
        // 2. Create isolated filesystem state
        // 3. Collect addresses and config the app will need
        Ok(Self {
            port,
            db_url,
            temp_dir,
            database,
        })
    }

    pub async fn run(&self) -> Result<AppHandle, String> {
        // 1. Start the application with this fixture's config
        // 2. Wait for readiness
        start_app(self.port, &self.db_url, self.temp_dir.path()).await
    }

    pub fn base_url(&self) -> String {
        format!("http://localhost:{port}", port = self.port)
    }
}
```

### Why fixtures

- **Encapsulation**: tests do not need to know how the environment is prepared. They call `AppFixture::new()` to set it up, then `run()` to start the app.
- **Isolation**: each test gets its own fixture, its own port, its own state. Tests never share mutable infrastructure.
- **Automatic cleanup**: fixtures clean up on drop. Even if the test panics, resources are freed.
- **Composability**: complex scenarios compose multiple fixtures. Need a database and a message queue? Combine two fixtures.

### Fixture anatomy

A well-structured fixture does four things:

1. **Prepare** — build or otherwise prepare the application artifact and dependencies.
2. **Start** — prepare dependencies in `new()`, then start the application explicitly with `run()`.
3. **Expose** — provide accessors for the test to interact with the running app (`base_url()`, `db_connection()`, `logs()`).
4. **Teardown** — clean up everything when dropped. This should be automatic (via `Drop` or equivalent), not manual.

## Preparing test state

Tests often need preconditions: a database with seed data, files on disk, a git repository, or a running dependency. **Prepare this state inside the test environment**, whether that environment is the host or a container.

Prefer the host when you can isolate state with temp directories, ephemeral ports, and fake dependencies in a parallel-safe way. Use containers when you need stronger environmental fidelity or process isolation.

For reusable setup, extract helper functions:

```rust
async fn seed_database(fixture: &AppFixture) {
    fixture.exec(&["psql", "-c", "INSERT INTO users (name) VALUES ('alice')"]).await;
}
```

These helpers live in the test module, not in production code. They are specific to testing and shouldn't leak into the main codebase.

## Test structure

Each test follows the same pattern:

```rust
#[tokio::test]
async fn test_feature_x() {
    // 1. Arrange — create fixture, prepare state
    let port = pick_unused_port();
    let fixture = AppFixture::new(port).await.expect("setup failed");
    seed_database(&fixture).await;
    let _app = fixture.run().await.expect("app start failed");

    // 2. Act — interact with the application through its public interface
    let client = reqwest::Client::new();
    let response = client
        .post(format!("{}/api/resource", fixture.base_url()))
        .json(&json!({ "name": "test" }))
        .send()
        .await
        .expect("request failed");

    // 3. Assert — verify the response
    assert_eq!(response.status().as_u16(), 201);
    let body: serde_json::Value = response.json().await.expect("parse failed");
    assert_eq!(body["name"], "test");
}
```

## Rules

1. **One fixture per test.** No shared state between tests. Each test is independent and can run in parallel.
2. **Test through the public interface.** If the app is an HTTP server, use HTTP. If it's a web app, use Playwright. If it's a CLI, invoke the binary. Never reach into internals.
3. **Cleanup is automatic.** Fixtures handle teardown via drop/destructors. Tests should never need a `finally` or manual cleanup step.
4. **Failures should be obvious.** Assert on specific status codes and response fields, not just "it didn't crash." Use descriptive assertion messages.
5. **Keep tests fast.** If a test takes longer than 10 seconds, it probably does too much. Split it or optimize the fixture.
6. **Helpers belong in tests.** Reusable setup functions live next to the tests, not in production code.
