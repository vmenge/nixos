---
name: testing
description: Testing approach for this project. Important for when implementing tests.
---

# Testing

## Philosophy

Prefer **integration tests** over unit tests. The goal is to test the application the same way a real user or client would interact with it — through its public interface, with the real binary running.

Unit tests are acceptable for pure logic (parsers, transformers, algorithms), but the default choice should always be an integration test that compiles and runs the actual application.

## Test from the outside

The most valuable tests never touch application internals. Instead, figure out which **external tools** can exercise your application the way a real user would:

- **Backend services**: use an HTTP/gRPC client to hit the real API.
- **Frontend/web apps**: use **Playwright** or similar browser automation tools to interact with the UI as a user would — clicking buttons, filling forms, reading rendered output.
- **Mobile apps**: use **emulators** or **MCP servers** that expose device interaction to your test runner.
- **CLI tools**: invoke the compiled binary as a subprocess and assert on stdout, stderr, and exit codes.

The pattern is always the same: start the real application, interact with it through the same interface a user would, and assert on observable behavior. The specific tool changes depending on the platform, but the principle doesn't.

## Make the application configurable

Integration testing becomes much easier when the application is **configurable at startup**: ports, database URLs, storage paths, feature flags. If the app can be pointed at a test database, a temp directory, or a random port via arguments or a config file, each test can spin up an isolated instance without conflicts.

Avoid hardcoding infrastructure details. An application that accepts `--port 0` or `--db-url sqlite::memory:` is trivially testable. One that assumes port 8080 and a production database is not.

## Compile the real application

Tests should build and run the **real binary**, not a mock or in-process test harness. This catches an entire class of bugs that unit tests miss: configuration wiring, middleware ordering, serialization mismatches, startup failures, and dependency injection mistakes.

The test binary is a separate process from the test runner. The test runner starts it, talks to it over its public interface, and tears it down when done.

```
test runner ──HTTP/browser/emulator──▶ real application binary
                                           ├── real database
                                           ├── real middleware
                                           └── real configuration
```

## Fixtures manage infrastructure

A **fixture** is a struct that encapsulates all the setup and teardown logic for a test. It builds the binary, starts any required infrastructure (containers, databases, temp directories), and exposes a clean interface for the test to use.

```rust
pub struct AppFixture {
    port: u16,
    container: Container,
}

impl AppFixture {
    pub async fn new(port: u16) -> Result<Self, String> {
        // 1. Compile the application
        // 2. Start infrastructure (database, container, etc.)
        // 3. Deploy the binary into the environment
        // 4. Start the application
        // 5. Wait for readiness
        Ok(Self { port, container })
    }

    pub fn base_url(&self) -> String {
        format!("http://localhost:{}", self.port)
    }
}
```

### Why fixtures

- **Encapsulation**: tests don't know or care how the app is started. They just call `Fixture::new()` and get a running instance.
- **Isolation**: each test gets its own fixture, its own port, its own state. Tests never share mutable infrastructure.
- **Automatic cleanup**: fixtures clean up on drop. Even if the test panics, resources are freed.
- **Composability**: complex scenarios compose multiple fixtures. Need a database and a message queue? Combine two fixtures.

### Fixture anatomy

A well-structured fixture does four things:

1. **Build** — compile or prepare the application artifact.
2. **Start** — launch the application and any dependencies (databases, containers).
3. **Expose** — provide accessors for the test to interact with the running app (`base_url()`, `db_connection()`, `logs()`).
4. **Teardown** — clean up everything when dropped. This should be automatic (via `Drop` or equivalent), not manual.

## Preparing test state

Tests often need preconditions: a database with seed data, files on disk, a git repository, a running dependency. **Prepare this state inside the test environment**, not on the host.

If the application runs in a container, exec commands inside that container. If it runs locally, use temp directories that are cleaned up automatically.

```rust
// Prepare state where the application can see it
fixture.exec(&["mkdir", "-p", "/data/test-input"]).await;
fixture.exec(&["sh", "-c", "echo '{\"key\": 1}' > /data/test-input/seed.json"]).await;
```

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
