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

The repository will grow over months, so diagrams should be curated rather than accumulated.

Prefer storing the **final / canonical recall image** for a completed investigation slice: the image that captures the major observed behavior, corrected mental model, important boundaries, and final conclusions after the experiment/source trace.

Visual checkpointing is proactive but approval-gated:

- when a completed slice has stable major conclusions, Codex must decide whether
  a retention-oriented diagram or mind map would materially help;
- if yes, Codex must automatically generate/update a draft and show it at the
  checkpoint, then ask for approval before adding, copying, or linking it into
  the durable repository;
- after approval to add it, inspect factual claims and rendered text, store it
  beside its owning README, and embed it;
- when multiple completed slices now form a stable subsystem architecture,
  propose a subsystem-level mind map in addition to any genuinely distinct
  experiment/failure visual;
- if the user declines, leave the preview outside the durable repository and do
  not add it silently.

Do **not** store every intermediate whiteboard, scratch diagram, hypothesis sketch, or temporary reasoning image by default. Those are useful while learning but should remain working artifacts unless the user explicitly decides one has lasting value.

A second diagram is justified only when it adds a genuinely different, durable view that the canonical image does not cover—for example a unique failure path or architecture view that remains important after the investigation is settled.

If a later final diagram subsumes an older one, prefer the final diagram in the durable repo. Git history already preserves the earlier evolution.

Store investigation-specific canonical images beside that investigation README and embed them from the README so a future session can discover the final mental model immediately.

Use previously approved diagrams as references for clarity and investigation storytelling.

### Approved retention-map reference

`subsystems/driver-runtime/daemon-lifecycle/daemon_lifecycle_session_recovery.png`
is the preferred reference for future subsystem/investigation mind maps. The
user explicitly approved it as especially concise and to the point.

Reuse its communication qualities rather than copying its exact layout:

- numbered sections with one responsibility each;
- architecture and ownership first;
- healthy path contrasted with failure/recovery behavior;
- observed experiment results embedded beside the relevant model;
- a compact major-conclusions strip for fast recall;
- enough detail to reconstruct the mental model without reproducing the full
  investigation README;
- clear tested/source-verified/unknown distinctions;
- high information density while remaining readable at ordinary desktop zoom.

Prefer this study-map style over decorative mind maps with vague branches,
repeated prose, or excessive empty space.

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
- corrected inference / final conclusion when relevant
- the unresolved boundary when useful

Before accepting a generated visual, verify:

- every status label still matches TESTED / SOURCE-VERIFIED / INFERENCE /
  UNKNOWN;
- no obsolete “not tested” or open-question label survives after the boundary
  was resolved;
- process, session, state-ownership, retry, and recovery claims match the owning
  README;
- exact identifiers and quoted runtime results are spelled correctly;
- the image remains legible at ordinary desktop zoom.

## 7.1 Documentation growth and restructuring

Codex should audit structure at natural checkpoints instead of waiting for the
user to notice runaway growth.

Propose restructuring when a file has rapidly grown, roughly doubled between
stable checkpoints, accumulated multiple completed slices, duplicated another
file's responsibility, or become difficult to resume from. Treat line counts as
signals rather than rigid limits; responsibility and retrieval quality decide.

Recommended steady-state shapes:

- `CURRENT.md`: compact live resume state, usually about 80–150 lines;
- subsystem README: canonical architecture/conclusion map plus links, usually
  about 150–250 lines;
- experiment/investigation README: one durable engineering slice, usually under
  about 400–500 lines.

When restructuring is warranted:

1. propose the minimal slice-based layout and explain what moves where;
2. ask the user to approve before changing paths, splitting files, or removing
   superseded artifacts;
3. after approval, preserve all meaningful experiments, conclusions, corrected
   inferences, evidence classifications, visuals, and stopping boundaries;
4. update every link and `CURRENT.md` in the same checkpoint;
5. do not create a file per conversation or per small question.

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

## 9. Day Start Brief

Use this compact user-facing structure at the beginning of a fresh Codex task or
an explicitly declared new day:

```text
DAY START BRIEF

Current Position
- repository / subsystem / engineering question
- understanding level, GREEN areas, unresolved boundary

Focused Time Budget
- default 5–6 focused hours, excluding breaks, or explicit override

Today's Substantial Output
- primary engineering result
- durable supporting artifact
- monthly / six-month goal advanced

Experiment / Evidence Plan
- hypothesis or evidence question
- activity, expected observation, ownership
- or: no runtime experiment today — <reason>

Major Checkpoints
- approximate focused time → outcome
- required human gates

Scope
- minimum relevant components/files
- explicit exclusions

Stopping Boundary
- definition of enough for today
- work that must not begin yet

First Action
- exact bounded next step
```

Keep the brief concrete and adapted to the current workflow phase. Do not paste
generic ceremony. The 5–6 hours are a planning budget, not a claim about elapsed
or focused time. Major checkpoints are outcome-based, and documentation/visuals
support rather than replace the day's engineering result.

When the current phase is issue discovery or design, `Experiment / Evidence
Plan` may explicitly state that no runtime experiment is planned and name the
source, issue, design, test, or maintainer artifact that will convert existing
evidence instead.

## 10. Resumability

A fresh session should normally be able to resume by reading:

1. `WORKFLOW.md`
2. `CONVENTIONS.md`
3. `CURRENT.md`
4. only the subsystem/investigation notes referenced by `CURRENT.md`

The fresh session should not restart broad exploration if `CURRENT.md` already contains a bounded engineering question.

## 11. Keep the system evolvable

These conventions should change as the learning process improves.

When a new structure, diagram style, handoff format, or investigation pattern clearly works better:
- use the better approach
- preserve the reasoning
- update this file afterward if the change is likely to be useful again

Do not hardcode a past solution merely because it worked once.
