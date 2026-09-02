# ADR-005: Client layering in `apps/web`

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-08-08 |
| **Decision** | Layered monolith under `apps/web/lib`: presentation / application / domain / infrastructure |

---

## Context

Product SoT §9 already specifies Flutter layers (Presentation → Application → Domain → Data / Local Storage). The client instead dumped widgets, Riverpod, Drift, pricing math, and templates under `lib/core/`, while [ADR-002](ADR-002-local-first-foundation.md) and Cursor rules told contributors to keep putting everything there.

This pass is **structure only**: move files to match the SoT layers so new work lands in the right place. Runtime behavior stays identical. No use-case extraction, no `app_shell` screen split, no hexagonal ports/adapters, and no `lib/core/` compatibility shims.

SoT “Data / Local Storage” maps to **infrastructure** in this tree (Drift SQLite, WhatsApp share, l10n helpers). Composition root stays [`apps/web/lib/main.dart`](../../../apps/web/lib/main.dart). Generated gen-l10n stays at [`apps/web/lib/l10n/`](../../../apps/web/lib/l10n/) per `l10n.yaml`.

---

## Decision

Organize `apps/web` as a **layered monolith** (one Flutter package, four folders).

### Folder map

| Layer | Path | Contents |
|-------|------|----------|
| Presentation | `lib/presentation/` | `app_shell.dart`, `features/**`, `widgets/**`, `theme/`, `transactions/transaction_list_item.dart`, `validation/input_formatters.dart` |
| Application | `lib/application/` | Riverpod `providers/`, `local_repository.dart` facade, `home/home_filter.dart`, `reports/report_builder.dart` |
| Domain | `lib/domain/` | models, pricing, loans, orders, templates, search, `validation/text_rules.dart`, inventory, `home/home_modules.dart`, `reports/report_models.dart` + `report_widgets.dart`, `config/app_branding.dart` |
| Infrastructure | `lib/infrastructure/` | `db/` (Drift; keep `part 'app_database.g.dart'` next to the library), `sharing/whatsapp_share.dart`, `l10n/` (`l10n_ext`, `timeline_l10n`, `india_date_format`) |
| Composition root | `lib/main.dart` | Wires prefs, Drift, repository, Riverpod overrides; may import every layer |
| Generated l10n | `lib/l10n/` | ARBs + `gen-l10n` output (not a layer) |

### Dependency rules (pass 1)

- **presentation** → application + domain; **must not** import `infrastructure/db` (Drift)
- **application** → domain + infrastructure
- **domain** → no `application/`, `presentation/`, `infrastructure/`, Drift, Riverpod, or `shared_preferences`
- **infrastructure** → domain (not presentation)
- **main.dart** → all layers

Enforced by this ADR, [`.cursor/rules/flutter-web-client.mdc`](../../../.cursor/rules/flutter-web-client.mdc), and `apps/web/test/architecture/layer_import_test.dart`.

### Temporary allowances

Documented impurities; do **not** “fix” in this pass:

- Presentation may call `LocalRepository` and `whatsapp_share` directly (no use-case/port extraction yet). Presentation may also import infrastructure l10n helpers (`l10n_ext`, date/timeline formatters) until those sit behind application APIs.
- Domain may import Flutter `Locale` / `AppLocalizations` where it already does (templates, workflows, field defs, inventory categories).
- `LocalRepository` remains a combined use-case facade + Drift adapter under application.

### Non-goals

- Hexagonal ports, Result types, or per-feature packages
- Splitting the repo / extracting `packages/*` modules
- Splitting `LocalRepository` into application use cases + infrastructure DAOs
- Removing Flutter from domain (`Locale` → `languageCode` strings)

---

## Consequences

- New UI lands under `lib/presentation/`; new business rules under `lib/domain/`; Drift schema under `lib/infrastructure/db/`.
- `lib/core/` must not return — no shims, no dump folder.
- Drift codegen still runs from `apps/web` (`dart run build_runner build --delete-conflicting-outputs`); `setup.sh` points at `lib/infrastructure/db/app_database.dart`.
- Branding constant stays `kAppDisplayName` in `lib/domain/config/app_branding.dart`.
- Track 5 completed the `app_shell.dart` screen split into `features/*` (customers, inventory, orders, more, shell) with a thin shell orchestrator.

---

## Related

- [Complete Idea Summary §9](../../vision/complete-idea-summary.md#9-system-architecture--technology)
- [ADR-002: Local-First Foundation](ADR-002-local-first-foundation.md)
- [ADR-001: Flutter Web Client](ADR-001-mobile-stack.md)
