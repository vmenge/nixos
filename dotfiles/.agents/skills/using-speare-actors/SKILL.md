---
name: using-speare-actors
description: Use when designing or implementing actor systems with the Rust speare crate, especially when translating Elixir or BEAM supervision, messaging, and actor-boundary patterns into Rust.
---

# Using Speare Actors

## Overview

`speare` is a thin actor runtime over tokio tasks and flume channels. Treat it as a way to put mutable state behind mailboxes, supervise failure boundaries, and keep concurrency explicit.

Read the references selectively:

- `references/using-speare.md` for crate usage, APIs, and quick examples
- `references/beam-patterns.md` for actor design, supervision shapes, patterns, and anti-patterns

## When to Use

- the user mentions `speare`
- the codebase uses `speare::Actor`, `Node`, `Handle`, `Ctx`, or `Request`
- the task involves actor design, supervision, request/reply, pub/sub, or registry usage
- the user wants Elixir or BEAM-style guidance adapted to Rust

Do not use this skill when:

- the task is about a different actor runtime
- the work is pure compute with no actor boundaries or lifecycle concerns
- the user only needs generic Rust concurrency advice

## Core Mental Model

- A `Node` is the root supervisor for top-level actors.
- One actor is one tokio task plus one mailbox.
- `Props` are immutable spawn-time inputs. Actor state lives on `self`.
- `handle()` is sequential. Keep it short and non-blocking.
- `Handle<Msg>` is the public boundary for send, request, stop, and restart.
- Parents define child supervision. `one_for_one` is built in; broader group strategies are composed with `watch()`, `stop_children()`, and `restart_children()`.

## Design Workflow

1. Choose the actor boundary around owned mutable state, an external resource, or a serialized workflow.
2. Define a message protocol before writing code: commands, queries, replies, events, and failure signals.
3. Pick the communication primitive intentionally:
   - `send` for fire-and-forget commands
   - `req` for request/reply
   - pub/sub for fanout events
   - registry for singleton or named discovery, not as a default dependency injector
4. Design supervision explicitly: decide which actors restart alone, which failures escalate, and where backoff is needed.
5. Plan restart semantics: `init` rebuilds state, props survive restarts, and background task completions from a previous incarnation can still arrive later.

## Good Defaults

- Prefer one actor per clear ownership boundary, not per tiny function.
- Keep business rules in pure helpers or domain modules; let actors coordinate I/O, sequencing, and lifecycle.
- Use immutable `Props` for durable configuration and reconstruct state in `init`.
- Use `watch()` to turn child failure into a parent decision.
- Call `node.shutdown().await` when clean shutdown matters.

## Anti-Patterns

- Wrapping `Arc<Mutex<_>>` inside actors and calling it actor-based design.
- Long-running or blocking work inside `handle()`.
- Giant actors with unrelated responsibilities and huge message enums.
- Using restart for expected validation errors or ordinary control flow.
- Assuming restart clears everything; `ctx.task(...)` work may still deliver stale results after restart.
- Using the registry as a global service locator for every dependency.
