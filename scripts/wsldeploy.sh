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
echo "Serve locally (pick one):"
echo "  cd apps/web && flutter run -d web-server --web-hostname=0.0.0.0"
echo "  python3 -m http.server 8080 --directory ${OUT}"
echo "  npx --yes serve ${OUT}"
echo
echo "Then open http://localhost:8080 (or the port you chose) in a browser."
echo "For a public feedback URL, use: ./scripts/flydeploy.sh"
