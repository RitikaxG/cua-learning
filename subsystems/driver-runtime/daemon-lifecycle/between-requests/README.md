# Daemon Lifecycle — Between Requests

## Engineering question

What survives, fails, and recovers when the long-running Daemon disappears
between tool calls while the MCP Proxy and logical session remain alive?

## Canonical visual

![Daemon lifecycle and session recovery](../daemon_lifecycle_session_recovery.png)

## Established model

```text
healthy Proxy owns logical session identity S1
→ persistent session_begin(S1) control connection exists
→ each tool call uses a fresh data-plane connection

old Daemon dies between requests
→ old listener, process memory, lifecycle state, and control connection vanish
→ Proxy and S1 may survive
→ socket pathname may remain without a listener

replacement Daemon binds the same address
→ later fresh data-plane calls can reach it
→ old, non-ended S1 can be lazily admitted
→ fresh lifecycle/session state is created under S1
→ old Daemon memory is not recovered

no restored control connection
→ no immediate Proxy-liveness cleanup for recreated S1
→ activity tracking and idle TTL remain
→ idle expiry invokes normal session-end cleanup
```

The concise ownership rule is:

> **Proxy owns identity continuity. Daemon owns process-local runtime state.**

## Experiment 1 — Daemon dead before the next request

Only the Daemon was terminated while the Proxy and MCP session stayed alive.

Observed:

- old Daemon PID `5263` exited;
- Proxy PID `69593` survived;
- the socket pathname remained but no listener existed;
- the next `list_apps` failed with `Connection refused`;
- no automatic steady-state Daemon restart appeared.

Conclusion:

```text
socket pathname exists ≠ listener exists ≠ Daemon is alive
startup ownership ≠ steady-state supervision
```

## Experiment 2 — manual replacement restores the data plane

A replacement Daemon was started manually at the same socket address while the
same Proxy/session survived.

Observed:

- the replacement bound the expected socket;
- the same Proxy/session called `list_apps` successfully;
- no new Proxy was required.

This works because ordinary tool calls open a new Unix connection per request.
It proves data-plane recoverability after external restoration, not old-state
recovery.

## Experiment 3 — old session identity on a replacement

Clean baseline:

- Proxy `14126`;
- old Daemon `48613`;
- replacement Daemon `19835`;
- session `mcp-14126-1788769126087137000`;
- pre-break session-owned cursor operation succeeded.

After replacing only the Daemon, the same surviving Proxy and old S1 performed:

- `list_apps(S1)` — succeeded;
- `set_agent_cursor_enabled(S1)` — succeeded.

The replacement had never received a new persistent `session_begin(S1)`.
Source inspection showed that an unknown, non-ended session can be admitted on
ordinary session-requiring work. Admission creates a fresh `LifecycleRecord`,
activity timestamp, and new session-owned state.

Conclusion:

> **Identity reuse + fresh state creation is not state recovery.**

## Experiment 4 — cleanup without control reconnect

After a later idle period, `get_agent_cursor_state(S1)` reported that S1 had
ended and rejected the call. The same Proxy `14126` and replacement Daemon
`19835` were still alive.

Source verified:

- implicit admission creates lifecycle/activity tracking;
- default idle TTL is 300 seconds;
- maintenance sweeps roughly every 30 seconds;
- in-flight calls are protected from idle eviction;
- idle expiry uses normal session-end hooks;
- the traced macOS hook clears cursor/config state.

The exact runtime end reason was not present in the available macOS logs, so
idle-reaper causation remains a strong inference rather than direct observation.

## Control-plane meaning

The persistent `session_begin(S1)` connection is not a universal admission gate.
Its main lifecycle guarantee is prompt owner-liveness cleanup:

```text
healthy Proxy dies
→ control connection EOF
→ session_end(S1)
→ cleanup hooks run immediately
```

After Daemon replacement, the surviving Proxy's old control task does not
reconnect in the traced source. The recreated S1 therefore has identity and
fresh state but no restored control-liveness relationship. Idle TTL is the
delayed fallback.

## Corrected inferences

1. **Rejected:** a replacement must reject stateful work without a new
   `session_begin(S1)`.
   - Runtime showed lazy admission and fresh state creation.
2. **Rejected:** recreated state becomes permanently orphaned without control
   reconnect.
   - Runtime showed S1 later became ended while both processes remained alive;
     source provides the idle-TTL cleanup path.

## Evidence boundary

### OBSERVED

- failure before the next request returns `Connection refused`;
- Proxy/session identity can survive Daemon death;
- later fresh connections reach a manually restored Daemon;
- an old session identity can be lazily admitted;
- replacement-created S1 later became ended while Proxy and Daemon stayed alive.

### SOURCE-VERIFIED

- one fresh data-plane connection per ordinary call;
- persistent control connection and EOF cleanup;
- lazy session admission;
- lifecycle/activity/in-flight bookkeeping;
- default TTL, maintenance sweep, and session-end hooks.

### STRONG INFERENCE

- the observed later S1 expiry was caused by the idle reaper.

### NOT ESTABLISHED FOR EVERY RESOURCE

- replacement and cleanup semantics for every session-owned resource family.

## Source landmarks

- `libs/cua-driver/rust/crates/cua-driver/src/proxy.rs` — Proxy session identity,
  control connection, and per-call forwarding.
- `libs/cua-driver/rust/crates/cua-driver/src/serve.rs` — Daemon connection
  handlers and session dispatch.
- `libs/cua-driver/rust/crates/cua-driver-core/src/session.rs` — session lifecycle
  and end hooks.
- macOS cursor/config registries — traced session-owned cleanup.

## Status

This between-request replacement/session-cleanup slice is GREEN enough. Do not
repeat it unless new evidence contradicts the model or a regression test becomes
part of an approved contribution.
