# Current Cua Learning State

## Phase

PHASE 3 — ISSUE-DRIVEN LEARNING / CONTRIBUTION DISCOVERY

## Current subsystem

Driver Runtime

## Completed enough

- happy path
- observation/targeting failures
- process/transport lifecycle

## Current lifecycle model

- Proxy survives Daemon death.
- Dead Daemon → next fresh connection gets `Connection refused`.
- No automatic steady-state restart occurred.
- A manually restored Daemon can be reached by the same Proxy.
- Data plane recovers through fresh connections.
- Persistent control relationship does not automatically come back.
- Daemon-owned session state after replacement is unresolved.

## Tested / not tested

**TESTED:** Daemon dead **before** the next request.

**NOT TESTED:** Daemon dies **during** an active request.

## Current exact engineering question

What does the replacement Daemon do when a surviving Proxy sends a tool request
carrying its old `session_id`, but the replacement Daemon has never received a
new `session_begin` for that session?

## Next bounded investigation

1. Inspect Proxy control registration.
2. Inspect Daemon `session_begin` / `session_end`.
3. Inspect normal request/session gating.
4. Inspect session bookkeeping.
5. Inspect only necessary cursor/config/recording ownership code.
6. Compare with `#1777` / PR `#1779`.
7. Classify OBSERVED / INFERENCE / UNKNOWN.
8. Do not run a new runtime experiment until the user predicts expected
   behavior.

## Possible outcomes to distinguish

- unregistered old session rejected
- stateless calls allowed but stateful calls gated
- old session accepted and state recreated
- another intended recovery mechanism exists

## Stop boundary

Do not broad-reconnoiter the repo, invent another failure, or implement a fix.
First establish the intended session/control correctness contract.

## Pointers

- `subsystems/driver-runtime/README.md`
- `subsystems/driver-runtime/happy-path/README.md`
- `subsystems/driver-runtime/failures/README.md`
- `subsystems/driver-runtime/daemon-lifecycle/README.md`
- `subsystems/driver-runtime/daemon-lifecycle/daemon_lifecycle_break_flowchart.png`
