# Current Cua Learning State

## Phase

PHASE 2.5 — MY PERSONAL CUA ARCHITECTURE UNDERSTANDING

The goal of this phase is personal runtime understanding through experiments,
not repository-wide reconnaissance or issue hunting.

## Current subsystem

Driver runtime / agent-to-computer execution path.

Current continuous path:

Agent
→ MCP Client
→ MCP Proxy
→ Unix Domain Socket
→ Cua Daemon
→ SDK Adapter
→ Cua Driver
→ macOS implementation
→ Accessibility / screenshot observation
→ result back to agent

Do not expand into Fleet, sandbox orchestration, Kubernetes, or unrelated Cua
subsystems unless the current runtime investigation requires it.

## Understanding status

Happy-path runtime understanding: GREEN

I can personally explain:

- what the MCP Client sends
- JSON-RPC `tools/call`
- what `cua-driver mcp` proxy does
- why Proxy lifetime differs from Daemon lifetime
- Unix socket as local IPC between Proxy and Daemon
- Daemon as long-running runtime/service
- SDK Adapter as the boundary into the Driver SDK contract
- Driver tool dispatch to macOS implementation
- `get_window_state` target validation
- WindowServer vs Accessibility
- AX tree vs screenshot as separate observation channels
- how results return to the MCP client / agent

Architecture details live in:
`subsystems/driver-runtime/README.md`

Happy-path reproduction lives in:
`subsystems/driver-runtime/happy-path/`

## Happy path verified

Experimentally verified with released/prebuilt Cua Driver on macOS:

- daemon startup and lifetime
- MCP stdio proxy
- `list_apps`
- `list_windows`
- `get_window_state`
- real Accessibility tree
- real screenshot
- JSON-RPC result path back through stdout
- MCP Proxy can exit while Daemon remains alive
- later requests can reuse the still-running Daemon

Also verified with a real Codex MCP consumer:

Codex Agent
→ Codex MCP Client
→ cua-driver MCP Proxy
→ Daemon
→ Driver
→ `get_window_state`

A normal control turn successfully returned both:

- AX information
- valid screenshot

## Failure scenarios completed

Detailed evidence:
`subsystems/driver-runtime/failures/README.md`

### 1. PID / window ownership mismatch — COMPLETE

Valid `window_id` + wrong `pid`

Result:
`window_owner_pid_mismatch`

Verified:

- request reaches `get_window_state`
- WindowServer ownership preflight rejects mismatched target
- rejection happens before AX walk and screenshot capture
- tool failure is distinct from JSON-RPC transport failure
- Daemon remains healthy

### 2. Stale / nonexistent window ID — COMPLETE

Valid PID + nonexistent/stale `window_id`

Result:
`window_id_not_found`

Verified:

- request reaches `get_window_state`
- window-scope preflight rejects nonexistent target
- expensive observation work does not proceed
- Daemon remains healthy

### 3. Live window with unresolved AX surface — COMPLETE

Valid PID
+ valid WindowServer window
+ correct ownership
+ no matching `AXWindow` / `CGWindowID`

Result:
`ax_window_unresolved`

Verified:

- this is degraded success, not target-validation failure
- Cua returns an empty AX tree rather than semantic elements from another surface
- AX resolution and screenshot capture are separate channels
- an AX-unresolved surface can still return a valid screenshot

Mental model:

AX ✓ + screenshot ✓
→ full observation

AX ✗ + screenshot ✓
→ pixel-only degraded observation

AX ✓ + screenshot ✗
→ AX-only degraded observation

AX ✗ + screenshot ✗
→ no trustworthy observation

The visual explanation is:
`subsystems/driver-runtime/failures/cua_get_window_state_flowchart.png`

## Parked reliability investigation

Observed intermittent macOS `get_window_state` observation/capture failures on
the same valid normal iTerm2 window.

Evidence included:

- repeated same-window calls sometimes returned screenshots and sometimes
  `px_capture_unavailable`
- one failure showed both:
  - ScreenCaptureKit capture failure
  - `screencapture -l` fallback failure
- later calls against the unchanged window succeeded
- during a real Codex agent turn, the same normal window temporarily returned:
  - `ax_window_unresolved`
  - zero AX elements
  - `px_capture_unavailable`
- Codex did not hallucinate or act on stale state
- Codex surfaced that the observation was unreliable
- a later fresh turn against the same PID/window succeeded

Current interpretation:

This is an investigation candidate, NOT yet a confirmed upstream bug.

Reason: the current reproduction machine is macOS 13.1 while documented current
Cua Driver support begins at macOS 14.

Do NOT spend more time on this now.

Resume it only when:

- a supported macOS 14+ environment is available, or
- this becomes a deliberate contribution candidate.

Then reproduce on a supported/current build before proposing retries, fixes,
issues, or PRs.

## Current investigation

Continue learning `get_window_state` degraded-observation behavior.

Next failure scenario:

AX succeeds
+
screenshot capture fails

Goal:

Verify that when pixel capture is unavailable but a trustworthy AX tree exists,
Cua preserves the semantic observation rather than failing the entire state.

Questions to answer experimentally:

1. Does the response retain the AX elements?
2. What screenshot failure metadata is returned?
3. Is the result considered degraded rather than a hard tool failure?
4. Can an actual agent still safely understand the UI through AX?
5. Does the Daemon remain healthy?

Do not intentionally investigate ScreenCaptureKit internals yet unless this
experiment creates a concrete question.

## Immediate next step

Design the smallest experiment that produces or observes:

AX ✓
+
screenshot ✗

Use the existing runtime path.

Follow the learning loop:

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

Do not begin with a theory lecture or broad source investigation.

## Stop boundary

For the current driver-runtime study, stop normal-path tracing.

Continue only through meaningful failure/degradation scenarios until I can
personally explain:

- target validation
- observation-channel independence
- degraded results
- safe failure behavior
- major recovery boundaries

Do not chase every possible error code.

## Pointers

- `subsystems/driver-runtime/README.md`
- `subsystems/driver-runtime/architecture.png`
- `subsystems/driver-runtime/happy-path/README.md`
- `subsystems/driver-runtime/failures/README.md`
- `subsystems/driver-runtime/failures/cua_get_window_state_flowchart.png`
