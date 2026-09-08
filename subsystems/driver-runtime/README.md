# Cua Driver Runtime

## Goal / what this subsystem does

The Driver Runtime takes a computer-tool request from an Agent/MCP client and
executes it through the long-running Cua Driver daemon. This record captures
the architecture, experiments, failure boundaries, and current issue thread.

## Current subsystem mind map

![Cua Driver Runtime current mental model](./driver_runtime_mind_map.png)

This is the current retention-oriented map: request path, ownership, healthy
session lifecycle, replacement behavior, active-request death, and the two
central invariants.

## Original architecture whiteboard

![Final Cua Driver architecture whiteboard](./architecture.png)

## Canonical execution path

```text
Agent
→ MCP Client
→ cua-driver mcp Proxy
→ Unix Domain Socket
→ long-running Cua Daemon
→ SDK Adapter
→ Cua Driver
→ macOS/platform implementation
→ result back to Agent
```

## Component responsibilities

- The Agent chooses a computer capability; the MCP Client sends JSON-RPC calls.
- The `cua-driver mcp` Proxy forwards them over local Unix IPC.
- The socket is the Proxy → Daemon address, not the Daemon or its listener.
- The Daemon is the long-running runtime/service boundary.
- The SDK Adapter reaches the Driver contract; the Driver/platform executes.

## Happy-path model I understand

`list_apps`, `list_windows`, and `get_window_state` verified the MCP request
entering the Proxy, crossing the socket to the Daemon, dispatching through the
SDK Adapter/Driver, doing macOS AX/screenshot work, and returning JSON-RPC to
the Agent. Proxy and Daemon lifetimes are independent.

## Observation / targeting model I understand

`get_window_state` checks PID/window ownership and window existence before
expensive observation. A valid WindowServer surface can lack an exact AXWindow;
`ax_window_unresolved` then returns an empty semantic tree rather than another
surface's AX state. AX and screenshots are independent channels. Intermittent
capture behavior is parked: macOS 13.1 is below the documented support baseline.

## Process / Daemon lifecycle model I understand

Proxy and Daemon are separate failure domains. A socket pathname can remain
after Daemon death without a listener. Startup can ensure a Daemon exists, but
the running Proxy did not automatically restart a later-dead Daemon.

Normal tool calls use fresh Unix connections, so the same surviving Proxy can
reach a manually restored replacement Daemon at the same socket path.

The Proxy owns **logical session identity continuity**; the Daemon owns
**process-local runtime/session state**. When the old Daemon dies, its memory and
persistent Proxy ↔ Daemon control connection disappear even though the Proxy
keeps the same `session_id`.

A replacement Daemon can lazily/implicitly admit that old, non-ended
`session_id`, create a fresh lifecycle record/activity state, and allow fresh
session-owned state to be created. This is **identity reuse + fresh state
creation**, not restoration of old Daemon memory.

The persistent `session_begin(session_id)` control connection is not a universal
admission gate for every session-owned action. Its important lifecycle role is
fast, deterministic liveness cleanup: if a healthy Proxy dies, control EOF drives
session-end cleanup. If the control connection is lost during Daemon replacement
and is not restored, the replacement-created session still participates in the
normal idle lifecycle path: default ~300-second idle TTL, maintenance sweep
about every 30 seconds, then session-end hooks.

Therefore Proxy-process liveness and replacement-Daemon session liveness can
diverge: the Proxy can remain alive while an inactive old S1 has already been
expired/tombstoned by the replacement Daemon.

## Experiments completed

| Experiment | What was broken/tested | Observed outcome | What it taught me | Status |
| --- | --- | --- | --- | --- |
| Happy path | `list_apps` → `list_windows` → `get_window_state` | AX/screenshot result returned through MCP | Full Agent → macOS → Agent path works | Complete |
| PID/window mismatch | Valid window ID, wrong PID | `window_owner_pid_mismatch` before observation | Ownership is preflight validation | Complete |
| Stale window | Valid PID, stale/nonexistent window | `window_id_not_found` before observation | Window scope is preflight validation | Complete |
| AX unresolved | Valid surface without exact AX mapping | Empty AX tree; screenshot can be valid | Truthful independent observation channels | Complete |
| Intermittent capture | Repeated same-window observation | `px_capture_unavailable`; later success | Candidate only; parked | Parked |
| Daemon dead before next request | Only Daemon killed before `list_apps` | `Connection refused`; Proxy/session identity survived | No steady-state restart; pathname is not liveness | Complete |
| Manual replacement | Replacement bound same path | Same Proxy/session `list_apps` succeeded | Fresh data connections reach replacement | Complete |
| Old S1 on replacement | Replacement never received new `session_begin(S1)` | `list_apps(S1)` and `set_agent_cursor_enabled(S1)` both succeeded | Old identity can be lazily admitted; fresh Daemon-side state is created | Complete |
| Idle cleanup without control reconnect | Same Proxy and same replacement Daemon stayed alive across inactivity | Later `get_agent_cursor_state(S1)` said session ended and rejected call | Control EOF is not the only cleanup path; inactive replacement-created S1 can expire independently | Complete enough |
| Daemon death during active request | Effect-conditioned `SIGKILL` during delayed exact-window Terminal `type_text` | Terminal retained strict prefix `CUA_MIDREQ2_`; Proxy returned `daemon closed connection without response` | A post-connect transport error can coexist with partial execution; no automatic replay resolves it | Complete enough |

## Final current subsystem model

The runtime now has a durable happy path, explicit target/degraded-observation
behavior, and a substantially understood **between-request Daemon lifecycle**:

```text
Proxy keeps logical session identity
        ↓
old Daemon dies → old process-local state/control connection disappear
        ↓
replacement Daemon can be reached by fresh per-tool connection
        ↓
old S1 can be lazily admitted
        ↓
fresh Daemon-side lifecycle/state is created under S1
        ↓
no control reconnect → no immediate Proxy-liveness cleanup
        ↓
idle lifecycle/reaper provides fallback cleanup
```

The between-request and active-request lifecycle slices are understood well
enough. Contribution legitimacy and maintainer direction remain open before any
error-contract design.

## What is GREEN

- MCP/Proxy/Daemon/Driver execution path and happy-path observation
- target validation and truthful degraded observation
- Proxy/Daemon lifetime independence and socket pathname vs listener
- startup auto-launch vs no steady-state restart
- tested `Connection refused` and manual replacement recovery
- data plane vs control plane
- Proxy logical identity vs Daemon process-local state ownership
- old-session lazy admission on a replacement Daemon
- identity continuity vs state continuity
- immediate control-EOF cleanup vs idle-TTL fallback cleanup
- Proxy liveness can diverge from replacement-Daemon session liveness
- active-request execution/acknowledgement boundary
- partial external effect with response-less transport failure
- response-path knowledge vs independently observed external effect

## What is still YELLOW / unknown

- safe retry policy/design for mutating operations
- maintainer-aligned error contract for pre-dispatch vs outcome-unknown failure
- whether current calls have useful idempotency/deduplication guarantees
- all session-owned resource families under replacement/recovery (cursor/config
  cleanup path is traced; not every resource has been runtime-tested)

## Current issue-driven thread

The active thread has moved from runtime reproduction and explain-back to the
contribution-commitment gate:

> **Should the common Proxy/daemon client distinguish pre-dispatch transport
> failure from post-write execution-outcome-unknown failure, without adding
> automatic replay or exactly-once machinery?**

The source/runtime boundary and human mental model are established. Bounded
issue/PR review found no direct deduplication/replay work; the candidate is now a
cross-platform client-visible error-contract improvement that requires human
commitment and maintainer alignment before design.

## Detailed notes

- [Happy path](./happy-path/README.md)
- [Failure experiments](./failures/README.md)
- [Daemon lifecycle index](./daemon-lifecycle/README.md)
- [Between-request replacement and cleanup](./daemon-lifecycle/between-requests/README.md)
- [Active-request death and uncertain outcome](./daemon-lifecycle/active-request-death/README.md)

The current subsystem mind map is retained at this level. The daemon-lifecycle
investigation keeps two distinct detailed visuals: session recovery between
requests and active-request uncertain execution. Scratch and superseded diagrams
are not retained in the live tree by default; Git history preserves them.

## Deferred

Do not resume broad repository reconnaissance or repeatedly vary the completed
between-request replacement experiment.

Do not repeat the marker or broaden the source trace. Next decide whether to
commit serious contribution time; if approved, prepare a maintainer-facing
problem statement before designing or coding.
