# Current Cua Learning State

## Phase

PHASE 3 — ISSUE-DRIVEN LEARNING / CONTRIBUTION DISCOVERY

## Current subsystem

Driver Runtime — Daemon lifecycle

## Active investigation

Active-request process death, uncertain execution, and retry/error-contract
classification.

## Understanding level

YELLOW overall.

- **GREEN enough:** happy path and observation/targeting boundaries.
- **GREEN enough:** between-request Daemon replacement/session recovery.
- **GREEN enough:** active-request execution/acknowledgement ambiguity.
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

## Live checkout grounding

- source repository: `../cua/`
- branch: `main`
- commit: `72fe7fff6e2d84863585f7164d9663367e8fa465`
- known pre-existing untracked paths remain untouched:
  `libs/cua-driver/rust/target 2/` and
  `libs/fleet/sdk-bindings/kotlin/.gradle/`

## Current exact engineering question

> Should we commit serious contribution time to a maintainer discussion about
> distinguishing pre-dispatch transport failure from post-write
> execution-outcome-unknown failure, without attempting replay or exactly-once
> execution?

## Immediate next work

1. Stop for the human's contribution-commitment decision.
2. If approved, prepare a maintainer-facing problem statement with reproduction,
   invariant, related context, non-goals, and error-contract alternatives.
3. Seek maintainer direction before implementation because issue creation is
   restricted and the change affects a cross-platform public contract.
4. Only then enter design, planning, and TDD for an approved direction.

## Durable visuals

- `subsystems/driver-runtime/driver_runtime_mind_map.png` — current subsystem
  architecture and retained conclusions.
- `subsystems/driver-runtime/daemon-lifecycle/daemon_lifecycle_session_recovery.png`
  — between-request state/recovery model and user-approved reference style for
  future retention maps.
- `subsystems/driver-runtime/daemon-lifecycle/active-request-death/active_request_uncertain_outcome.png`
  — active-request experiment and knowledge boundary.

## Stop boundary

Do not repeat the marker, broaden issue discovery, choose an error schema,
open/comment on an issue, or modify Cua source without human contribution
commitment and maintainer alignment.

## Pointers

- `subsystems/driver-runtime/README.md`
- `subsystems/driver-runtime/happy-path/README.md`
- `subsystems/driver-runtime/failures/README.md`
- `subsystems/driver-runtime/daemon-lifecycle/README.md`
- `subsystems/driver-runtime/daemon-lifecycle/between-requests/README.md`
- `subsystems/driver-runtime/daemon-lifecycle/active-request-death/README.md`
