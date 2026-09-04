# Current Cua Learning State

## Phase

PHASE 2.5 — MY PERSONAL CUA ARCHITECTURE UNDERSTANDING

This phase is almost complete.

Goal: personally understand the driver-runtime execution path well enough to
begin learning through real issues/contributions rather than continuing broad
pre-study.

Do NOT restart repository reconnaissance.

## Current subsystem

Driver runtime / agent-to-computer execution path.

Continuous path currently being studied:

Agent
→ MCP Client
→ `cua-driver mcp` Proxy
→ Unix Domain Socket
→ long-running Cua Daemon
→ SDK Adapter
→ Cua Driver
→ macOS implementation
→ AX / screenshot observation
→ result back to agent

Do not expand into Fleet, Kubernetes, sandbox orchestration, or unrelated
subsystems yet.

## Understanding status

Happy-path runtime understanding: GREEN

I can personally explain:

- MCP Client and JSON-RPC `tools/call`
- MCP Proxy responsibility
- Proxy lifetime vs Daemon lifetime
- Unix Domain Socket as local IPC
- Daemon as long-running service/runtime owner
- SDK Adapter boundary
- Driver dispatch into macOS implementation
- WindowServer target identity
- Accessibility / AX semantic observation
- screenshot / pixel observation
- how results return to the agent

Detailed architecture:
`subsystems/driver-runtime/README.md`

## Happy path — COMPLETE

Experimentally verified:

- Cua Driver daemon startup
- `cua-driver mcp` stdio Proxy
- `list_apps`
- `list_windows`
- `get_window_state`
- AX tree
- screenshot
- result returned through MCP JSON-RPC
- Proxy can exit while Daemon remains alive

Also verified using a real Codex MCP consumer:

Codex Agent
→ MCP
→ Cua Proxy
→ Daemon
→ Driver
→ macOS

A normal observation successfully returned AX information and pixels.

## Failure/degradation experiments — COMPLETE FOR CURRENT PURPOSE

Detailed notes:
`subsystems/driver-runtime/failures/README.md`

Verified:

### PID/window mismatch

valid window + wrong PID
→ `window_owner_pid_mismatch`

Target ownership is checked before expensive observation work.

### Stale/nonexistent window

valid PID + nonexistent window
→ `window_id_not_found`

Window scope is validated before observation proceeds.

### Valid WindowServer surface without matching AXWindow

→ `ax_window_unresolved`

Verified:

- target can be valid even when exact AX mapping fails
- Cua returns an empty semantic tree rather than elements from another surface
- AX and screenshot are independent observation channels
- AX failure can still produce truthful pixels

### Intermittent macOS observation/capture behavior

Observed:

- same valid normal iTerm2 window sometimes returned `px_capture_unavailable`
- both ScreenCaptureKit and shell fallback were observed failing
- later identical observation succeeded
- one real Codex turn received neither usable AX nor screenshot
- Codex did not hallucinate or act on stale evidence

Status: PARKED INVESTIGATION.

Do NOT spend more time on this now.

Reason: current reproduction machine is macOS 13.1 while current documented
support starts at macOS 14.

Only resume this investigation if:

- supported macOS 14+ reproduction becomes available, or
- it becomes a deliberate upstream contribution candidate.

## Final pre-issue experiment

This is the next task.

### Deliberately break the Daemon lifecycle boundary

We already verified:

Proxy exits
→ Daemon remains alive

Now test the opposite direction:

MCP Client / Agent
→ MCP Proxy
→ Unix socket
→ Daemon

While the MCP client/proxy session is active, deliberately terminate ONLY the
long-running Cua Daemon. Then invoke a normal Cua tool through the still-active
MCP client/session.

The purpose is to understand runtime ownership and recovery behavior.

### Do not run immediately

A fresh GPT session must first:

1. read this `CURRENT.md`
2. inspect only the minimum current runtime state needed
3. confirm which process is:
   - the long-running Daemon
   - the active MCP Proxy/client session
4. ask me to predict what will happen before breaking anything

Do not start with a source-code investigation.

### Prediction questions

Before running the experiment, I should predict:

- Will the Proxy notice the socket/Daemon disappeared?
- Will the next tool call return a connection error?
- Will the Proxy automatically reconnect?
- Will Cua automatically restart the Daemon?
- Will the MCP session itself die?
- Will a later request recover?
- How will Codex/the MCP consumer surface the failure?

The goal is not to guess correctly. The goal is to compare my mental model
against actual runtime behavior.

### Experiment shape

Keep the test minimal:

1. establish a healthy Daemon + MCP session
2. confirm a simple tool succeeds
3. record Daemon PID
4. terminate ONLY that Daemon process
5. keep the MCP client/session alive
6. invoke one simple Cua tool again
7. observe exact result
8. determine whether recovery is automatic, partial, or absent
9. check process/socket state afterward
10. explain the behavior back in my own words

Do not kill unrelated processes. Do not deliberately modify the target UI. Do
not introduce multiple failures at once.

Prefer a simple read-only tool such as `list_apps` for the post-failure request
unless evidence shows another tool is more appropriate.

### Questions the experiment must answer

- Who actually owns Daemon recovery?
- Does the Proxy assume the Daemon is permanently available?
- Is reconnection handled at the Proxy, CLI, launcher, or elsewhere?
- Does killing the Daemon invalidate the MCP session?
- What error crosses each boundary?
- Does the Agent recover naturally?
- What state survives the Daemon restart, if any?
- Does a fresh tool call require a fresh Proxy/session?

Only inspect source code AFTER the runtime result creates a concrete question.

Follow:

RUN
→ PREDICT
→ OBSERVE
→ TRACE
→ ASK WHY
→ READ MINIMUM RELEVANT CODE
→ FORM MENTAL MODEL
→ BREAK / CHANGE ONE THING
→ PREDICT FAILURE
→ RUN AGAIN
→ EXPLAIN IT BACK

## Stop boundary for Phase 2.5

This Daemon lifecycle break is the final planned pre-issue experiment.

After it, do NOT keep inventing failure scenarios merely to understand more of
the repository.

If I can explain:

- happy-path runtime
- process/lifetime ownership
- target validation
- degraded observations
- safe failure behavior
- Daemon failure/recovery boundary

then PHASE 2.5 is complete enough.

## What happens next

After the Daemon lifecycle experiment:

START ISSUE DISCOVERY.

Issue discovery becomes the learning mechanism.

Desired loop:

find candidate issue
→ reproduce it
→ identify responsible runtime boundary
→ read minimum relevant code
→ understand that piece deeply
→ propose alternatives
→ implement
→ test
→ maintainer discussion / PR

Do not wait until I understand the entire Cua repository.

The goal is:
understand subsystem deeply enough
→ make progressively harder real contributions
→ learn additional runtime concepts just in time.

## Pointers

- `subsystems/driver-runtime/README.md`
- `subsystems/driver-runtime/architecture.png`
- `subsystems/driver-runtime/happy-path/README.md`
- `subsystems/driver-runtime/failures/README.md`
- `subsystems/driver-runtime/failures/cua_get_window_state_flowchart.png`
