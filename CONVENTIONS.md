# Cua Learning Conventions

These are working conventions for how Cua learning should be documented, visualized, and handed off.

They are defaults, not permanent rules.

The latest explicit user decision always overrides this file. If a better pattern emerges, prefer it and update these conventions.

## 1. Durable project roles

### `WORKFLOW.md`
Defines how the investigation is run:
- reasoning loop
- evidence discipline
- when to inspect source
- when to test
- when to stop
- how to move toward a contribution

### `CONVENTIONS.md`
Defines the current preferred way to:
- document learning
- structure investigation notes
- generate diagrams
- generate Codex/checkpoint prompts
- preserve resumability

### `CURRENT.md`
Defines where the investigation is now:
- current phase
- current subsystem/thread
- what is understood
- what is still unknown
- exact current engineering question
- next bounded investigation
- stopping boundary
- pointers to detailed notes

### Subsystem / investigation READMEs
Hold the durable technical understanding, evidence, experiments, design questions, and investigation history.

Do not duplicate the full knowledge base into `CURRENT.md`.

## 2. Primary documentation goal

Optimize for:

> Can I return months later, or start a fresh ChatGPT/Codex session, and quickly reconstruct what I understood, what I tested, where it broke, what remains unknown, and what should happen next?

Do not over-compress important investigation state just to make a README short.

Do not add detail that does not help reasoning, reproduction, architecture understanding, or future contribution work.

## 3. Subsystem README

A subsystem README should be a durable overview, not merely a directory index.

Prefer to preserve:
- subsystem goal
- approved architecture image when one exists
- canonical execution path
- component responsibilities
- final mental model understood so far
- important experiments performed
- observed failure/degradation boundaries
- GREEN vs YELLOW/unknown areas
- current issue-driven thread
- links to deeper investigation notes
- intentionally deferred areas

Detailed experiment logs should live in their own investigation/failure folders, but the subsystem README should still contain enough context to recover the subsystem model quickly.

## 4. Investigation / failure README

For a focused investigation, preserve enough detail to reconstruct the engineering reasoning.

Useful sections may include:
- investigation goal
- healthy baseline
- prediction
- break introduced
- exact observed result
- exact failure boundary
- what survived
- what disappeared
- why the behavior occurred
- what the experiment proves
- what it does not prove
- current design model
- unknowns
- design questions
- minimum next source trace
- related issues / PRs
- next targeted reproduction
- candidate contribution directions
- stopping boundary

This is a flexible structure, not a mandatory template.

Use only the sections that make the investigation clearer.

## 5. Evidence discipline

Keep these distinctions explicit when they matter:

**OBSERVED**
Runtime evidence from an experiment.

**SOURCE-VERIFIED**
Behavior established from current source/design history.

**INFERENCE**
A reasoned conclusion that still depends on assumptions.

**UNKNOWN / NOT YET TESTED**
Something that requires more source evidence, design clarification, or runtime reproduction.

Do not promote a hypothesis into a bug.

Do not describe an untested scenario as though it was reproduced.

## 6. Investigation progression

Default direction:

understand current design
→ inspect minimum relevant source/design history
→ establish the invariant
→ ask the user to predict
→ run one targeted reproduction
→ compare expected vs actual
→ inspect related issues / PRs
→ classify the gap
→ discuss architecture alternatives
→ choose a contribution candidate
→ implement/test only after the problem is established

This is a guide, not a rigid sequence. Adapt it when the investigation requires a different order.

Avoid broad repository reconnaissance once a bounded engineering question exists.

## 7. Diagrams

Use previously approved diagrams as references for clarity and investigation storytelling.

A currently useful pattern is:

normal path
→ break introduced
→ exact failure location
→ observed outcome
→ fallback/recovery
→ remaining unknowns / next investigation

This is a preference, not a required template.

Adapt the diagram to the investigation. If another structure explains the engineering model better, use it.

Approved examples are stronger references than the written pattern.

A diagram should help someone reconstruct the investigation without needing to decode decorative architecture.

Prefer showing:
- relevant components only
- where the break occurs
- what survives
- what fails
- recovery/fallback when relevant
- the unresolved boundary when useful

Do not create duplicate diagrams for the same mental model unless there is a clear reason.

## 8. Codex / checkpoint prompts

When the user asks for a Codex prompt, update prompt, checkpoint prompt, or handoff prompt:

- return one complete copy-paste prompt
- do not split it across multiple blocks
- do not add unnecessary explanation before or after it
- preserve the latest approved structure
- preserve tested vs untested distinctions
- include enough state for Codex to update the durable notes correctly
- do not redesign the learning structure unless explicitly requested

Before generating such a prompt, follow the prompt-generation procedure defined in `WORKFLOW.md`.

The current conversation's latest explicit decisions override older repo text and older conventions.

## 9. Resumability

A fresh session should normally be able to resume by reading:

1. `WORKFLOW.md`
2. `CONVENTIONS.md`
3. `CURRENT.md`
4. only the subsystem/investigation notes referenced by `CURRENT.md`

The fresh session should not restart broad exploration if `CURRENT.md` already contains a bounded engineering question.

## 10. Keep the system evolvable

These conventions should change as the learning process improves.

When a new structure, diagram style, handoff format, or investigation pattern clearly works better:
- use the better approach
- preserve the reasoning
- update this file afterward if the change is likely to be useful again

Do not hardcode a past solution merely because it worked once.
