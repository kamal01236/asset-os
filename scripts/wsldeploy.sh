#!/usr/bin/env bash
# Build Flutter web artifacts for local use (WSL).
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

if [[ ! -d "$WEB" ]]; then
  echo "error: Flutter app not found at ${WEB}" >&2
  exit 1
fi

cd "$WEB"

echo "==> flutter build web"
flutter build web

OUT="${WEB}/build/web"
if [[ ! -d "$OUT" ]]; then
  echo "error: expected web build output not found at ${OUT}" >&2
  exit 1
fi

echo
echo "Web build succeeded."
echo "  Artifacts: ${OUT}"
echo
echo "Serve locally and open the printed URL:"
echo "  ./scripts/dev.sh servelocal"
echo "  # from Windows PowerShell: .\\scripts\\wsl.ps1 servelocal"
echo
echo "Optional port: ./scripts/dev.sh servelocal 8787"
echo "For a public feedback URL, use: ./scripts/flydeploy.sh"
