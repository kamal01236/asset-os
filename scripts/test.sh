#!/usr/bin/env bash
# Analyze and test apps/web (WSL).
# Suite target: lean harness (seedDemo:false) keeps most cases off full demo seed.
#
# Usage:
#   ./scripts/test.sh                 # analyze + all tests
#   ./scripts/test.sh all             # same
#   ./scripts/test.sh unit|widget|integration
#   ./scripts/test.sh orders|pricing|returns|…  # domain tags
#   ./scripts/test.sh -- --tags orders,pricing  # passthrough to flutter test
#
# Env:
#   TEST_SKIP_ANALYZE=1   skip flutter analyze (tight loops)
#   TEST_CONCURRENCY=N    override flutter test concurrency
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_lib.sh
source "${SCRIPT_DIR}/_lib.sh"

WEB="$(web_dir)"

# Layer + domain suites declared in apps/web/dart_test.yaml
KNOWN_SUITES=(
  all
  unit
  widget
  integration
  pricing
  orders
  returns
  inventory
  customers
  deposit
  search
  shell
  reports
  notes
  labels
  loans
)

usage() {
  cat <<'EOF'
Usage: ./scripts/test.sh [suite|all] [-- flutter-test-args...]
       ./scripts/test.sh -- --tags orders,pricing

Suites (analyze first unless TEST_SKIP_ANALYZE=1):
  all            All tests (default)
  unit           --tags unit
  widget         --tags widget
  integration    --tags integration
  pricing orders returns inventory customers deposit
  search shell reports notes labels loans

See docs/engineering/test-suites.md for dependency → suite map.
EOF
}

is_known_suite() {
  local candidate="$1"
  local s
  for s in "${KNOWN_SUITES[@]}"; do
    if [[ "$s" == "$candidate" ]]; then
      return 0
    fi
  done
  return 1
}

if ! ensure_flutter_on_path; then
  echo "error: flutter not found. Run ./scripts/setup.sh first." >&2
  exit 1
fi

require_cmd flutter

if [[ ! -d "$WEB" ]]; then
  echo "error: Flutter app not found at ${WEB}" >&2
  exit 1
fi

SUITE="all"
EXTRA_ARGS=()

if [[ $# -gt 0 ]]; then
  if [[ "$1" == "-h" || "$1" == "--help" || "$1" == "help" ]]; then
    usage
    exit 0
  fi
  if [[ "$1" == "--" ]]; then
    shift
    EXTRA_ARGS=("$@")
  elif is_known_suite "$1"; then
    SUITE="$1"
    shift
    if [[ $# -gt 0 && "$1" == "--" ]]; then
      shift
    fi
    EXTRA_ARGS=("$@")
  else
    echo "error: unknown suite '${1}'." >&2
    usage
    exit 1
  fi
fi

cd "$WEB"

if [[ "${TEST_SKIP_ANALYZE:-}" != "1" ]]; then
  echo "==> flutter analyze"
  flutter analyze
else
  echo "==> flutter analyze (skipped; TEST_SKIP_ANALYZE=1)"
fi

# Prefer explicit override; else nproc (WSL/Linux). Fallback 4 if nproc missing.
DEFAULT_CONCURRENCY="$(nproc 2>/dev/null || echo 4)"
CONCURRENCY="${TEST_CONCURRENCY:-$DEFAULT_CONCURRENCY}"

TAG_ARGS=()
if [[ "$SUITE" != "all" ]]; then
  TAG_ARGS=(--tags "$SUITE")
  echo "==> flutter test suite=${SUITE} (concurrency=${CONCURRENCY})"
else
  echo "==> flutter test (all) (concurrency=${CONCURRENCY})"
fi

flutter test --concurrency="${CONCURRENCY}" --reporter=compact "${TAG_ARGS[@]}" "${EXTRA_ARGS[@]}"

echo
echo "All checks passed."
