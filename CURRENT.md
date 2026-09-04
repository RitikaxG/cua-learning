# Current Cua Learning State

## Phase

PHASE 2.5 — MY PERSONAL CUA ARCHITECTURE UNDERSTANDING

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

failure experiments / break assumptions

See [01-screenshot.md](./01-screenshot.md) for the final architecture model and
[CUA_HAPPY_PATH.md](./CUA_HAPPY_PATH.md) for the runtime experiment.
