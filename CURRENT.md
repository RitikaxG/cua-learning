# Current Cua Learning State

## Phase

PHASE 2.5 — MY PERSONAL CUA ARCHITECTURE UNDERSTANDING

## Current subsystem

Driver runtime / agent-to-computer execution path

## Status

Happy-path runtime understanding: GREEN

## Current investigation

PID/window ownership mismatch failure

## Observed

`window_owner_pid_mismatch`

## Verified

- MCP Client → Proxy → Socket → Daemon → SDK Adapter → Driver → macOS
- `list_apps`
- `list_windows`
- `get_window_state`
- Accessibility state
- screenshot
- Proxy lifetime != Daemon lifetime

## Next

inspect minimum relevant source to confirm exact failure ordering

## Pointers

- [subsystems/driver-runtime/README.md](./subsystems/driver-runtime/README.md)
- [subsystems/driver-runtime/happy-path/README.md](./subsystems/driver-runtime/happy-path/README.md)
