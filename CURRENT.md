# Current Cua Learning State

## Phase

PHASE 3 — ISSUE-DRIVEN LEARNING / CONTRIBUTION DISCOVERY

## Current subsystem

Driver Runtime

## Active investigation

Daemon lifecycle / replacement-Daemon session admission and cleanup ownership

## Understanding level

YELLOW

The process/data-plane and control-connection model is understood well enough to
reason about Daemon replacement. Cleanup ownership for state recreated after
replacement is still unresolved.

## Completed enough

- happy path
- observation/targeting failures
- process/transport lifecycle
- Proxy `session_id` purpose
- persistent `session_begin(session_id)` control-connection purpose
- replacement-Daemon admission of an old Proxy session

## Current lifecycle model

- Proxy survives Daemon death.
- Dead Daemon → next fresh connection gets `Connection refused`.
- No automatic steady-state Daemon restart occurred.
- Normal tool calls use fresh data-plane connections.
- Proxy mints one internal `session_id` and stamps it on later requests.
- Proxy also opens one persistent control connection and sends
  `session_begin(session_id)`; that connection represents liveness/cleanup
  ownership.
- When the Daemon dies, the old control connection and old Daemon process memory
  disappear.
- The surviving Proxy keeps its old `session_id`, but its control-connection task
  does not automatically reconnect to a replacement Daemon.
- A manually restored Daemon at the same socket address can be reached by the
  same Proxy.
- **Observed:** the replacement Daemon accepted both a stateless `list_apps`
  call and a session-owned `set_agent_cursor_enabled` call from the surviving
  Proxy using its old `session_id`, despite no new `session_begin` being sent to
  the replacement Daemon.
- Therefore current behavior provides **session-identity continuity without
  restored control-liveness continuity**.
- Old Daemon-owned in-memory cursor/config/recording state does not survive the
  process death; the replacement can create fresh state under the same old
  session identity.
- Cleanup ownership for that newly created state after the surviving Proxy later
  dies is unresolved.

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

The user's prediction was that stateless work could recover but session-owned
work should be rejected without a restored live control relationship. The
observed behavior did **not** match that prediction.

A separate Codex attempt using an already-existing Proxy PID `69593` correctly
stopped as **NOT TESTED** because that Proxy had no observable live control
connection before the proposed break. It was not a valid one-variable lifecycle
baseline.

## Tested / not tested

**TESTED:**

- Daemon dead **before** the next request.
- same Proxy reaches a manually restored replacement Daemon.
- replacement Daemon accepts a stateless call carrying the old Proxy session.
- replacement Daemon accepts/recreates session-owned cursor state under the old
  Proxy session without a restored persistent control connection.

**NOT TESTED:**

- whether recreated state becomes orphaned when the surviving Proxy later dies.
- whether an idle-TTL/reaper or another fallback eventually cleans that state.
- Daemon dies **during** an active request.
- partial execution and retry safety.

## Current exact engineering question

When a replacement Daemon creates session-owned state for an old `session_id`
without a restored persistent control connection, what mechanism owns the
lifecycle of that state, and what happens when the surviving Proxy later dies?

## Next bounded investigation

1. Inspect only the source necessary to understand cleanup/liveness for an
   implicitly admitted session that has no active Proxy control connection.
2. Trace `session_end`, lifecycle records, idle activity/TTL eviction, cursor
   cleanup hooks, and any distinction between active control registration and
   implicit first-action session state.
3. Compare only the relevant design intent in `#1777` / PR `#1779`, especially
   deferred daemon-restart-mid-session control reconnection.
4. Classify SOURCE-VERIFIED / INFERENCE / UNKNOWN.
5. Establish the expected cleanup invariant.
6. Ask the user for a prediction before any new runtime break.
7. If runtime evidence is needed, run one narrow Proxy-death cleanup
   reproduction using the same replacement-Daemon state; do not expand into
   active-request failure yet.

## Experiment execution note

For lifecycle/failure experiments whose correctness depends on preserving an
exact live Proxy/MCP session/control relationship while selectively killing or
restarting another process, prefer the **first important reproduction** as an
interactive Human + ChatGPT run after Codex supplies the bounded source trace.

Codex may run the first reproduction only when it can create and verify the
entire clean baseline itself, including all process/session/control
relationships required by the hypothesis. A pre-existing MCP route is not a
valid lifecycle baseline merely because tool calls succeed.

After the behavior is understood, Codex may automate/repeat the experiment with
a deterministic harness.

## Stop boundary

Do not implement a fix, choose a recovery architecture, broad-reconnoiter the
repo, or test Daemon death during an active request.

First establish the cleanup/liveness contract for state recreated under the old
session identity without a restored control connection. Ask for the user's
prediction before the next runtime reproduction.

## Pointers

- `subsystems/driver-runtime/README.md`
- `subsystems/driver-runtime/happy-path/README.md`
- `subsystems/driver-runtime/failures/README.md`
- `subsystems/driver-runtime/daemon-lifecycle/README.md`
- `subsystems/driver-runtime/daemon-lifecycle/daemon_lifecycle_break_flowchart.png`
