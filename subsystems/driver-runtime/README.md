# Cua Driver Runtime

## Goal / what this subsystem does

The Driver Runtime takes a computer-tool request from an Agent/MCP client and
executes it through the long-running Cua Driver daemon. This record captures
the architecture, experiments, failure boundaries, and current issue thread.

## Architecture whiteboard

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
the running Proxy did not automatically restart a later-dead Daemon. Fresh
per-tool Unix connections let the same Proxy/session reach a manually replaced
Daemon at the same path. This is data-plane recovery, not proven control/session
recovery: the old persistent `session_begin(session_id)` connection and old
Daemon memory are lost, and no new control registration is automatic.

## Experiments completed

| Experiment | What was broken/tested | Observed outcome | What it taught me | Status |
| --- | --- | --- | --- | --- |
| Happy path | `list_apps` → `list_windows` → `get_window_state` | AX/screenshot result returned through MCP | Full Agent → macOS → Agent path works | Complete |
| PID/window mismatch | Valid window ID, wrong PID | `window_owner_pid_mismatch` before observation | Ownership is preflight validation | Complete |
| Stale window | Valid PID, stale/nonexistent window | `window_id_not_found` before observation | Window scope is preflight validation | Complete |
| AX unresolved | Valid surface without exact AX mapping | Empty AX tree; screenshot can be valid | Truthful independent observation channels | Complete |
| Intermittent capture | Repeated same-window observation | `px_capture_unavailable`; later success | Candidate only; parked | Parked |
| Daemon dead before next request | Only Daemon killed before `list_apps` | `Connection refused`; Proxy/session survived | No steady-state restart; pathname is not liveness | Complete |
| Manual replacement | Replacement bound same path | Same Proxy/session `list_apps` succeeded | Fresh data connections reach replacement | Complete |

## Final current subsystem model

The runtime has a durable happy path, explicit target/degraded-observation
behavior, and distinct process, transport, and session boundaries. Data-plane
transport recovery is verified; control-session and daemon-owned-state recovery
remain unresolved.

## What is GREEN

- MCP/Proxy/Daemon/Driver execution path and happy-path observation
- target validation and truthful degraded observation
- Proxy/Daemon lifetime independence and socket pathname vs listener
- startup auto-launch vs no steady-state restart
- tested `Connection refused` and manual replacement recovery
- data plane vs control plane

## What is still YELLOW / unknown

- Daemon death during an active request
- old Proxy `session_id` at a replacement Daemon
- control reconnection and daemon-owned cursor/config/recording state
- recovery versus intentional invalidation
- retry safety and Agent/SDK recovery

## Current issue-driven thread

Daemon restart mid-MCP-session → control/session-state recovery → issue
discovery. Establish the surviving-session contract before selecting a
contribution candidate.

## Detailed notes

- [Happy path](./happy-path/README.md)
- [Failure experiments](./failures/README.md)
- [Daemon lifecycle investigation](./daemon-lifecycle/README.md)

## Deferred

Do not resume broad reconnaissance or invent failures. Inspect only the
source/design evidence needed for the old-session-id/control-session question.
