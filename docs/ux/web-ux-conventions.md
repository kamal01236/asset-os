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

## Universal navigation contract
- Bottom navigation has 5 stable tabs: Home, Rentals, Inventory, Customers, More.
- Global action entry points always include Search, New Rental, Return, Add Inventory, Scan.
- Universal Search route must be reachable from all primary tabs.

## Form conventions
- Phone-first customer lookup for rental creation.
- Minimal required fields first; advanced details collapsed by default.
- Auto-detect existing customer by phone before asking for full profile fields.

## Offline and feedback
- Use a subtle non-blocking offline banner; never block primary workflows.
- Favor lightweight confirmations (snackbars, status pills) over modal interruptions.
- Optional offline simulation (More tab) is for UX checks only — not product positioning.
