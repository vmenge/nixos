---
name: think
description: Explore a question through reasoning, clarifying questions, and research without changing project files. Activate only when the user explicitly invokes $think.
---

# Think

Treat the accompanying request as an investigation and discussion, even when it uses action words such as implement, fix, or create.

## Boundaries

- Do not create, modify, delete, or rename files outside a dedicated temporary directory used for this task.
- Use inspection, research, and temporary experiments to ground the answer. Commands may write scratch files, caches, and build outputs within that temporary directory; ensure their writes stay there, including when working with copies of project files. If writes cannot be confined there, skip the command and explain the limitation.
- Do not change external state, send messages to others, install dependencies, commit, or deploy. Apply these restrictions to any delegated work too.
- Keep these restrictions in follow-up discussion until the user explicitly asks to leave thinking and proceed with changes. Agreement with a conclusion is not permission to implement it.

## Explore and clarify

- Read the available context before asking questions it already answers. Identify the user's objective, constraints, and ambiguities.
- Resolve material ambiguities in intent, scope, terminology, constraints, and preferences before settling on a recommendation. Ask focused questions rather than silently choosing an interpretation.
- When choices make a question easier to answer, offer two or three concrete options with a brief tradeoff for each, while allowing a different answer. Use open-ended questions when preset options would steer or constrain the user.
- Ask a small batch of the most consequential questions at a time. Follow up when an answer still leaves a material ambiguity.
- Continue independent investigation while awaiting answers. Keep conclusions that depend on unanswered questions provisional; do not silently choose an interpretation. If the user asks you to make assumptions, state them.
- Actively use web searches when external evidence can inform the answer, especially for current facts, unfamiliar topics, available alternatives, and tradeoffs. Combine this research with relevant project files and connected sources. Skip browsing when the question is fully answered by the conversation or local files.
- Prefer authoritative sources and cite evidence for consequential claims. Distinguish facts from inferences, and disclose unavailable or conflicting evidence.
- Examine plausible alternatives, tradeoffs, and counterexamples. Revise conclusions as evidence and user answers arrive.
- Respond with concise conclusions and their supporting rationale, plus any unresolved questions or uncertainty. Use the format that fits the discussion; an implementation plan is not required.
- Stop when the question is answered or the next useful step needs user input. Do not invent questions when the request is already clear, and do not begin implementation automatically.
