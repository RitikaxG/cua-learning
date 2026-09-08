# Current Cua Learning State

## Phase

PHASE 3 — ISSUE-DRIVEN LEARNING / CONTRIBUTION DISCOVERY

## Current subsystem

Driver Runtime

## Active investigation

Daemon lifecycle / active-request process death and retry ambiguity

## Understanding level

YELLOW overall.

The **between-request Daemon replacement/session-recovery slice is GREEN enough to move on**. Process/data-plane recovery, old-session lazy admission, state ownership, control-liveness semantics, and idle fallback cleanup are understood.

The active-request failure boundary remains YELLOW because Daemon disappearance during an executing tool call has not yet been traced or reproduced.

## Completed enough

- happy path
- observation/targeting failures
- process/transport lifecycle
- Proxy `session_id` purpose
- persistent `session_begin(session_id)` control-connection purpose
- Daemon disappearance before the next request
- manual replacement-Daemon data-plane recovery
- replacement-Daemon admission of an old Proxy session
- identity continuity vs Daemon-state continuity
- lazy recreation of Daemon-side lifecycle/session state
- immediate control-EOF cleanup vs idle-TTL fallback cleanup
- replacement session expiring while Proxy and Daemon processes both remain alive

## Established lifecycle model

- Normal tool calls use fresh Unix data-plane connections.
- Proxy and Daemon are separate process/failure domains.
- Proxy owns logical session identity/MCP continuity and stamps its internal `session_id` on later requests.
- Daemon owns process-local lifecycle/activity/in-flight bookkeeping and session-owned runtime state.
- The persistent `session_begin(session_id)` control connection provides a direct liveness / immediate-cleanup relationship; it is not a universal admission gate for every session-owned action.
- When the old Daemon disappears, its listener, process memory, and old control connection disappear while the Proxy and its old `session_id` may survive.
- The surviving Proxy's established control task does not automatically reconnect to a replacement Daemon in the traced source.
- A manually restored Daemon at the same socket address can be reached through later fresh per-tool connections.
- An unknown, non-ended old session identity can be lazily admitted by the replacement Daemon.
- Lazy admission creates fresh Daemon-side lifecycle/activity state and allows fresh session-owned state under the same logical identity.
- This is **identity reuse + fresh state creation**, not old Daemon-state recovery.
- Without a restored control relationship, immediate Proxy-liveness cleanup is unavailable for the replacement-created S1.
- The implicitly admitted S1 still participates in activity tracking: default idle TTL is 300 seconds, maintenance sweeps about every 30 seconds, and stale sessions with no in-flight dispatch are ended through the normal session-end path.
- Proxy-process liveness and replacement-Daemon session liveness can diverge: the Proxy may still run while an inactive S1 has already become ended/tombstoned.

## Corrected inferences

1. Earlier expectation: stateful/session-owned work should be rejected without a new `session_begin(S1)`.
   - Corrected by runtime evidence: `set_agent_cursor_enabled(S1)` succeeded on the replacement Daemon; an unknown, non-ended S1 can be lazily admitted.
2. Earlier concern: recreated S1 state might remain permanently orphaned without a restored control connection.
   - Corrected: control EOF provides immediate cleanup, but inactivity-based lifecycle cleanup remains as fallback. The old S1 later became ended while both the same Proxy and replacement Daemon were still alive.

## Latest runtime evidence

Valid manual reproduction:

- Proxy PID: `14126`
- old Daemon PID: `48613`
- replacement Daemon PID: `19835`
- Proxy session: `mcp-14126-1788769126087137000`
- pre-break `set_agent_cursor_enabled(enabled=true)`: succeeded
- after replacement, same Proxy `list_apps`: succeeded
- after replacement, same Proxy `set_agent_cursor_enabled(enabled=true)`: succeeded with the same old session identity
- after a later idle period, `get_agent_cursor_state` for the same S1 was rejected because the session had ended
- Proxy `14126` and replacement Daemon `19835` were both still alive at that later check

Evidence boundary:

- **OBSERVED:** old S1 was accepted/recreated, then later became ended while both processes stayed alive.
- **SOURCE-VERIFIED:** implicit lifecycle/activity tracking, 300-second default idle TTL, ~30-second sweep, in-flight protection, normal session-end hooks, traced cursor/config cleanup.
- **STRONG INFERENCE:** the observed S1 expiry was caused by the idle reaper; macOS logs did not directly expose the exact end reason.

## Tested / not tested

**TESTED:**

- Daemon dead before the next request.
- same Proxy reaches a manually restored replacement Daemon.
- replacement accepts a stateless call carrying the old Proxy session.
- replacement accepts/recreates clearly session-owned cursor state under the old Proxy session without a restored persistent control connection.
- same Proxy and same replacement Daemon remain alive while inactive old S1 later becomes ended and rejects further calls.

**NOT TESTED:**

- Daemon disappears during an active request.
- action executes but response is lost.
- partial / uncertain execution outcome.
- retry safety for mutating tool calls.
- request-level idempotency/deduplication guarantees.
- every session-owned resource family under replacement/recovery.

## Current exact engineering question

When the Daemon disappears **during an active tool request**, after dispatch may have started and an action may already have happened but before the Proxy receives a response:

> **What can the Proxy/caller actually know about whether the action executed, and what retries are safe?**

## Next bounded investigation

1. Ground in the current local Cua checkout: instructions, branch, commit, working tree.
2. Trace only the active-request path needed for this question: Proxy write/read/error path → Daemon receive/session admission → tool execution start → `in_flight` bookkeeping → one candidate operation's effect boundary → response serialization/write → any retry/request-id/idempotency/dedup mechanism.
3. Separate SOURCE-VERIFIED / INFERENCE / UNKNOWN.
4. Establish the acknowledgement/uncertain-execution invariant before choosing a runtime break.
5. Identify one safe, observable, controllable operation for a future mid-request experiment.
6. Ask the user for a prediction before the runtime break.
7. Run the first important lifecycle reproduction interactively as Human + ChatGPT when exact process/session/request preservation matters; Codex may automate/repeat later.
8. Do not propose a retry/idempotency fix before expected vs actual behavior is established.

## Durable visuals

Keep these two diagrams for the completed lifecycle slice because they preserve different durable views:

- `subsystems/driver-runtime/daemon-lifecycle/daemon_lifecycle_break_flowchart.png` — original Daemon-loss/failure/recovery sequence.
- `subsystems/driver-runtime/daemon-lifecycle/daemon_lifecycle_session_recovery.png` — consolidated session-recovery, ownership, and cleanup model after the later experiments.

Scratch/intermediate reasoning diagrams are not retained by default.

## Stop boundary

Do not implement a retry/idempotency fix, choose an architecture, broad-recon the repo, or claim active-request failure behavior yet.

First establish the active-request execution → possible effect → response boundary from current local source. Ask for the user's prediction before the first runtime reproduction.

## Pointers

- `subsystems/driver-runtime/README.md`
- `subsystems/driver-runtime/happy-path/README.md`
- `subsystems/driver-runtime/failures/README.md`
- `subsystems/driver-runtime/daemon-lifecycle/README.md`
- `subsystems/driver-runtime/daemon-lifecycle/daemon_lifecycle_break_flowchart.png`
- `subsystems/driver-runtime/daemon-lifecycle/daemon_lifecycle_session_recovery.png`
