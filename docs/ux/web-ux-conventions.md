# Web UX Conventions

UI-first conventions for `apps/web` to keep flows fast, clear, and touch-friendly in the browser.

## Interaction rules
- Keep primary actions in thumb zone (bottom nav, action FAB, bottom CTA bars).
- Show one dominant choice per step; defer advanced options behind expansion.
- Prefer text search, QR scan, and quick actions over deep menu traversal.
- Avoid chart-heavy dashboards in MVP; use status cards + list-first layouts.
- Keep each step understandable in under 5 seconds.
- **One primary CTA per viewport region** — do not duplicate the same action (e.g. New Order) in an empty state and Quick actions on the same screen.
- List rows use structured **title / meta / amount** (not one long `·`-joined subtitle). Prefer `ListEntityRow`, `OrderBillCard`, and `MoneyStack` from `ui_primitives.dart`.
- **Customer tier ≠ inventory status**: Trusted / Standard use `TierPill`, never Available / Archived status pills.
- Search min-length helper (“Type at least 3 characters”) shows only when the field is **focused** or the query is non-empty and still under 3 characters — not as a permanent helper that reads like an error.

## Status semantics
- Available = green
- Rented = blue
- Due Today = orange
- Overdue = red
- Archived = grey

## Home (attention-first)
- Home KPI status chips are compact and tappable: tap navigates to the matching tab with that list filter applied (Active / Due today / Overdue → Orders; Available → Inventory). Clear the filter chip on the destination tab to restore the full list.
- Home is modular (`search`, `kpis`, `filterResults`, `needsAttention`, `quickActions`, `recentActivity`, `suggestions`). Defaults are `search`, `kpis`, `needsAttention`, `quickActions` — no in-place `filterResults` under KPIs. Business templates may add `recentActivity` / `suggestions`; More → Customize Home lets users show/hide removable modules (including optional `filterResults`). Search is always on.
- Prefer overdue/due lists and status filters over chart dashboards.

## Universal navigation contract
- Bottom navigation has 5 stable tabs: Home, Orders, Inventory, Customers, More.
- Global action entry points always include Search, New Order, Return, Add Inventory, Scan.
- Universal search is in-page on Home (typeahead dropdown under the field) and reachable from any tab via FAB → Search, which opens a modal bottom sheet with the same typeahead — not a separate route. Selecting a hit navigates to Customer / Order / Inventory detail.

## Form conventions
- New Order is **items-first**: compact multi-line form (inventory → identity → duration → amount per line) with a running order total, then attach customer (phone-first lookup / create, or Unknown / no-phone) before confirm.
- When issuing from a customer profile (`initialCustomerId`), skip the customer step: items → confirm only.
- Minimal required fields first; advanced details collapsed by default.
- Auto-detect existing customer by phone when attaching the customer (at end of a blank order, or when issued from a customer).
- Free-text identity/note fields (customer name, item name, category, instance name, SELF nickname, notes when non-empty) require at least 3 characters; search runs only at ≥3 chars (Home/global = all entities; Inventory tab = inventory; Customers tab = customers + order nicknames).

## Order bills and deposit
- Orders tab lists orders as bill-style cards. When no Home KPI filter is active, light chips **All / Open / Completed** narrow the list; default scope is **Open** (active / non-completed only). **All** includes open + completed + **cancelled**. Filters (Active / Due today / Overdue) from Home KPIs still narrow among open bills.
- Bill cards: **party name** as title; item summary + short `#id`; trailing **Bill** / **Deposit** amounts; status pill bottom-left — not a mega concatenated subtitle.
- Customer detail shows a signed net from all that customer’s orders (positive = owes shop, negative = credit). Advance = sum of order deposits; pending = sum of bill charges. No customer wallet Add/Refund in the profile UI. Customer **list** shows phone + TierPill and signed net only (breakdown stays on detail).
- Deposit / token / advance lives on the **order** (set at New Order). Return and cancel settle against that order deposit, not a shared customer wallet.
- Order detail is a full bill: lines, deposit, total, status chip in the app bar. Charges use `MoneyStack` rows. Return only while status is open and ≥1 rent line is still out. **Cancel order** is the last bottom-bar action on open orders with no returned rent lines (not an app-bar icon). Sell-only orders complete at create.
- Share reports: **Share to my WhatsApp** stays disabled until the owner number is configured; preview is structured key-value rows with Copy still producing the same plain text.

## Order return and cancel
- Returns always require an explicit confirm dialog. Show the computed line total (read-only), an editable **final amount to collect** (0…total; remainder shown as discount), deposit preview against that final amount (from the order deposit), and an optional note (≥3 chars when set).
- **Cancel order** is available on open orders with no rent lines already returned, as the last control in the order-detail bottom action bar (danger-styled outline; not the primary filled CTA). Confirmation settles order deposit as amount kept + amount returned (both default 0; sum ≤ order deposit remaining) plus optional note, then cancels the order and restores stock.
- Per-line Replace/Change is not offered; do not reintroduce SKU swap from order detail.
- **Order notes** (order detail only): append-only after create; optional link to one rental line; body ≥3 characters; kinds `general` / `terms` / `measurement`. No edit/delete in MVP.

## Offline and feedback
- Use a subtle non-blocking offline banner; never block primary workflows.
- Favor lightweight confirmations (snackbars, status pills) over modal interruptions.
- Optional offline simulation (More tab) is for UX checks only — not product positioning.

## Appearance
- App supports Dark and Light themes only (no system-follow).
- Default is Dark when no preference is stored; choice persists via SharedPreferences.
- Theme toggle lives on More (beside Language) as a segmented Dark / Light control.
- Prefer `ColorScheme` / `textTheme` over hardcoded light greys or white fills so both modes stay readable.

## Localization
- All user-visible chrome (nav, actions, forms, empty states, status labels, More) is l10n-backed via Flutter gen-l10n (`en` default, `hi` selectable).
- Add new chrome strings to ARB files first; do not hardcode UI copy in widgets.
- Keep `kAppDisplayName` and seeded entity/data names untranslated.
