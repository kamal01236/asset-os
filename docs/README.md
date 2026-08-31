# Documentation

Index for Hando (Asset Handover Platform) documentation.

## Documents

1. **[Complete Idea Summary](vision/complete-idea-summary.md)** — sole product source of truth: scope, architecture, workflows, edge cases, monetization, and delivery plan
2. **[ADR-001: Flutter Web Client](architecture/decisions/ADR-001-mobile-stack.md)** — Flutter web client now; native packaging later
3. **[ADR-002: Local-First Foundation](architecture/decisions/ADR-002-local-first-foundation.md)** — Drift + Riverpod local DB
4. **[ADR-003: UI Localization](architecture/decisions/ADR-003-localization.md)** — gen-l10n English default + Hindi
5. **[ADR-004: Business Resources](architecture/decisions/ADR-004-business-resources.md)** — Business → Resources → Transactions → Reports (direction; implementation deferred)
6. **[ADR-005: Client Layering](architecture/decisions/ADR-005-client-layering.md)** — presentation / application / domain / infrastructure in `apps/web`
7. **[ADR-006: Customer subscription tiers](architecture/decisions/ADR-006-customer-subscription-tiers.md)** — customer-owned nested tiers + period ledger (not shop-owner Hando plans)
8. **[Web UX Conventions](ux/web-ux-conventions.md)** — touch-friendly interaction rules, status semantics, and shell contracts
9. **[Phase 5 Extension Stubs](ux/phase5-extension-stubs.md)** — lightweight stubs for voice, templates, and AI suggestions
10. **[Test Suites](engineering/test-suites.md)** — tagged unit/widget/integration suites and dependency → suite map
11. **[Schema Migrations](engineering/schema-migrations.md)** — Drift baseline v24, legacy vs forward upgrades, and migration checklist

## Document conventions

- **Complete Idea Summary** is the product-facing reference for what we are building and why
- **ADRs** are engineering-facing: decisions, context, and consequences
