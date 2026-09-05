# Cua Driver Runtime

## What this subsystem does

The runtime takes a tool request from an Agent/MCP client and executes it
against the local computer through the long-running Cua Driver daemon.

![Final Cua Driver architecture whiteboard](./architecture.png)

## Main execution path

```text
Agent
→ MCP Client
→ cua-driver mcp Proxy
→ Unix Domain Socket
→ Cua Daemon
→ SDK Adapter
→ Driver/platform
→ result back to Agent
```

## Component responsibilities

- The MCP Client sends JSON-RPC tool calls.
- The `cua-driver mcp` Proxy translates and forwards them over local IPC.
- The Unix Domain Socket connects Proxy and Daemon.
- The Daemon owns the long-running runtime/service boundary.
- The SDK Adapter reaches the Driver contract.
- The Driver/platform implementation executes the requested computer action.

## Happy-path understanding

The normal path is an MCP JSON-RPC tool call entering the Proxy, crossing the
local socket to the Daemon, reaching the SDK Adapter and Driver/platform code,
then returning a result to the Agent. The Proxy is tied to its MCP session;
the Daemon is a separate long-running runtime process.

## Target and observation failures

`get_window_state` validates that a WindowServer window belongs to the supplied
PID and still exists before expensive observation. A valid WindowServer surface
may still lack an exact Accessibility mapping; Cua then returns an empty AX tree
rather than semantic elements from another surface. AX and screenshot are
separate observation channels.

## Proxy and Daemon lifecycle

The Proxy and Daemon have independent lifetimes. When the Daemon was dead
before a later tool call, the existing Proxy/session stayed alive but its fresh
Unix connection failed. A manually started replacement Daemon at the same path
served a later call through that same Proxy/session. This proves transport
recovery for fresh tool connections; control/session-state recovery remains
separate.

## What I have actually tested

- Happy-path MCP tool execution reaches macOS and returns results to the Agent.
- `get_window_state` target validation and independent AX/pixel degradation.
- Proxy and Daemon independent lifetimes.
- Daemon dead before the next call → `Connection refused` without automatic
  steady-state restart.
- Manual Daemon replacement at the same socket path → later `list_apps`
  succeeds through the same Proxy/session.

## What remains unclear

Daemon death during an active request is not tested. The replacement Daemon's
handling of the old Proxy `session_id`, control registration, daemon-owned
state, retry safety, and Agent/SDK recovery are still unknown.

## Detailed records

- [Happy path](./happy-path/README.md)
- [Failure experiments](./failures/README.md)
- [Daemon lifecycle investigation](./daemon-lifecycle/README.md)

## Current focus

Daemon restart mid-MCP-session → control/session-state recovery → issue
discovery.
