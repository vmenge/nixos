---
name: pr
description: Prepare a concise GitHub PR title and description, confirm them with the user, then create the PR using gh. Activate only when the user explicitly invokes $pr.
---

# PR

Create a PR for the current or specified branch after the user approves its destination, title, and description.

## prepare

- Inspect repository instructions, any PR template, Git status, remotes, branch history, and the full diff against the intended base. Ground the proposal in the final changes, not just commit messages or conversation history.
- Resolve the repository, head branch, and base branch from the request and repository context. Ask when ambiguity would change the PR.
- Check for an existing PR for that head and base. If one exists, return its link and ask before updating it; do not create a duplicate.
- Identify uncommitted changes and explain in chat that they are excluded. Do not edit project files, stage changes, or create commits as part of this skill.
- Resolve draft versus ready-for-review status from the user's instructions; ask if unspecified.
- Determine whether the head branch needs pushing. Include the exact remote and branch in the proposed action so confirmation explicitly covers any required push.

## write

- Use lowercase prose and headings in chat, the title, and the description. Preserve acronyms and exact casing in identifiers, crate/package/lib names, paths, commands, and other case-sensitive text.
- Keep the title short and concrete. State the problem addressed or resulting behavior.
- Write for a human reviewer: simple language, short bullets, and only details that help them understand or assess the change.
- Organize the description into useful sections without fixed headings. Group by behavior, crate/package/lib, module, or concern when that helps explain the change. Use the terminology established by the repository and language.
- Explain intent, effects, and meaningful decisions. Do not repeat file inventories, narrate the diff, or recount implementation history.
- Avoid filler, promotional language, excessive jargon, generic claims, repeated summaries, and empty sections. A small PR may need only one short section.
- Do not add routine validation sections or obvious statements such as tests were run. Include a limitation, migration requirement, or operational risk only when it materially affects review or use.
- Follow required repository template fields while keeping answers concise and factual. Do not invent results or add boilerplate sections merely because they are common elsewhere.

## confirm and create

- Show short sections: `## target` for repository, base/head, draft status, and any required push; `## title` for the exact title; `## description` for the exact Markdown body; and `## confirmation` for one approval question covering the stated actions.
- Wait for explicit confirmation before pushing, creating, or updating a PR. If the title, description, destination, status, or scope changes, show the revised proposal and obtain confirmation again.
- Recheck the branch, diff, working-tree state, and existing PRs after confirmation. Stop if they materially differ from the approved proposal.
- Push only the approved branch to the approved remote if needed. Never force-push, merge, amend, or add reviewers, labels, or other metadata unless explicitly requested.
- Use `gh pr create` with explicit repository, base, head, title, and draft status as approved. Write the exact description to a temporary file and pass it with `--body-file` to preserve Markdown and avoid shell interpolation.
- Surface failures clearly. If pushing succeeds but PR creation fails, report both outcomes. Before retrying an ambiguous creation failure, check whether the PR was created to avoid duplicates.
- On success, return the PR link and a brief status. Do not repeat the title, description, or change summary unnecessarily.
