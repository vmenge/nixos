---
name: diff
description: Preview the complete proposed changes for a request or plan as a diff in the chat, without changing project files. Use when the user asks to see the exact edits before applying them, including after $plan or $map.
---

# Diff

Show the complete proposed patch for the requested work in the conversation. Ground it in the actual files and cover the whole request, rather than showing illustrative edits.

## Boundaries

- Do not create, modify, delete, or rename files outside a dedicated temporary directory for this task. Leave project files, the repository's Git index, and Git metadata untouched. Do not create a Git worktree, since it modifies repository metadata.
- Do not change external state, send messages to others, install dependencies, commit, or deploy. Apply these restrictions to any delegated work too.
- Confine scratch files, caches, build outputs, and test writes to the temporary directory. Copies must not contain writable symlinks back into the project. Skip operations whose writes cannot be confined and explain the limitation.
- Stop after the preview. Keep these restrictions in follow-up discussion until the user explicitly requests implementation; agreement with the proposal is not permission to apply it.

## Prepare the patch

- Use the accompanying request and any current plan or map to identify the work. A prior plan is not required. Ask for scope only when the conversation does not establish it.
- Inspect affected files and callers. Include every necessary implementation, test, fixture, configuration, documentation, and export change within that scope.
- Use the current working tree, including relevant untracked files and uncommitted edits, as the baseline. Show only the additional changes proposed for this request; preserve unrelated user work.
- Resolve decisions that prevent a concrete patch before claiming completeness. Label assumptions and any necessary additions to an existing plan.
- When useful, copy the relevant files into separate baseline and proposed directories inside the temporary directory, edit only the proposed copies, and generate a unified diff. A temporary Git repository is also acceptable, provided all its metadata stays there and no commits are created.
- Ensure the comparison includes new and deleted files, renames, and file mode changes. Ordinary Git diffs omit untracked files; account for them explicitly. Diff commands can return a nonzero status when differences exist; distinguish that result from an actual failure.
- Check that the patch matches the inspected baseline and covers the complete request. Run appropriate checks on temporary copies only when their writes and side effects satisfy the boundaries above. Report what passed, failed, or could not be checked.

## Output

- Start with a short statement of the intended outcome.
- Show the full unified patch in fenced `diff` blocks, using project-relative paths rather than temporary-directory paths.
- Include all changed hunks and the complete content of added or deleted text files. Do not substitute placeholders, ellipses, summaries, or instructions such as "repeat elsewhere" for required edits. Unchanged lines may be omitted using normal unified-diff hunks.
- Explicitly list binary assets or other changes that cannot be represented usefully as text diffs, including their paths and exact proposed operations. State any limits on reproducing those changes from the chat preview.
- If the complete patch exceeds the response limit, split it into numbered parts and clearly state what remains. Never label a partial preview complete or silently truncate it.
- Finish with concise verification results and any unresolved decisions or meaningful risks. Distinguish an untested proposal from a verified patch, and state that project files were not changed.
