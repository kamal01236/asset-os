# Web UX Conventions

UI-first conventions for `apps/web` to keep flows fast, clear, and touch-friendly in the browser.

## Interaction rules
- Keep primary actions in thumb zone (bottom nav, action FAB, bottom CTA bars).
- Show one dominant choice per step; defer advanced options behind expansion.
- Prefer text search, QR scan, and quick actions over deep menu traversal.
- Avoid chart-heavy dashboards in MVP; use status cards + list-first layouts.
- Keep each step understandable in under 5 seconds.

## Status semantics
- Available = green
- Rented = blue
- Due Today = orange
- Overdue = red
- Archived = grey

## Home (attention-first)
- Home KPI status cards are tappable filters: tap stays on Home and shows matching rentals/inventory in a Results section; tap again or Clear clears the filter.
- Home is modular (`search`, `kpis`, `filterResults`, `needsAttention`, `quickActions`, `recentActivity`, `suggestions`). Business templates set default module sets; More → Customize Home lets users show/hide removable modules. Search is always on.
- Prefer overdue/due lists and status filters over chart dashboards.

## Universal navigation contract
- Bottom navigation has 5 stable tabs: Home, Rentals, Inventory, Customers, More.
- Global action entry points always include Search, New Rental, Return, Add Inventory, Scan.
- Universal Search route must be reachable from all primary tabs.

## Form conventions
- Phone-first customer lookup for rental creation.
- Minimal required fields first; advanced details collapsed by default.
- Auto-detect existing customer by phone before asking for full profile fields.
- Free-text identity/note fields (customer name, item name, category, instance name, SELF nickname, notes when non-empty) require at least 3 characters; search runs only at ≥3 chars (Home/global = all entities; Inventory tab = inventory; Customers tab = customers + rental nicknames).

## Offline and feedback
- Use a subtle non-blocking offline banner; never block primary workflows.
- Favor lightweight confirmations (snackbars, status pills) over modal interruptions.
- Optional offline simulation (More tab) is for UX checks only — not product positioning.

## Localization
- All user-visible chrome (nav, actions, forms, empty states, status labels, More) is l10n-backed via Flutter gen-l10n (`en` default, `hi` selectable).
- Add new chrome strings to ARB files first; do not hardcode UI copy in widgets.
- Keep `kAppDisplayName` and seeded entity/data names untranslated.
