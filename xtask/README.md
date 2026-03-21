# xtask

This crate contains the local `x` command runner.

## Commands

- `x agents-md`
  Creates `AGENTS.override.md` in the current directory as a symlink to a file under `~/.agents/`.

- `x build`
  Builds the `xtask` crate in debug mode.

- `x ws`
  Runs workstream commands.

## `x ws` Overview

`x ws` is the runtime for repository workstreams stored under:

```
.workstreams/<name>/
```

The command does not own the full workstream methodology by itself. The full model lives in two layers:

1. The workstream skill docs define the policy and human workflow.
2. `x ws` implements the execution runtime and loop orchestration.

That split is intentional.

## Workstream Files

`x ws` works primarily with these files:

- `tasks.json`
  Durable execution ledger. This is the source of truth for task completion state.

- `activity.json`
  High-signal execution history written by agents as work progresses.

- `run.json`
  Live execution state, lock file, and progress snapshot for the current `x ws exec` run.

- `done`
  Runtime-owned marker written only after a workstream finishes a clean execute/review cycle.

Other workstream files such as `design.md`, `plan.md`, and `review.md` matter to the overall workflow, but `x ws` does not interpret them directly. They are consumed by the agents that `x ws exec` launches.

## Subcommands

### `x ws ls`

Lists workstreams under `.workstreams/` and prints:

- name
- run status
- completed task count
- running duration
- last update age
- latest activity summary

Status is derived from `run.json` plus whether the recorded PID is still alive:

- `done`
- `idle`
- `running:execute`
- `running:review`
- `stale-lock`
- `error`

`done` means all tasks are complete, there is no live run lock, and the runtime has written the `done` marker. A fully complete workstream without that marker still shows as `idle`.

### `x ws info <name>`

Shows the full activity log for a workstream and a summary of:

- task progress
- run status
- pid
- phase
- iteration
- duration
- last update age

### `x ws rm <name>`

Deletes `.workstreams/<name>/`, but only if there is no live run lock.

If `run.json` says the workstream is still running and the recorded PID is alive, removal is refused.

### `x ws exec <name> --agent <codex|claude> [--stall-limit <n>]`

Starts the workstream execution loop.

This is the most important command in the module.

`--stall-limit` controls how many repeated no-progress passes the Ralph loop will tolerate before aborting. The default is `10`.

Starting a new execution clears any stale `done` marker before the loop begins. Successful final review writes a fresh `done` marker before the command exits.

### `x ws queue run <name>... --agent <codex|claude> [--stall-limit <n>]`

Runs multiple workstreams serially in the order they are listed.

Queue mode is a thin wrapper over the existing single-workstream Ralph loop:

- each queued workstream gets the full `x ws exec` loop
- the same `--agent` and `--stall-limit` behavior applies
- queue execution stops on the first failed or stalled workstream
- failure output reports how many workstreams completed, which one failed, and which ones completed before the failure

## `x ws exec` Is a Ralph Loop

Do not read the alternating execute and review prompts as a contradiction of the workstream skill docs.

They are the automation of those docs.

`x ws exec` is designed as a Ralph loop:

- the repository state is durable
- workstream state is durable
- each agent invocation is fresh
- the loop re-prompts the agent with a narrow phase-specific instruction
- the loop continues until completion or stall detection

In practice, the phases are:

1. `workstream-execute <name>`
2. inspect the updated `tasks.json`
3. if tasks remain, run execute again
4. if all tasks are done, switch to `workstream-review <name>`
5. inspect the updated `tasks.json` again
6. if review re-opens work, go back to execute
7. if review leaves everything done, finish successfully

This is not a mismatch with the skill docs. It is the runtime that automates the execute/review cycle they describe.

## Policy vs Runtime

The easiest way to understand `x ws` is:

- the skills define policy
- `x ws` defines runtime

The skill layer carries rules such as:

- wave discipline
- TDD expectations
- how `design.md`, `plan.md`, `tasks.json`, and `review.md` relate
- when to commit
- how review gates work

The Rust code carries:

- CLI parsing
- loading and validating workstreams
- live-run locking through `run.json`
- runner invocation
- phase transitions
- stall detection
- cleanup after success or failure

`x ws` therefore assumes that the prompted agent will follow the workstream policy. It does not try to re-encode every rule from the prose docs into the CLI.

## Stall Detection

The loop aborts when it sees repeated non-progress:

- ten consecutive execute passes with no task progress
- or ten execute/review cycles with no net progress

This prevents livelock when an agent keeps spinning without changing the durable task state. `--stall-limit` overrides the default for both checks.

## Implementation Map

Main files:

- `xtask/src/cmd/ws.rs`
  CLI entrypoints for `ls`, `info`, `rm`, `exec`, and `queue run`

- `xtask/src/workstream/fs.rs`
  Loading and writing `tasks.json`, `activity.json`, `run.json`, and the `done` marker

- `xtask/src/workstream/model.rs`
  Data model for workstream files

- `xtask/src/workstream/agent.rs`
  Agent runner command construction and sandbox path calculation

- `xtask/src/workstream/loop.rs`
  The Ralph loop implementation for alternating execute and review passes

- `xtask/tests/ws.rs`
  Integration tests that define the expected behavior of the runtime
