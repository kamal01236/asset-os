# Web UX Conventions

Operator UX contract for Hando’s Flutter web client (`apps/web`). Audience: counter staff and shop owners working offline-first, list-first—not consumer analytics.

Feature math (deposit allocation, subscription covering-SKU selection, report column rules, loan interest formulas) lives in code, ADRs, and vision—not in this file. Deferred ideas live in [`phase5-extension-stubs.md`](phase5-extension-stubs.md) and vision; do not expand them here.

## Operator principles

- **Attention over analytics.** Prefer status lists, KPI chips, and overdue/due attention over chart dashboards.
- **Progressive disclosure.** One dominant choice per step; advanced options stay collapsed (e.g. New Order **More options**).
- **Thumb-zone primary actions.** Primary settle / create / navigate actions live in bottom nav, the action FAB sheet, and detail bottom bars.
- **Feedback ladder.** Snackbar = soft success or validation; dialog = money or destructive settlement; sheet = choose an action or search. Prefer snackbars over modal interruptions for soft confirmations.
- **Error UX.** Explain what failed, suggest the next step, preserve input, never show stack traces to operators.
- **Offline transparency.** Subtle non-blocking banner only; never gate primary workflows on connectivity.
- **l10n floor.** EN/HI chrome via ARB (`en` default, `hi` selectable). Keep `kAppDisplayName` and seeded entity names untranslated. Prefer `ColorScheme` / `textTheme` over light-only hardcodes so Dark and Light stay readable. A11y engineering contract: [`ADR-007-accessibility.md`](../architecture/decisions/ADR-007-accessibility.md) (WCAG 2.2 AA)—not a third theme, not AAA.

## Navigation & shell

- Bottom navigation has **5 stable tabs:** Home · Transactions · Resources · Customers · More. Do not add or remove tabs without updating this contract.
- **Transactions** is the UI umbrella for **Orders** (rental/sale/job) and cash **Loans** (money_loans). Engines and Drift tables stay separate; the tab merges them in the UI only (All / Orders / Loans filters; New → Order | Loan chooser).
- Global FAB actions always include: **Search**, **New Order**, **Return**, **Add Resource**, **Scan**.
- **Search** is in-page on Home (typeahead under the field) and reachable from any tab via FAB → Search (modal bottom sheet with the same typeahead)—not a separate route. Selecting a hit navigates to Customer / Order / Resource detail.

## Status & tier semantics

| Status | Color |
| --- | --- |
| Available | green |
| Rented | blue |
| Due Today | orange |
| Overdue | red |
| Archived | grey |

- Customer **Trusted / Standard** use `TierPill`—never Available / Archived `StatusPill`.
- Active **subscription** is compact meta (tier + expiry text), not a status pill.

## Lists, money display, empty states

- List rows use structured **title / meta / amount**—not one long `·`-joined subtitle. Prefer `ListEntityRow`, `OrderBillCard`, and `MoneyStack` from `ui_primitives.dart`. Short ids via `shortOrderId` (e.g. `#9001`).
- **One primary CTA per viewport region.** Do not duplicate the same action (e.g. New Order) in an empty state and FAB/Quick Actions on the same screen.
- Empty: `CompactEmptyState` for inline/list gaps (message only, or one CTA max); `EmptyStatePane` for full-pane voids. Prefer message-only when FAB already covers the action.
- Filtered lists may show `ActiveFilterBar`; clearing the chip restores the full list.

## Search & text floors

- Search and typeahead (Home/global, Resources, Customers, Transactions) activate on the **first** non-empty trimmed character (`kMinMeaningfulTextLength = 1`). Do **not** show a “Type at least N characters” helper under search fields.
- Free-text identity fields (customer name, item name, category, instance name, SELF nickname, optional catalog notes when non-empty) must meet the same ≥1 floor when required.
- **Two note systems:**
  - **Money note** — optional free text ≤20 (`kMoneyNoteMaxLength`) on Pay, New Order commercial cash/security, loan create/repayment/disbursement/adjustment, return/cancel. Never block settle solely because the note is empty. Stored as entered (trimmed); appears on timelines as `Ref …` when present.
  - **Order notes** — order-detail append-only body ≥3 characters; kinds `general` / `terms` / `measurement`; optional link to one rental line. No edit/delete in MVP.

## Forms & settle

- **New Order** is items-first: compact multi-line form with a running order total. Happy path per line is item → qty → days (rent) or amount (sell). Fulfillment (Rent/Sell/Job), open-ended, custom end date, and billing readout sit under **More options**. Sell / Job segments appear only when the template’s enabled resource types include them—catalog items are not hidden by type. Then attach customer (phone-first lookup / create, or Unknown / no-phone). Skip the customer step when issuing from a profile (`initialCustomerId`).
- A **commercial step** (Pay / Advance / Security / Membership) appears only when cart policy requires or offers it (required gate, optional security/advance, `requireAnyOf`, or unmet subscription min-tier). Policy resolution and covering-SKU rules live in domain/code—not here. If every step is off (or optional and skipped) and coverage is OK, generate immediately and open order detail; collect remaining payment via **Pay** there.
- Unit identity fields are optional unless the catalog item requires them.
- **Money entry** (`MoneyAmountField`): live amount-in-words in the current locale (EN/HI, Indian scale); capped at **1 lakh crore**.
- Optional money notes never block settle. **Return** and **Cancel order** always use explicit confirm dialogs (money settlement).

## Home

- Defaults: `search` + `kpis` + `needsAttention`. Prefer overdue/due lists and status filters over charts.
- KPI chips navigate to the matching tab with that list filter applied (Active / Due today / Overdue → Transactions; Available → Resources). Clear the filter on the destination to restore the full list.
- **Customize Home** (More) shows/hides removable modules (`pendingJobs`, `quickActions`, `recentActivity`, `suggestions`, optional `filterResults`). Search stays always on. Templates may preset modules (e.g. library adds `recentActivity`; job packs add `pendingJobs`). FAB covers New Order / Return on the default stack.

## Appearance

- Dark and Light only (no system-follow). Default **Dark** when no preference is stored; persists via SharedPreferences.
- Theme toggle: More (beside Language), segmented Dark / Light.
- Material 3 seed `#006D77` plus status color constants in `AppTheme`. Contrast-safe status foregrounds keep status **meanings** on both themes.
- Do not add a third high-contrast product theme or system-follow for a11y.

## Shipped surfaces (short)

- Cash-loan detail: ruled Date | Particulars | Amount | Bal **passbook** timeline; **Share timeline** downloads a full PNG (manual share from gallery/files—no in-app WhatsApp image sheet).
- Share Reports: **Share to my WhatsApp** stays disabled until the owner number is configured.
- More-tab offline simulation is for UX checks only—not product positioning.

## Onboarding (current)

Empty DB runs a multi-step wizard before the shell: **Language** (EN default / HI) → **Offline or Online** (Offline default) → **WhatsApp** only when Online (required; OTP stubbed) → **industry template** (full pack seeds resources + Home modules). More → Business Templates remains for later merges.

## Out of scope

Backlog and Phase 5 stubs are **not** part of this contract. See [`phase5-extension-stubs.md`](phase5-extension-stubs.md) and product vision for deferred ideas (OTP, backup, PIN, photos, real camera QR, guided tour, etc.). Web IA in this file supersedes stale vision §12 nav/theme names where they conflict.
