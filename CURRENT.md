# Current Cua Learning State

## Phase

PHASE 3 — ISSUE-DRIVEN LEARNING / CONTRIBUTION DISCOVERY

## Current thread

Daemon restart mid-MCP-session → control-session recovery → daemon-owned
session-state semantics → candidate issue discovery.

## GREEN

- happy path
- Proxy vs Daemon lifetimes
- socket pathname vs listener
- tested `Connection refused` case
- startup auto-launch vs no steady-state auto-restart
- manual replacement recovery
- fresh per-tool connections
- data plane vs control plane

## YELLOW

- old `session_id` against replacement Daemon
- control reconnection
- session-owned state recovery/cleanup
- restart/session semantics
- retry semantics
- Agent/SDK recovery

## Tested / not tested

**TESTED:** Daemon dead before the next request.

**NOT TESTED:** Daemon dies during an active request.

## Current exact question

What happens when a replacement Daemon receives tool calls carrying the old
Proxy `session_id` without a newly established persistent control registration?

## Pointers

- `subsystems/driver-runtime/README.md`
- `subsystems/driver-runtime/happy-path/README.md`
- `subsystems/driver-runtime/failures/README.md`
- `subsystems/driver-runtime/daemon-lifecycle/README.md`
