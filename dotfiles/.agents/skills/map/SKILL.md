---
name: map
description: Give a bird's-eye overview of proposed changes, showing which files need to change and why. Use when the user requests a change map or a file-level overview of planned work, including after $plan.
---

# Map

Make the scope of proposed work easy to understand at a glance. Explain what changes, where, and why without showing diffs or turning the overview into an implementation plan.

## Boundaries

- Treat this as a read-only task. Do not create, modify, delete, or rename project files, change external state, install dependencies, commit, or deploy.
- Return the map in the conversation. Do not implement the proposed changes automatically; wait for an explicit request to proceed.
- Preserve any active thinking or planning restrictions in follow-up discussion.

## Ground the map

- Use the current plan when available, including output from $plan. Otherwise, use the user's request and inspect the relevant code. A prior plan is not required.
- Check the relevant files and callers so the map reflects the repository. Include necessary tests, fixtures, documentation, configuration, and exports alongside implementation files.
- Stay within the requested scope. If inspection reveals a missing necessary change, identify it as an addition to the plan and explain why.
- Distinguish verified existing paths, proposed new paths, and unresolved locations. Do not invent precise paths when the location is unknown.
- If neither the conversation nor the request identifies the work to map, ask what change the user wants to understand.

## Output

Start with one sentence stating the intended outcome. Then use a compact table:

| File | Intended change | Why |
|---|---|---|
| Concrete path | Brief description of what changes | Purpose or behavior this enables |

- Use one row per affected file, with clickable paths for existing local files. Mark additions, deletions, and renames explicitly; show both paths for a rename.
- Describe each change at the level of the file's responsibility. Keep cells short and use plain language.
- Group long maps by purpose, retaining the individual file paths. Do not hide necessary scope just to shorten the table.
- After the table, briefly state the resulting behavior and any meaningful risks or unresolved decisions. Omit empty sections and repeated information.
- Leave out diffs, code snippets, line-by-line explanations, execution steps, and unrelated files. The map should complement a plan rather than repeat it.
