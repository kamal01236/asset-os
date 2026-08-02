#!/usr/bin/env bash
# Bootstrap Flutter web tooling for apps/web (WSL).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_lib.sh
source "${SCRIPT_DIR}/_lib.sh"

ROOT="$(repo_root)"
WEB="$(web_dir)"

echo "==> Hando setup (Flutter web)"
echo "    repo: ${ROOT}"
echo "    web:  ${WEB}"

if ! ensure_flutter_on_path; then
  echo "error: flutter not found on PATH (also checked ~/flutter/bin and /opt/flutter/bin)." >&2
  echo "  Install Flutter stable: https://docs.flutter.dev/get-started/install/linux" >&2
  exit 1
fi

require_cmd flutter

echo "==> flutter config (web)"
flutter config --no-analytics >/dev/null 2>&1 || true
flutter config --enable-web >/dev/null 2>&1 || true

if ensure_chrome_executable; then
  echo "    CHROME_EXECUTABLE=${CHROME_EXECUTABLE} (${ASSET_OS_CHROME_KIND})"
  if [[ "${ASSET_OS_CHROME_KIND}" == "windows" ]]; then
    echo "    note: Windows Chrome under WSL — localrun uses web-server + browser URL"
  fi
else
  echo "warning: Chrome/Chromium not found. localrun will use web-server (URL in terminal)." >&2
  echo "  Optional: apt install chromium-browser, or set CHROME_EXECUTABLE" >&2
fi

echo "==> flutter doctor (web-only: ignore Android/Linux desktop ✗)"
flutter doctor -v || true

if [[ ! -d "$WEB" ]]; then
  echo "error: Flutter app not found at ${WEB}" >&2
  exit 1
fi

if [[ ! -d "${WEB}/web" ]]; then
  echo "==> enabling web platform under apps/web"
  (
    cd "$WEB"
    flutter create --platforms=web .
  )
fi

echo "==> flutter pub get"
(
  cd "$WEB"
  flutter pub get
  # Regenerate Drift sources when schema/deps change.
  if [[ -f "$WEB/lib/core/db/app_database.dart" ]]; then
    echo "==> dart run build_runner (Drift)"
    dart run build_runner build
  fi
)

echo
echo "Setup complete (web)."
echo "Next steps:"
echo "  ./scripts/test.sh          # analyze + unit/widget tests"
echo "  ./scripts/localrun.sh      # run in Chrome or web-server"
echo "  ./scripts/wsldeploy.sh     # flutter build web (artifacts under build/web)"
echo "  ./scripts/servelocal.sh    # serve build/web and print open URL"
echo "  ./scripts/flydeploy.sh     # deploy static web app to Fly.io"
echo "  ./scripts/dev.sh doctor    # re-check tooling (Chrome ✓ is enough)"
