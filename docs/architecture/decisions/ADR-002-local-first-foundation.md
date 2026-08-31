# ADR-002: Local-First Foundation (Drift + Riverpod)

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-08-02 |
| **Decision** | Drift SQLite as local source of truth; Riverpod for reactive UI state |

---

## Context

The UI-first shell stored a JSON snapshot in SharedPreferences and drove the UI with `ChangeNotifier` / `AppStateScope`. Vision docs and [ADR-001](ADR-001-mobile-stack.md) call for a local-first foundation: SQLite as source of truth, a repository layer, and a state approach that keeps future sync additive.

---

## Decision

In `apps/web`:

- Use **Drift** (SQLite; web via `drift_flutter` + `sqlite3.wasm` / `drift_worker.js`) as the local persistence source of truth.
- Use **Riverpod** (`flutter_riverpod`) for reactive app state (lists, tab index, offline demo toggle).
- Expose a thin **`LocalRepository` facade** over Drift tables so existing Home / Rentals / Inventory / Customers / Search / Scan / flow screens keep the same workflows with wiring-only changes.
- On first boot after upgrade: if the Drift DB is empty and SharedPreferences key `asset_os_snapshot_v1` exists, **migrate once** into Drift, then clear the prefs key. If neither exists, **seed demo data**.
- Keep domain models in `lib/domain/models/`; tables live under `lib/infrastructure/db/`; providers under `lib/application/providers/`. Folder map and dependency rules: [ADR-005](ADR-005-client-layering.md).

---

## Consequences

- Core workflows no longer depend on SharedPreferences snapshots or `ChangeNotifier` app state.
- Sync, SQLCipher encryption, real camera QR, notifications, reports, and native packaging remain **out of scope** (future ADRs).
- Web deploys must serve `sqlite3.wasm` with `Content-Type: application/wasm` (GitHub Pages does this in normal cases). SPA deep links on Pages use a copied `404.html` (same content as `index.html`) from the CI build.

---

## Related

- [Complete Idea Summary §9 / §14](../../vision/complete-idea-summary.md)
- [Schema migrations](../../engineering/schema-migrations.md) — baseline v24, incremental upgrades
- [ADR-001: Flutter Web Client](ADR-001-mobile-stack.md)
