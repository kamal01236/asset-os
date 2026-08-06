# ADR-004: Business Resources Domain Direction

| Field | Value |
|-------|-------|
| **Status** | Accepted; phases 1–5 implemented; configurable engine MVP complete |
| **Date** | 2026-08-06 |
| **Decision** | Hando’s long-term domain is **Business → Resources → Transactions → Reports**, not Inventory → Rental alone |

---

## Context

Hando ships rental-first UX today (`InventoryItem`, `Rental`, industry templates). Multi-industry templates — camera rental, gym, boutique, salon, mechanic, library, and similar — make “Inventory” and “Asset Movement” alone too narrow as the lasting product language.

The product SoT already aims at **one engine + configuration**, not forked apps per industry. This ADR locks the long-term domain names and mapping so later phases (UI rename, type expansion, workflows, dynamic fields) stay aligned without implying schema or code changes in this slice.

---

## Decision

Treat Hando’s enduring domain as:

```text
Business → Resources → Transactions → Reports
```

### Resource

**Resource** is the catalog unit: a physical item, service, job, membership, digital asset, or financial record the business manages. Configuration (resource type + template pack) shapes fields, status vocabulary, and home widgets — not a separate module per industry.

### Resource types (configuration, not separate modules)

| Type | Role (examples) |
|------|-----------------|
| Rental Item | Cameras, tools, costumes — lend / return |
| Sale Item | Boutique SKUs, parts — sell / stock |
| Service | Salon treatments, consulting hours |
| Job | Mechanic work orders, repair tickets |
| Subscription | Recurring service entitlement (New Order default: **sell**) |
| Membership | Gym / club access (New Order default: **sell**) |
| Loan | Issue without rental commercial terms (default: **rent**) |
| Financial | Deposits, fees, credits as catalogued lines |
| Custom | Template-defined type when none of the above fit |

**Implemented:** full `ResourceType` enum on the catalog (`default_item_kind` column); legacy `general` migrated to `sale`. New Order still bridges to Rent / Sell / Job line fulfillment only. Membership and subscription fulfill as sell; loan as rent.

### Transaction

**Transaction** is the universal action: customer (or counterparty) + resource lines + status + timeline. Current `Rental` / order is the first concrete transaction shape. Other shapes (sale, job ticket, membership period, loan) share the same conceptual stack when enabled by template.

### Template = configuration pack

An industry / business template is a **configuration pack**, not a forked codebase:

- Enabled resource types
- Default fields / terminology (`FieldDef` + `extraFieldIds`)
- Home widget set
- Status vocabulary (`WorkflowDefinition` presets)
- Report widgets (`ReportWidgetId` packs)

**Same DB, different config** is the north star. Dynamic field values live as JSON on `inventory_items.metadata`. Share Reports composes plain-text sections from template `defaultReportWidgets`. Workflow status ids live on `rentals.workflow_status` (nullable); billing still uses `OrderStatus`.

### Current mapping (code / schema → product language)

```text
InventoryItem     → Business Resource (catalog; Dart/table names unchanged)
ResourceType      → full type set (rental | sale | service | job | …)
Rental / Order    → Transaction
RentalEvent       → Transaction timeline
IndustryTemplate  → Business configuration pack (types + Home + workflow + fields + reports)
FieldDef          → Dynamic catalog field registry (JSON metadata)
ReportWidgetId    → Composable Share Reports sections
WorkflowDefinition→ Status pipeline preset (rental / boutique / job / salon)
HomeModuleId      → Dashboard widget config (template presets)
```

Product language is **Resources**. Code and Drift keep `InventoryItem` / `inventory_items` / `Rental` until an explicit rename ADR/PR.

### Non-goals (near-term)

- ERP or full accounting suite
- Marketplace or customer-facing storefront as the product identity
- Separate product / codebase per industry
- Claiming the full configurable engine ships in V1
- Free-form custom status editor beyond template presets
- Plugin marketplace; PDF/Excel beyond WhatsApp plain-text share

### Constitution check

Direction stays **local-first / offline-first / cloud-optional**. Template and resource-type configuration must work without network; cloud remains additive.

### Evolution ladder

```text
Offline Register → Digital Rental → Asset Handover
  → Business Resources Platform → Configurable Business OS
```

Asset / Person remain useful related concepts (Digital Asset Passport, customers / members). They sit under the Business Resources stack rather than competing with it.

---

## Consequences

- Docs and planning use **Business Resource / Transaction / Reports** as canonical long-term language.
- **Phases 1–3 done in product:** UI/l10n say Resources (en+hi); `ResourceType` replaces `InventoryItemKind` with same-table migration (`general` → `sale`); industry templates declare `enabledResourceTypes` + Home module presets, persisted and used to gate New Order More-options Sell/Job (catalog items stay visible).
- **Phase 0 leftovers closed:** demo/legacy rental-only derivation no longer silently hides Sell/Job; More → enabled resource types multi-select; membership/subscription → sell fulfillment; import **merges** types, Home layout apply **replaces** them (UX copy).
- **Phase 4 done:** `WorkflowDefinition` presets on templates; active workflow id in prefs; `rentals.workflow_status` (schema v12); order detail Advance / pick next; timeline `status_changed`; terminal workflow → `OrderStatus.completed`; cancel stays cancelled.
- **Phase 5 done:** `FieldDef` registry + template `extraFieldIds`; `inventory_items.metadata` JSON (schema v13); add/edit resource shows type-relevant fields; `ReportBuilder` composable `ReportWidgetId` sections; templates declare `defaultReportWidgets`; Share Reports builds from that list + locale (plain text, no charts). **Configurable engine MVP is complete.**

### Implementation phases (ordered)

1. **UI / l10n rename** Inventory → Resources (+ Hindi), without requiring a full schema rename — **done**.
2. **Expand `ResourceType`** and migrate `InventoryItemKind` storage — **done**.
3. **Template packs** declare enabled types + home widget sets — **done**.
4. **Configurable statuses / workflows** per template — **done**.
5. **Dynamic fields** per type; universal reports as widgets — **done** (engine MVP complete).

### Later track (not in engine MVP phases 4–5)

These stay **out of** the configurable-engine MVP (phases 4–5). Document here so they are not pulled into workflow/fields PRs:

| Item | Why later |
|------|-----------|
| Rename `Rental` / `InventoryItem` types & tables | Large churn; product language already says Resources / Transaction |
| New `HomeModuleId`s (check-ins, delivery board, etc.) | Needs workflows + richer data first; compose existing modules until then |
| AI morning brief / suggestions depth | No extra architecture once reports/timeline exist; separate epic |
| Rule engine / payments / sync | SoT Future; constitution keeps local-first |

---

## Related

- [Complete Idea Summary §13](../../vision/complete-idea-summary.md#13-universal-platform--10-year-vision)
- [ADR-002: Local-First Foundation](ADR-002-local-first-foundation.md)
