# Cua Learning Workflow

This workspace is the durable learning state for my long-term reverse-engineering
of Cua and learning of production AI agent infrastructure.

The conversation is not the source of truth.

If a ChatGPT or Codex conversation is new, lost, compacted, or incomplete,
the learning workspace must contain enough information to resume without
reconstructing previous conversations manually.

---

## Global Specialization Context

This workspace is the active repository-level learning workspace inside the
broader agent-infrastructure specialization.

Global strategy lives in:

`RitikaxG/agent-infrastructure-specialization`

When available locally:

`../agent-infrastructure-specialization/`

The global workspace owns:

- the six-month North Star
- which repository/subsystem is active
- rules for deciding which issues/PRs deserve serious time
- cross-repository invariants
- interview evidence
- repository switching
- promotion of repeated failures into reusable reliability tooling
- global Codex orchestration rules in `AGENTS.md`

This Cua workspace owns the detailed repository investigation:

- source paths
- subsystem understanding
- hypotheses
- experiments
- runtime evidence
- failure reproductions
- Cua-specific architecture
- exact current engineering question

### When the global workspace must be consulted

Do not read every global file during every coding step.

Consult the global specialization before:

1. choosing a new Cua subsystem;
2. committing significant time to a newly discovered issue or PR;
3. deciding that an observed behavior should become a contribution;
4. deciding that the current Cua subsystem is complete enough to move on;
5. extracting a failure into reusable tooling;
6. changing the broader specialization direction.

For issue/PR selection, apply:

`CONTRIBUTION_FILTER.md`

For the active subsystem and global stopping boundary, apply:

`ROADMAP.md`

For repository-switch decisions, apply:

`WORKFLOW.md`

For Codex orchestration and global promotion triggers, apply:

`AGENTS.md`

After meaningful Cua work:

- promote a genuinely reusable invariant to `PATTERN_LEDGER.md`;
- promote defensible personal engineering work to `INTERVIEW_EVIDENCE.md`;
- update the global `ROADMAP.md` only if the active/next subsystem changes.

Do not treat planning research, other people's PRs, or untested hypotheses as
personal evidence.

The global specialization strategy takes precedence over local opportunities:
an interesting Cua issue is not automatically worth pursuing.

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

### Documentation growth / restructuring gate

At every meaningful checkpoint, Codex should audit whether the durable files
still match these responsibilities. Rapid growth is a signal to inspect, not a
reason to keep appending indefinitely.

Trigger a restructuring proposal when one or more are true:

- `CURRENT.md` contains detailed architecture, source traces, or experiment
  history instead of primarily representing NOW;
- one investigation README contains multiple completed engineering slices that
  are difficult to retrieve independently;
- a durable file roughly doubles between stable checkpoints;
- navigation requires reading hundreds of unrelated lines before reaching the
  active boundary;
- repeated conclusions/evidence appear in three or more files without a clear
  summary-versus-detail relationship.

Useful size heuristics, not hard limits:

- `CURRENT.md`: normally about 80–150 lines;
- subsystem README: normally about 150–250 lines;
- one investigation/experiment README: normally under about 400–500 lines.

When the trigger fires, Codex must:

1. identify the responsibility overlap and measured growth;
2. propose the smallest slice-based restructuring that improves retrieval;
3. preserve experiments, conclusions, corrected inferences, evidence labels,
   and stopping boundaries;
4. ask the user for approval before moving, splitting, deleting, or renaming
   durable artifacts;
5. after approval, perform the restructuring and update links/instructions at
   the same checkpoint.

Split by durable engineering slice, not by conversation, day, or every small
question. Git history preserves superseded organization; do not create a second
chronological archive unless it has a distinct durable purpose.

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

ChatGPT can be my:

- technical teacher
- architecture reasoning partner
- reasoning interviewer
- whiteboard reviewer
- engineering reviewer

When ChatGPT is used separately from Codex, it does not need to be the primary
repository investigator when Codex can inspect the local Cua repository.

The role boundary is about **human understanding vs AI evidence gathering**, not
about forcing every activity into a particular product surface.

---

## Codex

Codex is the repository-aware investigator **and may also orchestrate the
learning/engineering workflow**.

It should read:

- the global specialization `AGENTS.md` when available;
- Cua's applicable repository instructions, including `AGENTS.override.md`;
- `cua-learning/WORKFLOW.md`;
- `cua-learning/CONVENTIONS.md`;
- `cua-learning/CURRENT.md`;
- the relevant subsystem/investigation note when necessary.

When Codex is started from a layout such as:

```text
open-source/
  agent-infrastructure-specialization/
  cua/
  cua-learning/
```

use the actual local layout rather than assuming a hardcoded absolute path.

Every fresh Codex session must ground itself in the current live Cua checkout
before investigating. The learning workspace records what I currently
understand; the Cua checkout is the implementation source of truth.

At the beginning of a fresh Codex investigation:

1. Read the applicable Cua repository instructions, including
   `AGENTS.override.md`.
2. Confirm the current branch, commit, and working-tree state.
3. Use `CURRENT.md` and its referenced investigation note to identify the exact
   Cua files/functions relevant to the active engineering question.
4. Inspect those files/functions in the current checkout before reasoning from
   older learning notes.
5. Do not perform broad repository reconnaissance unless the bounded
   investigation genuinely requires it.

Codex may:

- locate relevant code;
- trace a bounded runtime path;
- inspect tests;
- gather runtime evidence;
- run focused experiments when the experiment-ownership rules below are
  satisfied;
- point me to the minimum files/functions/lines I should personally inspect;
- teach only the language/syntax/concepts required for the current code path;
- cross-question my mental model and ask for explain-back;
- decide when further source reading has diminishing value;
- decide routine transitions between understanding, source trace, experiment,
  checkpoint, issue discovery, design, implementation, verification, and
  contribution work;
- later assist implementation/testing;
- autonomously maintain `cua-learning` at natural checkpoints;
- consult/promote to the global specialization when the trigger rules require
  it.

Codex should investigate the current engineering question rather than broadly
exploring the repository.

Do not ask me to decide routine workflow transitions that are already implied by
`CURRENT.md`, the evidence, and these instructions.

The human still owns the actual understanding, important predictions,
architecture decisions, contribution commitment, and approval of meaningful
implementation direction.

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

Codex should invoke the appropriate workflow when the investigation reaches that
phase rather than requiring me to remember which process to use.

Superpowers becomes useful after sufficient subsystem understanding exists.

It is not a substitute for understanding the runtime path.

---

## Experiment execution ownership

Choose who runs an experiment based on what must remain under observation and
control. Do not default every reproduction to Codex merely because Codex can run
shell commands.

### Codex-first experiments

Codex may run the first reproduction when either:

- the experiment is deterministic and does not depend on preserving a specific
  long-lived user-visible process/session/control relationship; or
- Codex can create, own, and verify the entire clean baseline itself, including
  every process/session/control relationship required by the hypothesis.

Typical examples include focused unit/integration tests, temporary deterministic
harnesses, parsing logs, bounded source-backed reproductions, or experiments in
which Codex launches every relevant component from a known clean state.

### Human + AI first reproduction

For an important lifecycle/failure experiment, prefer the first reproduction as
an interactive Human + AI run when correctness depends on preserving an exact
live relationship while selectively breaking another component, for example:

- keep this exact Proxy PID alive;
- keep this exact MCP session alive;
- preserve this exact `session_id`;
- verify a live persistent control connection;
- kill only the Daemon;
- replace only one process/listener;
- continue through the same surviving session;
- observe process, socket, state, and response transitions step by step.

In these cases Codex should normally provide the minimum source trace and help
validate the experiment design first. If the human is running the experiment
from Terminal, Codex should:

1. provide one command at a time;
2. explain what the command does and why it is needed;
3. inspect the returned output before advancing;
4. stop if the clean baseline is not verified;
5. ask for my prediction before the important break;
6. help interpret each process/session/state transition afterward.

The goal is not manual work for its own sake. The goal is that I personally see
and reason through the process/session/state transitions that the experiment is
teaching.

### Clean-baseline rule

A pre-existing MCP route, Proxy process, socket, or apparently successful tool
call is NOT sufficient proof of a valid lifecycle baseline.

Before a lifecycle experiment, verify every relationship that the hypothesis
requires. Depending on the experiment, this may include:

- exact Proxy PID
- exact Daemon PID
- socket/listener identity
- internally minted session identity
- persistent control connection / `session_begin` relationship
- relevant pre-break state
- absence of a previous replacement/recovery event that already changed the
  starting condition

If the required precondition is already absent, the experiment is **NOT TESTED**.
Do not continue and reinterpret the stale starting state as the requested
one-variable reproduction.

### Automation after understanding

After the first important behavior is understood, Codex may automate or repeat
it with a deterministic harness. At that stage automation is useful for:

- repeatability
- regression testing
- collecting cleaner logs
- varying one parameter at a time
- turning a reproduced problem into a test before implementation

Do not let automation replace the first-principles mental model.

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

For a fresh Codex session, then ground the investigation in the current Cua
checkout before tracing, testing, breaking, or proposing changes:

1. Read the current Cua repository instructions.
2. Confirm branch, commit, and working-tree state.
3. Open the exact Cua files/functions named by `CURRENT.md` or the active
   investigation README.
4. Verify that the current implementation still matches the recorded mental
   model before relying on it.

Codex should then state briefly:

- where we currently are;
- what is already solid;
- what remains unknown;
- what it is doing next and why.

### Fresh-session / new-day brief

At the beginning of a fresh Codex task, or when I explicitly say `Start a new
day`, apply the global New-day kickoff contract in the current local sibling:
`../agent-infra-specialization/AGENTS.md` (the repository's canonical long name
is `agent-infrastructure-specialization`).

Before substantive Cua work, derive the Day Start Brief from `CURRENT.md`, its
linked investigation note, the live Cua checkout, and the global roadmap. Do not
ask me to reconstruct the prior day.

For Cua, the brief must identify:

- today's exact Driver/runtime engineering question;
- the default 5–6 focused-hour budget or my explicit override;
- the primary engineering output and its Cua/September goal connection;
- today's experiment/evidence plan, or why no runtime experiment is appropriate;
- outcome-based major checkpoints with approximate focused time;
- the minimum source/runtime/issue scope;
- prediction, explain-back, design, contribution, or destructive-action gates;
- the exact stopping boundary and first action.

A normal day should produce at least one major engineering checkpoint plus a
durable supporting artifact. Reading, note expansion, or image generation alone
is not substantial progress. If the engineering boundary is reached early, do
not broaden into another repository or unrelated Cua subsystem merely to fill
the time budget.

`Start a new day` means present the brief and wait for confirmation. `Start a
new day and proceed with the recommended scope` allows routine safe work to
begin after the brief while preserving all existing human ownership gates.

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
3. Trace a bounded repository path if implementation evidence is required.
4. Decide experiment ownership using the rules above before running a break.
5. Gather only enough evidence to test the hypothesis.
6. Help me interpret the evidence.
7. Identify the important boundary, executor, state owner, and result/error
   path when relevant.
8. Ask WHY the component or boundary exists when architecturally important.
9. Separate verified behavior from inference.
10. Consider relevant failure behavior.
11. Ask me to explain the resulting mental model back.
12. Correct incorrect assumptions.
13. Continue only when the current piece is sufficiently understood.

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

Supported directly by runtime evidence.

### SOURCE-VERIFIED

Supported directly by current code, tests, or authoritative design history.

### INFERENCE

Architectural reasoning that has not yet been directly verified.

### UNKNOWN

Not yet established.

Never silently convert inference into fact.

### Stop-reading rule

When further source reading would add implementation trivia rather than change
the engineering model, stop.

If I can independently explain the relevant flow, boundary, state owner, failure
path, and architectural purpose, state that the slice is GREEN enough and move
to the next engineering phase.

Do not let repository exploration become passive learning.

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

If I do not know the language or syntax of a relevant file, explain only what is
required to reason about the current function/path, then return to the
engineering question.

If an external resource would materially improve understanding of the CURRENT
problem, recommend at most one excellent targeted resource.

Do not create a second curriculum or large reading list.

Codex may proactively select a relevant Cua repository document, project-authored
technical resource, or one targeted external resource when it materially
strengthens understanding of the CURRENT engineering question.

Follow the global just-in-time resource-selection rules in:

`../agent-infrastructure-specialization/AGENTS.md`

Do not create a reading curriculum. Return to the active Cua runtime path
immediately after the resource has served its purpose.

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

Codex should proactively recognize when the current slice has reached GREEN
enough to move forward instead of continuing source exploration indefinitely.

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

I form the mental model.

ChatGPT or Codex may validate, challenge, and help organize it rather than
silently replacing it with unverified architecture.

Codex may organize/link diagrams during checkpoints, but should not silently
add unverified architecture to them.

Diagram/document presentation conventions live in `CONVENTIONS.md` and may
evolve as better patterns emerge.

When a completed investigation slice has stable major conclusions and a durable
recall diagram or mind map would materially help, Codex must automatically
generate/update a draft visual and show it at that checkpoint. Then ask the user
for approval before copying, linking, or otherwise adding it to the durable
workspace. The user should not need to remember to ask for the draft.

After approval to add it, Codex should inspect it for factual and text accuracy,
store it beside the owning README, embed it, and retire any now-superseded visual
according to `CONVENTIONS.md`. A subsystem-level mind map should be generated as
a draft whenever multiple completed slices now form a stable architecture worth
retaining.

If approval is declined or image generation is unavailable, record the visual
as pending only when it remains useful. The prose checkpoint itself must not be
blocked.

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

A fresh Codex session should normally need only a short resume instruction
because the durable files already carry the detailed state.

---

# 10. Checkpoints

A checkpoint preserves enough durable state that the current conversation can
be discarded safely.

A checkpoint is NOT a new investigation.

Create one when:

- a meaningful runtime section has been understood;
- an important inference is corrected;
- an experiment materially changes the mental model;
- a bounded engineering question is resolved;
- the stopping boundary changes significantly;
- the understanding level changes;
- important architecture/failure reasoning has been established;
- the work is about to move into issue/design/implementation mode;
- enough durable progress has accumulated that losing context would be costly;
- or the session is ending after meaningful progress.

### Autonomous Codex checkpointing

Codex may recognize and write a checkpoint automatically. I should not need to
ask it to update stale learning files as routine ceremony.

A separate ChatGPT `CHECKPOINT HANDOFF` is optional, not required.

If ChatGPT has produced a useful handoff, Codex may use it. Otherwise Codex
should derive the checkpoint from:

- the current durable workspace;
- source/runtime evidence gathered in the session;
- my demonstrated understanding and explicit conclusions;
- the latest explicit decisions.

At a checkpoint, Codex should:

1. update the relevant subsystem/investigation README with durable detailed
   understanding;
2. update an associated experiment folder only when real evidence/reproduction
   material warrants it;
3. rewrite `CURRENT.md` to represent the new live state;
4. audit visual coverage and documentation growth; proactively propose any new
   canonical mind map/diagram or slice-based restructuring, obtain approval
   before adding/moving/removing durable artifacts, then preserve/link only the
   approved durable visuals according to `CONVENTIONS.md`;
5. consult the global specialization and promote only what has actually been
   earned:
   - reusable invariant → `PATTERN_LEDGER.md`;
   - defensible personal engineering work → `INTERVIEW_EVIDENCE.md`;
   - active/next subsystem change → `ROADMAP.md`;
   - improved selection rule → `CONTRIBUTION_FILTER.md`;
6. show a concise checkpoint summary/diff.

After the checkpoint, `CURRENT.md` must be sufficient for a fresh session to
know exactly where to resume.

Do not turn checkpoint maintenance into a separate learning activity.

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

If the current Cua source contradicts `cua-learning`, surface the discrepancy
before changing the durable model. Determine whether the implementation changed
since the learning note was written or whether the previous mental model was
incorrect. Do not silently overwrite either side.

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
8. invariant
9. alternatives/tradeoffs
10. test strategy

Only then move toward implementation.

Before seriously investing in a discovered issue/PR, consult the global
`ROADMAP.md` and `CONTRIBUTION_FILTER.md` so the six-month plan does not split
into unrelated workstreams.

At the appropriate point, use the relevant Superpowers workflow for debugging,
design, planning, TDD, verification, or review.

For a non-trivial solution, keep HLD and LLD connected:

- HLD: components, responsibilities, lifecycle, invariant, failure/recovery
  behavior;
- LLD: modules, types, functions, state transitions, error paths, and tests that
  implement the HLD.

I must be able to explain every important engineering decision.

---

# 13. Core Rules

**Conversation history is disposable.**

**The learning workspace is durable.**

**WORKFLOW.md defines the Cua investigation protocol.**

**CONVENTIONS.md defines current presentation/documentation defaults.**

**CURRENT.md tells us exactly where to resume.**

**Subsystem notes preserve detailed understanding.**

**The current Cua checkout is the implementation source of truth.**

**The global specialization keeps Cua work connected to the six-month strategy.**

**Latest explicit user decisions override older conventions/state.**

**Codex gathers evidence and may orchestrate routine workflow transitions.**

**First important lifecycle reproductions are manual when exact live process/session ownership is the thing being learned, unless Codex can establish and verify the entire clean baseline itself.**

**ChatGPT or Codex may teach/challenge; the human owns the actual engineering understanding.**

**Superpowers provides disciplined engineering workflows when needed.**

**I own the engineering understanding and decisions.**
