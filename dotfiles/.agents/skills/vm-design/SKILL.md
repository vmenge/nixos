---
name: vm-design
description: Use only when the user explicitly invokes vm-design for a software or technical design document.
---

# VM Design

Create a technical design through dialogue. Keep one review-ready document as the durable record.

## Hard boundaries

- Write only to the selected design document. Read other files as evidence, but do not edit them.
- Do not write code, configuration, tests, implementation plans, task breakdowns, issues, glossaries, or ADRs.
- Do not stage or commit the design document.
- Ask one question at a time and wait for the answer.

## Establish the document

1. Read repository instructions and inspect relevant code, docs, decisions, and recent changes.
2. Locate an existing design document before creating one.
3. Follow repository convention when one exists. Otherwise use `.vm/<topic>/design.md`, unless the user requests another path.
4. If `.vm/` is not ignored by Git, warn the user before creating the document. Never edit `.gitignore`.
5. Keep the selected document canonical and free of interview transcript.

## Build the design

Resolve dependent decisions in order. For each unresolved branch:

1. Answer through repository exploration when possible.
2. Surface conflicts between the user's account, code, terminology, and existing decisions.
3. Ask one precise question with a recommended answer and rationale.
4. Present alternatives only for a meaningful fork. Use a concrete example to clarify the trade-off.
5. Probe happy paths, edge cases, failures, boundaries, and operational consequences.
6. Immediately integrate each confirmed decision. Replace superseded conclusions instead of appending history.

Allow the user to defer a decision. Record the open question, why it matters, and what must resolve it.

## Write for engineering review

Assume reviewers missed the conversation. Make the document self-contained and easy to challenge.

- Open with a short review guide: the problem, recommended approach, main risks or uncertainties, and requested review focus.
- Use an adaptive structure with this minimum backbone: Purpose, Goals and non-goals, Constraints, Proposed design, Concrete scenarios, Alternatives and trade-offs, and Open questions.
- Add architecture, data flow, failures, testing, migration, rollout, or operations only when relevant.
- Include alternatives in the final document only when they explain a meaningful trade-off or the user requests them.
- Distinguish facts, assumptions, decisions, and unresolved questions.
- Cite evidence selectively with stable file paths, symbols, or document references. Avoid line numbers.
- Define project terms. Use active voice, concrete language, focused paragraphs, and necessary words.
- Avoid unexplained jargon, inflated language, and detail that does not help a reviewer evaluate the design.
- Add a diagram only when it explains architecture, flow, state, or ownership better than prose. Follow repository convention and explain it nearby.

## Completion gate

Continue until all conditions hold:

- Every material branch is resolved or explicitly deferred.
- The design agrees with repository evidence, or intentional differences are documented.
- Happy paths, edge cases, and failures are covered.
- Meaningful trade-offs are recorded.
- The user has reviewed and approved the complete document.

Do not declare the design complete before this gate passes.
