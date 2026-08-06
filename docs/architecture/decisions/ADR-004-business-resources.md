# ADR-004: Business Resources Domain Direction

| Field | Value |
|-------|-------|
| **Status** | Accepted; phases 1–3 implemented in product |
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
| Subscription | Recurring service entitlement |
| Membership | Gym / club access |
| Loan | Issue without rental commercial terms |
| Financial | Deposits, fees, credits as catalogued lines |
| Custom | Template-defined type when none of the above fit |

**Implemented:** full `ResourceType` enum on the catalog (`default_item_kind` column); legacy `general` migrated to `sale`. New Order still bridges to Rent / Sell / Job line fulfillment only.

### Transaction

**Transaction** is the universal action: customer (or counterparty) + resource lines + status + timeline. Current `Rental` / order is the first concrete transaction shape. Other shapes (sale, job ticket, membership period, loan) share the same conceptual stack when enabled by template.

### Template = configuration pack

An industry / business template is a **configuration pack**, not a forked codebase:

- Enabled resource types
- Default fields / terminology
- Home widget set
- Status vocabulary
- Report widgets

**Same DB, different config** is the north star. Dynamic field JSON, workflow tables, and template-driven dashboards are **future schema** — not required for accepting this direction.

### Current mapping (code / schema → product language)

```text
InventoryItem     → Business Resource (catalog; Dart/table names unchanged)
ResourceType      → full type set (rental | sale | service | job | …)
Rental / Order    → Transaction
RentalEvent       → Transaction timeline
IndustryTemplate  → Business configuration pack (enabled types + Home modules)
HomeModuleId      → Dashboard widget config (template presets)
```

Product language is **Resources**. Code and Drift keep `InventoryItem` / `inventory_items` / `Rental` until an explicit rename ADR/PR.

### Non-goals (near-term)

- ERP or full accounting suite
- Marketplace or customer-facing storefront as the product identity
- Separate product / codebase per industry
- Claiming the full configurable engine ships in V1

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
- Phases 4–5 remain deferred (workflows, dynamic fields). No Transaction rename (`Rental` stays).

### Implementation phases (ordered)

1. **UI / l10n rename** Inventory → Resources (+ Hindi), without requiring a full schema rename — **done**.
2. **Expand `ResourceType`** and migrate `InventoryItemKind` storage — **done**.
3. **Template packs** declare enabled types + home widget sets — **done**.
4. **Configurable statuses / workflows** per template — deferred.
5. **Dynamic fields** per type; universal reports as widgets — deferred.

Each remaining phase needs its own plan/PR; this ADR gates sequencing.

---

## Related

- [Complete Idea Summary §13](../../vision/complete-idea-summary.md#13-universal-platform--10-year-vision)
- [ADR-002: Local-First Foundation](ADR-002-local-first-foundation.md)
