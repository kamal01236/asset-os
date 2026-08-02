#!/usr/bin/env bash
# Shared helpers for Hando WSL scripts (Flutter web).
# shellcheck disable=SC2034

set -euo pipefail

_lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

repo_root() {
  cd "${_lib_dir}/.." && pwd
}

web_dir() {
  echo "$(repo_root)/apps/web"
}

require_cmd() {
  local cmd="$1"
  local hint="${2:-}"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "error: required command not found: $cmd" >&2
    if [[ -n "$hint" ]]; then
      echo "  hint: $hint" >&2
    fi
    exit 1
  fi
}

ensure_flutter_on_path() {
  if command -v flutter >/dev/null 2>&1; then
    return 0
  fi
  if [[ -x "${HOME}/flutter/bin/flutter" ]]; then
    export PATH="${HOME}/flutter/bin:${PATH}"
    return 0
  fi
  if [[ -x "/opt/flutter/bin/flutter" ]]; then
    export PATH="/opt/flutter/bin:${PATH}"
    return 0
  fi
  return 1
}

# Prefer native Linux Chrome/Chromium. Windows chrome.exe under /mnt/c often fails to
# launch from WSL; we still record it but callers should prefer web-server then.
# Returns 0 if any chrome-like binary is found; sets:
#   CHROME_EXECUTABLE
#   ASSET_OS_CHROME_KIND=linux|windows
ensure_chrome_executable() {
  if [[ -n "${CHROME_EXECUTABLE:-}" ]]; then
    if [[ -x "${CHROME_EXECUTABLE}" || -f "${CHROME_EXECUTABLE}" ]]; then
      if [[ "${CHROME_EXECUTABLE}" == /mnt/c/* || "${CHROME_EXECUTABLE}" == *.exe ]]; then
        ASSET_OS_CHROME_KIND=windows
      else
        ASSET_OS_CHROME_KIND=linux
      fi
      export ASSET_OS_CHROME_KIND
      return 0
    fi
  fi

  local candidate
  for candidate in google-chrome google-chrome-stable chromium chromium-browser; do
    if command -v "$candidate" >/dev/null 2>&1; then
      export CHROME_EXECUTABLE
      CHROME_EXECUTABLE="$(command -v "$candidate")"
      export ASSET_OS_CHROME_KIND=linux
      return 0
    fi
  done

  for candidate in \
    "/mnt/c/Program Files/Google/Chrome/Application/chrome.exe" \
    "/mnt/c/Program Files (x86)/Google/Chrome/Application/chrome.exe"; do
    if [[ -f "$candidate" ]]; then
      export CHROME_EXECUTABLE="$candidate"
      export ASSET_OS_CHROME_KIND=windows
      return 0
    fi
  done

  return 1
}

# Prints a Flutter web device id (chrome or web-server) on stdout.
# Prefer Chrome only when a native Linux browser is available; otherwise web-server.
# Fails clearly if Flutter web support is missing entirely.
require_web_device() {
  require_cmd flutter

  ensure_chrome_executable || true

  local devices
  devices="$(flutter devices 2>/dev/null || true)"

  # Native Linux Chrome → use chrome device
  if [[ "${ASSET_OS_CHROME_KIND:-}" == "linux" ]]; then
    if echo "$devices" | grep -qiE 'chrome\s+•\s+chrome\s+•|Chrome\s+\(web\)'; then
      echo "chrome"
      return 0
    fi
  fi

  # web-server is always available when web is enabled (no GUI required)
  if echo "$devices" | grep -qiE 'Web Server\s+\(web\)|web-server\s+•\s+web-server'; then
    echo "web-server"
    return 0
  fi

  # Flutter lists chrome even for Windows chrome.exe; still prefer web-server in WSL
  if flutter config --list 2>/dev/null | grep -qi 'enable-web:\s*true'; then
    echo "web-server"
    return 0
  fi

  if echo "$devices" | grep -qiE 'chrome\s+•\s+chrome\s+•|Chrome\s+\(web\)'; then
    # Last resort: chrome device exists but web config check failed
    if [[ "${ASSET_OS_CHROME_KIND:-}" == "linux" ]]; then
      echo "chrome"
      return 0
    fi
    echo "web-server"
    return 0
  fi

  echo "error: no Flutter web device available (chrome / web-server)." >&2
  echo "  Enable web: flutter config --enable-web" >&2
  echo "  Then re-run ./scripts/setup.sh" >&2
  echo "  Check with: flutter devices" >&2
  exit 1
}
