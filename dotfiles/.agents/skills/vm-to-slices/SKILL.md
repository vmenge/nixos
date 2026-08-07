---
name: vm-to-slices
description: Use only when the user explicitly invokes vm-to-slices for a technical source artifact.
---

# VM to Slices

Turn a design, plan, spec, issue, or conversation into thin vertical slices. Keep the result local, concrete, and ready for engineering use.

## Hard boundaries

- Write only the selected `slices.md`. Do not edit the source or implement anything.
- Do not publish issues, create an implementation plan, or classify slices as AFK or HITL.
- Do not stage or commit the output.
- Synthesize directly. Ask only when the source, topic, or a boundary-changing decision is ambiguous.

## Select the source and output

Use this source precedence:

1. An artifact named by the user.
2. The active topic's design under `.vm/<topic>/`.
3. The current conversation.

If equally plausible sources exist, ask which one to use. Read the full source, repository instructions, and relevant code, glossary, and decisions before slicing.

Reuse `<topic>` when the source lives under `.vm/<topic>/`. Otherwise derive a short kebab-case topic from the subject; ask if ambiguous. Write `.vm/<topic>/slices.md` unless the user requests another path.

If the file exists, reconcile it with the current source. Preserve valid user refinements and decisions, update stale slices, add missing coverage, and remove obsolete slices. Never append a competing breakdown or silently discard user-authored intent.

## Define vertical for this source

Begin with a short **Slicing model** that names the boundaries relevant to the source. Derive them from the capability, not from a generic stack. A web workflow may cross interaction, domain rules, persistence, integration, and verification; a library may cross public API, precedence rules, parsing, errors, and consumer-visible behavior.

## Create the slices

Each slice must:

- Deliver the smallest coherent capability that crosses every relevant boundary.
- Produce observable behavior that can be verified independently.
- Include necessary groundwork within the first slice that consumes it.
- State only genuine dependencies and appear after its blockers.
- Remain independent of unrelated slices so parallel work stays possible.

Never create horizontal work such as “build the database layer.” When shared groundwork is large or risky, make the first slice a thin walking skeleton that proves one real end-to-end behavior. Do not add a final “integrate everything” slice unless it delivers distinct source behavior.

## Keep slices digestible

Prefer more small, complete slices over fewer comprehensive ones. Each slice must be small enough to understand, review, implement, and verify as one focused change without internal implementation phases.

Default to one trigger-to-observable-result flow and one primary behavior per slice. A slice may cross several architectural boundaries, but only as far as required to deliver that behavior.

Split a slice again when:

- Its title or outcome joins independently useful capabilities with “and.”
- It contains multiple entrypoints, triggers, flows, or observable outcomes.
- Its acceptance criteria mix the primary behavior with distinct variants, retry policies, administrative operations, migrations, or observability work.
- Implementing it would require internal sequencing such as “first,” “then,” and “finally,” or would naturally produce several independently reviewable changes.
- Its acceptance criteria cannot remain a small set—normally two to five criteria describing one coherent behavior.

Split along observable scenarios, decision branches, triggers, operational risks, or independently valuable outcomes. Start with the narrowest real walking skeleton, then add error cases, variants, retries, migrations, and observability in later slices when they provide separate value.

Keep every resulting slice vertical and independently demonstrable. Never reduce size by extracting horizontal setup, infrastructure, or integration slices.

## Write `slices.md`

Use this adaptive structure:

```markdown
# <Topic> slices

## Source
<source artifact and scope>

## Slicing model
<relevant boundaries and why they define a complete slice>

## S1 — <outcome-oriented title>

**Outcome:** <complete behavior or capability>

**Boundaries crossed:** <source-relevant boundaries>

**Acceptance criteria:**
- [ ] <observable criterion>

**Dependencies:** <slice IDs or None>

**Verification:** <independent proof of completion>

**Source coverage:** <requirements, scenarios, or decisions when traceable>

## Coverage map
<source item → slice IDs>
```

Keep prose clear and concrete. Avoid generic user-story phrasing, file-level task lists, implementation steps, and code snippets. Include the coverage map only when the source has stable requirements, scenarios, stories, or decisions.
