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
- Home KPI status chips are compact and tappable: tap navigates to the matching tab with that list filter applied (Active / Due today / Overdue → Transactions; Available → Resources). Clear the filter chip on the destination tab to restore the full list.
- Home is modular (`search`, `kpis`, `filterResults`, `needsAttention`, `pendingJobs`, `quickActions`, `recentActivity`, `suggestions`). Defaults are `search`, `kpis`, `needsAttention` — no Quick Actions or Pending jobs on the default stack (FAB covers New Order / Return; both modules stay available via Customize Home). No in-place `filterResults` under KPIs. Business templates set Home defaults and enabled resource types: rental packs use the thin default; library / membership add `recentActivity`; job/service packs add `pendingJobs`. More → Customize Home lets users show/hide removable modules (including optional `filterResults`). Search is always on.
- Prefer overdue/due lists and status filters over chart dashboards.

## Universal navigation contract
- Bottom navigation has 5 stable tabs: Home, **Transactions**, Resources, Customers, More.
- **Transactions** is the product umbrella for **Orders** (rental/sale/job engine) and cash **Loans** (money_loans engine). Engines and Drift tables stay separate; the tab merges them in the UI only (All / Orders / Loans filters, New → Order | Loan chooser).
- Global action entry points always include Search, New Order, Return, Add Resource, Scan.
- Universal search is in-page on Home (typeahead dropdown under the field) and reachable from any tab via FAB → Search, which opens a modal bottom sheet with the same typeahead — not a separate route. Selecting a hit navigates to Customer / Order / Resource detail.

## Form conventions
- New Order is **items-first**: compact multi-line form with a running order total. Happy path per line is item → qty → days (rent) or amount (sell); fulfillment (Rent/Sell/Job), open-ended, custom end date, and billing readout sit under **More options**. Sell / Job segments appear only when the business template’s enabled resource types include them (`sale` for Sell; `job` / `service` for Job) — catalog items are not hidden by type. Then attach customer (**phone-first** lookup / create, or Unknown / no-phone). A **commercial step** (Pay / Advance / Security / Membership) appears only when the cart’s resolved commercial policy has a required gate, optional security/advance, a `requireAnyOf` group, or an unmet **subscription min-tier** — driven by catalog type + item overlay + template type defaults + the selected customer’s ledger, not the template name. After the customer is known, show a chip with the active **tier + expiry** when coverage is OK. If the cart’s max `minSubscriptionTier` is not covered, offer a covering membership/subscription SKU **on the same order** (cheapest catalog SKU at or above the gap; operator can change it). Unknown / no-phone cannot satisfy a required min-tier (block or collect security when `requireAnyOf` allows it). If every step is off (or optional and skipped) and coverage is OK, generate immediately and open **order detail**; collect remaining payment via **Pay** there. When a step is required (or `requireAnyOf` unmet), the primary CTA stays disabled until satisfied, then create + settlement run in one local transaction.
- When issuing from a customer profile (`initialCustomerId`), skip the customer step: items → confirm only.
- Minimal required fields first; advanced details collapsed by default. Unit identity fields are optional unless the catalog item requires them; otherwise short codes auto-assign at submit (optional “Add unit labels”).
- Auto-detect existing customer by phone when attaching the customer (at end of a blank order, or when issued from a customer).
- Free-text identity/note fields (customer name, item name, category, instance name, SELF nickname, notes when non-empty) require at least 3 characters; search runs only at ≥3 chars (Home/global = all entities; Resources tab = resources; Customers tab = customers + order nicknames).
- **Money entry fields** (`MoneyAmountField`) show a live amount-in-words helper in the current app locale (EN or HI), using the Indian numbering scale (thousand / lakh / crore). Inputs are capped at **1 lakh crore**; overflow shows a short localized message instead of words.

## Order bills and deposit
- Transactions tab lists a merged chronological feed of orders and loans (type badge on each row). Filter chips **All / Orders / Loans** appear when both kinds are relevant; Home KPI filters (Active / Due today / Overdue) still narrow to matching open orders. Orders retain bill semantics on detail; the list row is lightweight (party, status, amount, date).
- Legacy note: when viewing orders alone, bill-style cards used **All / Open / Completed / Pending jobs**; that scope chrome is superseded by the unified Transactions filters above.
- Customer detail shows a signed net from all that customer’s orders (positive = owes shop, negative = credit). Advance = sum of order deposits; pending = sum of bill charges. No customer wallet Add/Refund in the profile UI. Customer **list** shows phone + TierPill and signed net only (breakdown stays on detail). Active **subscription** is compact meta (tier + expiry text), not a status pill — subscription tier is not Available/Rented. Customer detail lists the highest active tier + expiry and a short history of ledger periods.
- Add/Edit Resource: membership/subscription SKUs require system **tier + period** (day/week/month/year × count). Other resources may set optional **Requires subscription** min-tier (`None` / Basic / Standard / Pro / Premium). Higher tiers include lower gated resources.
- Customer detail has a single **Transactions** section (orders + loans for that party), not separate Orders / Loans blocks.
- Advance / payment is collected on New Order **only when commercial policy requires or offers** those fields; otherwise from **order detail → Pay**. Sell lines show as **minimum payment due now**; rental security is suggested from catalog `securityDepositPaise` but entered manually and stored as order advance. Cash allocates sell-first, then advance; shortfall vs sell due is recorded as sell discount (same idea as return’s final amount). Unpaid sell shows a badge on order detail. Return and cancel still settle against that order advance, not a shared customer wallet. Pay on detail hides security when no rent/loan-with-security lines apply, hides pay when nothing is due, and hides the CTA when the cart policy has nothing to collect. **Payment ref** (operator-entered, ≤15 chars, letters/digits/hyphen/underscore, uppercased on save) is **required** whenever Pay or the New Order commercial step collects cash or security; it appears on the order timeline as `Ref …`. Cash-loan **repayment** and **disbursement** reuse the entry note field with the same limit and rules; adjustment/capitalization notes stay optional. On **pending** loans, repayment and disbursement timeline rows can be **edited** (amount, date, ref) or deleted; adjustments and capitalization stay add-only — reopen a closed loan before editing its entries.
- Cash-loan detail **Share timeline** (icon beside the timeline heading) downloads a full PNG of scenario, setup, and every timeline row; the operator shares it manually from gallery/files (no in-app WhatsApp image or system share sheet).
- Cash-loan **timeline** is a ruled Date | Particulars | Amount | Bal passbook (tabular figures, date on the row and blank when the previous body row is the same calendar day, pending/overpaid as a grid footer). Share PNG uses the same ledger widgets.
- Order detail is a full bill: lines, deposit, sell paid/discount, total, status chip (+ unpaid sell badge) in the app bar. Charges use `MoneyStack` rows. **Pay / Add advance** opens Payment again. Return only while status is open and ≥1 **rent** line is still out. **Mark complete** closes open **job** lines (no stock restore). **Cancel order** is the last bottom-bar action on open orders with no settled rent/job lines (not an app-bar icon). Sell-only orders complete at create; job-only stay open until marked complete.
- Resource catalog types: **Rental / Sale / Service / Job / Subscription / Membership / Loan / Financial / Custom** (stored as `ResourceType`; UI may still omit a type picker). Job/service lines charge the catalog rate (editable override), stay open until Mark complete, and do not restore stock. Rent-like catalog items may set a per-unit **security deposit** used as Payment’s suggested advance.
- Share reports: **Share to my WhatsApp** stays disabled until the owner number is configured. Preview is a compact table (same snapshot as Copy / WhatsApp). **Print** opens the browser A4 print dialog (no PDF). Period tables show issued / returned / closed in range only; still-out orders appear in a labeled **Still out (as of …)** block. Idle catalog and empty Available unit rows are omitted.

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
