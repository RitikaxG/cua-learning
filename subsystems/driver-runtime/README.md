# Cua Driver Runtime

## What this subsystem does

The runtime takes a tool request from an Agent/MCP client and executes it
against the local computer through the long-running Cua Driver daemon.

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

## What I have verified

- Happy-path MCP tool execution reaches macOS and returns results to the Agent.
- Proxy and Daemon are separate processes with independent lifetimes.
- `get_window_state` validates its target and can degrade observation channels
  independently.
- A dead Daemon causes the next request to fail at the Unix-socket boundary;
  a manually replaced Daemon can serve later fresh tool connections.

## Detailed records

- [Happy path](./happy-path/README.md)
- [Failure experiments](./failures/README.md)
- [Daemon lifecycle investigation](./daemon-lifecycle/README.md)

## Current focus

Daemon restart mid-MCP-session → control/session-state recovery.
