# Daemon Lifecycle — Active-Request Death

## Engineering question

When the Daemon disappears after a mutating tool call may have started but
before the Proxy receives a final response, what can the caller know about the
external effect and retry safety?

## Canonical experiment visual

![Active-request death and uncertain outcome](./active_request_uncertain_outcome.png)

## Source-verified execution path

```text
MCP tools/call + JSON-RPC id
→ Proxy keeps the outer id
→ DaemonRequest(method="call", name, args, session_id)
→ one fresh Unix connection
→ request frame written
→ Daemon parses and admits dispatch
→ process-local in_flight guard acquired
→ optional action-history start
→ tool.invoke(args) performs the platform effect
→ result/history projection
→ final DaemonResponse written
→ Proxy parses response or reports transport failure
```

Important boundaries:

- `DaemonRequest` carries no request id, idempotency key, attempt number, or
  deduplication key.
- The Daemon sends no admission/execution-start acknowledgement.
- The first positive acknowledgement visible to the Proxy is the final
  `DaemonResponse`.
- `tool.invoke(...)` runs before that response is constructed.
- The Proxy issues one daemon request and does not reconnect/replay it.
- `idempotentHint` is advisory metadata, not retry or deduplication machinery.
- `in_flight` is process-local cleanup protection, not durable execution proof.

Acknowledgement invariant:

```text
final response parsed
→ Daemon reported an outcome

no final response after request dispatch
→ execution outcome is unknown to the Proxy
```

The response path alone cannot distinguish not started, partially executed,
completed, or completed with its response lost.

## Experiment design

Use delayed, character-by-character `type_text` against a disposable Terminal
prompt. The payload contains no newline or shortcut, so a partial marker is
visible but cannot execute a command.

The important break must be conditioned on an observed external effect rather
than a fixed timer. A one-shot observer therefore watches the exact Terminal tab
and kills only the verified Daemon after the unique prefix appears.

Human prediction:

> Terminal will retain a non-empty partial prefix, and the Proxy will return a
> transport error.

## Invalid attempt 1 — killed before dispatch

Baseline:

- Proxy `17783`;
- Daemon `19835`;
- session `mid-request-20260908`;
- disposable Terminal `63260` / `24885`.

The scheduled kill fired before `type_text` connected. The Proxy returned
`Connection refused`; the marker was absent. This repeated the already-known
between-request failure and did **not** test active execution.

Recovery required a new task/connector after the app-owned Proxy was explicitly
terminated. Repeated `start_session` inside the stale task continued to return
`Transport closed`, proving that another message did not create a fresh
connector.

## Invalid attempt 2 — global input lost the target

A fresh task established session `mid-request-20260908-resume`, reached Daemon
`65529`, and completed ordinary read-only preflights. Candidate Proxy `68340` was
selected from process start time; the connector did not expose its PID directly.

Desktop-scope typing returned `effect:"unverifiable"`, Terminal remained
unchanged, the observer timed out, and the Daemon survived. Codex had regained
foreground before global synthesis ran.

Source inspection established the smallest correction: exact-window foreground
typing for a Terminal target skips the ineffective AX insertion path, fronts the
exact window, and emits delayed CGEvents character by character.

No ambiguous action was retried because direct observation proved that the
first marker was absent.

## Valid attempt — effect-conditioned Daemon death

Verified baseline:

- fresh-task Proxy candidate `68340`;
- Daemon `65529` with the expected listener;
- session `mid-request-20260908-resume`;
- Terminal `63260` / window `24885` at an idle prompt;
- exact-window foreground `type_text`, `delay_ms:200`;
- payload `CUA_MIDREQ2_20260908_ABCDEFGHIJKLMNOPQRSTUVWXYZ`.

The observer detected `CUA_MIDREQ2_` in the exact front Terminal tab, then sent
`SIGKILL` only to Daemon `65529`.

Observed:

- Terminal retained exactly `CUA_MIDREQ2_`;
- Daemon and listener disappeared;
- Proxy candidate and Terminal survived;
- the same call returned:

```text
daemon transport error forwarding `type_text`:
daemon closed connection without response
```

- no automatic Proxy replay occurred;
- the marker was not retried.

The human prediction matched the observed result.

## What the evidence proves

### OBSERVED

- the request was executing far enough to create a partial external effect;
- the Daemon died before a final response arrived;
- the Proxy surfaced only a transport error;
- external Terminal state survived process death.

### SOURCE-VERIFIED

- effect execution precedes final response construction;
- daemon-wire request identity/deduplication is absent;
- the Proxy does not replay the logical action;
- process-local execution bookkeeping dies with the Daemon.

### CONCLUSION SUPPORTED BY BOTH

> A post-dispatch transport error cannot be interpreted as “the action did not
> run.” Blind retry of a mutating action may repeat or compound an effect that is
> already partial or complete.

### NOT TESTED

- a completed effect followed by response loss;
- behavior of a real caller retry;
- a deduplicating or exactly-once design;
- optional action-history evidence after this killed Daemon.

## Human explain-back

The human correctly separated the two evidence domains:

- the Proxy knows that the established connection closed without a valid final
  response;
- the Proxy cannot infer the execution state from that response path;
- independent Terminal observation proved partial execution in this run;
- replaying the full marker after restoration could append a second full effect
  to the surviving prefix.

This active-request execution/acknowledgement slice is GREEN enough.

## Related issue and PR context

- [#1777](https://github.com/trycua/cua/issues/1777) remains open for session
  lifecycle follow-ups. Merged PR `#1779` added the persistent Proxy control
  connection and deferred reconnect across Daemon replacement.
- [#2618](https://github.com/trycua/cua/issues/2618) was closed by merged PR
  `#2631`, which removed one concrete Linux Daemon-exit cause rather than adding
  replay/deduplication.
- [#3300](https://github.com/trycua/cua/issues/3300) was closed by merged PR
  `#3314`, which kept the permission-gated macOS Daemon stable and rejected work
  before execution with a typed pending status.
- [#3337](https://github.com/trycua/cua/issues/3337) remains open for Linux/X11
  external state leaked across abnormal exit.
- [#3656](https://github.com/trycua/cua/issues/3656) remains open for a current
  Windows UIA crash that produces the same response-less transport symptom.

A bounded GitHub search on 2026-09-08 found no direct issue or PR implementing
daemon-wire request identity, mutating-call deduplication, or automatic Proxy
replay.

## Contribution classification

This is not a proven automatic-retry bug: the Proxy sends one request and does
not replay it. Response loss is expected to be ambiguous without a stronger
protocol.

The concrete candidate is a client-visible error-contract improvement:

- connect-before-dispatch and post-write outcome-unknown failures both become
  generic JSON-RPC `-32603`;
- the Proxy comment describes transport failure as “I couldn't reach the tool
  at all,” contradicted by the reproduced partial effect;
- the string says no response arrived but provides no stable execution-phase or
  outcome classification.

Candidate invariant:

> After request dispatch, a client-visible transport failure must not imply
> “not executed” or “safe to retry”; execution outcome must be unknown.

A bounded proposal could distinguish pre-dispatch connection failure from
post-write outcome-unknown failure in the common daemon client/Proxy contract,
with Unix/Windows protocol tests and accurate wording. Non-goals are automatic
replay, deduplication, and exactly-once claims.

Because this changes a cross-platform public error contract and no direct issue
selects the work, maintainer alignment is required before design or code.

## Source landmarks

- `libs/cua-driver/rust/crates/cua-driver/src/proxy.rs::forward_tool_call`
- `libs/cua-driver/rust/crates/cua-driver-core/src/daemon.rs::send_request`
- `libs/cua-driver/rust/crates/cua-driver/src/serve.rs::invoke_daemon_tool`
- `libs/cua-driver/rust/crates/platform-macos/src/tools/type_text.rs`

## Stop boundary

Do not repeat the marker, implement replay/exactly-once machinery, choose an
error schema, or begin source changes without human contribution commitment and
maintainer alignment.
