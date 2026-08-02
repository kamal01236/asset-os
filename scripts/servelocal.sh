#!/usr/bin/env bash
# Serve Flutter web build artifacts locally (static http.server).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_lib.sh
source "${SCRIPT_DIR}/_lib.sh"

DEFAULT_PORT="${ASSET_OS_SERVE_PORT:-8080}"
PORT="${1:-$DEFAULT_PORT}"
if [[ $# -gt 0 ]]; then
  shift
fi

WEB="$(web_dir)"
OUT="${WEB}/build/web"

if [[ ! -d "$OUT" ]]; then
  echo "error: web build not found at ${OUT}" >&2
  echo "  Run first: ./scripts/dev.sh wsldeploy" >&2
  exit 1
fi

require_cmd python3

# Return PIDs listening on TCP $1 (best-effort; empty if unknown).
pids_on_port() {
  local port="$1"
  local pids=""
  if command -v ss >/dev/null 2>&1; then
    pids="$(ss -tlnp "sport = :${port}" 2>/dev/null | sed -n 's/.*pid=\([0-9]\+\).*/\1/p' | sort -u || true)"
  fi
  if [[ -z "$pids" ]] && command -v fuser >/dev/null 2>&1; then
    pids="$(fuser "${port}/tcp" 2>/dev/null | tr ' ' '\n' | grep -E '^[0-9]+$' | sort -u || true)"
  fi
  if [[ -z "$pids" ]] && command -v lsof >/dev/null 2>&1; then
    pids="$(lsof -nP -t -iTCP:"${port}" -sTCP:LISTEN 2>/dev/null | sort -u || true)"
  fi
  echo "$pids"
}

is_our_http_server() {
  local pid="$1"
  local cmd=""
  if [[ -r "/proc/${pid}/cmdline" ]]; then
    cmd="$(tr '\0' ' ' <"/proc/${pid}/cmdline" 2>/dev/null || true)"
  else
    cmd="$(ps -p "$pid" -o args= 2>/dev/null || true)"
  fi
  # Only reclaim listeners we started (python http.server).
  [[ "$cmd" == *http.server* ]] && [[ "$cmd" == *python* ]]
}

port_is_free() {
  local port="$1"
  if command -v ss >/dev/null 2>&1; then
    ! ss -tln "sport = :${port}" 2>/dev/null | grep -qE ":${port}\\b"
    return
  fi
  python3 - "$port" <<'PY'
import socket, sys
port = int(sys.argv[1])
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
try:
    s.bind(("0.0.0.0", port))
except OSError:
    sys.exit(1)
finally:
    s.close()
sys.exit(0)
PY
}

# Free $1 only when our python http.server owns it. Returns 0 if free (or freed).
ensure_port_available() {
  local port="$1"
  local pids pid

  if port_is_free "$port"; then
    return 0
  fi

  pids="$(pids_on_port "$port")"
  if [[ -n "$pids" ]]; then
    for pid in $pids; do
      if is_our_http_server "$pid"; then
        echo "==> Stopping prior python http.server on port ${port} (pid ${pid})"
        kill "$pid" 2>/dev/null || true
        sleep 0.3
        kill -9 "$pid" 2>/dev/null || true
      else
        local cmd
        cmd="$(tr '\0' ' ' <"/proc/${pid}/cmdline" 2>/dev/null || ps -p "$pid" -o args= 2>/dev/null || echo "pid ${pid}")"
        echo "warning: port ${port} is in use by another process (not our http.server):" >&2
        echo "  ${cmd}" >&2
        return 1
      fi
    done
  else
    # Bound but no PID (e.g. Docker publish / another namespace) — do not force-kill.
    echo "warning: port ${port} is already in use (listener not owned by this user / docker publish)." >&2
    return 1
  fi

  if port_is_free "$port"; then
    return 0
  fi
  echo "warning: port ${port} still busy after stopping prior http.server." >&2
  return 1
}

pick_port() {
  local preferred="$1"
  local candidate
  if ensure_port_available "$preferred"; then
    echo "$preferred"
    return 0
  fi
  for candidate in $(seq "$preferred" $((preferred + 20))); do
    if [[ "$candidate" -eq "$preferred" ]]; then
      continue
    fi
    if port_is_free "$candidate"; then
      echo "note: port ${preferred} busy — using ${candidate} instead." >&2
      echo "$candidate"
      return 0
    fi
  done
  echo "error: no free port found near ${preferred}." >&2
  exit 1
}

PORT="$(pick_port "$PORT")"
URL="http://localhost:${PORT}"

echo
echo "========================================"
echo "  Hando local static serve"
echo "  Open: ${URL}"
echo "========================================"
echo "  Directory: ${OUT}"
echo "  Stop with Ctrl+C"
echo

# Bind all interfaces so Windows browser can reach WSL.
exec python3 -m http.server "$PORT" --bind 0.0.0.0 --directory "$OUT"
