# Current Cua Learning State

## Phase

PHASE 3 — ISSUE-DRIVEN LEARNING / CONTRIBUTION DISCOVERY

## Current subsystem

Driver Runtime — Daemon lifecycle

## Active investigation

Active-request process death, uncertain execution, and retry/error-contract
classification.

## Current specialization fundamental

Primary:

- **Execution outcome & retry safety**

Supporting:

- lifecycle & readiness;
- ownership & generations;
- interface/error semantics;
- recovery.

## External proof stage

**Stage 3 — CONTRIBUTION CANDIDATE / EXISTING-WORK CLASSIFICATION**

Already earned:

- coherent subsystem model;
- multiple lifecycle experiments;
- valid active-request failure reproduction;
- candidate invariant;
- bounded contribution-shaped error-contract question;
- existing-work scan found no direct daemon-wire request-id/dedup/replay work.

Not yet earned:

- maintainer-visible evidence/discussion;
- approved regression/design direction;
- PR/review/merge.

Next desired movement:

**Stage 3 → Stage 4: maintainer-visible technical discussion/evidence**, if the
human commits to this contribution direction.

## Assistance profile

These levels are intentionally uneven and should move over time.

- **Agent-infra vocabulary / CUA concepts: GUIDED → SHARED** — daemon, Proxy,
  session, control/data connection, runtime generation are becoming concrete
  through experiments, but unfamiliar terminology still needs contextual
  teaching.
- **HLD reconstruction: SHARED** — the human can reason about Proxy vs Daemon
  ownership and surviving logical identity, but should practice redrawing the
  model without relying on generated prose.
- **LLD / Rust source navigation: GUIDED** — Codex should continue locating the
  minimum files/functions and teaching only the Rust needed for the current path.
- **Failure reasoning: SHARED** — the human correctly reasoned that a surviving
  side effect plus lost acknowledgement makes blind replay unsafe.
- **Test design: GUIDED** — Codex may identify the existing harness and candidate
  test shape; the human should own the plain-language property the regression
  must prove before implementation.
- **Contribution/design decision: SHARED** — Codex/ChatGPT may frame alternatives
  and upstream context; the human owns whether to commit time and which
  architectural guarantee is worth proposing.

## What I can explain without AI prose

At the current checkpoint, the human should be able to reconstruct and should be
periodically tested on these claims:

- Proxy and Daemon are independent process/failure domains.
- Proxy owns logical session identity and MCP/client continuity.
- Daemon owns process-local lifecycle/activity/in-flight/runtime state.
- Reusing a logical session id after Daemon replacement does **not** mean the old
  Daemon's runtime state survived.
- The Daemon can begin/perform an external effect before the final response is
  written back.
- If the Daemon dies after an effect begins but before the response arrives, the
  caller cannot conclude that the operation did not execute.
- Blind retry of an outcome-unknown non-idempotent action can compound external
  state.

If these cannot be explained from memory at a weekly checkpoint, revisit the
small HLD + one real failure rather than rereading the whole subsystem.

## What still needs AI scaffolding

Current legitimate dependencies:

- locating exact Rust files/functions/types for a new LLD question;
- explaining unfamiliar Rust constructs only where they affect control flow,
  ownership, concurrency, or error propagation;
- locating the nearest existing test harness and showing what it currently
  protects;
- translating human-stated regression intent into repo-native test code;
- bounded issue/PR/RFC history search;
- helping compare public error-contract alternatives and blast radius.

The goal is for failure hypotheses, invariants, test intent, and architecture
questions to increasingly originate from the human while Codex continues to
accelerate source search and syntax.

## Understanding level

YELLOW overall.

- **GREEN enough:** happy path and observation/targeting boundaries.
- **GREEN enough:** between-request Daemon replacement/session recovery.
- **GREEN enough:** active-request execution/acknowledgement ambiguity.
- **YELLOW:** independent recall of the compact HLD/relevant LLD.
- **YELLOW:** regression-test design in the Rust codebase.
- **YELLOW:** contribution legitimacy, maintainer direction, and any future
  error-contract design.

## Current mental model

- Proxy and Daemon are independent process/failure domains.
- Proxy owns logical session identity and MCP continuity.
- Daemon owns process-local lifecycle/activity/in-flight state and session-owned
  runtime state.
- Ordinary calls use a fresh data-plane connection; `session_begin` uses a
  persistent control connection for immediate owner-liveness cleanup.
- Replacement can reuse an old, non-ended identity while creating fresh state;
  this is not old-state recovery.
- Without control reconnect, idle lifecycle expiry remains a delayed cleanup
  fallback.
- The Daemon invokes the platform effect before writing its final response.
- The daemon-wire request has no request identity, attempt number, idempotency
  key, or deduplication key.
- The Proxy does not automatically replay a failed logical action.
- Therefore, after dispatch, no final response means execution outcome is
  unknown—not that the action did not execute.

## Latest runtime evidence

Valid active-request reproduction on 2026-09-08:

- fresh-task Proxy candidate `68340`;
- Daemon `65529`;
- session `mid-request-20260908-resume`;
- disposable Terminal `63260` / window `24885`;
- exact-window foreground `type_text`, `delay_ms:200`;
- observer killed only the Daemon after seeing `CUA_MIDREQ2_`;
- Terminal retained exactly that strict prefix;
- Proxy reported `daemon closed connection without response`;
- Proxy candidate and Terminal survived; Daemon/listener did not;
- no automatic replay and no manual retry occurred.

The human correctly explained that the Proxy knows only the response-path
failure, while independent Terminal observation proved partial execution. Blind
full retry could compound the surviving external state.

## Contribution classification

The contribution filter is a strong strategic match: lifecycle, failure
reproduction, action/effect correctness, retry ambiguity, and cross-platform
runtime contracts are central specialization goals.

Bounded issue/PR review found no direct daemon-wire request-id, deduplication, or
automatic-replay work. Existing related fixes remove specific crash/restart
causes or reject work before execution.

Current classification:

- not a proven automatic-retry bug;
- expected uncertainty under the current protocol;
- credible client-visible error-contract improvement candidate.

Candidate invariant:

> After request dispatch, a client-visible transport failure must not imply
> “not executed” or “safe to retry”; execution outcome must be unknown.

Candidate scope: distinguish pre-dispatch connection failure from post-write
outcome-unknown failure in the common daemon client/Proxy contract. Automatic
replay, deduplication, and exactly-once claims are explicit non-goals.

## Weekly checkpoint focus

Until this contribution direction is resolved, weekly revision should stay on
this same engineering story:

- redraw the compact Driver Runtime/Daemon HLD from memory;
- trace the relevant LLD from Proxy request → Daemon → tool/platform effect →
  response/error using only the important landmarks;
- explain the between-request and active-request failure scenarios without
  notes;
- restate what is OBSERVED vs SOURCE-VERIFIED vs INFERENCE vs UNKNOWN;
- explain why `Connection refused` before dispatch differs from a connection
  closing after the effect begins;
- state what a regression test would need to prove, even if Codex still writes
  the Rust test;
- review whether the external proof stage actually moved.

If Stage 4 is reached early in a week, prioritize maintainer response, narrowing
the contract, regression-test design, or a related follow-up in the same
subsystem. Do not broaden into a new CUA subsystem merely to fill time.

## Current exact engineering question

> Should we commit serious contribution time to a maintainer discussion about
> distinguishing pre-dispatch transport failure from post-write
> execution-outcome-unknown failure, without attempting replay or exactly-once
> execution?

## Immediate next work

1. Stop for the human's contribution-commitment decision.
2. If approved, prepare a maintainer-facing problem statement with reproduction,
   invariant, related context, non-goals, and error-contract alternatives.
3. Seek maintainer direction before implementation because the change affects a
   cross-platform public contract.
4. If maintainers support the direction, identify the nearest test harness;
   Codex may scaffold the Rust/test mechanics while the human must be able to
   state the regression property and important cases in plain language.
5. Only then enter design, planning, TDD, implementation, and verification.

## Live checkout grounding

- source repository: `../cua/`
- recorded branch: `main`
- recorded commit: `72fe7fff6e2d84863585f7164d9663367e8fa465`
- known pre-existing untracked paths remain untouched:
  `libs/cua-driver/rust/target 2/` and
  `libs/fleet/sdk-bindings/kotlin/.gradle/`

A fresh Codex session must re-check branch, commit, and working-tree state before
relying on the recorded checkout state.

## Durable visuals

- `subsystems/driver-runtime/driver_runtime_mind_map.png` — current subsystem
  architecture and retained conclusions.
- `subsystems/driver-runtime/daemon-lifecycle/daemon_lifecycle_session_recovery.png`
  — between-request state/recovery model and user-approved reference style.
- `subsystems/driver-runtime/daemon-lifecycle/active-request-death/active_request_uncertain_outcome.png`
  — active-request experiment and knowledge boundary.

## Stop boundary

Do not repeat the marker, broaden issue discovery, choose an error schema,
open/comment on an issue, or modify Cua source without human contribution
commitment and maintainer alignment.

Do not reset to broad daemon orientation because the global specialization files
changed.

## Pointers

- `subsystems/driver-runtime/README.md`
- `subsystems/driver-runtime/happy-path/README.md`
- `subsystems/driver-runtime/failures/README.md`
- `subsystems/driver-runtime/daemon-lifecycle/README.md`
- `subsystems/driver-runtime/daemon-lifecycle/between-requests/README.md`
- `subsystems/driver-runtime/daemon-lifecycle/active-request-death/README.md`
