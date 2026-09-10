# Cua Learning Workflow

This workspace is the durable repository-specific learning state for CUA inside
the broader **Agent Runtime Reliability** specialization.

The conversation is not the source of truth. A fresh ChatGPT/Codex session must
be able to resume from this workspace without asking the human to reconstruct
old chats.

## 1. Global Context and Precedence

Global strategy lives in:

`../agent-infrastructure-specialization/`

The global workspace owns:

- six-month goal and professional identity;
- agent-runtime fundamentals;
- proof/independence checkpoints;
- active/next repository sequence;
- contribution and maintainer-selection rules;
- cross-repository invariants;
- interview evidence;
- Codex orchestration.

This CUA workspace owns:

- exact CUA source paths and runtime model;
- current subsystem/investigation;
- experiments and failure evidence;
- CUA-specific HLD/LLD;
- exact engineering question;
- assistance/proof state for the current CUA work;
- stopping boundary.

When instructions conflict, the latest explicit human direction and global
specialization strategy take precedence over older local process wording.

Consult the global workspace before:

- choosing a new CUA subsystem;
- committing serious time to an issue/PR;
- deciding an observed behavior should become a contribution;
- deciding the CUA stopping boundary is reached;
- promoting an invariant or interview story;
- building reusable failure tooling.

## 2. Local Files

- `WORKFLOW.md` — permanent CUA investigation protocol.
- `CONVENTIONS.md` — documentation/diagram/handoff preferences.
- `CURRENT.md` — live resume state, assistance levels, proof stage, exact
  question, next action, stopping boundary.
- `subsystems/<name>/README.md` — durable subsystem mental model.
- investigation/failure folders — only for real evidence-producing slices.

`CURRENT.md` represents NOW. Do not turn it into a chronological archive.

Detailed source traces and experiments belong in the relevant subsystem or
investigation README. Keep only durable, useful diagrams.

## 3. Human / ChatGPT / Codex Roles

### Human

The end-state is that the human can defend:

- compact HLD;
- relevant LLD landmarks;
- state/ownership reasoning;
- failure explanation;
- important invariant;
- test intent;
- architecture trade-offs;
- contribution decision.

This does **not** mean the human must discover all of those unaided at the start.
Use the global assistance ladder:

```text
GUIDED → SHARED → USER-LED → TRANSFER
```

Track the current level per dimension in `CURRENT.md`.

### ChatGPT

Use as technical teacher, architecture partner, reasoning interviewer, and
engineering reviewer. It may help make unfamiliar agent-infrastructure concepts
concrete and cross-question the human's model.

### Codex

Codex is the repository-aware investigator and implementation accelerator.

It may:

- locate relevant code/tests;
- trace bounded runtime paths;
- gather source/runtime evidence;
- teach only the Rust/syntax needed for the current path;
- suggest failure boundaries in GUIDED mode;
- identify nearby tests and explain what they protect;
- help design and run focused experiments;
- translate human-stated test intent into repo-native code;
- implement/verify approved changes;
- maintain durable CUA state at natural checkpoints.

Codex must not treat its own explanation as human understanding.

## 4. Fresh Session Bootstrap

At the start of a fresh CUA session:

1. Read global `agent-infrastructure-specialization/AGENTS.md`.
2. Read this `WORKFLOW.md` and `CONVENTIONS.md`.
3. Read `CURRENT.md`.
4. Identify current phase, subsystem, investigation, assistance levels, proof
   stage, exact question, and stopping boundary.
5. Read only the subsystem/investigation notes referenced by `CURRENT.md` when
   more detail is necessary.
6. Read CUA's own repository AGENTS/contribution/testing instructions.
7. Re-ground the live `../cua/` checkout: branch, commit, working-tree state, and
   minimum source landmarks relevant to the current question.

Do not restart previously established architecture unless new evidence
contradicts it or the human explicitly asks to revisit it.

## 5. Learning Method

Study one continuous execution/failure path at a time.

For a new concept or runtime hop:

```text
plain-language role
→ actual CUA component/process/type
→ responsibility and state ownership
→ healthy request path
→ minimum relevant source
→ human explain-back
→ failure variation when useful
→ evidence / invariant
```

Do not ask for a meaningful failure prediction before the normal path and
unfamiliar concepts are concrete enough.

### GUIDED mode

Codex may supply the architecture skeleton, vocabulary, candidate failure
boundaries, and nearby tests. The human explains the important relationships.

### SHARED mode

The human reconstructs or predicts a bounded part first; Codex verifies and
corrects with source/runtime evidence.

### USER-LED mode

The human originates the engineering question, failure variation, invariant, or
test intent; Codex mainly gathers evidence and accelerates implementation.

## 6. CUA HLD Contract

The HLD for the active subsystem should stay small enough to redraw from memory.
It should answer:

- what the subsystem solves;
- 3–7 important components;
- what each component owns;
- one healthy control/execution path;
- durable/logical vs process/generation-local state;
- lifecycle/readiness states;
- independent failure boundaries;
- recovery/cleanup owner.

Do not map the entire CUA repository.

## 7. CUA LLD Contract

LLD is the implementation slice required for the active failure/feature.

Locate only:

```text
entry
→ transport
→ state/types
→ effect boundary
→ result/error
→ recovery/cleanup
→ nearest tests
```

Codex should initially point to exact files/functions/lines and teach only the
Rust needed to understand those sections. Over time, ask the human where they
expect the implementation to live before locating it.

## 8. Experiment Ownership

Choose who runs an experiment based on what must remain under observation and
control.

### Codex-first

Codex may run deterministic tests/harnesses where it can create and verify the
entire baseline itself.

### Human + AI first reproduction

Prefer an interactive first reproduction when correctness depends on preserving
an exact live relationship while selectively breaking another component, such
as:

- exact Proxy PID;
- exact Daemon PID;
- exact logical session id;
- persistent control relationship;
- same surviving Proxy/session after Daemon death;
- kill/replace only one process or listener.

For these experiments:

1. give one command at a time;
2. explain what it does and why;
3. inspect output before advancing;
4. verify every required baseline relationship;
5. ask for the human prediction once the concept is sufficiently grounded;
6. introduce only the minimum break;
7. observe state/process/external effect transitions;
8. explain the result together.

### Clean-baseline rule

A process/socket/tool call merely existing is not enough. Verify every
precondition the hypothesis depends on.

If the required precondition is absent, classify the requested scenario as
**NOT TESTED**. Do not reinterpret the stale starting state as valid evidence.

## 9. Evidence Discipline

Use these labels when important:

- **OBSERVED** — direct runtime evidence.
- **SOURCE-VERIFIED** — behavior established by current implementation/design.
- **INFERENCE** — reasoned conclusion that still depends on assumptions.
- **UNKNOWN / NOT YET TESTED** — unresolved.

Do not promote a hypothesis into a bug. Do not claim an untested scenario was
reproduced.

## 10. Failure Reasoning

For each important reproduction, preserve this compact story:

```text
healthy baseline
→ break introduced
→ exact failure location/boundary
→ observed outcome
→ what survived / disappeared
→ explanation
→ fallback/recovery
→ what remains unknown
```

Then connect it to one global fundamental/invariant.

Early on, Codex may suggest failure families. Progressively ask the human to
propose nearby variations and, later, recognize the same family in another repo.

## 11. Test-Design Training

Human ownership of test strategy is the **destination**, not an initial
prerequisite.

### GUIDED

Codex identifies the nearest test harness/tests and explains:

- setup;
- observable;
- protected contract;
- missing coverage.

The human must be able to state what property a new regression test should prove.

### SHARED

The human proposes:

```text
setup
fault/variation
observable
assertion
race/failure case
cleanup assertion
```

Codex may translate this into Rust/TypeScript/Python test code.

### USER-LED

The human originates the invariant and test cases; Codex reviews and helps
implement/verify.

Measure who owns the test **intent**, not who types the syntax.

## 12. Source-Reading Guard

Do not allow deep learning to become indefinite source consumption.

After at most two focused sessions dominated by source/docs understanding, the
next meaningful session should produce at least one of:

- explain-back / HLD reconstruction;
- prediction;
- controlled experiment;
- failure reproduction;
- issue/PR analysis;
- test intent;
- design/contract decision;
- maintainer-facing evidence.

Stop reading when additional source would add trivia rather than change the
engineering model or contribution decision.

## 13. Contribution Progression

Before serious contribution time, apply global `CONTRIBUTION_FILTER.md`.

Inspect exact/adjacent issues, active/recent PRs, RFCs, assignments, and current
maintainer direction before creating public work.

Preferred progression:

```text
EXPECTED
→ ACTUAL
→ REPRODUCTION
→ HLD BOUNDARY
→ RELEVANT LLD
→ STATE / OWNERSHIP
→ FAILURE BOUNDARY
→ INVARIANT
→ EXISTING-WORK INVENTORY
→ MAINTAINER ALIGNMENT
→ TEST / DESIGN
→ IMPLEMENT
→ VERIFY
→ PR / REVIEW / OUTCOME
```

Do not create a new issue/PR when an active contribution already owns the same
work.

Do not implement a cross-component/public-contract redesign before maintainer
alignment when the blast radius is meaningful.

## 14. Daily / Weekly / Monthly Checkpoints

The canonical progress rules live in global `PROGRESS_GATES.md` and
`AGENTS.md`.

### Daily

Use `CURRENT.md` to record:

- assistance profile;
- proof stage;
- primary fundamental;
- what the human can explain unaided;
- what still needs AI scaffolding;
- exact question and stopping boundary.

End substantial learning days with a short no-notes reasoning check.

### Weekly

Revise the same active story through HLD, LLD landmarks, failures, invariant/test
intent, contribution status, maintainer feedback, and independence movement.

If the weekly checkpoint finishes early, deepen the same subsystem/contribution
before broadening.

### Monthly

Judge externally inspectable proof, maintainer relationship, fundamental depth,
retention, independence, and interview-story quality—not hours or note volume.

## 15. Checkpoint Maintenance

Codex should update durable state automatically when:

- evidence materially changes the model;
- an inference is corrected;
- proof/assistance level changes;
- an engineering question is resolved;
- the stopping boundary changes;
- work moves into issue/design/implementation/review mode.

At a checkpoint:

1. update the relevant subsystem/investigation README;
2. rewrite `CURRENT.md` to represent NOW;
3. follow `CONVENTIONS.md` for diagram/documentation curation;
4. promote only earned conclusions to the global specialization.

New durable visual assets and structural reorganizations remain approval-gated.

## 16. Workspace Cleanliness

Do not create a file per chat/day/question. Split only by durable engineering
slice when retrieval actually benefits.

Use `CONVENTIONS.md` size/restructuring heuristics. Prefer updating existing
subsystem/investigation documents over accumulating parallel summaries.

## 17. Current CUA Continuity

The current active-request Daemon-death / execution-uncertainty investigation is
already contribution-shaped.

Do not reset to broad daemon orientation because this workflow changed.

Resume from `CURRENT.md` and its stopping boundary: contribution commitment →
maintainer-facing evidence → maintainer direction → regression/design/
implementation only if warranted.

## 18. Handoff

After meaningful work, end with exactly one of:

### NEXT

The next bounded engineering action and why it advances the proof/fundamental.

### WAITING ON HUMAN

The exact prediction, explain-back, terminal result, contribution commitment, or
design approval required.

### BLOCKED

The blocker, missing evidence/authority, and smallest unblock action.

The human should never have to infer the next workflow transition.