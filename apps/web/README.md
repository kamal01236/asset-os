# Hando — Flutter web + Android client

Flutter app for Hando: **web** (GitHub Pages) and **Android** (debug APK) from the same `lib/` codebase. See [ADR-008](../../docs/architecture/decisions/ADR-008-android-packaging.md).

## Local-first foundation

- **Source of truth:** Drift (SQLite). On **web**, `sqlite3.wasm` and `drift_worker.js` live under `web/`. On **Android**, native SQLite via `drift_flutter`.
- **Layers:** `lib/presentation/` (UI), `lib/application/` (Riverpod + `LocalRepository`), `lib/domain/` (rules), `lib/infrastructure/` (Drift + share + l10n helpers). Composition root is `lib/main.dart`. See [ADR-005](../../docs/architecture/decisions/ADR-005-client-layering.md).
- **State:** Riverpod providers watch repository streams; UI screens are `ConsumerWidget`s.
- **Migration:** One-time import from SharedPreferences `asset_os_snapshot_v1` when the DB is empty. Production first boot does **not** load the Priya/DSLR demo snapshot — only the Unknown customer sentinel, then the Language → Mode → WhatsApp (online) → industry-template wizard seeds inventory.
- **Sync / encryption:** Not implemented yet — see [ADR-002](../../docs/architecture/decisions/ADR-002-local-first-foundation.md).

After dependency or schema changes:

```bash
cd apps/web
dart run build_runner build --delete-conflicting-outputs
```

## Dev commands (web)

Use repo-root scripts from WSL (or `.\scripts\wsl.ps1` from Windows):

```bash
./scripts/setup.sh
./scripts/localrun.sh      # Chrome / web-server
./scripts/test.sh          # analyze + all flutter tests
./scripts/test.sh unit     # focused: unit|widget|integration|orders|pricing|…
./scripts/wsldeploy.sh     # flutter build web
```

Tags live in `dart_test.yaml` and `@Tags` on each `*_test.dart`. Dependency → suite map: [Test Suites](../../docs/engineering/test-suites.md). Override concurrency with `TEST_CONCURRENCY`; skip analyze with `TEST_SKIP_ANALYZE=1` for tight loops.

Unit tests use `test/support/test_harness.dart` with `seedDemo: false` by default (empty DB + Unknown sentinel). Widget/smoke flows that assert seeded demo names pass `seedDemo: true`. Expect a much faster suite than full demo seed per case.


Public preview: push to `main` → GitHub Pages at [https://kamal01236.github.io/asset-os/](https://kamal01236.github.io/asset-os/). See the [repository README](../../README.md) for setup and the full command table.

## Dev commands (Android, Windows)

From the repo root in PowerShell:

```powershell
.\scripts\setup-android.ps1
.\scripts\localrun-android.ps1
.\scripts\build-apk-debug.ps1
```

Requires Flutter on Windows PATH, Android SDK (API 34), JDK 17, and a device or emulator. See [ADR-008](../../docs/architecture/decisions/ADR-008-android-packaging.md).

## First launch

On an empty database, Hando runs a short onboarding wizard:

1. **Language** — English (default) or Hindi  
2. **Working mode** — Offline (default, local-first) or Online  
3. **WhatsApp** — only when Online; number required (OTP verification comes later)  
4. **Business type** — industry template packs starter inventory and Home layout  

There is no skip-empty path in this pass. Already-onboarded installs never re-prompt.

## Business Templates

After onboarding, **More → Business Templates** still lets you merge additional packs (pick an industry → multi-select starter items → **Add selected to inventory**; same-name items are skipped). Edit existing rows from Inventory detail.
