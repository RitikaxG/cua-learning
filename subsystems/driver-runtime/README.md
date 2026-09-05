# Cua Driver Architecture — macOS `get_window_state`

This is the durable architecture model established from the first
`get_window_state` happy path and the later daemon-lifecycle investigation. It
describes the released/prebuilt Cua Driver on macOS plus the minimum current
source/design evidence needed for the active issue-driven thread; it is not a
map of the complete Cua codebase.

## Final architecture whiteboard

![Final Cua Driver architecture whiteboard](./architecture.png)

## Canonical flow

```text
Agent
→ MCP Client
→ MCP Proxy
→ Unix Domain Socket
→ Cua Daemon
→ SDK Adapter
→ Cua Driver
→ macOS implementation
```

## Responsibilities and boundaries

- The Agent decides which computer capability is needed.
- The MCP Client sends JSON-RPC operations such as `tools/call`; in the
  experiment, the terminal played this role.
- `cua-driver mcp` starts the MCP Proxy. It reads JSON-RPC on stdin, extracts
  the tool and arguments, converts them into Cua's internal daemon request,
  and sends that request to the daemon.
- The Unix Domain Socket (`cua-driver.sock`) is the local IPC endpoint between
  Proxy and Daemon. It is not a process.
- The Cua Daemon is the long-running runtime/service process. It owns service
  lifetime, accepts internal requests, and dispatches into Driver execution.
- The SDK Adapter is the small boundary from daemon/runtime callers into the
  public Driver SDK interface, keeping daemon logic independent of
  Driver/platform internals.
- Cua Driver resolves the requested capability to the platform implementation,
  executes it, and returns the result.

For macOS `get_window_state`, the Driver implementation validates the PID and
window, walks the Accessibility tree, re-checks scope, captures a screenshot,
combines state, and returns a `ToolResult`.

```text
macOS → Driver → SDK Adapter → Daemon → Unix socket → Proxy → stdout → MCP Client
```

## Verified happy-path facts

An MCP Proxy/session lifetime is different from a Cua Daemon lifetime. A Proxy
can exit when its stdin/MCP session ends while the Daemon remains alive.

`get_window_state` validates target ownership. Its tool execution failures are
distinct from JSON-RPC transport failures, and an invalid tool call does not
take down the Daemon.

Detailed reproduction:
[happy-path/README.md](./happy-path/README.md).

Verified observation/targeting failures:
[failures/README.md](./failures/README.md).

---

## Daemon lifecycle / recovery model

The final pre-issue experiment deliberately terminated only the long-running
Daemon while keeping the MCP client and Proxy alive.

Experimentally established:

- Proxy and Daemon are separate processes and failure domains;
- killing the Daemon does not automatically kill the MCP session;
- a later tool call reaches the existing Proxy and fails at the Proxy → Daemon
  Unix-socket boundary with `Connection refused`;
- the socket pathname can remain after the Daemon is gone, so pathname
  existence is not a liveness guarantee;
- no replacement Daemon was automatically started by the running Proxy during
  the bounded failure test;
- when a replacement Daemon was started externally/manually at the same socket
  pathname, the same Proxy and MCP session successfully used it for a later
  `list_apps` call.

### Data plane

Forwarded tool calls use fresh per-request Unix connections.

Therefore a replacement Daemon can become reachable by a still-healthy Proxy
without recreating the MCP session.

### Control plane

The Proxy also owns one long-lived control connection established at Proxy
startup. It sends `session_begin(session_id)` and gives the Daemon a liveness
signal for session cleanup.

This connection is separate from per-tool request connections.

If the Daemon dies, the old control connection is lost. Current upstream design
history explicitly records daemon-restart-mid-session control-connection
re-establishment as deferred work.

Therefore:

> data-plane transport recovery after Daemon replacement does not imply that
> daemon-side control/session semantics were reconstructed.

### Daemon-owned state

Session-owned state can include cursor/overlay ownership, per-session config
overrides, recording, and other daemon-side session bookkeeping.

The Proxy may preserve the same session-id string across Daemon replacement,
but the replacement Daemon does not inherit the old process memory.

The intended recovery/invalidation contract for this state is now an active
issue-driven question rather than a pre-study topic.

Detailed lifecycle investigation and issue links:
[daemon-lifecycle/README.md](./daemon-lifecycle/README.md).

Lifecycle recovery mind map:
[daemon-lifecycle/mindmap.md](./daemon-lifecycle/mindmap.md).

---

## Current architectural distinction

```text
MCP CLIENT / PROXY LIFETIME
        │
        ├── persistent stdio protocol session
        ├── Proxy-minted session identity
        │
        └──────────────────────────────────────────────┐
                                                       │
DAEMON GENERATION                                     │
        │                                              │
        ├── Unix listener                             │
        ├── control-session registration              │
        ├── daemon-owned session state                │
        └── Driver runtime                            │
                                                       │
Daemon replacement can preserve the left side         │
while replacing the right side completely. ◄──────────┘
```

This boundary is now the bridge from subsystem understanding into real issue
discovery.

## Deferred unless a real issue requires them

- Tokio/runtime internals
- ScreenCaptureKit internals
- macOS Accessibility internals
- broad socket internals beyond the lifecycle boundary
- cross-platform Driver implementations unrelated to a selected issue
- Fleet / Kubernetes / sandbox orchestration

Additional runtime concepts should now be learned just in time through real
issues and contributions rather than broad repository reconnaissance.
