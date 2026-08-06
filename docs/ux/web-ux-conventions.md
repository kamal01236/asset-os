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
- **Customer tier ≠ resource status**: Trusted / Standard use `TierPill`, never Available / Archived status pills.
- Search min-length helper (“Type at least 3 characters”) shows only when the field is **focused** or the query is non-empty and still under 3 characters — not as a permanent helper that reads like an error.

## Status semantics
- Available = green
- Rented = blue
- Due Today = orange
- Overdue = red
- Archived = grey

## Home (attention-first)
- **First launch:** empty DB shows a multi-step onboarding wizard before the shell: **Language** (EN default / HI) → **Offline or Online** (Offline default) → **WhatsApp** only when Online (required; OTP verification stubbed for later) → **industry template** (full pack seeds resources + Home modules). More → Business Templates remains for later merges.
- Home KPI status chips are compact and tappable: tap navigates to the matching tab with that list filter applied (Active / Due today / Overdue → Orders; Available → Resources). Clear the filter chip on the destination tab to restore the full list.
- Home is modular (`search`, `kpis`, `filterResults`, `needsAttention`, `pendingJobs`, `quickActions`, `recentActivity`, `suggestions`). Defaults are `search`, `kpis`, `needsAttention` — no Quick Actions or Pending jobs on the default stack (FAB covers New Order / Return; both modules stay available via Customize Home). No in-place `filterResults` under KPIs. Business templates set Home defaults and enabled resource types: rental packs use the thin default; library / membership add `recentActivity`; job/service packs add `pendingJobs`. More → Customize Home lets users show/hide removable modules (including optional `filterResults`). Search is always on.
- Prefer overdue/due lists and status filters over chart dashboards.

## Universal navigation contract
- Bottom navigation has 5 stable tabs: Home, Orders, Resources, Customers, More.
- Global action entry points always include Search, New Order, Return, Add Resource, Scan.
- Universal search is in-page on Home (typeahead dropdown under the field) and reachable from any tab via FAB → Search, which opens a modal bottom sheet with the same typeahead — not a separate route. Selecting a hit navigates to Customer / Order / Resource detail.

## Form conventions
- New Order is **items-first**: compact multi-line form with a running order total. Happy path per line is item → qty → days (rent) or amount (sell); fulfillment (Rent/Sell/Job), open-ended, custom end date, and billing readout sit under **More options**. Sell / Job segments appear only when the business template’s enabled resource types include them (`sale` for Sell; `job` / `service` for Job) — catalog items are not hidden by type. Then attach customer (**phone-first** lookup / create, or Unknown / no-phone) before confirm. Advance is a collapsed optional field on the customer/summary step.
- When issuing from a customer profile (`initialCustomerId`), skip the customer step: items → confirm only.
- Minimal required fields first; advanced details collapsed by default. Unit identity fields are optional unless the catalog item requires them; otherwise short codes auto-assign at submit (optional “Add unit labels”).
- Auto-detect existing customer by phone when attaching the customer (at end of a blank order, or when issued from a customer).
- Free-text identity/note fields (customer name, item name, category, instance name, SELF nickname, notes when non-empty) require at least 3 characters; search runs only at ≥3 chars (Home/global = all entities; Resources tab = resources; Customers tab = customers + order nicknames).

## Order bills and deposit
- Orders tab lists orders as bill-style cards. When no Home KPI filter is active, light chips **All / Open / Completed / Pending jobs** narrow the list; default scope is **Open** (active / non-completed only). **Pending jobs** shows open orders with ≥1 unfinished job line. **All** includes open + completed + **cancelled**. Filters (Active / Due today / Overdue) from Home KPIs still narrow among open bills.
- Bill cards: **party name** as title; item summary + short `#id`; trailing **Bill** / **Advance** amounts; status pill bottom-left — not a mega concatenated subtitle.
- Customer detail shows a signed net from all that customer’s orders (positive = owes shop, negative = credit). Advance = sum of order deposits; pending = sum of bill charges. No customer wallet Add/Refund in the profile UI. Customer **list** shows phone + TierPill and signed net only (breakdown stays on detail).
- Advance lives on the **order** (set at New Order). Return and cancel settle against that order advance, not a shared customer wallet.
- Order detail is a full bill: lines, deposit, total, status chip in the app bar. Charges use `MoneyStack` rows. Return only while status is open and ≥1 **rent** line is still out. **Mark complete** closes open **job** lines (no stock restore). **Cancel order** is the last bottom-bar action on open orders with no settled rent/job lines (not an app-bar icon). Sell-only orders complete at create; job-only stay open until marked complete.
- Resource catalog types: **Rental / Sale / Service / Job / Subscription / Membership / Loan / Financial / Custom** (stored as `ResourceType`; UI may still omit a type picker). Job/service lines charge the catalog rate (editable override), stay open until Mark complete, and do not restore stock.
- Share reports: **Share to my WhatsApp** stays disabled until the owner number is configured; preview is structured key-value rows with Copy still producing the same plain text.

## Order return and cancel
- Returns always require an explicit confirm dialog. Show the computed line total (read-only), an editable **final amount to collect** (0…total; remainder shown as discount), deposit preview against that final amount (from the order deposit), and an optional note (≥3 chars when set).
- **Mark complete** (job lines) uses a simple confirm; stock is not restored.
- **Cancel order** is available on open orders with no rent/job lines already settled, as the last control in the order-detail bottom action bar (danger-styled outline; not the primary filled CTA). Confirmation settles order deposit as amount kept + amount returned (both default 0; sum ≤ order deposit remaining) plus optional note, then cancels the order and restores stock.
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

## First-load onboarding (backlog — not in this pass)

Documented ideas only; do not implement until scoped:

- Real WhatsApp / SMS OTP verification for online mode.
- Dark / Light theme pick during onboarding (today defaults Dark; More toggle remains).
- Business display name / shop name for reports.
- Currency default (INR today).
- Optional ~30-second guided tour (New Order / Return / Resources).
- “Start empty” escape hatch after language (advanced).
- Restore from backup as an alternate first-run path.
