# Cua System Map

This is the currently verified macOS MCP -> `get_window_state` path, not the complete Cua architecture.

MCP Client
    -> Cua Proxy
    -> Cua Daemon
        -> SdkAdapter
        -> CuaDriver
        -> ToolRegistry
        -> GetWindowStateTool
        -> `screenshot_window_bytes()`
        -> ???

