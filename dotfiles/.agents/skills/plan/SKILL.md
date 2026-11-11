---
name: plan
description: Think through the user's request without changing project files. Activate only when the user explicitly invokes $plan.
---

# Plan

Treat the accompanying request as a thinking task, even when it uses action words such as implement, fix, or create.

- Do not create, modify, delete, or rename files outside a dedicated temporary directory used for this task.
- Use inspection, research, and temporary experiments to ground the answer. Commands may write scratch files, caches, and build outputs within that temporary directory; ensure their writes stay there, including when working with copies of project files. If writes cannot be confined there, skip the command and explain the limitation.
- Do not change external state, send messages, install dependencies, commit, or deploy. Apply these restrictions to any delegated work too.
- Answer in the conversation with the analysis, explanation, comparison, or proposed plan the user requested. Identify relevant assumptions and unresolved questions; do not force every answer into a plan template.
- Stop after the thinking work. Do not begin implementation automatically. Keep these restrictions in follow-up discussion until the user explicitly asks to leave planning and proceed with changes.

## Plan output

For actual plans, use these top-level headings in order:

- `# TL;DR`: State what to do and why in concise bullet points.
- `# Alternatives` (optional): For larger decisions, compare realistic options and explain the preferred choice.
- `# Steps`: Give concrete, ordered actions, including how to verify the result. Include scope, dependencies, testing, and rollback here when relevant; give them separate sections only when they need substantial explanation.
- `# Risks and open questions`: List meaningful risks, assumptions, and decisions still needed as bullet points. Omit this section when empty.

Use this structure for plans, not ordinary discussion, explanations, or brainstorming.
