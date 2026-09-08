# Cua Driver — Daemon Lifecycle

## Goal

Understand Daemon/Proxy failure domains, session ownership, replacement and
cleanup behavior, and what a caller can know when the Daemon disappears before
or during a tool request.

## Canonical visuals

### Between-request replacement and session recovery

![Daemon lifecycle and session recovery](./daemon_lifecycle_session_recovery.png)

### Active-request death and uncertain outcome

![Active-request death and uncertain outcome](./active-request-death/active_request_uncertain_outcome.png)

These preserve two different durable views: state/lifecycle recovery between
requests and execution/acknowledgement ambiguity during a request.

## Architecture at a glance

```text
MCP Client
→ cua-driver mcp Proxy
→ Unix socket / named pipe
→ long-running Daemon
→ Driver / platform tool
→ response back through Daemon and Proxy
```

Two connection roles matter:

- **Data plane:** a fresh connection for each ordinary tool call.
- **Control plane:** one persistent `session_begin(session_id)` connection for
  the Proxy session lifetime.

Ownership:

- **Proxy:** logical session identity and MCP/client continuity.
- **Daemon:** process-local lifecycle/activity/in-flight bookkeeping and
  session-owned runtime state.

## Completed slice 1 — death between requests

Observed and source-verified model:

1. Proxy and Daemon are separate process/failure domains.
2. Daemon death removes its listener, memory, lifecycle state, and old control
   connection; the Proxy and its `session_id` may survive.
3. A socket pathname can remain without a listener.
4. The running Proxy does not automatically supervise/restart a later-dead
   Daemon in the tested path.
5. A manually restored Daemon at the same address can receive later fresh
   data-plane connections.
6. An unknown, non-ended old session identity can be lazily admitted.
7. Lazy admission creates fresh Daemon-side state. It does not restore old
   process memory.
8. `session_begin` is not a universal admission gate; its main role is immediate
   owner-liveness cleanup via control EOF.
9. Without control reconnect, replacement-created session state still has
   lifecycle/activity tracking and idle-TTL fallback cleanup.
10. Proxy liveness and replacement-Daemon session liveness can diverge.

Concise rule:

> **Identity continuity is not state continuity.**

Detailed evidence: [Between-request lifecycle](./between-requests/README.md)

Status: **GREEN enough**.

## Completed slice 2 — death during an active request

The source path has no intermediate execution acknowledgement and no daemon-wire
request identity/deduplication. The Daemon awaits the platform effect before
constructing its final response.

A controlled experiment killed the Daemon only after delayed `type_text` had
created a visible Terminal prefix. Terminal retained `CUA_MIDREQ2_`; the same
Proxy call returned `daemon closed connection without response`; no automatic
replay occurred.

Concise rule:

> **No final response is not evidence of no execution.**

The Proxy knows the connection closed without a valid response. Independent
Terminal observation proved partial execution in this run. The Proxy cannot
derive that effect from its response path, so blind retry may duplicate or
compound external state.

Detailed evidence: [Active-request death](./active-request-death/README.md)

Status: **GREEN enough**.

## Experiment index

| Slice | Experiment | Result | Status |
| --- | --- | --- | --- |
| Between requests | Daemon dead before next call | `Connection refused`; Proxy survived | Tested |
| Between requests | Manual replacement | Same Proxy reached new listener | Tested |
| Between requests | Old S1 on replacement | Lazy admission + fresh state | Tested |
| Between requests | No control reconnect | S1 later ended while processes lived | Tested; exact idle reason inferred |
| Active request | Fixed-delay kill | Kill happened before connect | Invalid / not tested |
| Active request | Desktop-scope target | Input missed Terminal; no kill | Invalid / not tested |
| Active request | Effect-conditioned kill | Partial prefix + response-less error | Tested |

## Tested / not tested

### TESTED

- Daemon dead before the next request;
- lack of automatic steady-state restart in the tested path;
- manual data-plane recovery;
- lazy old-session admission and fresh state creation;
- idle lifecycle cleanup without restored control connection;
- Daemon death during executing delayed `type_text`;
- partial external effect followed by loss of the final response;
- no automatic Proxy replay.

### SOURCE-VERIFIED

- fresh per-call data connections;
- persistent control connection and immediate EOF cleanup;
- session lifecycle/activity/in-flight bookkeeping;
- execution before final response construction;
- no daemon-wire request id, deduplication key, or retry mechanism.

### NOT TESTED / DESIGN PENDING

- every session-owned resource family after replacement;
- completed effect followed by response loss;
- behavior of an actual caller retry;
- a typed pre-dispatch versus outcome-unknown error contract;
- deduplication or exactly-once architecture.

## Contribution status

Bounded issue/PR review found no direct work for daemon-wire request identity,
mutating-call deduplication, or automatic Proxy replay. Existing related fixes
prevented concrete Daemon failures or rejected calls before execution.

The current candidate is narrower than replay: distinguish connection failure
before dispatch from response loss after dispatch, so client-visible errors do
not imply that mutating work was never executed or is safe to retry.

This is an architecture-improvement candidate, not a proven automatic-retry
bug. It changes a cross-platform public error contract and therefore requires
human commitment plus maintainer alignment before design or implementation.

## Current engineering question

> Should we commit serious contribution time to a maintainer discussion about a
> phase-aware transport-error contract, without attempting automatic replay or
> exactly-once execution?

## Stop boundary

Do not repeat the lifecycle experiments, implement a retry/idempotency design,
choose an error schema, or begin source changes without that commitment and
maintainer direction.
