# Designing `speare` Actors with BEAM Patterns

## Translate BEAM Ideas, Do Not Copy OTP Literally

`speare` supports BEAM-style thinking, not full OTP semantics. Use Elixir and Erlang patterns as design guidance:

- isolate state
- communicate by messages
- supervise failure
- structure the system as trees

Then adapt those ideas to Rust's runtime and type system.

## Start with Ownership Boundaries

Create an actor when one of these is true:

- it owns mutable state that must stay serialized
- it wraps an external resource or connection
- it represents a workflow that should process one event at a time
- it needs an independent failure boundary

Do not create an actor for:

- pure calculation
- one tiny helper function
- stateless formatting or mapping logic
- domain rules that are better expressed as pure functions

Good rule: actors coordinate and own state; plain Rust functions implement pure business logic.

## Message Design

Use message enums to model intent, not transport mechanics.

Good message shapes:

- commands: `StartSync`, `StoreItem`, `Stop`
- queries: `Request<Key, Value>`
- events: `OrderPlaced`, `WorkerFailed`

Prefer explicit protocol boundaries:

- commands for "do this"
- queries for "tell me"
- pub/sub events for "this happened"

Avoid a single giant enum that mixes unrelated subdomains just because one actor can technically handle them.

## Supervision Topologies

### One actor, one resource

Use one-for-one restart when a worker owns one isolated resource or state machine.

Examples:

- one connection actor per upstream service
- one queue consumer actor per partition
- one aggregate actor per document or session when contention is the real problem

### Parent with a worker set

Use a manager or supervisor actor when workers must be created, watched, or replaced together.

In `speare`:

- child-level `Supervision::Restart` gives one-for-one behavior
- `watch()` plus `stop_children().await` lets a parent build one-for-all
- `watch()` plus targeted restart or full group rebuild gives rest-for-one style recovery

### Coordinator plus pure domain logic

This is the safest default in Rust:

- actor receives message
- actor loads or holds state
- actor calls pure domain functions
- actor emits decisions, replies, or child messages

This keeps actor code small and keeps business rules testable without the runtime.

## Choosing the Right Communication Primitive

| Need | Prefer |
| --- | --- |
| Fire-and-forget command | `send` |
| Caller needs answer | `req` / `req_timeout` |
| Broadcast event fanout | pub/sub |
| Dynamic lookup for singleton or named worker | registry |
| Internal deferred work | self-message or `send_in` |
| Finite concurrent async work returning to same actor | `ctx.task` |
| Long-lived stream or timer | `sources()` |

Anti-pattern: defaulting to registry lookup for everything. That produces implicit dependencies and weakens topology clarity.

## Good Patterns

- One actor per clear state or failure boundary.
- Child actors for flaky I/O work, supervised by a stable parent.
- Explicit parent messages from `watch()` when escalation matters.
- Idempotent commands when retries or duplicate deliveries are possible.
- Self-messages for bootstrapping rather than stuffing everything into `init`.
- Immutable `Props` for configuration, fresh `self` state on restart.
- Group restart only when the children truly share fate.

## Anti-Patterns

### Actor-per-trivial-function

Do not translate every module or function into an actor. That creates mailbox overhead and opaque control flow with no ownership benefit.

### God actor

One actor that owns many unrelated workflows, caches, network calls, and timers becomes a serialized bottleneck and a debugging trap.

### Shared-state actor shell

An actor that forwards into shared `Arc<Mutex<_>>` state gives you both message complexity and lock complexity.

### Blocking or CPU-heavy `handle`

`handle()` is the mailbox bottleneck. Blocking there stalls every message behind it. Offload finite async work with `ctx.task`, and move CPU-heavy work to dedicated execution paths.

### Restart as business logic

Restart is for recovering corrupted actor state or crashed dependencies, not for ordinary validation failures, not-found cases, or domain rejections.

### Wrong `Resume`

`Supervision::Resume` only makes sense when the state is still trusted after the failed message. If state may be corrupted, restart or stop.

### Forgetting stale task completions

`speare` background tasks survive actor restart. If a restart invalidates old work, stale completions can arrive in the new incarnation. Track generation or compare state before applying results.

### Registry everywhere

Use the registry for dynamic discovery, singletons, or named worker pools. Do not use it as a replacement for all parent-child structure or for every dependency edge.

## BEAM Mapping Cheat Sheet

| BEAM intuition | `speare` equivalent |
| --- | --- |
| Process / GenServer | `Actor` + `Handle` |
| Supervisor root | `Node` or a parent actor |
| `cast` | `send` |
| `call` | `req` |
| one-for-one | child `Supervision::Restart` |
| one-for-all | `watch()` + `stop_children().await` + respawn |
| rest-for-one | `watch()` + selective restart / rebuild ordering |
| Registry | `spawn_registered`, `spawn_named`, `get_handle*` |
| PubSub | `subscribe` / `publish` |

## Design Review Checklist

Before implementing, check:

- Does each actor own something real: state, resource, workflow, or failure boundary?
- Is the message protocol explicit and minimal?
- Is the supervision tree intentional?
- Could any `handle()` path block the mailbox too long?
- What happens to in-flight tasks and queued messages after restart?
- Would a pure function or ordinary module be simpler than another actor?
