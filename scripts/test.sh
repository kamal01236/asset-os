#!/usr/bin/env bash
# Analyze and test apps/web (WSL).
# Suite target: lean harness (seedDemo:false) keeps most cases off full demo seed.
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

echo "==> flutter analyze"
flutter analyze

# Prefer explicit override; else nproc (WSL/Linux). Fallback 4 if nproc missing.
DEFAULT_CONCURRENCY="$(nproc 2>/dev/null || echo 4)"
CONCURRENCY="${TEST_CONCURRENCY:-$DEFAULT_CONCURRENCY}"
echo "==> flutter test (concurrency=${CONCURRENCY})"
flutter test --concurrency="${CONCURRENCY}" --reporter=compact

echo
echo "All checks passed."
