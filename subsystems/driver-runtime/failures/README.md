# Driver Runtime — Failure Experiments

Daemon lifecycle and recovery are recorded separately in
[daemon-lifecycle/README.md](../daemon-lifecycle/README.md).

## 1. PID / window ownership mismatch

**Prediction:** Calling `get_window_state` with a valid `window_id` but the wrong
`pid` should reach tool execution and fail target validation.

**Experiment:** `get_window_state(pid=<wrong>, window_id=<valid>)`

**Observed:**
- The request reached `get_window_state`.
- The tool returned `isError: true` with code `window_owner_pid_mismatch`.
- This was a tool execution error, not a JSON-RPC transport error.
- Ownership preflight rejected the request before the Accessibility tree walk
  and screenshot capture.
- The long-running daemon remained healthy after the failed request.

**Conclusion:** `get_window_state` verifies that the requested WindowServer
window belongs to the supplied PID instead of trusting the caller.

---

## 2. Stale / nonexistent window ID

**Prediction:** Calling `get_window_state` with a valid `pid` but a nonexistent
or stale `window_id` should reach tool execution and fail window-scope
validation.

**Experiment:** `get_window_state(pid=<valid>, window_id=<nonexistent>)`

**Observed:**
- The request reached `get_window_state`.
- The tool returned `isError: true` with code `window_id_not_found`.
- This was a tool execution error, not a JSON-RPC transport error.
- The request was rejected during window-scope preflight.
- Expensive Accessibility/screenshot observation did not proceed.
- The long-running daemon remained healthy after the failed request.

**Conclusion:** `get_window_state` verifies that the requested WindowServer
window still exists before producing an observation.

---

## 3. Live window with unresolved Accessibility surface

A WindowServer window can exist and be owned by the correct PID while Cua
cannot find an `AXWindow` whose `CGWindowID` maps to that exact WindowServer
window.

Observed on auxiliary iTerm2 window 8601:

- Ownership preflight passed.
- `degraded: true`
- `degraded_reason: ax_window_unresolved`
- `element_count: 0`
- Cua did not substitute AX elements from a sibling window/surface.

**Conclusion:** `ax_window_unresolved` is degraded success, not
target-validation failure. Cua prefers an empty AX tree over returning semantic
UI from the wrong surface.

![get_window_state flow and degradation model](./cua_get_window_state_flowchart.png)

### Pixel fallback observed

A later observation of the same AX-unresolved auxiliary window returned:

- `element_count: 0`
- `degraded_reason: ax_window_unresolved`
- valid screenshot

**Conclusion:** AX resolution and pixel capture are separate observation
channels. Cua can fail to semantically resolve a window while still returning
truthful pixels for that same WindowServer surface.

Installed `cua-driver 0.23.2` does not expose
`include_accessibility_tree:false`; AX processing remained part of those calls.
They were not capture-only `get_window_state` tests.

---

## Reliability investigation — intermittent macOS window observation

**Investigation candidate, not a confirmed upstream bug.**

### Manual reproduction

Repeated `get_window_state` calls against the same normal iTerm2 window showed
intermittent observation/capture failure.

Verified:

- Same valid PID, valid `window_id`, and normal iTerm2 window.
- Some calls returned valid screenshots; some returned `px_capture_unavailable`.
- Later calls against the unchanged window succeeded.

One failed screenshot attempt showed both macOS capture paths failing:

- Native ScreenCaptureKit failed to start its stream because of an
  audio/video capture failure.
- The `screencapture -l ...` shell fallback could not create an image from the
  window.

### Current Rust behavior

- Native ScreenCaptureKit first.
- On native error, timeout, or empty result, one shell `screencapture -l`
  fallback.
- No streaming-start-specific bounded retry was found.

Historical Swift behavior is investigation evidence only: it had a similar
ScreenCaptureKit streaming-start failure, one targeted retry after about 250 ms,
and additional fallback behavior. This is not a proposal for Rust to copy it.

### Agent-level impact

In the real Codex MCP experiment, Codex used:

`list_apps` → `list_windows` → `get_window_state`

It initially received AX information and a valid screenshot. After multiple
successful observations, one turn against the same normal iTerm2 window
returned:

- `ax_window_unresolved`
- `element_count: 0`
- `px_capture_unavailable`
- no valid screenshot

Codex did not retry `get_window_state` in that turn. It behaved safely: it did
not claim visual inspection, reuse stale visual evidence, or modify the UI; it
surfaced that the observation was unreliable.

A later fresh turn against the same PID/window again returned AX elements and a
valid screenshot.

**Conclusion:** The observation failure can be transient and can propagate to
an actual agent turn. Cua reports the degraded state truthfully, but the failed
observation was not transparently recovered inside that Codex turn.

MCP session-expiry recovery was a separate session-lifecycle event and is not
part of this capture issue.

### Status

**Investigation candidate — not yet confirmed upstream bug.**

The reproduction machine is macOS 13.1; current documented Cua Driver support
begins at macOS 14. Before filing an upstream issue or proposing a fix,
reproduce on supported macOS 14+, preferably against current/main or a
precisely identified supported release.

---

## Recording rules

- Normal expected failure: add one concise section here.
- Actual bug, upstream issue, or PR candidate: create
  `failures/<bug-slug>/README.md`, plus `repro.sh` only when a standalone
  reproduction is useful.
- A promoted bug README should contain only:
  - expected behavior
  - actual behavior
  - minimal reproduction
  - root cause/evidence
  - proposed fix or alternatives
  - upstream issue/PR link when applicable
