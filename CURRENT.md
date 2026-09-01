# Current Cua Learning State

## Phase

Phase 2.5 — Personal Cua execution-path understanding

## Current Subsystem

Agent / computer-action execution path

We are learning how a real computer action travels from an agent-facing
request boundary into Cua's execution/runtime layer, reaches the platform
implementation, and eventually returns an observation/result.

The concrete path currently being used to learn this subsystem is:

macOS `get_window_state` with screenshot capture.

This is intentionally one narrow path through Cua, not a study of the entire
repository.

## Current Investigation

macOS get_window_state screenshot execution path

Detailed investigation: `01-screenshot.md`

Human-created diagrams:

- `diagrams/01-mcp-request-to-cua-proxy.png`
- `diagrams/02-cua-proxy-to-driver-dispatch.png`
- `diagrams/03-get-window-state-to-screenshot-boundary.png`

## Progress So Far

Session 1 completed.

The human personally traced the request from the external MCP entry path
through Cua's request/dispatch layers to the screenshot capture boundary.

The current personally established boundary is:

`GetWindowStateTool` -> `spawn_blocking` ->
`screenshot_window_bytes(window_id)` -> ???

Detailed architecture and reasoning are intentionally kept in
`01-screenshot.md` rather than repeated here.

## Understanding Level

YELLOW

The human can explain the request-entry, process-boundary, daemon/driver/tool
dispatch, and pre-capture path. The actual pixel-capture implementation,
capture failures, final result construction, and return path have not yet been
personally traced.

## Current Stopping Boundary

`screenshot_window_bytes(window_id)`

Do not silently continue beyond this boundary using earlier AI-generated
repository traces.

## Next Engineering Question

What happens inside `screenshot_window_bytes(window_id)` from the moment
capture is requested until image bytes or a capture error are produced?

## Next Session — Start Here

1. Read this file.
2. Read `01-screenshot.md` only as needed to restore detailed context.
3. Do NOT restart from MCP Client / Proxy / Daemon / ToolRegistry.
4. Begin at `screenshot_window_bytes(window_id)`.
5. Before inspecting the implementation, ask the human for a prediction of:
   - what this function probably needs to do;
   - what macOS capability/component might actually capture pixels;
   - what success might return;
   - what could fail at this boundary.
6. Then inspect only the minimum code needed to test that hypothesis.

## Immediate Scope

Understand only:

`screenshot_window_bytes(window_id)` -> macOS screenshot capture boundary ->
image bytes OR capture error

Do not yet continue into the complete result-return path unless the human has
understood the capture boundary first.

## Still Unknown

- internals of `screenshot_window_bytes`
- actual macOS pixel-capture mechanism
- ScreenCaptureKit / fallback behavior
- permission and capture failures
- image-byte production
- final result construction
- return path to MCP client

## Resume Rule

Resume from the current stopping boundary. Do not restart earlier architecture
unless the human asks to revisit it or new evidence contradicts the existing
mental model.
