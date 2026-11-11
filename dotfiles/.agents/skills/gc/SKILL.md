---
name: gc
description: Group all non-ignored repository changes into one commit, or N commits with $gc N, after the user confirms the groups and messages. Activate only when the user explicitly invokes $gc.
---

# Git Commit

- `$gc` defaults to one commit. `$gc N` requests exactly N non-empty commits; N must be a positive integer.
- Group all current non-ignored changes by purpose, respect explicit grouping instructions, and order dependencies before their dependents. Prefer whole-file groups; split independent hunks when needed without editing working-tree files.
- If the requested count cannot be achieved sensibly, explain why and ask before proceeding. Do not create empty or filler commits or silently change the count.

1. Inspect the repository status, staged and unstaged diffs, and non-ignored untracked files from the repository root. Include all changes, even those made before this conversation. Do not edit files as part of this workflow. If there are no changes, report that and stop. If there are unresolved conflicts or apparent secrets in the changes, explain the issue and stop before committing.
2. Check the effective Git author and committer identity. Use the user configured in the repository; never override the identity. If it is missing or differs from the configured user, ask the user to resolve it.
3. Propose a concise message for each commit matching the repository's conventions. Show each group's changes and exact message in commit order, then request one confirmation for the entire sequence. Wait for explicit confirmation before changing staging or committing. If a group, order, or message is revised, show the revised proposal and obtain confirmation again.
4. Recheck the changes after confirmation and before each commit. If content or scope differs from the approved remaining groups, stop and obtain confirmation of an updated proposal. Respect ignore rules; never force-add or commit ignored files, including any already staged. If ignored files are staged, report them and stop without altering the user's staging.
5. For one commit, run `git add -A` from the repository root. For multiple commits, stage only the current approved group, including its additions, modifications, and deletions. Reorganize existing staging only as needed for the approved groups, preserving all working-tree changes. Verify the complete staged diff matches the current group before each commit; already staged changes from later groups must not leak into it.
6. Commit each group with its confirmed message. Do not add AI-assistance disclosures, assistant attribution, or assistant co-author trailers. Preserve any unrelated attribution already requested by the user. Honor repository hooks; do not bypass failures or silently retry with a different message or scope. On failure, stop the sequence and report successful commits, the failure, and remaining staged and unstaged changes. Do not automatically undo successful commits. Do not amend or push unless separately requested.
7. Report each successful commit's hash and subject, plus any remaining working-tree changes. Do not claim the sequence succeeded unless all requested commits succeeded.

## Chat output

Use Markdown headers (`##`, with `###` inside per-commit sections) to distinguish sections. Keep each section short: prefer concise bullets, avoid nested lists and long paragraphs, and omit empty sections and routine success checklists.

For one commit, before confirmation, use these sections in order:

- `## Changes`: A fenced `text` block listing only the files included in this proposed commit, one repository-relative path per line, without prose descriptions.
  - Prefix each path with `A` (added), `M` (modified), or `D` (deleted), followed by two spaces.
  - Show renames as `R  old/path → new/path`.
  - Describe the proposed commit's changes relative to its predecessor, not the current staging status. Included untracked files appear as `A`.
  - Append ` (partial)` when only part of a file's pending changes belongs to this commit.
- `## Commit message`: The exact proposed message in a fenced code block.
- `## Confirmation`: Ask, "Commit these changes with this message?"

For one commit, after success, use these sections in order:

- `## Committed`: The commit hash and exact subject.
- `## Working tree`: "Clean" or brief bullets listing remaining changes.
- `## Checks`: Only meaningful hook results or validation limits. Do not imply tests ran merely because the commit succeeded. Omit when unnecessary.

For multiple commits:

- Before confirmation, repeat `## Commit i of N` in commit order, each containing `### Changes` and `### Commit message` using the same concise format above.
- End with one shared `## Confirmation`: "Create these N commits with these messages?" Substitute the requested count for N.
- After execution, repeat `## Commit i of N` for each successful commit with `### Committed` containing its hash and exact subject. Finish with one shared `## Working tree` and optional `## Checks`.

Handle other outcomes without forcing the normal sections:

- If there are no changes, say only "No changes to commit."
- If a blocker prevents proceeding, use `## Blockers` with the issue and required action; do not ask for commit confirmation.
- If an operation fails, use `## Failed` with the reason and current staging and commit state. Include relevant hook or check failures here.
- Do not repeat the changes summary after a successful commit.
