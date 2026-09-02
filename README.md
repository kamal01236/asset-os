# Hando

Privacy-first, offline-first operational tool for physical asset handovers.

Working product name is **Hando** (repo and package ids may still say `asset-os` / `asset_os`).

## Status

Product vision lives in the [Complete Idea Summary](docs/vision/complete-idea-summary.md). Flutter client at `apps/web` ships **web** (GitHub Pages) and **Android** (debug APK sideload) from one codebase. Play Store / iOS packaging remain deferred.

## Project Philosophy

- Local-first: business data remains on-device by default.
- Offline-first: core workflows work without internet access.
- Cloud-optional: sync and backup are additive, not required.
- Privacy-first: collect only what operations need.
- Simplicity-first: optimize for fast, low-friction field usage.

## Documentation

- **Start here:** [Complete Idea Summary](docs/vision/complete-idea-summary.md)
- Index: [Documentation Index](docs/README.md)
- Stack decision: [ADR-001: Flutter Web Client](docs/architecture/decisions/ADR-001-mobile-stack.md)
- Android packaging: [ADR-008: Android packaging](docs/architecture/decisions/ADR-008-android-packaging.md)

## App

Flutter client (web + Android): [`apps/web`](apps/web).

## Dev commands (WSL, web)

From the repo root inside WSL:

```bash
./scripts/setup.sh
./scripts/localrun.sh      # Chrome if available, else web-server URL
./scripts/test.sh          # analyze + all tests
./scripts/test.sh unit     # focused suite (also: widget, orders, pricing, …)
./scripts/wsldeploy.sh     # flutter build web → apps/web/build/web

# or one entrypoint
./scripts/dev.sh setup|localrun|test|wsldeploy|servelocal|doctor
```

From Windows PowerShell:

```powershell
.\scripts\wsl.ps1 setup
.\scripts\wsl.ps1 localrun
.\scripts\wsl.ps1 test
.\scripts\wsl.ps1 test unit      # focused; see docs/engineering/test-suites.md
.\scripts\wsl.ps1 test orders
.\scripts\wsl.ps1 wsldeploy
.\scripts\wsl.ps1 servelocal
```

### Android (Windows PowerShell)

Install Flutter stable, Android Studio (SDK API 34+), JDK 17, then:

```powershell
.\scripts\setup-android.ps1      # flutter doctor, pub get, build_runner
.\scripts\localrun-android.ps1   # flutter run -d android
.\scripts\build-apk-debug.ps1    # build/app/outputs/flutter-apk/app-debug.apk
```

Suite filters: [Test Suites](docs/engineering/test-suites.md). Prefer focused suites during feature work; full `test` before PR/push.

### Customer feedback (GitHub Pages)

**Public preview URL (use this):** [https://kamal01236.github.io/asset-os/](https://kamal01236.github.io/asset-os/)

1. Local preview: `./scripts/localrun.sh` — open the printed URL.
2. Public preview: push to `main` (or run **Actions → Deploy GitHub Pages → Run workflow**). CI builds Flutter web with `--base-href /asset-os/` and publishes via [`.github/workflows/pages-deploy.yml`](.github/workflows/pages-deploy.yml).

**Do not use** `https://asset-os-web.fly.dev` — that hostname is not this app. Fly.io deploy was removed after every CI deploy failed (empty/invalid `FLY_API_TOKEN`). Hosting is GitHub Pages only.

**One-time GitHub Pages setup** (already done for this public repo if the site loads):

1. Repo must be **public** (Free plan) or have GitHub Pro/Team for private Pages.
2. **Settings → Pages → Build and deployment → Source** = **GitHub Actions**.
3. After a successful **Deploy GitHub Pages** workflow, open the Pages URL above.
4. Optional cleanup: delete the obsolete **Production** environment and its `FLY_API_TOKEN` / `FLY_APP` / `FLY_ORG` secrets/vars from the old Fly.io attempt.
