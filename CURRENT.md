# Current Cua Learning State

## Phase

PHASE 3 — ISSUE-DRIVEN LEARNING / CONTRIBUTION DISCOVERY

PHASE 2.5 is complete enough.

I now understand the driver-runtime happy path and major failure/lifecycle
boundaries well enough that further learning should come from real issues,
design history, reproductions, and contributions rather than broad pre-study.

Do NOT restart repository reconnaissance.

Do NOT invent additional failure experiments merely to learn more of Cua.

## Current subsystem

Driver runtime / agent-to-computer execution path.

Current issue-driven thread:

**Daemon restart mid-MCP-session → control-session and daemon-owned state
recovery.**

Continuous runtime boundary:

```text
Agent
→ MCP Client
→ `cua-driver mcp` Proxy
→ Unix Domain Socket
→ long-running Cua Daemon
→ SDK Adapter
→ Cua Driver
→ platform implementation
```

Current focus is only the Proxy ↔ Daemon lifecycle/session boundary.

Do not expand into Fleet, Kubernetes, sandbox orchestration, or unrelated
subsystems unless a selected real issue requires it.

## Understanding status

### Happy-path runtime: GREEN

I can personally explain:

- MCP Client and JSON-RPC `tools/call`;
- MCP Proxy responsibility;
- Proxy lifetime vs Daemon lifetime;
- Unix Domain Socket as local IPC;
- Daemon as long-running service/runtime owner;
- SDK Adapter boundary;
- Driver dispatch into the platform implementation;
- WindowServer target identity;
- Accessibility / AX semantic observation;
- screenshot / pixel observation;
- how results return to the agent.

Detailed architecture:
`subsystems/driver-runtime/README.md`

### Process / transport lifecycle: GREEN

I can personally explain:

- why killing the Daemon does not kill the MCP Proxy/session;
- why a stale socket pathname can remain with no live listener;
- why the next tool call returns `Connection refused`;
- why the running Proxy does not automatically revive the Daemon in the
  observed path;
- why a replacement Daemon listening at the same socket pathname can be used
  by the same Proxy on a later per-tool request;
- the difference between automatic recovery and transport recoverability once
  the runtime is restored;
- the difference between per-tool data connections and the persistent control
  connection.

Detailed lifecycle thread:
`subsystems/driver-runtime/daemon-lifecycle/README.md`

Mind map:
`subsystems/driver-runtime/daemon-lifecycle/mindmap.md`

### Control-session / daemon-owned state recovery: YELLOW

I understand why the persistent control connection exists and that it is lost
when the Daemon dies, but I have not yet established the intended correctness
contract for:

- control-session re-establishment after Daemon replacement;
- Daemon instance/generation semantics;
- what session-owned state should be restored vs invalidated;
- whether an old Proxy may safely continue using its old session ID against a
  new Daemon;
- request gating/retry while control recovery is incomplete;
- concurrent calls racing a restart;
- cached Proxy state across Daemon replacement;
- actual higher-level agent recovery policy.

## Happy path — COMPLETE

Experimentally verified:

- Cua Driver daemon startup;
- `cua-driver mcp` stdio Proxy;
- `list_apps`;
- `list_windows`;
- `get_window_state`;
- AX tree;
- screenshot;
- result returned through MCP JSON-RPC;
- Proxy can exit while Daemon remains alive;
- a real Codex MCP consumer can traverse the same path.

## Failure/degradation work — COMPLETE FOR CURRENT PURPOSE

Detailed notes:
`subsystems/driver-runtime/failures/README.md`

Verified:

- PID/window ownership mismatch → `window_owner_pid_mismatch`;
- stale/nonexistent window → `window_id_not_found`;
- valid WindowServer surface without exact AXWindow → `ax_window_unresolved`;
- AX and pixel capture can degrade independently;
- intermittent macOS capture behavior can propagate to a real agent turn.

The intermittent macOS capture investigation remains PARKED because the local
machine is macOS 13.1 while current documented support starts at macOS 14.
Only revisit on supported macOS or as a deliberate real contribution target.

## Daemon lifecycle experiment — COMPLETE

### Experiment A — Daemon death while MCP session remains alive

Starting from a healthy Daemon + Proxy + successful `list_apps`:

- only the long-running Daemon was terminated;
- the same MCP Proxy remained alive;
- the same MCP session remained alive;
- the Unix socket pathname remained but no process listened behind it;
- the next `list_apps` reached the Proxy and failed with daemon transport
  `Connection refused`;
- a second call failed the same way;
- no replacement Daemon appeared during the bounded check;
- the running Proxy did not automatically restart the Daemon.

### Experiment B — replacement Daemon with same Proxy/session

Without restarting Codex or the MCP Proxy:

- a replacement Daemon was started manually/externally;
- it listened at the same configured socket pathname;
- the same Proxy made a fresh per-tool Unix connection;
- `list_apps` succeeded;
- a fresh Proxy/MCP session was not required for that read-only call.

### Architectural conclusion

```text
DATA PLANE
fresh per-tool Unix connection
→ can recover once replacement Daemon is available

CONTROL PLANE
persistent session control connection
→ dies with old Daemon
→ is not automatically re-established in the current observed/design path
```

Therefore:

> Daemon restart can restore the request transport without proving that
> daemon-side session ownership/state has been safely reconstructed.

## Source/design history established

Minimum source inspection established:

- macOS MCP startup checks Daemon liveness and can launch CuaDriver before the
  Proxy steady-state loop;
- each forwarded tool call opens a fresh Unix stream;
- the Proxy mints one session ID and opens one persistent control connection;
- `session_begin(session_id)` registers the control session with the Daemon;
- control-connection EOF is used to trigger `session_end` cleanup;
- session cleanup can own cursor/config/recording state;
- ordinary steady-state Proxy forwarding does not automatically launch a new
  Daemon after a later transport failure;
- upstream PR `trycua/cua#1779` explicitly records
  daemon-restart-mid-session control-connection re-establishment as deferred.

## Real issue connections

These are now issue-discovery evidence, not a new study syllabus.

### `trycua/cua#1777`

Session-identity model / session-owned lifecycle history.

### `trycua/cua#1779`

Merged persistent-control-connection work. Closest design history to the
current thread. Mid-session Daemon restart control reconnection was deferred.

### `trycua/cua#2618`

Closed issue demonstrating a real sustained workload where the Daemon
terminated while the caller remained alive and the next request received
Unix-socket `Connection refused`.

### `trycua/cua#3337`

Open Linux/X11 abnormal-exit lifecycle issue. Shows that runtime/session revival
can coexist with external OS resources left orphaned after the old process
dies.

Architectural lesson:

> process/RPC recovery ≠ complete state/resource recovery.

### `trycua/cua#2002`

Opposite lifetime direction: session/host work ends while driver/resource state
can remain alive. Useful design-history context for lifecycle ownership.

## Current investigation

This is no longer a pre-study exercise.

Current investigation question:

> What is the intended correctness contract when a Daemon is replaced while an
> MCP Proxy remains alive, and what must happen to its control session and
> daemon-owned state before normal tool calls are considered safely recovered?

### First bounded sub-question

Determine from minimum current code/design history:

1. what the new Daemon does when a per-tool request carries a Proxy session ID
   for which the new Daemon has never received `session_begin`;
2. whether such a request can create or mutate session-owned state;
3. if it can, what lifetime/reaper owns that state without a live control
   connection;
4. which tools require an active registered control session and which merely
   accept the stamped session ID;
5. whether Daemon instance/generation identity or compatibility checks protect
   this boundary today.

This is the most important next trace because it decides whether the observed
control-plane gap is:

- only missing continuity/UX;
- a deliberate invalidation model;
- a cleanup/resource-lifetime bug;
- a trust/correctness problem;
- or some combination.

## Candidate contribution directions

Do not select one until the first bounded sub-question is answered.

### Candidate A — mid-session control reconnection

Closest to current understanding and explicitly deferred in PR `#1779`.

Potential concerns to evaluate:

- replay `session_begin` vs mint a new generation;
- block tool calls until registration succeeds;
- old session ID trust across Daemon generations;
- retry semantics;
- concurrency;
- compatibility after Daemon replacement.

### Candidate B — session-state recovery / invalidation contract

Understand and possibly test/document what should happen to:

- cursor;
- config overrides;
- recordings;
- grants/approvals;
- other daemon-owned state.

Do not assume all state should be replayed. Some state may need deliberate
invalidation after a runtime generation change.

### Candidate C — external resource cleanup after abnormal exit

`#3337` is a concrete open issue but is Linux/X11-specific and adjacent to the
current macOS Proxy/Daemon thread.

### Candidate D — long-run Daemon failure diagnostics/stability

Only revisit `#2618`-class work if current main or a supported release shows a
reproducible current failure.

## Immediate scope

For the next investigation, prefer roughly 3–5 important files/functions.
Likely areas only if needed:

- Proxy control-session establishment/reconnection path;
- Daemon request dispatch/session gate;
- core session identity/end tracking;
- cursor/config/recording ownership hooks;
- relevant tests and PR `#1779` design history.

Do not inspect unrelated Driver tools or platform internals unless one selected
state path requires it.

Always separate:

### OBSERVED

Supported by code, test, runtime evidence, or upstream design history.

### INFERENCE

Reasoning such as the possibility of session-owned state being recreated
without a control reaper after Daemon replacement.

### UNKNOWN

The intended recovery/invalidation contract and exact current behavior until
traced/tested.

## Exact stopping boundary

The lifecycle-break experiment itself is finished.

Do NOT run another runtime experiment immediately.

Next session should begin by:

1. reading this `CURRENT.md`;
2. reading `subsystems/driver-runtime/daemon-lifecycle/README.md`;
3. inspecting the lifecycle mind map if useful;
4. answering the first bounded sub-question from minimum current code/design
   evidence;
5. asking me to predict behavior before any new targeted runtime reproduction;
6. using that result to decide which real issue/contribution candidate to
   pursue.

The intended loop is now:

```text
real design/issue question
→ predict
→ inspect minimum code/history
→ form invariant
→ reproduce only if needed
→ compare designs/tradeoffs
→ select contribution
→ implement/test
→ maintainer discussion / PR
```

Do not wait until I understand the entire Cua repository.

## Pointers

- `subsystems/driver-runtime/README.md`
- `subsystems/driver-runtime/architecture.png`
- `subsystems/driver-runtime/happy-path/README.md`
- `subsystems/driver-runtime/failures/README.md`
- `subsystems/driver-runtime/failures/cua_get_window_state_flowchart.png`
- `subsystems/driver-runtime/daemon-lifecycle/README.md`
- `subsystems/driver-runtime/daemon-lifecycle/mindmap.md`
