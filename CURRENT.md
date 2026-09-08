# Current Cua Learning State

## Phase

PHASE 3 — ISSUE-DRIVEN LEARNING / CONTRIBUTION DISCOVERY

## Current subsystem

Driver Runtime

## Active investigation

Daemon lifecycle / active-request process death and retry ambiguity

## Understanding level

YELLOW overall.

The **between-request Daemon replacement/session-recovery slice is GREEN enough
to move on**: process/data-plane recovery, old-session lazy admission, state
ownership, control-liveness semantics, and idle fallback cleanup are understood.

The active-request failure boundary is still YELLOW because Daemon death during
an executing tool call has not yet been traced or reproduced.

## Completed enough

- happy path
- observation/targeting failures
- process/transport lifecycle
- Proxy `session_id` purpose
- persistent `session_begin(session_id)` control-connection purpose
- Daemon death before the next request
- manual replacement-Daemon data-plane recovery
- replacement-Daemon admission of an old Proxy session
- identity continuity vs Daemon-state continuity
- lazy recreation of Daemon-side lifecycle/session state
- immediate control-EOF cleanup vs idle-TTL fallback cleanup
- replacement session expiring while Proxy and Daemon processes both remain alive

## Established lifecycle model

- Normal tool calls use fresh Unix data-plane connections.
- Proxy and Daemon are separate process/failure domains.
- Proxy mints one internal `session_id` and stamps it on later requests.
- Proxy owns logical session identity/MCP continuity.
- Daemon owns process-local lifecycle records, activity/in-flight bookkeeping,
  and session-owned runtime state such as the traced cursor/config state.
- Proxy also opens one persistent control connection and sends
  `session_begin(session_id)`.
- That persistent connection primarily supplies a direct liveness / immediate
  cleanup relationship; it is not a universal admission gate for every
  session-owned action.
- When the old Daemon dies, its listener, process memory, and old control
  connection disappear while the Proxy and its old `session_id` may survive.
- The surviving Proxy's established control task does not automatically
  reconnect to a replacement Daemon in the traced source.
- A manually restored Daemon at the same socket address can be reached by the
  same Proxy through later fresh per-tool connections.
- An unknown, non-ended old session identity can be lazily/implicitly admitted
  by the replacement Daemon on an ordinary session-requiring action.
- Lazy admission creates a fresh Daemon-side `LifecycleRecord` / activity state
  and allows fresh session-owned state under the same logical identity.
- This is **identity reuse + fresh state creation**, not old Daemon memory/state
  recovery.
- Therefore replacement behavior can provide **session-identity continuity
  without state continuity and without restored control-liveness continuity**.
- Without the restored persistent control relationship, immediate Proxy-death
  EOF cleanup is unavailable for that replacement-created S1.
- The implicitly admitted S1 still participates in normal lifecycle/activity
  tracking: default idle TTL is 300 seconds, lifecycle maintenance sweeps about
  every 30 seconds, and stale sessions with no in-flight dispatch are ended
  through the normal session-end path.
- Normal admitted activity refreshes the session activity timestamp.
- Proxy process liveness and replacement-Daemon session liveness can diverge:
  the Proxy may still run while an inactive S1 has already become ended /
  tombstoned at the replacement Daemon.

## Corrected inferences

### Corrected inference 1

Earlier expectation:

> Stateless work may recover, but session-owned/stateful work should be rejected
> by a replacement Daemon that never received a new `session_begin(S1)`.

Observed behavior contradicted this. `set_agent_cursor_enabled(S1)` succeeded on
the replacement Daemon using the same old S1. An unknown, non-ended session can
be lazily admitted.

### Corrected inference 2

Earlier concern:

> Without a restored control connection, replacement-created S1 state may become
> permanently orphaned because later Proxy death cannot signal EOF to the new
> Daemon.

This was too strong. The control connection supplies immediate liveness-based
cleanup, but implicitly admitted state still has inactivity-based lifecycle
cleanup. Runtime evidence later showed S1 had become ended while both the same
Proxy and same replacement Daemon were still alive.

## Latest runtime evidence

Valid manual reproduction used a fresh Proxy whose healthy baseline was observed
before the break:

- Proxy PID: `14126`
- old Daemon PID: `48613`
- replacement Daemon PID: `19835`
- Proxy session: `mcp-14126-1788769126087137000`
- pre-break `set_agent_cursor_enabled(enabled=true)`: succeeded
- after replacement, same Proxy `list_apps`: succeeded
- after replacement, same Proxy `set_agent_cursor_enabled(enabled=true)`:
  succeeded and returned the same old session identity

After a later idle period, before killing the Proxy:

- `get_agent_cursor_state` for the same S1 was rejected because the session had
  ended;
- Proxy `14126` was still alive;
- replacement Daemon `19835` was still alive.

macOS unified-log checks did not expose a session-specific line proving this
exact transition's end reason was `IdleTimeout`.

Evidence classification:

**OBSERVED**

- same Proxy and same replacement Daemon stayed alive;
- old S1 had previously been admitted and used for session-owned cursor state;
- later old S1 was ended and rejected.

**SOURCE-VERIFIED**

- implicit session lifecycle/activity tracking;
- 300-second default idle TTL;
- ~30-second maintenance sweep;
- in-flight protection;
- idle expiry uses normal session-end hooks;
- traced cursor/config cleanup path.

**STRONG INFERENCE**

- the observed old-S1 expiry was caused by the idle reaper.

A separate earlier Codex attempt using old Proxy PID `69593` correctly stopped as
**NOT TESTED** because its required live pre-break control relationship was
already absent. That reinforced the clean-baseline rule now recorded in
`WORKFLOW.md`.

## Tested / not tested

**TESTED:**

- Daemon dead **before** the next request.
- same Proxy reaches a manually restored replacement Daemon.
- replacement Daemon accepts a stateless call carrying the old Proxy session.
- replacement Daemon accepts/recreates clearly session-owned cursor state under
  the old Proxy session without a restored persistent control connection.
- same Proxy and same replacement Daemon remain alive while inactive old S1
  later becomes ended and rejects further calls.

**NOT TESTED:**

- Daemon dies **during** an active request.
- a tool side effect happens but the response is lost.
- partial execution / uncertain execution outcome.
- retry safety for mutating tool calls.
- request-level idempotency/deduplication guarantees.
- every session-owned resource family under replacement/recovery.

## Current exact engineering question

When the Daemon dies **during an active tool request**, after dispatch may have
started and a side effect may already have happened but before the Proxy receives
a response:

> **What can the Proxy/caller actually know about whether the action executed,
> and what retries are safe?**

## Next bounded investigation

1. Read the current local Cua repository instructions and confirm local branch,
   commit, and working-tree state.
2. Trace only the active-request path needed for this question:
   - Proxy per-tool request write/read/error path;
   - Daemon request receive and session-dispatch admission;
   - point where tool execution begins;
   - `in_flight` lifecycle bookkeeping;
   - side-effect boundary for one candidate operation;
   - response serialization/write back to Proxy;
   - any retry, request-id, idempotency, or deduplication mechanism.
3. Separate SOURCE-VERIFIED / INFERENCE / UNKNOWN.
4. Establish the acknowledgement/uncertain-execution invariant before choosing
   a runtime break.
5. Identify one **safe, observable, controllable** operation for a future
   mid-request failure experiment. Do not use an irreversible/destructive action
   merely to create a timing window.
6. Ask the user for a prediction before any runtime break.
7. If the first important reproduction depends on preserving an exact
   Proxy/Daemon/request and killing one process at a precise boundary, run it
   interactively as Human + ChatGPT. Codex may later automate/repeat with a
   deterministic harness.
8. Do not propose a fix/retry architecture until expected vs actual behavior and
   ambiguous side-effect boundaries are established.

## Experiment execution note

Use Codex for bounded source tracing and deterministic tests/harnesses it can own
from a clean baseline.

For the first important lifecycle/failure reproduction whose correctness depends
on preserving an exact live process/session/request relationship while breaking
another component, prefer Human + ChatGPT interactive execution.

## Visual learning note

All meaningful diagrams the user deliberately creates for understanding should
be retained with the relevant investigation and indexed/embedded from its
README. Do not discard earlier useful mental-model images merely because a later
polished study map exists; label superseded inferences in text when needed.

Current daemon-lifecycle visuals:

- `subsystems/driver-runtime/daemon-lifecycle/daemon_lifecycle_break_flowchart.png`
- `subsystems/driver-runtime/daemon-lifecycle/daemon_lifecycle_session_recovery.png`

## Stop boundary

Do not implement a retry/idempotency fix, choose an architecture, broad-recon the
repo, or claim active-request failure behavior yet.

First establish the active-request execution → possible side effect → response
boundary from current local source. Ask for the user's prediction before the
first runtime reproduction.

## Pointers

- `subsystems/driver-runtime/README.md`
- `subsystems/driver-runtime/happy-path/README.md`
- `subsystems/driver-runtime/failures/README.md`
- `subsystems/driver-runtime/daemon-lifecycle/README.md`
- `subsystems/driver-runtime/daemon-lifecycle/daemon_lifecycle_break_flowchart.png`
- `subsystems/driver-runtime/daemon-lifecycle/daemon_lifecycle_session_recovery.png`
