#!/bin/bash
set -euo pipefail

# Exercise the real macOS path:
# JSON-RPC/stdin → MCP Proxy → Unix socket → Cua Daemon → SDK Adapter/Driver → macOS.
# Usage: ./run.sh [optional-running-app-name]

APP_NAME="${1:-}"
TRACE_DIR="${TRACE_DIR:-/tmp/cua-learning-trace}"
FINAL_SCREENSHOT="$TRACE_DIR/final-screenshot.png"

export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

if [[ "$(/usr/bin/uname -s)" != "Darwin" ]]; then
  echo "ERROR: this reproduction script requires macOS." >&2
  exit 1
fi
if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR: python3 is required to parse MCP JSON and decode the returned PNG." >&2
  exit 1
fi
mkdir -p "$TRACE_DIR"

install_driver_if_needed() {
  # A CLI without its signed app bundle cannot carry macOS TCC identity.
  if command -v cua-driver >/dev/null 2>&1 && [[ -d /Applications/CuaDriver.app ]]; then
    return
  fi
  echo "Installing the official released/prebuilt Cua Driver (no source build)..."
  /bin/bash -c "$(/usr/bin/curl -fsSL https://cua.ai/driver/install.sh)"
  hash -r
  if ! command -v cua-driver >/dev/null 2>&1 || [[ ! -d /Applications/CuaDriver.app ]]; then
    echo "ERROR: installation did not provide cua-driver and /Applications/CuaDriver.app." >&2
    exit 1
  fi
}

daemon_pid_from_status() {
  /usr/bin/perl -ne 'if (/^\s*(?:daemon\s+)?pid\s*:\s*(\d+)\b/i) { print "$1\n"; exit }' "$1"
}

require_running_daemon() {
  local status_file="$1"
  cua-driver status >"$status_file" 2>&1 || true
  if [[ -z "$(daemon_pid_from_status "$status_file")" ]]; then
    echo "Starting CuaDriver.app as the long-running daemon..."
    open -n -g -a CuaDriver --args serve
    sleep 2
    cua-driver status >"$status_file" 2>&1
  fi
  if [[ -z "$(daemon_pid_from_status "$status_file")" ]] || ! /usr/bin/grep -qi 'socket' "$status_file"; then
    echo "ERROR: Cua daemon PID/socket were not verified. Inspect $status_file" >&2
    exit 1
  fi
}

permissions_are_granted() {
  python3 - "$1" <<'PY'
import json, sys

data = json.load(open(sys.argv[1], encoding="utf-8"))
# Current release reports Accessibility/Screen Recording as booleans. Direct capture
# is verified by `permissions grant`; a later read-only status may say `not_checked`.
ok = data.get("accessibility") is True and data.get("screen_recording") is True
direct = data.get("direct_capture_status")
if direct not in (None, "granted", "not_checked"):
    ok = False
raise SystemExit(0 if ok else 1)
PY
}

# Each call ends stdin after one request, so each cua-driver mcp is one Proxy session.
mcp_call() {
  local step="$1" tool="$2" args_json="$3"
  local request_file="$TRACE_DIR/${step}-request.jsonl"
  local response_file="$TRACE_DIR/${step}-response.jsonl"
  local call_line
  call_line="$(printf '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"%s","arguments":%s}}' "$tool" "$args_json")"
  printf '%s\n' \
    '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"cua-learning","version":"1"}}}' \
    '{"jsonrpc":"2.0","method":"notifications/initialized","params":{}}' \
    "$call_line" >"$request_file"
  cua-driver mcp <"$request_file" >"$response_file"
}

select_app() {
  python3 - "$TRACE_DIR/01-response.jsonl" "$APP_NAME" <<'PY'
import json, sys

messages = [json.loads(line) for line in open(sys.argv[1], encoding="utf-8") if line.strip()]
response = next((m for m in messages if m.get("id") == 2), None)
if not response or response.get("error") or response.get("result", {}).get("isError"):
    raise SystemExit(f"list_apps failed: {response}")
apps = (response["result"].get("structuredContent") or {}).get("apps") or []
apps = [a for a in apps if a.get("running") is True and int(a.get("pid") or 0) > 0]
wanted = sys.argv[2].lower()
if wanted:
    apps = [a for a in apps if str(a.get("name", "")).lower() == wanted or wanted in str(a.get("name", "")).lower()]
else:
    apps = [a for a in apps if str(a.get("name", "")).lower() != "cuadriver"]
    apps.sort(key=lambda a: a.get("active") is True, reverse=True)
if not apps:
    raise SystemExit(f'No running app matched "{sys.argv[2]}".' if wanted else "No running regular app was discovered.")
app = apps[0]
print(f'{app["pid"]}\t{app.get("name", "unknown")}')
PY
}

select_window() {
  python3 - "$TRACE_DIR/02-response.jsonl" "$TARGET_PID" <<'PY'
import json, sys

messages = [json.loads(line) for line in open(sys.argv[1], encoding="utf-8") if line.strip()]
response = next((m for m in messages if m.get("id") == 2), None)
if not response or response.get("error") or response.get("result", {}).get("isError"):
    raise SystemExit(f"list_windows failed: {response}")
pid = int(sys.argv[2])
windows = [w for w in ((response["result"].get("structuredContent") or {}).get("windows") or []) if int(w.get("pid") or 0) == pid]
def area(w):
    b = w.get("bounds") or {}
    return float(b.get("width") or 0) * float(b.get("height") or 0)
windows = [w for w in windows if w.get("is_on_screen") is True and area(w) > 0]
if not windows:
    raise SystemExit(f"No usable on-screen window found for pid={pid}.")
# Prefer a substantive current-Space surface; z-order only breaks equal-size ties.
windows.sort(key=lambda w: (w.get("on_current_space") is True, area(w), w.get("z_index") if isinstance(w.get("z_index"), int) else -1), reverse=True)
print(windows[0]["window_id"])
PY
}

extract_screenshot_and_summary() {
  python3 - "$TRACE_DIR/03-response.jsonl" "$TRACE_DIR/03-summary.json" "$FINAL_SCREENSHOT" <<'PY'
import base64, json, sys

response_path, summary_path, screenshot_path = sys.argv[1:]
messages = [json.loads(line) for line in open(response_path, encoding="utf-8") if line.strip()]
response = next((m for m in messages if m.get("id") == 2), None)
if not response or response.get("error") or response.get("result", {}).get("isError"):
    raise SystemExit(f"get_window_state failed: {response}")
result = response["result"]
# Current MCP schema: an actual image content block carries the returned PNG bytes.
image = next((item for item in result.get("content", []) if item.get("type") == "image" and isinstance(item.get("data"), str)), None)
if not image or image.get("mimeType") != "image/png":
    raise SystemExit("get_window_state returned no PNG MCP image content block.")
payload = image["data"]
if payload.startswith("data:"):
    prefix, payload = payload.split(",", 1)
    if prefix != "data:image/png;base64":
        raise SystemExit("returned image data URL is not PNG base64")
try:
    png = base64.b64decode(payload, validate=True)
except Exception as exc:
    raise SystemExit(f"returned image could not be base64-decoded: {exc}")
open(screenshot_path, "wb").write(png)
s = result.get("structuredContent") or {}
summary = {
    "pid": s.get("pid"), "window_id": s.get("window_id"),
    "element_count": s.get("element_count"),
    "screenshot_frame_valid": s.get("screenshot_frame_valid"),
    "screenshot_width": s.get("screenshot_width"),
    "screenshot_height": s.get("screenshot_height"),
    "screenshot_scale": s.get("screenshot_scale", s.get("screenshot_scale_factor")),
    "screenshot_mime_type": s.get("screenshot_mime_type", image["mimeType"]),
}
json.dump(summary, open(summary_path, "w", encoding="utf-8"), indent=2)
print(json.dumps(summary))
PY
}

install_driver_if_needed
echo "== Cua Driver happy-path reproduction =="
echo "Trace directory: $TRACE_DIR"

require_running_daemon "$TRACE_DIR/00-daemon-before.txt"
cua-driver permissions status --json >"$TRACE_DIR/00-permissions.json"
if ! permissions_are_granted "$TRACE_DIR/00-permissions.json"; then
  echo "macOS approval is interactive: enable CuaDriver for Accessibility and Screen Recording/direct capture."
  cua-driver permissions grant
  require_running_daemon "$TRACE_DIR/00-daemon-before.txt"
  cua-driver permissions status --json >"$TRACE_DIR/00-permissions.json"
  if ! permissions_are_granted "$TRACE_DIR/00-permissions.json"; then
    echo "ERROR: permissions remain ungranted; retry after enabling both switches in System Settings." >&2
    exit 1
  fi
fi

require_running_daemon "$TRACE_DIR/00-daemon-before.txt"
DAEMON_PID_BEFORE="$(daemon_pid_from_status "$TRACE_DIR/00-daemon-before.txt")"

echo "[1/3] list_apps"
mcp_call "01" "list_apps" '{}'
APP_SELECTION="$(select_app)"
TARGET_PID="${APP_SELECTION%%$'\t'*}"
TARGET_APP="${APP_SELECTION#*$'\t'}"

echo "[2/3] list_windows"
mcp_call "02" "list_windows" "$(printf '{"pid":%s,"on_screen_only":true}' "$TARGET_PID")"
TARGET_WINDOW_ID="$(select_window)"

echo "[3/3] get_window_state"
mcp_call "03" "get_window_state" "$(printf '{"pid":%s,"window_id":%s,"include_screenshot":true}' "$TARGET_PID" "$TARGET_WINDOW_ID")"
SUMMARY_JSON="$(extract_screenshot_and_summary)"

if [[ ! -s "$FINAL_SCREENSHOT" ]] || ! /usr/bin/file "$FINAL_SCREENSHOT" | /usr/bin/grep -q 'PNG image data'; then
  echo "ERROR: final screenshot is missing, empty, or not a valid PNG: $FINAL_SCREENSHOT" >&2
  exit 1
fi
/usr/bin/sips -g pixelWidth -g pixelHeight "$FINAL_SCREENSHOT" >/dev/null

# Proxies ended at stdin EOF above; compare the long-running daemon around them.
cua-driver status >"$TRACE_DIR/04-daemon-after.txt" 2>&1
DAEMON_PID_AFTER="$(daemon_pid_from_status "$TRACE_DIR/04-daemon-after.txt")"
if [[ -z "$DAEMON_PID_AFTER" ]]; then
  echo "ERROR: daemon did not remain available after MCP sessions." >&2
  exit 1
fi

python3 - "$SUMMARY_JSON" "$TARGET_APP" "$TARGET_PID" "$TARGET_WINDOW_ID" <<'PY'
import json, sys
s = json.loads(sys.argv[1])
print(f"app: {sys.argv[2]}")
print(f"pid: {sys.argv[3]}")
print(f"window_id: {sys.argv[4]}")
print(f"element_count: {s['element_count']}")
print(f"screenshot_frame_valid: {s['screenshot_frame_valid']}")
print(f"screenshot dimensions: {s['screenshot_width']}x{s['screenshot_height']}")
print(f"screenshot scale: {s['screenshot_scale']}")
print(f"screenshot MIME type: {s['screenshot_mime_type']}")
PY

if [[ "$DAEMON_PID_BEFORE" == "$DAEMON_PID_AFTER" ]]; then
  echo "Daemon lifetime proof: MCP Proxy sessions ended; daemon PID $DAEMON_PID_AFTER remained alive."
else
  echo "NOTE: daemon PID changed ($DAEMON_PID_BEFORE → $DAEMON_PID_AFTER); inspect 00/04 daemon status traces."
fi
echo "Screenshot: $FINAL_SCREENSHOT"
echo "Traces: $TRACE_DIR"

# Optional after success: open "$FINAL_SCREENSHOT"
