---
name: feature
description: Walk one feature through the whole planning chain — grill → specify → clarify → plan (+impact) → tasks → analyze — ending at "waiting for human APPROVED". A convenience orchestrator; invoking each skill manually is always equally valid.
argument-hint: Describe the feature idea (any language)
---

Guide the user through the planning phase for ONE feature, in this order. This
is a wrapper for convenience — every step below can also be invoked manually,
and a partially-done chain is fine: detect existing artifacts (spec.md, plan.md,
tasks.md in the current feature dir) and CONTINUE from where things stand
instead of restarting.

Prerequisite: the repo must have `.specify/` (else point to /night-shift:init).

1. **Grill** — invoke the `grilling` skill (note: `grill-with-docs` is a
   user-invoke-only stub that expands to `grilling` + `domain-modeling`, so an
   agent must call the engines directly). Also invoke `domain-modeling` when
   the feature involves domain/data-model design (skip it for mechanical work
   like typing fixes or refactors). No grilling skill installed → ask sharp
   questions yourself in the same style. Interview until the decision tree for
   this feature is resolved; offer a recommended answer with each question.
2. **Specify** — invoke `speckit-specify` with the distilled description. The
   spec must include: acceptance criteria (testable, labeled AC-1..N), edge
   cases + error handling, spec-routing (which product-spec sections were read),
   and the night-shift frontmatter (`status: DRAFT`, `risk`, `depends_on`).
3. **Clarify** — invoke `speckit-clarify` (≤5 targeted questions). Encode the
   answers back into the spec. Set `status: SPEC_READY`.
4. **Plan** — invoke `speckit-plan`. The plan MUST declare the change surface
   (files/areas allowed to change — the gate enforces it) and an Impact section:
   who consumes what this feature touches (use graphify/code search if
   available), and which consumers' tests must run.
5. **Tasks** — invoke `speckit-tasks`: dependency-ordered, test-first, each task
   small enough for one autonomous iteration.
6. **Analyze** — invoke `speckit-analyze`; resolve every inconsistency it finds.
7. **Stop and hand over.** Print exactly what remains for the human:
   review the artifacts, then set `status: APPROVED` + `approved_by:` in
   `specs/<n>/spec.md` and commit. Do NOT set APPROVED yourself under any
   circumstances — that line is the human's signature.
