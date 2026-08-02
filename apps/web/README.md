# Hando — Flutter web client

Flutter shell for Hando (web for local validation and Fly.io feedback). Native packaging is deferred until after feedback.

## Local-first foundation

- **Source of truth:** Drift (SQLite). On web, `sqlite3.wasm` and `drift_worker.js` live under `web/`.
- **State:** Riverpod providers watch repository streams; UI screens are `ConsumerWidget`s.
- **Migration:** One-time import from SharedPreferences `asset_os_snapshot_v1` when the DB is empty; otherwise demo seed on first empty boot.
- **Sync / encryption:** Not implemented yet — see [ADR-002](../../docs/architecture/decisions/ADR-002-local-first-foundation.md).

After dependency or schema changes:

```bash
cd apps/web
dart run build_runner build --delete-conflicting-outputs
```

## Dev commands

Use repo-root scripts from WSL (or `.\scripts\wsl.ps1` from Windows):

```bash
./scripts/setup.sh
./scripts/localrun.sh      # Chrome / web-server
./scripts/test.sh
./scripts/wsldeploy.sh     # flutter build web
./scripts/flydeploy.sh     # deploy to Fly.io
```

See the [repository README](../../README.md) for the full command table and Fly.io feedback workflow.

## Business Templates

**More → Business Templates** → pick an industry → select starter items → **Add selected to inventory** (merge; same-name items are skipped). Edit existing rows from Inventory detail.
