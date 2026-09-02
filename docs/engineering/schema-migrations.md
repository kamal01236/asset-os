# Database schema migrations

Hando stores all operator data in a local Drift (SQLite) database. Schema changes must **never lose existing data** on upgrade — aligned with [Complete Idea Summary §error handling](../vision/complete-idea-summary.md).

## Baseline (v26)

| Artifact | Role |
|----------|------|
| `apps/web/lib/infrastructure/db/tables.dart` | Column definitions (source of truth) |
| `AppDatabase.onCreate` → `m.createAll()` | Fresh installs get the full v26 schema |
| `kSchemaBaselineVersion` (= 26) | Era marker; do **not** lower `schemaVersion` in shipped builds |
| `drift_schemas/drift_schema_v26.json` | Committed snapshot for drift schema tooling |

Fresh browsers and new installs never run legacy migrations — they receive the current schema via `onCreate`.

## Legacy vs forward migrations

```
Fresh install          → onCreate (createAll) → v26 schema
Existing DB (from < 24) → migrateLegacyToBaseline → v24 schema
Any DB at v24+         → runForwardMigration (one step per version)
```

| Module | Path | When to edit |
|--------|------|--------------|
| Legacy (frozen) | `migrations/legacy_migrations.dart` | **Never** (except critical bug fix via new forward step) |
| Forward | `migrations/forward_migrations.dart` | Every schema bump v25+ (living example: v26 `AuditEvents`) |

`app_database.dart` wires `onUpgrade`:

1. If `from < kSchemaBaselineVersion`, run `migrateLegacyToBaseline`.
2. Loop `from … to` calling `runForwardMigration(m, v + 1)` for each version.

## Checklist: adding schema v27+

1. **Bump** `schemaVersion` / `kSchemaBaselineVersion` by 1 (only when shipping the change).
2. **Update** `tables.dart` with the new column/table definition.
3. **Add exactly one** `case` in `runForwardMigration` for the new version.
   - Prefer `m.addColumn` / `m.createTable`.
   - Use table rebuild + `INSERT … SELECT` only when SQLite requires it.
   - Include `UPDATE` / `customStatement` backfills for non-null semantics or renamed values.
4. **Verify** `onCreate` still matches `tables.dart` (fresh install path).
5. **Add** a migration test in `test/schema_migration_test.dart` (or extend `test/support/schema_fixtures.dart`).
6. **Regenerate** the schema snapshot:

   ```bash
   cd apps/web
   dart run drift_dev schema dump lib/infrastructure/db/app_database.dart drift_schemas/drift_schema_v<N>.json
   ```

7. **Run** `.\scripts\wsl.ps1 test unit` (and full `test` before PR).

## Schema snapshot

`apps/web/build.yaml` sets `schema_dir: drift_schemas/`. After changing `tables.dart`, dump the new baseline:

```bash
cd apps/web
dart run drift_dev schema dump lib/infrastructure/db/app_database.dart drift_schemas/drift_schema_v26.json
```

Commit the generated `drift_schemas/drift_schema_v<N>.json`. Future CI may use Drift schema-step tests between versions.

## Tests

| Test | File | Intent |
|------|------|--------|
| Fresh install | `schema_migration_test.dart` | v26, all tables, spot-check columns |
| Legacy smoke (v22) | `schema_migration_test.dart` + `schema_fixtures.dart` | Near-baseline fixture → v23–v24 legacy steps complete |
| v23 → v24 | `schema_migration_test.dart` + `schema_fixtures.dart` | Row preserved; `reference_code` added nullable |
| v24 → v25 | `schema_migration_test.dart` | `media_attachments` created |
| v25 → v26 | `schema_migration_test.dart` | `audit_events` created |

> **Note:** A full v1→v24 jump can fail on `createTable` steps that use the current `tables.dart` definition (e.g. `money_loans` at v14). Incremental upgrades shipped version-by-version are unaffected. Near-baseline fixtures (v22/v23) validate the legacy module without re-running all historical steps.

Run: `.\scripts\wsl.ps1 test unit` (tag `@Tags(['unit'])`).

## Related

- [ADR-002: Local-First Foundation](../architecture/decisions/ADR-002-local-first-foundation.md) — Drift as source of truth
- [Test Suites](test-suites.md) — tagged suites and dependency map
