# ADR-006: Customer subscription tiers

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-08-10 |
| **Decision** | Subscription access is a **customer-owned**, nested system tier (Basic ⊂ Standard ⊂ Pro ⊂ Premium) with period-based ledger rows — not a shop-wide boolean and not a Hando product plan |

---

## Context

Commercial checkout used `customerHasActiveEntitlement`: any still-valid membership/subscription **sell line** counted as yes. That could not express “Pro includes Basic”, did not belong on the shop owner, and could not tell New Order which gated resources the **selected customer** may use.

Hando stays local-first (ADR-002). Rental `BillingMode` must not gain `yearly` — subscription periods are a separate clock.

## Decision

- Fixed ranks everywhere: `none` < `basic` < `standard` < `pro` < `premium`. Effective rank = max among non-expired, non-cancelled `customer_subscriptions` rows. Higher includes lower; leftover lower rows still apply after a higher tier expires.
- Period: `day` | `week` | `month` | `year` + positive count. Reuse calendar month math; do not extend rental billing modes.
- Catalog metadata (no extra inventory columns): SKUs store `subscriptionTier` + period; other resources store optional `minSubscriptionTier`.
- Drift table `customer_subscriptions` (schema **v23**) is the source of truth. Grant/renew on sell of membership **or** subscription SKUs after issue. Unknown / no-phone customers never receive ledger rows and cannot satisfy a required min-tier.
- New Order: after the customer is known, if the cart’s max min-tier is uncovered, add/choose a covering SKU **on the same order**. Library `requireAnyOf: [security, subscription]` still passes when security is collected even without coverage.
- UI: customer list/detail show tier + expiry as meta (not a status pill). Commercial / summary chip names the active tier and date.

## Consequences

- Boolean sell-line entitlement scans are replaced by tier coverage helpers in `domain/subscriptions/`.
- Templates only name and price SKUs that map onto the fixed ranks.
- Out of scope: customer self-serve checkout, auto-renew / payment gateway, shop-owner Hando subscription, per-resource à-la-carte entitlement lists.

## Related

- [ADR-004: Business Resources](ADR-004-business-resources.md)
- [ADR-005: Client Layering](ADR-005-client-layering.md)
- [Web UX conventions](../../ux/web-ux-conventions.md)
