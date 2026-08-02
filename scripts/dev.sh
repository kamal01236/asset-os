#!/usr/bin/env bash
# Single entrypoint for Asset OS WSL dev commands (web).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_lib.sh
source "${SCRIPT_DIR}/_lib.sh"

usage() {
  cat <<'EOF'
Usage: ./scripts/dev.sh <command> [args...]

Commands:
  setup       Bootstrap Flutter web tooling and pub get
  localrun    Run the app on Chrome or web-server (extra args → flutter run)
  test        flutter analyze + flutter test
  wsldeploy   Build web artifacts (build/web) and print serve hints
  flydeploy   Deploy static web app to Fly.io (requires fly auth login)
  doctor      flutter doctor -v
  help        Show this help

Web client only. Native Android/iOS packaging is deferred until after feedback.
EOF
}

cmd="${1:-}"
if [[ -z "$cmd" ]]; then
  usage
  exit 1
fi
shift || true

case "$cmd" in
  setup)
    exec bash "${SCRIPT_DIR}/setup.sh" "$@"
    ;;
  localrun)
    exec bash "${SCRIPT_DIR}/localrun.sh" "$@"
    ;;
  test)
    exec bash "${SCRIPT_DIR}/test.sh" "$@"
    ;;
  wsldeploy)
    exec bash "${SCRIPT_DIR}/wsldeploy.sh" "$@"
    ;;
  flydeploy)
    exec bash "${SCRIPT_DIR}/flydeploy.sh" "$@"
    ;;
  doctor)
    if ! ensure_flutter_on_path; then
      echo "error: flutter not found. Run ./scripts/setup.sh first." >&2
      exit 1
    fi
    require_cmd flutter
    exec flutter doctor -v
    ;;
  help|-h|--help)
    usage
    ;;
  *)
    echo "error: unknown command: ${cmd}" >&2
    usage
    exit 1
    ;;
esac
