# Current Cua Learning State

## Phase

PHASE 3 — ISSUE REPRODUCTION / CONTRIBUTION PREPARATION

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
- **GREEN enough:** contribution fit and classification as an RFC 2549
  implementation/parity gap.
- **GREEN enough:** the human's plain-language HLD and failure explanation for
  issue #2686's Python SDK → Daemon → Linux `type_text` timeout path.
- **GREEN enough:** isolated Linux/X11 Python SDK → Daemon short-text baseline.
- **YELLOW:** independent runtime reproduction of #2686, PR #2743's
  implementation/test, maintainer selection, and code.

## Assistance and proof state

- external proof stage: **3 — existing issue/PR matched**; the human has not yet
  published maintainer-visible evidence or review
- vocabulary/concepts: **SHARED** for SDK, execution backend, Daemon, Unix
  socket, timeout, and non-idempotent retry
- HLD reconstruction: **SHARED** for the #2686 path
- LLD/source navigation: **GUIDED**
- failure reasoning: **SHARED**
- test design: **GUIDED**
- contribution/design decisions: **GUIDED**

The human can now explain without repeating a generated summary that the SDK
sends a complete request over a Unix socket, the separate Daemon performs the
Linux keyboard effect, Linux's 10 ms per-character pacing makes 16,000
characters take about 160 seconds, and the SDK's 120-second response wait does
not cancel the Daemon. Therefore the timeout leaves completion unknown and a
blind full retry can duplicate or corrupt target state.

Valid #2686 healthy baseline on 2026-09-11:

- current Cua commit `648c251400ebb356f6d7dbc3d0c835690b9bb4b4`;
- disposable Ubuntu 24.04 Linux arm64 container with Xvfb, Openbox, GTK3, the
  real compiled Cua Daemon, and generated Python SDK/native library;
- exact-window foreground click established focus, followed by the original
  desktop-scope Python `type_text` path;
- marker `CUA_2686_HEALTHY` arrived exactly in the GTK entry;
- Python returned success in 0.197 seconds;
- the Daemon remained alive.

Earlier ambient-focus setup attempts delivered only suffixes and an exact-window
typed call returned the expected background-unavailable refusal. These were
invalid baseline setups, not #2686 results. No long-text action has run yet.

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

Current classification and selected direction:

- not a proven automatic-retry bug;
- expected uncertainty under the current protocol;
- credible client-visible completion-reporting parity bug;
- human-selected Approach 3: shared common-transport classification mapped to
  existing SDK `ActionInterrupted` and additive MCP completion data;
- no `retry_safe` flag; the agent owns observation/reconciliation and an
  external supervisor/host owns only Daemon availability;
- RFC 2549 already requires honest interrupted-action completion reporting and
  MCP/Daemon/SDK parity; PR #2561 implemented that architecture;
- no new RFC is needed. The ordinary Daemon/MCP behavior is a focused gap against
  the existing contract.

Candidate invariant:

> After request dispatch, a client-visible transport failure must not imply
> “not executed” or “safe to retry”; execution outcome must be unknown.

Approved contract: failure before the first write attempt is `NotStarted`;
failure after a write attempt begins is `Unknown`. SDK Daemon actions reuse
`DriverError::ActionInterrupted`; MCP retains `-32603` and gains optional
structured completion data. Automatic replay, deduplication, exactly-once
claims, Daemon supervision, and state mutation are explicit non-goals.

Local external-form artifact:
`subsystems/driver-runtime/daemon-lifecycle/active-request-death/external-bug-form-draft.md`.
It has not been posted. The visual is local-only and must not be uploaded with
the external report.

Existing-work inventory (2026-09-09):

- #2686 has open PR #2743 and is the closest existing expression of the
  action-exceeds-response-boundary problem. The PR remains the existing-work
  path, but on 2026-09-10 it was `CHANGES_REQUESTED`, merge-conflicted, 594
  commits behind current `origin/main`, and unchanged since 2026-08-27.
- RFC #2549 and its implementation PR #2561 are merged work, not a new work
  item to claim.
- #2002 and #3241 are adjacent macOS lifecycle investigations, but neither is
  the current execution/response boundary.
- #2079 is stale against current `main`; #3191 and #3337 are closed by merged
  work.

## Live checkout grounding

- source repository: `../cua/`
- worktree branch: `main`
- worktree and `origin/main` commit:
  `648c251400ebb356f6d7dbc3d0c835690b9bb4b4`
- known pre-existing untracked paths remain untouched:
  `libs/cua-driver/rust/target 2/` and
  `libs/fleet/sdk-bindings/kotlin/.gradle/`

## Current exact engineering question

> On the verified isolated Linux/X11 Python SDK → Daemon path, does a
> 16,000-character `type_text` make Python time out near 120 seconds while the
> Daemon remains alive and the target continues changing?

## Immediate next work

1. Stop for the human's exact long-run prediction now that the healthy baseline
   is verified.
2. Run one 16,000-character action without retry. Observe Python elapsed/error,
   Daemon liveness, and target character count at the client timeout and after
   the expected Daemon completion window.
3. Compare the result with the fixed-120-second source model and classify
   OBSERVED / SOURCE-VERIFIED / UNKNOWN.
4. Only after valid evidence, inspect #2743 line by line and have the human
   identify what it fixes and what remains unproven or incorrect.
5. Decide whether a technically useful public review is warranted. Keep the
   bug draft and contract visual local-only.

## Durable visuals

- `subsystems/driver-runtime/driver_runtime_mind_map.png` — current subsystem
  architecture and retained conclusions.
- `subsystems/driver-runtime/daemon-lifecycle/daemon_lifecycle_session_recovery.png`
  — between-request state/recovery model and user-approved reference style for
  future retention maps.
- `subsystems/driver-runtime/daemon-lifecycle/active-request-death/active_request_uncertain_outcome.png`
  — active-request experiment and knowledge boundary.
- `subsystems/driver-runtime/daemon-lifecycle/active-request-death/interrupted_action_reporting_contract.png`
  — approved shared transport/SDK/MCP/recovery ownership proposal.

## Stop boundary

Do not repeat the marker, create a new RFC, open/comment on a new bug issue,
upload the visual externally, comment on #2743, or modify Cua source. The
existing #2743 findings are a preliminary Codex-only audit, not a human-owned
review conclusion. Complete architecture understanding and a valid #2686
reproduction before returning to the PR. Maintainer renewal/selection remains
mandatory before implementation.

## Pointers

- `subsystems/driver-runtime/README.md`
- `subsystems/driver-runtime/happy-path/README.md`
- `subsystems/driver-runtime/failures/README.md`
- `subsystems/driver-runtime/daemon-lifecycle/README.md`
- `subsystems/driver-runtime/daemon-lifecycle/between-requests/README.md`
- `subsystems/driver-runtime/daemon-lifecycle/active-request-death/README.md`
- `subsystems/driver-runtime/daemon-lifecycle/active-request-death/external-bug-form-draft.md`
- `subsystems/driver-runtime/daemon-lifecycle/active-request-death/interrupted_action_reporting_contract.png`
