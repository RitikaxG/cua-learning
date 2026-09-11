# External Bug Form Draft

## Title

`[Bug]: Daemon/MCP actions lose RFC 2549 interrupted-completion classification`

## Primary area

Cua Driver

## Summary

Ordinary Daemon-backed SDK and MCP action calls collapse pre-dispatch and
post-dispatch interruption into generic transport errors. This loses the
`NotStarted` versus `Unknown` completion distinction required by RFC 2549 and
already implemented by private-worker, remote, and trusted-service action
paths.

## Reproduction

1. Start a healthy `cua-driver serve` Daemon and an MCP Proxy on macOS.
2. Verify an ordinary read-only call succeeds through the Proxy.
3. Focus a disposable Terminal prompt.
4. Invoke exact-window foreground `type_text` with a unique no-newline marker
   and `delay_ms: 200`.
5. After a strict marker prefix is visibly present, kill only the Daemon before
   it can return a final response.
6. Observe the Terminal contents and MCP result without retrying the action.

Observed in the controlled run:

- Terminal retained the strict prefix `CUA_MIDREQ2_`;
- the Daemon and listener disappeared;
- the Proxy and Terminal survived;
- MCP returned `daemon closed connection without response` under JSON-RPC
  `-32603`;
- no automatic logical replay occurred.

A contrasting attempt where the Daemon was already unavailable before the
request returned `Connection refused` and produced no marker.

## Expected behavior

Interrupted ordinary Daemon-backed actions should preserve the completion
knowledge defined by RFC 2549:

```text
failure before the first request-write attempt
→ NotStarted

failure after a request-write attempt begins
→ Unknown
```

Ordinary SDK Daemon actions should align with the existing
`DriverError::ActionInterrupted { completion, reason }` behavior. MCP action
errors should expose an equivalent stable completion value without changing the
fact that the transport failed. The exact MCP field shape can follow maintainer
direction.

Completion classification must not imply that retry is safe. When completion is
`Unknown`, the agent/application remains responsible for observing external
state and reconciling its original intent.

## Actual behavior

`cua-driver-core::daemon::send_request` returns an untyped transport error for
connect, write, read, EOF, timeout, and decode failures.

- `cua-driver::proxy::forward_tool_call` maps every final transport error to
  JSON-RPC `-32603` with message text and no completion classification.
- the ordinary SDK Daemon backend maps every final `send_request` error to
  `DriverError::Transport`, including action calls.
- the Proxy's source comment describes this category as “I couldn't reach the
  tool at all,” which is not true for the reproduced partial-execution case.

Private-worker, remote, and trusted-service action paths already return
`ActionInterrupted(NotStarted|Unknown)`. The trusted-service tests include a
lost-response case where the server reads an action and closes without a
response, producing `Unknown` without replay.

## Environment

```text
Cua Driver: 0.23.2
Source commit inspected: 72fe7fff6e2d84863585f7164d9663367e8fa465
Operating system: macOS 26.6.2, arm64
Target application: Terminal.app, disposable idle prompt
Transport: MCP stdio Proxy → Unix socket → installed CuaDriver.app Daemon
```

## Evidence

Existing contract:

- RFC 2549, “Define lifecycle and failure behavior”: interrupted actions must
  report completed, failed-before-side-effect, or unknown completion.
- PR #2561 implemented RFC 2549.

Relevant implementation boundary:

- `libs/cua-driver/rust/crates/cua-driver-core/src/daemon.rs::send_request`
- `libs/cua-driver/rust/crates/cua-driver/src/proxy.rs::forward_tool_call`
- `cua-driver-sdk/src/service_session.rs::lost_action_response_is_reported_with_unknown_completion`
  demonstrates the expected classification on an existing action path.

Issue #2861 / PR #2863 addresses predictable `type_text` synthesis-budget
ambiguity while the tool remains alive; it does not classify an unexpected
post-dispatch transport failure.

## Workaround and additional context

Treat response-less action transport failures as unknown completion. After
Daemon availability is restored, observe authoritative external application
state before deciding whether any further action is safe. If the state cannot
be observed reliably, do not blindly retry a non-idempotent action.

This issue is limited to preserving the existing RFC 2549 completion contract
for ordinary Daemon/MCP action paths. It does not request Daemon supervision,
automatic retry, request deduplication, action continuation, or exactly-once
execution.

## Submission checks

- [x] I searched for duplicate issues and active pull requests.
- [x] This issue describes a single problem.
- [x] I removed credentials, private data, sensitive screenshots, and
  vulnerability details from this public report.
