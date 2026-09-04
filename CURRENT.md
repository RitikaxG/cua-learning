# Current Cua Learning State

## Phase

PHASE 2.5 — MY PERSONAL CUA ARCHITECTURE UNDERSTANDING

## Current subsystem

Driver runtime / agent-to-computer execution path

## Status

Happy-path runtime understanding: GREEN

## Verified

- MCP Client → Proxy → Socket → Daemon → SDK Adapter → Driver → macOS
- `list_apps`
- `list_windows`
- `get_window_state`
- Accessibility + screenshot happy path
- Proxy lifetime != Daemon lifetime
- `window_owner_pid_mismatch`
- `window_id_not_found`
- `ax_window_unresolved` degraded observation
- real Codex MCP consumer path

## Current investigation

Intermittent macOS `get_window_state` observation/capture failure.

## Evidence

- Repeated calls against the same normal valid window can intermittently fail.
- ScreenCaptureKit and shell fallback were both observed failing.
- An actual Codex agent turn surfaced the degraded observation without retrying.
- A later observation against the same PID/window succeeded.

## Next

Reproduce the same behavior on supported macOS 14+ before deciding whether this
is an upstream bug, issue, or fix candidate.

## Pointers

- [subsystems/driver-runtime/README.md](./subsystems/driver-runtime/README.md)
- [subsystems/driver-runtime/happy-path/README.md](./subsystems/driver-runtime/happy-path/README.md)
- [subsystems/driver-runtime/failures/README.md](./subsystems/driver-runtime/failures/README.md)
