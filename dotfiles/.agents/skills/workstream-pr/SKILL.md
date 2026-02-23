---
name: workstream pr
description: "Generate a PR description for a workstream. Triggers on: workstream pr, ws pr, make a workstream pr, workstream pull request."
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash(git diff *), Bash(git log *), Bash(git branch *), Bash(ls *)
---

# Workstream PR

Generate a concise pull request description for a workstream's branch.

## Steps

1. Ask the user which workstream they want a PR for (or accept it as an argument).
2. Find the workstream at `.workstreams/<name>/`.
3. Read `.workstreams/<name>/PLAN.md` for high-level context.
4. Read `.workstreams/<name>/tasks.json` to understand what was done.
5. Diff the workstream branch against the main branch (`git diff main...<branch>` and `git log main...<branch> --oneline`).
6. Only ask clarifying questions if something is genuinely ambiguous. Otherwise just write the PR.
7. Output the PR description in markdown.

## PR Format

```markdown
# Context

One or two sentences explaining **why** this change exists.

# New

- Bullet points of new things introduced (omit section if none)

# Changed

- Bullet points of things changed (omit section if none)

# Fixed

- Bullet points of bugs fixed (omit section if none)
```

You may add extra sections if the changes warrant it (e.g. "# Breaking Changes", "# Notes", "# Migration").

## Writing Guidelines

- Be concise. Brevity over verbosity.
- Focus on what matters to a reviewer.
- Don't list every file touched; describe the logical changes.
- Omit empty sections entirely.
- Don't wrap the output in a code block; output raw markdown.
- Avoid using so many code types name directly. People can ready the pr itself. Be slightly more high level.
