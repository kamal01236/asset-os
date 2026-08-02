#!/usr/bin/env bash
# Deploy Flutter web (Docker/nginx) to Fly.io for customer feedback.
# CI deploys via .github/workflows/fly-deploy.yml (push to main / workflow_dispatch).
# Prefer this script for local/first-time deploys (creates the app if missing).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_lib.sh
source "${SCRIPT_DIR}/_lib.sh"

ROOT="$(repo_root)"
cd "$ROOT"

FLY_BIN=""
if command -v flyctl >/dev/null 2>&1; then
  FLY_BIN="flyctl"
elif command -v fly >/dev/null 2>&1; then
  FLY_BIN="fly"
else
  echo "error: Fly CLI not found (flyctl / fly)." >&2
  echo "  Install: https://fly.io/docs/hands-on/install-flyctl/" >&2
  echo "  Then: fly auth login" >&2
  exit 1
fi

if ! "$FLY_BIN" auth whoami >/dev/null 2>&1; then
  echo "error: not authenticated with Fly.io." >&2
  echo "  Run: fly auth login" >&2
  echo "  Then re-run: ./scripts/flydeploy.sh" >&2
  exit 1
fi

if [[ ! -f "${ROOT}/fly.toml" ]]; then
  echo "error: fly.toml not found at repo root." >&2
  exit 1
fi

if [[ ! -f "${ROOT}/Dockerfile" ]]; then
  echo "error: Dockerfile not found at repo root." >&2
  exit 1
fi

echo "==> Deploying Asset OS web to Fly.io (${FLY_BIN})"
echo "    app config: ${ROOT}/fly.toml"
echo

# Create the app on first deploy if it does not exist yet.
app_name="$(grep -E '^app\s*=' "${ROOT}/fly.toml" | head -1 | sed -E 's/^app\s*=\s*"?([^"]+)"?.*/\1/' || true)"
if [[ -n "$app_name" ]]; then
  if ! "$FLY_BIN" status -a "$app_name" >/dev/null 2>&1; then
    echo "==> App '${app_name}' not found — creating (first deploy)"
    "$FLY_BIN" apps create "$app_name" --org personal 2>/dev/null \
      || "$FLY_BIN" apps create "$app_name" \
      || {
        echo "error: could not create Fly app '${app_name}'." >&2
        echo "  Create manually: fly apps create ${app_name}" >&2
        echo "  Or edit app name in fly.toml if taken." >&2
        exit 1
      }
  fi
fi

"$FLY_BIN" deploy

echo
echo "Deploy finished."
echo "  Share the public URL from the deploy output for customer feedback."
echo "  Status: ${FLY_BIN} status"
echo "  Open:   ${FLY_BIN} open"
