# Driver Runtime — Daemon Lifecycle and Recovery

This thread records the daemon-lifecycle investigation that completed the
pre-issue architecture phase and became the first issue-driven learning thread.

It is intentionally scoped to:

- MCP Proxy lifetime
- Cua Daemon lifetime
- Unix-domain-socket lifecycle
- persistent MCP control-session semantics
- per-tool request transport
- daemon-owned session state
- recovery after daemon replacement

It does not expand into unrelated Driver internals, Fleet, Kubernetes, or
sandbox orchestration.

See the visual map in [mindmap.md](./mindmap.md).

---

## 1. Runtime boundary under study

```text
Agent / MCP Client
        │
        ▼
`cua-driver mcp` Proxy
        │
        ├── persistent control connection
        │       `session_begin(session_id)`
        │
        └── fresh per-tool Unix connection
                │
                ▼
        `cua-driver serve` Daemon
                │
                ▼
              Driver
```

The Proxy and Daemon are separate processes with different lifetimes.

---

## 2. Experiment A — kill only the Daemon

### Prediction before the experiment

I predicted that:

- the Proxy would survive because it is independent of the Daemon;
- the Proxy would try to reconnect on the next tool call;
- the MCP session might die when the tool call failed;
- some Cua-owned mechanism might automatically revive the Daemon.

### Observed runtime behavior

Starting from a healthy MCP session and successful `list_apps`:

1. only the long-running `cua-driver serve` process was terminated with
   `SIGTERM`;
2. the existing `cua-driver mcp` Proxy remained alive;
3. the existing MCP client/session remained alive;
4. the Unix socket pathname remained on disk;
5. no replacement Daemon appeared during the bounded observation window;
6. the next `list_apps` reached the existing Proxy but failed with a daemon
   transport error:

```text
connect to .../cua-driver.sock: Connection refused
```

7. a second tool call failed the same way;
8. the Proxy did not automatically start a replacement Daemon after the
   forwarding failure.

### Conclusion

Daemon failure and MCP-session failure are different failure domains.

```text
Codex / MCP session     healthy
Proxy                   healthy
Proxy → Daemon IPC      broken
Daemon                  dead
```

A failed tool invocation does not by itself destroy the MCP stdio session.

---

## 3. Unix socket lifecycle

A Unix socket pathname is not the listener itself.

After the Daemon was terminated:

```text
socket pathname on filesystem    present
process listening behind it      absent
connect()                         ECONNREFUSED
```

Therefore:

> socket pathname exists ≠ Daemon is available

Source inspection established two cleanup paths:

### Normal shutdown

The Daemon's normal shutdown path removes the socket it owns and removes its
PID file. Socket removal checks ownership/device-inode information so an old
shutdown path does not accidentally unlink a replacement socket.

### Startup after a stale pathname

Standalone daemon startup removes the configured socket pathname before
binding a new `UnixListener`.

Therefore a stale pathname left by an abnormal process termination does not,
by itself, permanently prevent a later Daemon from binding the standard socket
path.

The experiment used `SIGTERM`; in the bounded server path inspected, the
process did not return through the normal protocol-driven cleanup path, which
matched the stale pathname remaining afterward.

---

## 4. Daemon startup and recovery ownership

On macOS, the MCP startup path checks daemon liveness before entering the
steady-state Proxy loop.

If no Daemon answers at Proxy startup, the CLI can launch CuaDriver via
LaunchServices and wait for the Daemon to become available.

Conceptually:

```text
MCP Proxy startup
      │
      ├── daemon alive? ── yes ──┐
      │                          │
      └── no                     │
           │                     │
           ▼                     │
     launch CuaDriver.app        │
           │                     │
           ▼                     │
      wait for Daemon            │
           │                     │
           └─────────────────────┘
                    │
                    ▼
                run Proxy
```

Once the steady-state Proxy loop is running, the bounded path inspected does
not provide an ongoing daemon watchdog/restart loop.

Therefore the current verified statement is:

> The MCP startup path owns ensuring that a Daemon exists before Proxy startup;
> the running Proxy does not automatically restore a Daemon after a later
> per-tool transport failure.

Do not generalize this to every possible external macOS supervisor without
additional evidence.

---

## 5. Data plane vs control plane

This is the most important architectural distinction learned from the lifecycle
break.

### Data plane — per-tool requests

Every forwarded tool call opens a fresh Unix stream to the configured socket,
sends one request, receives one response, and closes that request connection.

Conceptually:

```text
tool call #1
→ connect(socket)
→ request / response
→ close

tool call #2
→ connect(socket)
→ request / response
→ close
```

The Proxy does not depend on one permanent per-tool Daemon connection.

### Control plane — session lifetime

At Proxy startup, one MCP session identity is minted.

The Proxy also opens one long-lived control connection to the Daemon and sends
`session_begin(session_id)`. That control connection remains open for the
Proxy's lifetime.

The Daemon uses control-connection liveness to own and clean up session-scoped
state. When that connection reaches EOF, the Daemon can fire `session_end` and
clean resources such as session cursor state, config overrides, and recording.

This persistent control connection is separate from the per-tool connections.

---

## 6. Experiment B — restore only the Daemon

After Experiment A:

- the original Daemon was dead;
- the same Proxy was still alive;
- the same MCP session was still alive;
- the stale socket pathname remained.

A replacement Daemon was then started manually without restarting Codex or the
Proxy.

Observed:

1. the replacement Daemon started with a new PID;
2. it successfully listened at the same configured socket pathname;
3. the existing Proxy process remained unchanged;
4. the same MCP session invoked `list_apps`;
5. `list_apps` succeeded through the replacement Daemon;
6. no fresh Proxy was required.

### Conclusion

The system has **transport recoverability once the Daemon is restored**:

```text
same Proxy
    │
    │ fresh per-tool connect()
    ▼
replacement Daemon
    │
    ▼
read-only call succeeds
```

This is different from **automatic runtime recovery**. The running Proxy did not
restore the Daemon by itself.

---

## 7. What survived daemon replacement

Verified for the bounded experiment:

| State / component | Survived replacement? | Evidence |
| --- | --- | --- |
| MCP client/session | yes | same client/session made later successful call |
| MCP Proxy process | yes | same Proxy remained alive |
| Proxy-minted session ID | yes in Proxy memory | same Proxy process continued |
| Socket pathname | stable address | replacement Daemon listened at same path |
| Old socket/listener instance | no | old Daemon died; replacement created a new listener |
| Daemon process memory | no | old process terminated |
| Per-tool transport connection | recreated per call | fresh connect on later request |
| Persistent control connection to old Daemon | no | old daemon-side connection died with old Daemon |

### Important unknown

A successful `list_apps` proves that a read-only/stateless request can recover
through the replacement Daemon.

It does **not** prove that daemon-owned session semantics were reconstructed.

---

## 8. Daemon-owned session state

Current source and upstream design history show that the Daemon owns
session-scoped state including, depending on platform/tool path:

- agent cursor state / overlay ownership;
- per-session configuration overrides;
- owned recording state;
- daemon-side active-session bookkeeping;
- other state explicitly bound to a transport/public session.

When the Daemon process is replaced, its in-memory registries are replaced too.

The Proxy can preserve the same session-id string, but:

> preserving an identifier is not the same as reconstructing the server-side
> session object and its owned state.

---

## 9. Known recovery gap from upstream design history

PR `trycua/cua#1779` introduced the persistent control connection used to make
session cleanup reliable when a Proxy exits or crashes.

That PR explicitly records **daemon-restart-mid-session control-connection
re-establishment** as deferred work.

This matches the experiment:

```text
OLD DAEMON
Proxy ── control connection ──► Daemon
Proxy ── per-call connection ─► Daemon

Daemon dies

Proxy ── control connection ──X
Proxy remains alive

NEW DAEMON
Proxy ── control connection ──X   not automatically rebuilt
Proxy ── per-call connection ───► new Daemon   works for list_apps
```

This is now the first issue-driven investigation thread.

---

## 10. Candidate correctness risk — not yet verified

The existing Proxy still stamps its session identity on later forwarded
requests after daemon replacement.

If the new Daemon accepts such requests without a re-established
`session_begin` control connection, a question arises:

> Can new session-owned state be created under the old session ID without a
> live control connection that can later reap it?

This is currently an **INFERENCE / investigation hypothesis**, not an
established bug.

It must be answered from the minimum relevant code and a targeted reproduction
before any upstream claim or fix proposal.

---

## 11. Design questions for issue discovery

These questions are now justified by the experiment and upstream history.
They should be answered from existing design/code/issues before proposing a
new design.

### Control-session recovery

- Should the persistent control connection reconnect after Daemon replacement?
- If it reconnects, should it replay `session_begin` using the existing Proxy
  session ID or mint a new generation/session?
- How is an old Proxy authenticated/validated against a new Daemon generation?
- Should tool calls be blocked until control-session registration succeeds?

### Daemon generation

- Is there an explicit Daemon instance/generation identity today?
- Which state is valid only for one Daemon generation?
- How should stale capabilities from generation N behave against generation
  N+1?

### Session-owned state

For each state category:

- should it be restored;
- should it be deliberately invalidated;
- should it require user/agent re-establishment;
- can replaying it cause unsafe side effects?

Especially:

- cursor state;
- config overrides;
- recording;
- browser grants/approvals;
- other resource/capability bindings.

### Request behavior during recovery

- Fail immediately or wait for recovery?
- Retry only idempotent/read-only requests?
- Which layer owns retry: Proxy, SDK/client, or higher-level agent host?
- What error should cross MCP when recovery is impossible?
- What happens when multiple requests race daemon replacement?

### Cached Proxy state

- The Proxy caches the daemon tool list at startup. What happens if the
  replacement Daemon is a different version/tool registry?
- Is compatibility revalidated after a mid-session Daemon replacement?

These are design questions, not assumed defects.

---

## 12. Real-world issue connections

### `trycua/cua#1777` — session identity model

Tracks session-owned cursor/config/recording lifecycle work. This is the
closest design-history issue for the persistent session model.

### `trycua/cua#1779` — persistent control connection

Merged PR that made control-connection EOF the reliable session cleanup signal.
It explicitly deferred daemon-restart-mid-session control reconnection.

### `trycua/cua#2618` — Daemon exits during sustained Linux SDK sessions

A real long-running workload observed the Daemon disappear while the caller
remained alive. The next request received Unix-socket `Connection refused`.
The issue is closed, but it proves the failure class can happen outside a
manual lifecycle experiment.

### `trycua/cua#3337` — external resources survive abnormal Driver exit

Open Linux/X11 issue where abnormal Driver exit can leave MPX input devices
registered outside the process. A real host also observed a session dying
mid-call and being revived by a higher-level client.

Architectural lesson:

> process/RPC recovery does not imply recovery or cleanup of resources owned
> outside the process.

### `trycua/cua#2002` — opposite lifetime direction

Tracks cases where agent/session work ends but driver/capture/overlay resources
can remain alive. It reinforces that parent/session and runtime/resource
lifetimes must be deliberately connected.

---

## 13. Candidate contribution directions

These are not yet selected issues.

### A. Daemon restart mid-MCP-session control recovery

Closest to the experiment and explicitly deferred in upstream history.

Need to establish:

- current expected contract;
- whether ordinary calls can create unowned session state after replacement;
- safe re-registration semantics;
- daemon-generation / compatibility behavior;
- tests that model restart while keeping one Proxy alive.

### B. Session-state recovery/invalidation contract

Potential design/documentation/test work around what must be intentionally
lost or restored across Daemon generation changes.

This should probably be addressed together with or after A, not as broad
architecture work.

### C. Abnormal-exit external-resource cleanup

`#3337` is a concrete open issue showing lifecycle leakage outside the process.
It is Linux/X11-specific and therefore adjacent to, rather than identical with,
the current macOS Proxy/Daemon thread.

### D. Daemon crash diagnostics / long-run stability

`#2618` demonstrates the failure class but is closed. Only revisit if current
main or a supported release shows a reproducible regression.

---

## 14. Current understanding level

### Process / transport lifecycle: GREEN

I can explain:

- Proxy and Daemon lifetime independence;
- stable socket pathname vs listener instance;
- per-tool fresh connections;
- why tool failure does not kill the MCP session;
- why a manually restored Daemon can serve later tool calls;
- startup-only Daemon availability ownership in the Proxy path.

### Control-session / state recovery: YELLOW

I understand the persistent control-connection purpose and that it is lost on
Daemon replacement, but I have not yet established the intended recovery
contract for:

- control-session re-registration;
- Daemon generation;
- session-owned state reconstruction/invalidation;
- retries and concurrency during recovery;
- actual agent-host recovery policy.

---

## 15. Current stopping boundary

Do not run more invented lifecycle failures simply to explore the repository.

The next work is issue-driven:

1. read the minimum design history around `#1777` / PR `#1779`;
2. trace only the code needed to understand control-session registration,
   daemon-side session ownership, and behavior when requests carry a session ID
   without a live control connection;
3. identify the intended invariants across Daemon generations;
4. compare concrete recovery designs and tradeoffs;
5. choose a real contribution target;
6. only then build a minimal reproduction/test for that target.

The next engineering question is:

> What is the intended correctness contract when a Daemon is replaced while an
> MCP Proxy remains alive, and what must happen to its control session and
> daemon-owned state before normal tool calls are considered safely recovered?
