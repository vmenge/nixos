---
name: software architecture and domain modeling
description: use this whenever user asks you to architecure software or model real world problems into software. also to be used when planning software related tasks and workstreams.
---
# Architecting Software with Functional Core + Imperative Shell, Vertical Slices, and Functional Domain Modeling

## Goal
Build systems that:
- keep business rules deterministic and easy to reason about
- push I/O and nondeterminism to the boundaries
- organize code by features that change together
- model the domain with explicit types, states, and workflows
- scale from modular monolith to services without rewriting

This skill combines:
- **Functional Core, Imperative Shell (FC/IS)**: core business logic is pure; all side effects live at the edges (shell). (Scott Wlaschin, “Moving IO to the Edges of Your App: Functional Core, Imperative Shell” — user-provided notes)
- **Vertical Slice Architecture (VSA)**: organize code around requests/use-cases (“slices”), not horizontal layers. (https://www.jimmybogard.com/vertical-slice-architecture/ — 2018-04-19)
- **DDD + functional domain modeling**: bounded contexts, ubiquitous language, workflows as pipelines, invariants via types, persistence at the edges.

FC/IS is the top-level constraint: if anything below conflicts, FC/IS wins.

---

## 1) Foundational constraints (non-negotiable)

### 1.1 Functional Core, Imperative Shell (primary rule)
**Core**:
- pure functions: `Output = f(Input)`
- deterministic: same input => same output
- no side effects, no hidden dependencies
- no exceptions as control flow
- no async/await inside domain logic (treat as I/O boundary concern)

**Shell**:
- does all I/O (DB, filesystem, network, clock, randomness, env)
- gathers data, validates it, calls core, interprets the core’s decisions, performs side effects
- handles retries, timeouts, transactions, orchestration, observability

### 1.2 The golden rule: avoid I/O in domain logic
Domain/business logic must not:
- read/write DB
- call HTTP
- read/write filesystem
- access time/random/environment directly
- publish to a message bus directly

An application must do I/O to be useful; it just must not do it in the core.

### 1.3 Validation at the edge
Validation belongs at the *outermost* edge of the shell. Once data enters the core, it is trusted and shaped to domain types. Core code should not be defensive (no null checks, no “just in case” parsing).

---

## 2) Architectural primitives

### 2.1 Slice (use-case / request)
A **slice** is everything needed to fulfill one request end-to-end (boundary → validation → workflow → persistence/events → response).

VSA rule: couple along the axis of change—features change across layers, so group per feature. (https://www.jimmybogard.com/vertical-slice-architecture/ — 2018-04-19)

### 2.2 Bounded context (autonomous subsystem)
A **bounded context** is an autonomous subsystem with its own model/dialect and (ideally) its own data ownership.

- contexts communicate via events → commands → workflows → events
- context boundaries are for autonomy, not “cleanliness”

### 2.3 Domain model (types + rules)
The domain model captures business meaning using the ubiquitous language (avoid technical fake nouns like `OrderManager`).

### 2.4 Workflow as a pipeline
Workflows are pipelines:
- validated input → pure decisions/transforms → emitted decisions/events/results
- steps have explicit inputs/outputs; dependencies are explicit and not ambient

---

## 3) Organizing a codebase

### 3.1 Top-level shape (context → slice)
Organize by **bounded context**, then by **slice**. Each slice is built as FC/IS: a pure core module plus an imperative shell module.

**Rules**
- Avoid reintroducing layer buckets (`Services/`, `Repositories/`, etc.) across the whole app.
- “Domain/” and “Core/” code should be mostly pure (no I/O).
- “Infrastructure/” is for adapters; it must not contain business policy.

### 3.2 Slice folder rules (VSA + FC/IS)
A slice should be “copyable” and contain:
- boundary code (HTTP/message/CLI) — shell
- input validation and parsing — shell edge
- pure workflow and domain types — core
- decision interpretation and side effects — shell

Avoid forced hop chains (controller → service → repository) unless they reduce complexity in that slice. (https://www.jimmybogard.com/vertical-slice-architecture/ — 2018-04-19)

### 3.3 If you “must do I/O in the middle”
Split the workflow into smaller core steps:
- do I/O in shell → feed data into core → get decision → do I/O → feed next core step → …

Don’t contaminate the core. Make the “I/O seams” explicit.

---

## 4) Designing the domain (functional DDD)

### 4.1 Start from events and workflows, not tables
Model around:
- **events** (past tense facts)
- **commands** (intentful requests)
- **workflows** (business goal pipelines)

This supports shared understanding and maps directly to core pipelines.

### 4.2 Use types to encode meaning and invariants
Prefer domain-specific types over primitives:
- constrained strings, identifiers, money, quantities, units
- explicit optionality and errors (no “sentinel values”)

Goal: make invalid states unrepresentable or hard to construct.

### 4.3 Model lifecycle with explicit states
Model state transitions explicitly (e.g., Unvalidated → Validated → Priced → Placed) so transitions are clear and type-driven.

---

## 5) Building workflows as pure decision engines

### 5.1 Prefer “decisions” over side effects
Core should return *decisions* (what should happen), not perform actions.

Examples of decisions:
- `PersistUpdatedCustomer(updatedCustomer)`
- `SendVerificationEmail(emailAddress)`
- `PublishOrderPlaced(orderPlacedEvent)`
- `DoNothing`

The shell interprets decisions and performs effects.

### 5.2 Good vs bad function shapes
Bad:
- `void DoSomething()` (hidden side effects, no test surface)
- `void DoSomething(Input x)` (black hole: effects you can’t assert)
- `Output DoSomething()` (magic generator: hidden nondeterminism)

Good:
- `Output DoSomething(Input x)` (pure and testable)

### 5.3 Dependency management strategy (preferred order)
1. **Dependency rejection** (FC/IS): core rejects I/O entirely; returns decisions.
2. **Parameterization**: pass required functions/data explicitly to keep steps small.
3. **DI**: OK in shell; avoid “interface creep”.
4. **Dependency interpretation** (instruction DSL + interpreter): powerful, often overkill.
5. **Dependency retention**: acceptable for throwaway scripts, not core apps.

---

## 6) Communication between bounded contexts (contracts)

### 6.1 Default integration shape: events → commands
Upstream emits event; downstream translates to command; runs its workflow; emits new events.

### 6.2 Messages/contracts are not domain types
Cross-context messages should be serialization-friendly contracts (versionable, explicit).

They do **not** need to be called “DTOs” or have `Dto` appended. Name them in the ubiquitous language of the boundary:
- `OrderPlaced`, `ShipOrder`, `PaymentAuthorized`
- not `OrderPlacedDto`

### 6.3 Boundary as a trust boundary
- input gate validates/parses untrusted messages into domain types
- output gate prevents leaking private info and reduces coupling

---

## 7) Persistence and infrastructure (always shell)

### 7.1 Push persistence to edges
Persistence is I/O, therefore shell. Core code should not “save” or “load”; it should request persistence via decisions, or accept already-loaded data.

### 7.2 CQS / CQRS aligned with FC/IS
- **Commands**: core returns decisions/events; shell executes effects.
- **Queries**: still keep domain transformations pure; shell does the data fetch and mapping.

### 7.3 Contexts own their data
Other contexts must not read your database directly; use APIs/events or replicated read models.

### 7.4 ORM guidance (principle, not a tool rule)
Avoid patterns that encourage hidden writes in domain methods. If an ORM pushes you toward “save in the middle”, fence it into the shell.
As a whole, try to avoid ORMs.

---

## 8) Testing strategy aligned to FC/IS + VSA

### 8.1 Unit tests: domain + complicated logic only
Use unit tests primarily for:
- domain invariants and state transitions
- pure workflow decision logic that’s hard to cover cleanly end-to-end
- tricky transformations, calculations, and edge cases

**Hard rule:** unit tests must be **pure** — no interaction with external systems:
- no network calls
- no database
- no filesystem
- no clock/time without an injected abstraction
- no environment variables unless injected
- no message bus

If a test touches I/O, it’s not a unit test.

### 8.2 Slice tests: black-box, compiled application tests
Prefer testing slices by running the **fully compiled application** as a **black box**:
- start the app (real HTTP server / real message consumer / real CLI)
- hit the public boundary (HTTP, messaging, CLI)
- assert on externally observable outcomes (responses, persisted state, published events, side effects)

Test workflows, not classes. A “unit” is business value, not a class.

### 8.3 Integration tests belong to the shell
To test the shell, test the whole pipeline end-to-end (I/O → core → I/O) against real dependencies (often via containers). Don’t unit test whether “a database insert works”.

### 8.4 Contract tests across contexts
Because messages/events are the coupling point, add contract/versioning tests around:
- schemas and backward compatibility
- mapping (message ↔ domain) correctness

---

## 9) Review checklists (for agents)

### 9.1 FC/IS checklist (first)
- [ ] Core contains no I/O, no async, no exceptions for control flow
- [ ] All nondeterminism is injected or handled in shell
- [ ] Core returns explicit decisions/events/results
- [ ] Validation happens before entering core

### 9.2 Slice checklist
- [ ] One request/use-case, named by intent (verb + noun)
- [ ] Command vs Query is clear
- [ ] Slice contains boundary + core + shell interpretation
- [ ] Slice tested primarily via black-box compiled-app tests

### 9.3 Context boundary checklist
- [ ] Context owns its data store; no direct DB reads by others
- [ ] Inter-context communication uses contract messages/events, not domain types
- [ ] Input/output gates exist (validation + info-hiding)
