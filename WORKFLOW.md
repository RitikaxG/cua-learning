# Cua Learning Workflow

This workspace is the durable learning state for my long-term reverse-engineering
of Cua and learning of production AI agent infrastructure.

The conversation is not the source of truth.

If a ChatGPT or Codex conversation is new, lost, compacted, or incomplete,
the learning workspace must contain enough information to resume without
reconstructing previous conversations manually.

---

## 1. Source of Truth

Each file has one responsibility.

### `WORKFLOW.md`

Permanent protocol for HOW the learning process works.

It should not contain current investigation details.

### `CONVENTIONS.md`

Working defaults for HOW the learning should be documented, visualized, and
handed off.

It records current preferences for:

- subsystem/investigation documentation structure
- diagram style and approved references
- Codex/checkpoint prompt generation
- resumability and handoff quality

These conventions are intentionally evolvable. The latest explicit user
decision overrides older conventions or repository text.

### `CURRENT.md`

Live resume state.

It tells a fresh session:

- current phase
- broader subsystem being learned
- concrete investigation being used
- what I have personally established
- current understanding level
- exact stopping boundary
- what remains unknown
- next engineering question
- immediate scope
- how to begin the next session

`CURRENT.md` represents NOW, not history.

Do not duplicate detailed architecture here.

### `subsystems/<name>/README.md`

This contains the current durable understanding of one subsystem:

- runtime flow established
- component responsibilities
- boundaries
- relevant state ownership
- important evidence
- failure reasoning
- architectural conclusions
- architectural inference
- unresolved questions

A new session reads this only when the detail is needed.

### `subsystems/<name>/<experiment>/`

This contains evidence and a reproducible experiment that developed or changed
the subsystem understanding.

Do not create an experiment folder before the experiment exists. Do not create
a decision file before a meaningful decision exists. Do not create global
architecture maps until multiple understood subsystems need connecting. Do not
create incremental notes for each question.

Prefer updating the subsystem README after understanding changes. Runtime
traces are evidence, not durable learning docs. Preserve only final useful
diagrams, not intermediate whiteboards.

---

# 2. Roles

## Human

I own:

- architecture understanding
- runtime-flow understanding
- state ownership reasoning
- failure reasoning
- root-cause conclusions
- engineering decisions
- alternatives and tradeoffs
- test strategy

AI discovering something does NOT mean I understand it.

Understanding increases only when I can independently explain and reason
about the system.

---

## ChatGPT

ChatGPT is my:

- technical teacher
- architecture reasoning partner
- reasoning interviewer
- whiteboard reviewer
- engineering reviewer

ChatGPT is not the primary repository investigator when Codex can inspect the
local Cua repository.

Codex gathers repository/runtime evidence.

I form the engineering model.

ChatGPT helps me understand, challenge, test, and refine that model.

---

## Codex

Codex is the repository-aware investigator.

It should read:

- Cua's `AGENTS.override.md`
- `cua-learning/WORKFLOW.md`
- `cua-learning/CONVENTIONS.md`
- `cua-learning/CURRENT.md`
- the relevant subsystem/investigation note when necessary

Codex may:

- locate relevant code
- trace a bounded runtime path
- inspect tests
- run focused experiments
- gather runtime evidence
- help explain implementation details
- later assist implementation/testing
- maintain `cua-learning` during checkpoints

Codex should investigate the current engineering question rather than broadly
exploring the repository.

---

## Superpowers

Superpowers is used through Codex when a concrete engineering workflow
requires:

- systematic debugging
- design / brainstorming
- planning
- TDD
- verification
- code review

It becomes useful after sufficient subsystem understanding exists.

It is not a substitute for understanding the runtime path.

---

# 3. Starting or Resuming Any Session

A fresh ChatGPT or Codex session must be able to resume without previous
conversation history.

At session start:

1. Read `WORKFLOW.md`.
2. Read `CONVENTIONS.md`.
3. Read `CURRENT.md`.
4. Determine:
   - current phase
   - current subsystem
   - current investigation
   - understanding level
   - exact stopping boundary
   - next engineering question
5. Read only the subsystem/investigation notes referenced by `CURRENT.md` when
   more detail is needed.
6. Inspect referenced diagrams when useful.
7. Resume from the recorded stopping boundary.

Do NOT restart previous architecture merely because the conversation is new.

Do NOT make me explain previous sessions again if the information already
exists in the learning workspace.

Restart an earlier section only if:

- I explicitly ask to revisit it, or
- new evidence contradicts the existing mental model.

The same rule applies after conversation context compaction:

**recover state from the learning workspace rather than guessing from partial
conversation history.**

---

# 4. Learning Method

Study one continuous real execution path rather than disconnected concepts.

For each new runtime hop:

1. Establish one concrete engineering question.
2. Ask for my hypothesis first when useful.
3. Give Codex a bounded investigation question if repository evidence is
   required.
4. Gather only enough evidence to test the hypothesis.
5. Help me interpret the evidence.
6. Identify the important boundary, executor, state owner, and result/error
   path when relevant.
7. Ask WHY the component or boundary exists when architecturally important.
8. Separate verified behavior from inference.
9. Consider relevant failure behavior.
10. Ask me to explain the resulting mental model back.
11. Correct incorrect assumptions.
12. Continue only when the current piece is sufficiently understood.

Preferred loop:

PREDICT
→ OBSERVE
→ TRACE
→ ASK WHY
→ READ MINIMUM RELEVANT CODE
→ FORM MENTAL MODEL
→ TEST / BREAK WHEN USEFUL
→ PREDICT FAILURE
→ OBSERVE
→ EXPLAIN BACK

Do not dump the complete architecture before I have reasoned through it.

---

# 5. Investigation Scope

Investigate one engineering question at a time.

Prefer the minimum relevant code/runtime evidence.

Usually begin with roughly 3–5 important files/functions rather than broad
repository archaeology.

For a runtime path, reason about whichever of these matter:

- entry point
- request/data representation
- process/network boundary
- in-process boundary
- executor
- state owner
- result/error path
- failure cases
- timeout/retry implications
- lifecycle implications

Always separate:

### OBSERVED

Supported directly by code, tests, runtime evidence, or documentation.

### INFERENCE

Architectural reasoning that has not yet been directly verified.

### UNKNOWN

Not yet established.

Never silently convert inference into fact.

---

# 6. Depth Control

Learn concepts just in time.

When an unfamiliar concept appears, classify it as:

### STUDY NOW

Required to understand the current runtime path, failure, or engineering
decision.

### LEARN LATER

Relevant, but not required for the current question.

### IGNORE FOR CURRENT TASK

Interesting but unrelated to the active investigation.

Avoid prerequisite rabbit holes.

Do not study an entire technology merely because one function uses it.

If an external resource would materially improve understanding of the CURRENT
problem, ChatGPT may recommend one excellent targeted resource.

Do not create a second curriculum or large reading list.

---

# 7. Understanding Levels

Understanding is based on what I can independently explain and reason about.

### RED

The path/subsystem is mostly unclear.

### YELLOW

The main flow is becoming clear, but important responsibilities, boundaries,
state, or failures remain uncertain.

### GREEN

I can independently explain:

- responsibilities
- runtime flow
- important boundaries
- relevant state ownership
- major failure cases

without depending on an AI-generated trace.

### DARK GREEN

In addition to GREEN, I can independently reason about:

- alternative designs
- tradeoffs
- reliability implications
- recovery behavior
- why a particular design fits particular constraints

AI finding more code does not increase this level.

---

# 8. Whiteboarding

I should create diagrams when they materially help with:

- process boundaries
- request/response paths
- state ownership
- lifecycle
- concurrency
- retries
- partial failures

I draw the mental model.

ChatGPT validates and challenges it rather than replacing it with a polished
AI-generated architecture.

Codex may organize/link diagrams during checkpoints, but should not silently
add unverified architecture to them.

Diagram/document presentation conventions live in `CONVENTIONS.md` and may
evolve as better patterns emerge.

---

# 9. Before Generating Codex / Checkpoint Prompts

This applies whenever I ask for a Codex prompt, update prompt, checkpoint
prompt, handoff prompt, or similar prompt — including midway through a long
conversation.

Before generating the prompt:

1. Re-read `CONVENTIONS.md`.
2. Re-read `CURRENT.md`.
3. Read the relevant subsystem/investigation note referenced by `CURRENT.md`
   when the prompt will update or continue that work.
4. Incorporate the latest explicit decisions from the current conversation.
5. If the current conversation conflicts with older repository text or
   conventions, the latest explicit user decision wins and the prompt should
   bring the durable workspace up to that approved state.
6. Preserve established structures and approved artifacts unless I explicitly
   ask to redesign them.
7. Return one complete copy-paste prompt unless I ask for another format.

Do not generate checkpoint/update prompts from conversation memory alone when
the durable workspace exists.

---

# 10. Checkpoints

A checkpoint preserves enough durable state that the current conversation can
be discarded safely.

A checkpoint is NOT a new investigation.

Create one when:

- a meaningful runtime section has been understood;
- the stopping boundary changes significantly;
- the understanding level changes;
- important architecture/failure reasoning has been established;
- or the session is ending after meaningful progress.

At a checkpoint, ChatGPT produces a concise:

## CHECKPOINT HANDOFF

containing only:

- what I personally established
- important architectural conclusions I personally reasoned through
- corrections to my previous mental model
- important experiments/evidence
- current understanding level
- exact stopping boundary
- still unknown
- next engineering question
- diagrams created, if any

Do not turn the handoff into a conversation transcript.

Codex then uses the handoff to update the learning workspace.

Codex should:

1. update the relevant subsystem README with durable detailed understanding;
2. update the associated experiment folder when new evidence or reproduction
   material exists;
3. rewrite `CURRENT.md` to represent the new live state;
4. preserve/link only relevant final diagrams;
5. show a concise diff for review.

After the checkpoint, `CURRENT.md` must be sufficient for a fresh session to
know exactly where to resume.

---

# 11. Context-Safety Rule

Never rely on a long ChatGPT/Codex conversation as the only location of
important learning state.

Before ending a meaningful session, or when context is becoming large, make
sure a checkpoint captures durable progress.

Anything required to resume later belongs in:

- `CURRENT.md` for live state, or
- the relevant durable workspace file for detailed knowledge.

Therefore:

**new chat should be safe.**

**context compaction should be safe.**

**losing conversation history should be safe.**

The latest explicit user decision overrides older conventions or durable text.
When that happens, update the workspace at the next checkpoint rather than
silently reverting to the older state.

---

# 12. Before Fixing Real Issues

Do not jump from finding code to implementing a fix.

Before fixing a real issue, establish:

1. expected behavior
2. actual behavior
3. reproduction
4. runtime path
5. relevant state ownership
6. failure boundary
7. plausible root cause
8. alternatives/tradeoffs
9. test strategy

Only then move toward implementation.

At that point, use the appropriate Superpowers workflow for debugging, design,
planning, TDD, verification, or review.

I must be able to explain every important engineering decision.

---

# 13. Core Rules

**Conversation history is disposable.**

**The learning workspace is durable.**

**WORKFLOW.md defines the investigation protocol.**

**CONVENTIONS.md defines current presentation/documentation defaults.**

**CURRENT.md tells us where to resume.**

**Subsystem notes preserve detailed understanding.**

**Latest explicit user decisions override older conventions/state.**

**Codex gathers evidence.**

**ChatGPT teaches and challenges.**

**Superpowers provides disciplined engineering workflows when needed.**

**I own the engineering understanding and decisions.**
