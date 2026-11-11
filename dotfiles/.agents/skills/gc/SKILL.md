---
name: gc
description: Stage all non-ignored repository changes and commit them after the user confirms the commit message. Activate only when the user explicitly invokes $gc.
---

# Git Commit

1. Inspect the repository status, staged and unstaged diffs, and non-ignored untracked files from the repository root. Include all changes, even those made before this conversation. Do not edit files as part of this workflow. If there are no changes, report that and stop. If there are unresolved conflicts or apparent secrets in the changes, explain the issue and stop before committing.
2. Check the effective Git author and committer identity. Use the user configured in the repository; never override the identity. If it is missing or differs from the configured user, ask the user to resolve it.
3. Propose a concise commit message matching the repository's conventions and summarizing the actual changes. Show the exact message and a brief summary of what will be included, then ask the user to confirm it. Wait for explicit confirmation before staging or committing. If the user requests a revised message, show the revision and obtain confirmation.
4. Recheck the changes after confirmation. If the content or scope has changed, show the updated summary and message and obtain confirmation again. Otherwise, run `git add -A` from the repository root to include additions, modifications, and deletions. Respect ignore rules; never force-add or commit ignored files, including any already staged. If ignored files are staged, report them and stop without altering the user's staging.
5. Commit with the confirmed message. Do not add AI-assistance disclosures, assistant attribution, or assistant co-author trailers. Preserve any unrelated attribution already requested by the user. Honor repository hooks; do not bypass failures or silently retry with a different message or scope. Do not amend or push unless separately requested.
6. Report the commit hash and subject, plus any remaining working-tree changes. Surface failures clearly; do not claim success unless the commit succeeded.
