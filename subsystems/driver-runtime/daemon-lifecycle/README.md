# Cua Driver — Daemon Lifecycle / Recovery

## Investigation goal

Understand what breaks, survives, and recovers when the long-running Daemon
disappears while an MCP Proxy and session remain alive. The current boundary is
data-plane recovery versus control-session/daemon-owned-state recovery.

## Lifecycle break flowchart

![Cua Driver daemon lifecycle break](./daemon_lifecycle_break_flowchart.png)

## Healthy runtime design

```text
MCP Client → cua-driver mcp Proxy → Unix socket → Cua Daemon → Driver
```

- **Data plane:** a fresh Unix connection for each normal tool call.
- **Control plane:** a persistent `session_begin(session_id)` connection for
  session lifetime and cleanup ownership.

Lifecycle baseline: Daemon PID 5263 (`CuaDriver.app` `cua-driver serve`), Proxy
PID 69593 (`cua-driver mcp`), socket
`~/Library/Caches/cua-driver/cua-driver.sock`; `list_apps` succeeded.

## Experiment 1 — Daemon dead before next request

### Prediction

The next call would reveal whether the Proxy/session survived, how the missing
Daemon failure crossed MCP, and whether anything restarted it.

### Baseline

The Daemon, Proxy, MCP session, socket path, and `list_apps` were healthy.

### Break introduced

Only the Daemon was terminated. It was dead **before** the next `list_apps`.
This is not a Daemon-dies-during-request test.

### Exact observed result

- Old Daemon PID 5263 was gone; Proxy PID 69593 and the MCP session survived.
- The socket pathname remained, but no Daemon listener existed.
- No replacement `cua-driver serve` appeared.
- The first and second `list_apps` calls through the same session failed with a
  daemon transport/MCP tool error caused by `Connection refused`.
- No automatic recovery occurred.

### Where the request failed

```text
MCP Client → existing Proxy → fresh Unix connect → no Daemon listener
→ Connection refused → Proxy transport/MCP tool error → Agent tool failure
```

### What survived

- MCP client/session
- Proxy process
- socket pathname

### What disappeared

- Daemon process and Unix listener
- old Daemon process memory
- old persistent Proxy ↔ Daemon control connection

### What this proves

The Proxy and Daemon are separate failure domains. A later data-plane call uses
a fresh connection and fails at the absent listener. The running Proxy did not
automatically restart the Daemon.

### What this does NOT prove

It does not describe Daemon death during an active request, partial execution,
retry safety, or a replacement Daemon's control/session relationship with the
old Proxy.

## Unix socket lifecycle

```text
socket pathname exists
!= listener exists
!= Daemon alive
```

After Daemon death, the pathname remained. Source inspection established that a
replacement startup can remove/replace a stale endpoint and bind a **new** Unix
listener at the same configured path. The path is an address, not proof of the
same listener or process.

## Startup ownership vs steady-state supervision

At Proxy startup, source inspection showed: check Daemon liveness, launch
`CuaDriver.app` / `serve` if needed on macOS, wait, then enter Proxy operation.
Later per-tool forwarding does not invoke that path.

```text
startup auto-launch != steady-state Daemon supervision
```

## Experiment 2 — manually restore replacement Daemon

### Prediction

Fresh per-tool connections could reach a replacement Daemon at the same address
without replacing the Proxy or MCP session.

### Setup

The same MCP client, session, and Proxy PID 69593 remained alive. A replacement
Daemon, PID 48613, was manually started at the same socket pathname.

### Observed result

The same Proxy/session then called `list_apps` successfully. No new Proxy was
required.

### Why it recovered

```text
tool call → UnixStream::connect(socket) → request → response → connection ends
next tool call → another fresh connection
```

Once the replacement listened at the same address, the next fresh connection
reached the new process.

### What this proves

**Automatic Daemon recovery:** not observed.

**Data-plane transport recoverability after external/manual restore:** verified.

### What this does NOT prove

Successful `list_apps` does not prove that control registration or daemon-owned
state was reconstructed at the replacement Daemon.

## Current final lifecycle model

### Data plane

Normal tool execution uses a fresh Unix connection per tool call. A manually
restored Daemon at the same path can serve later requests from the same Proxy.

### Control plane

At Proxy startup, the Proxy creates/uses a `session_id`, opens a long-lived
control connection, and sends `session_begin(session_id)`. This separate
connection represents session lifetime/cleanup ownership.

### Daemon-owned session state

Potential state includes cursor/overlay ownership, per-session config,
recording, and daemon-side bookkeeping. When the old Daemon dies, its memory and
control connection die. The Proxy may retain `session_id`, but the replacement
Daemon does not automatically receive a new `session_begin`.

**Data-plane recovery:** verified.

**Control-session / daemon-owned-state recovery:** not yet understood.

## Tested vs not tested

**TESTED:** Daemon dead **before** the next request.

**NOT TESTED:** Daemon dies **during** an active request:

```text
tool starts → Proxy connects → Daemon begins executing → Daemon dies → unknown
```

This separate class includes unknown EOF/timeout/transport behavior, partial
actions, and retry safety for mutating operations.

## Current correctness boundary

What happens when a replacement Daemon receives a normal tool request stamped
with the surviving Proxy's old `session_id`, but never received a new
`session_begin` for that session?

This is a design/correctness question, not a confirmed bug.

## Design questions to inspect next

1. What does `session_begin(session_id)` establish: active registration,
   lifetime/reaper semantics, or both?
2. How does the Daemon handle a normal request whose ID it never saw through
   `session_begin`: reject, stateless-only, broad acceptance, lazy state, or
   another mechanism?
3. Which operations require a registered/live control session: observation,
   cursor, config, recording, or browser/session-sensitive work?
4. Can per-tool requests create state without live control registration? If so,
   who cleans it up and can it become orphaned?
5. After replacement, should control reconnect with the same identity, should
   the old session be invalidated, or should a new Daemon-side generation exist?
6. Which state should survive versus disappear: cursor, config, recording,
   permissions/grants, and cached runtime state?
7. Are normal calls intentionally allowed while data plane is healthy but the
   control/session relationship is missing?
8. If the replacement has a different version, does Proxy metadata/tool caching
   require compatibility or tool-list revalidation?
9. What happens during Daemon death in an active request, including partial
   execution and safe retries? **NOT YET TESTED.**

## Minimum next source trace

Inspect only the minimum source/design evidence for the old-session-id question:

- `libs/cua-driver/rust/crates/cua-driver/src/proxy.rs`: session ID creation,
  persistent control connection, `session_begin`, control loss, per-tool
  session-ID stamping
- `libs/cua-driver/rust/crates/cua-driver/src/serve.rs`: `session_begin`,
  `session_end`, request dispatch, active-session gating
- `libs/cua-driver/rust/crates/cua-driver-core/src/session.rs`: identity,
  active/ended semantics, cleanup/reaper behavior

Then inspect only cursor/config/recording ownership code necessary to determine
whether an unregistered session can create state. Use `#1777` and PR `#1779`
for design intent; do not read the entire Driver repository.

## How the next investigation proceeds

```text
design question → minimum source/design history → OBSERVED / INFERENCE / UNKNOWN
→ establish invariant → user prediction → narrow repro → inspect issues/PRs
→ classify problem → choose contribution candidate
```

Do not run a new experiment until the user has predicted its behavior.

## Related issue / PR context

- `#1777` — session identity/lifecycle model and session-owned state context
- PR `#1779` — persistent control connection/session cleanup; mid-session
  Daemon control reconnection explicitly deferred
- `#2618` — real Daemon disappearance followed by `Connection refused` (closed)
- `#3337` — abnormal exit can leave external Linux MPX state behind
- `#2002` — opposite lifecycle direction / cleanup ownership problem

These are context, not an automatically selected contribution target.

## Candidate contribution directions — NOT YET CHOSEN

- mid-session control reconnection
- explicit session invalidation/new-session semantics after replacement
- session-owned state cleanup/recovery correctness
- external resource cleanup after abnormal process death
- retry/uncertain-execution semantics if a real gap is reproduced

## Next targeted investigation

The next session should turn this lifecycle understanding into a concrete issue
or PR candidate without assuming a bug.

1. Trace whether a replacement Daemon requires active
   `session_begin(session_id)` registration before accepting normal requests
   carrying that `session_id`. Inspect only:
   - `libs/cua-driver/rust/crates/cua-driver/src/proxy.rs`: session ID creation,
     persistent control connection, `session_begin`, control-connection loss,
     and old-ID stamping on later per-tool requests
   - `libs/cua-driver/rust/crates/cua-driver/src/serve.rs`: `session_begin`,
     `session_end`, normal dispatch, and active control/session checks
   - `libs/cua-driver/rust/crates/cua-driver-core/src/session.rs`: active/ended
     bookkeeping, cleanup/reaper semantics, and whether state can exist without
     a live control connection
   Then inspect only the cursor/config/recording ownership code needed to
   answer the question.
2. Compare the result with issue `#1777` and PR `#1779`, specifically what the
   persistent control connection was intended to guarantee and what deferred
   mid-session control reconnection means for current behavior.
3. Classify the source trace as **OBSERVED** (current code), **INFERENCE**
   (implication for a surviving Proxy), and **UNKNOWN** (runtime evidence still
   needed).
4. Establish the expected invariant before testing. Distinguish, rather than
   assume: rejection; stateless-only acceptance; broad acceptance; lazy
   recreation of session-owned state; or another recovery mechanism.
5. Identify one safe, minimal stateful/session-owned operation. Choose from
   cursor/overlay, per-session config, or recording only if the source trace
   supports it; avoid ambiguous browser or input actions.
6. Only after the trace, ask the user to predict behavior. Then run one narrow
   repro: healthy Proxy/session → establish needed state → kill only Daemon →
   start replacement Daemon → retain Proxy/session → invoke the chosen stateful
   operation with the old `session_id`.
7. If state is accepted or recreated, inspect cleanup ownership: whether a live
   control connection exists, whether `session_end` can occur, who removes the
   state, and whether orphaning is possible. Treat orphaning as a hypothesis
   until reproduced.
8. Compare the result with `#1777` / PR `#1779` and search narrowly for daemon
   restart, `session_begin`, `session_end`, control connection, reconnect,
   stale session, session cleanup, restart mid-session, old `session_id`, and
   daemon replacement.
9. Classify the result before proposing architecture: intended invalidation,
   continuity/UX gap, cleanup/resource bug, session correctness bug,
   trust/safety boundary, already-deferred work, or not a bug.
10. Only then discuss alternatives: reconnect the control plane with the same
    session identity; invalidate the old session; or create a new Daemon-side
    generation with explicit replay/invalidation rules. Do not select one before
    the current contract and behavior are understood.

Next session should begin with the source/design trace above.

Do not start with another random lifecycle break. Do not test Daemon death
during an active mutating request yet; it remains a separate later scenario
after the control/session recovery contract is understood.

## Stopping boundary

No random new lifecycle break. Next session begins with the old-session-id /
control-registration design question, establishes the intended contract, and
only then chooses a targeted reproduction or contribution candidate.
