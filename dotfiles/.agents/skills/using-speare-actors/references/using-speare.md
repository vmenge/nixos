# Using `speare`

Primary reference material: the `speare` book, especially the chapters under `book/src/`.

## Quick Start

The basic shape is:

1. define an actor struct for mutable state
2. define a `Msg` enum for its protocol
3. implement `Actor`
4. spawn from a `Node`
5. interact through a `Handle`
6. call `shutdown().await` when the process must drain cleanly

```rust
use speare::*;

struct Counter {
    count: u32,
}

enum CounterMsg {
    Add(u32),
    Get(Request<(), u32>),
}

impl Actor for Counter {
    type Props = u32;
    type Msg = CounterMsg;
    type Err = ();

    async fn init(ctx: &mut Ctx<Self>) -> Result<Self, Self::Err> {
        Ok(Self {
            count: *ctx.props(),
        })
    }

    async fn handle(&mut self, msg: Self::Msg, _ctx: &mut Ctx<Self>) -> Result<(), Self::Err> {
        match msg {
            CounterMsg::Add(n) => self.count += n,
            CounterMsg::Get(req) => req.reply(self.count),
        }
        Ok(())
    }
}

#[tokio::main]
async fn main() {
    let mut node = Node::default();
    let counter = node.actor::<Counter>(0).spawn();

    counter.send(CounterMsg::Add(2));
    let value = counter.reqw(CounterMsg::Get, ()).await.unwrap();
    assert_eq!(value, 2);

    node.shutdown().await;
}
```

## Main Types

| Type | Role |
| --- | --- |
| `Node` | Root supervisor for top-level actors |
| `Actor` | Trait implemented by each actor |
| `Ctx<Self>` | Runtime context for props, children, registry, pub/sub, tasks, and sources |
| `Handle<Msg>` | Cloneable external reference for messaging and lifecycle control |
| `Request<Req, Res>` | Request/reply message wrapper |
| `Supervision` | Child failure policy |
| `SourceSet` | Timers and streams feeding the mailbox |

## Lifecycle

- `init(ctx)` builds the actor and is called again on restart.
- `handle(&mut self, msg, ctx)` processes one message at a time.
- `exit(this, reason, ctx)` is the cleanup hook.
- `Props` survive restart.
- A dropped `Node` sends stop signals but does not await full shutdown. Use `node.shutdown().await` when ordering matters.

## Communication

Use the smallest primitive that matches the intent:

- `handle.send(msg)` for fire-and-forget commands
- `handle.req(payload).await` when the caller needs a reply
- `handle.req_timeout(payload, duration).await` when waiting forever is unsafe
- `send_in` for delayed self-messages or deferred work

Prefer message enums that model intent cleanly. If the enum derives `From`, `send` and `req` call sites stay compact.
If it does not, use `reqw` / `reqw_timeout` for request/reply wrappers.

## Supervision

Per-child supervision is configured at spawn time:

- `Supervision::Stop` for unrecoverable or explicit-failure actors
- `Supervision::Resume` when the state is still safe and only the message failed
- `Supervision::Restart` when a fresh actor instance is the right recovery model

Use limits and backoff deliberately. Unlimited immediate restart is easy to configure and easy to regret.

`watch()` is how a parent turns permanent child failure into a parent message. That is the key building block for BEAM-style supervisor behavior that is broader than simple one-for-one restart.

## Background Work

`ctx.task(async { ... })` runs concurrent work and feeds its `Ok(msg)` result back into the actor.

Use it for finite async work that should report back into the same mailbox.

Important caveat: task completions survive actor restart. If a restart invalidates in-flight work, add your own generation token or state check so stale completions are ignored.

## Sources

Use `sources()` plus `SourceSet` when the actor should continuously react to timers or streams:

- periodic ticks
- external stream events
- long-lived async feeds

Earlier sources have higher polling priority. Put the highest-throughput source last if starvation is possible.

## Registry and Pub/Sub

Use the registry for discovery when the actor relationship is dynamic:

- `spawn_registered()` for a singleton by actor type
- `spawn_named(name)` for named instances
- `get_handle_for::<Actor>()` or `get_handle::<Msg>(name)` for lookup

Use pub/sub for broadcast-style events:

- `ctx.subscribe::<Event>("topic")`
- `ctx.publish("topic", event)`

Topics are type-locked by first use. Keep event payloads cloneable and stable.

## Practical Heuristics

- Put long-lived mutable state on the actor, not in shared locks.
- Keep `handle()` small; move CPU-heavy work elsewhere.
- Use child actors when failure isolation matters.
- Use `ctx.clear_mailbox()` during restart only when discarding queued work is the correct recovery behavior.
