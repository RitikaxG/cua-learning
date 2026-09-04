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
- Accessibility state
- screenshot
- Proxy lifetime != Daemon lifetime

## Next

failure experiment — deliberately break one assumption and inspect the failing
boundary

## Pointers

- [subsystems/driver-runtime/README.md](./subsystems/driver-runtime/README.md)
- [subsystems/driver-runtime/happy-path/README.md](./subsystems/driver-runtime/happy-path/README.md)
