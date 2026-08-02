#!/usr/bin/env bash
# Run the Flutter app on web (Chrome preferred on Linux, else web-server) in WSL.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_lib.sh
source "${SCRIPT_DIR}/_lib.sh"

WEB="$(web_dir)"

if ! ensure_flutter_on_path; then
  echo "error: flutter not found. Run ./scripts/setup.sh first." >&2
  exit 1
fi

require_cmd flutter
ensure_chrome_executable || true

device="$(require_web_device)"
echo "==> Using web device: ${device}"

if [[ ! -d "$WEB" ]]; then
  echo "error: Flutter app not found at ${WEB}" >&2
  exit 1
fi

cd "$WEB"

if [[ "$device" == "web-server" ]]; then
  if [[ "${ASSET_OS_CHROME_KIND:-}" == "windows" ]]; then
    echo "    Windows Chrome detected under WSL — using web-server (more reliable)."
  else
    echo "    No native Linux Chrome — using web-server."
  fi
  echo "    Open the URL Flutter prints (usually http://localhost:xxxx) in your browser."
  exec flutter run -d web-server --web-hostname=0.0.0.0 "$@"
fi

exec flutter run -d "$device" "$@"
