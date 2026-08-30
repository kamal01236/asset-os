# ADR-007: Accessibility (WCAG 2.2 Level AA)

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-08-30 |
| **Decision** | WCAG 2.2 Level AA for Hando Flutter web (Light + Dark); Semantics → ARIA |

---

## Context

Product vision mentioned “large fonts, screen readers, high contrast” without a standard or acceptance tests. Engineering already ships localizable chrome (ADR-003), Dark/Light themes only (no system-follow), status as **label + color**, and some search/icon semantics. Enterprise operators need a concrete contract that fits Flutter web and the existing UX rules—not a third theme, not AAA in one pass, and not reintroducing system theme for a11y.

### Vision notes intentionally ignored or replaced

| Vision / idea | Disposition |
|---------------|-------------|
| Theme: **system** follow | **Ignored.** Product already rejected system-follow; Dark/Light only. Do not reintroduce for a11y. |
| Vague “large fonts, screen readers, high contrast” | **Replaced** by WCAG 2.2 Level **AA** on Light + Dark with verifiable criteria below. |
| Separate “high contrast” product theme | **Out of scope** until AA on existing themes is green; prefer stronger `ColorScheme` / status foreground roles. |
| WCAG **AAA** / full VPAT every screen | **Out of scope** for this program; AA + phased critical paths is the baseline. |
| Connected-mode / multi-device sync a11y | **N/A** until product exists. |

---

## Decision

**Standard:** [WCAG 2.2](https://www.w3.org/TR/WCAG22/) Level **AA** for Flutter **web**. Flutter `Semantics` maps to browser ARIA; verify with keyboard and a screen reader on critical paths.

### Must

1. **Contrast** — Text/UI vs background ≥ 4.5:1 (normal text), ≥ 3:1 (large text / UI components). Verify Light and Dark. Status **meanings** stay (Available green, etc.); chip/text roles use contrast-safe foregrounds on tinted chips via `AppTheme`, not a third theme.
2. **Name, role, value** — Every interactive control has an accessible name (`tooltip` / `Semantics` / visible label). No bare icon-only buttons.
3. **Keyboard** — Tab/Shift+Tab reach primary chrome (nav, FAB sheet, dialogs, forms); Escape closes sheets/dialogs; search keeps arrow/Enter/Escape.
4. **Text scale** — UI usable at system text scale up to **1.5×** (200% stretch goal on shell); no clipped primary CTAs on Home / New Order / loan detail.
5. **Not color alone** — Status and amount sign keep labels / signed text (WCAG 1.4.1).
6. **Errors** — Form validation tied to fields (`InputDecoration.errorText` / semantics); snackbars remain secondary.
7. **l10n** — Accessibility strings (semantic hints, clear-search, qty steppers, etc.) in ARB **en + hi** like other chrome (ADR-003).

### Non-goals (this program)

- Captions for video (N/A)
- AAA conformance
- Third “high contrast” product theme
- Platform-native TalkBack-only APIs beyond Flutter Semantics
- Rewriting every screen layout in one pass

### Engineering preferences

- Prefer `ColorScheme` / `textTheme`; avoid light-only greys or white fills.
- Shared primitives (`StatusPill`, `TierPill`, `ListEntityRow` / `EntityCard`, `MoneyStack`, `ScopedSearchField`, `OfflineBanner`) own default semantics so feature screens inherit them.
- Icon-only actions: require `tooltip` or `Semantics(label:)` (convention in UX rules).

---

## Consequences

- Theme and status chip foregrounds may differ by brightness while hue meaning is preserved.
- New chrome/a11y strings land in ARBs before widgets.
- Widget tests cover semantics labels and a 1.5× text-scale smoke on shell; full Narrator/keyboard passes are manual (appendix).
- Connected-mode and AAA remain future ADRs if needed.

---

## Appendix A — Manual checklist (not CI)

Run on Chrome (Windows) after code changes that touch shell or critical flows:

### Keyboard

- [ ] Tab / Shift+Tab reach bottom nav destinations and the Actions FAB.
- [ ] Enter/Space opens FAB sheet; Escape dismisses sheet/dialogs.
- [ ] Home / global search: type, Arrow Up/Down highlights, Enter selects, Escape clears highlight.
- [ ] New Order and Pay: fields and primary CTA reachable without pointer-only traps.

### Screen reader (Narrator or ChromeVox)

- [ ] Home: brand, nav labels, Actions FAB name announced.
- [ ] Offline banner (simulation on): announced as a live region when shown.
- [ ] Status / tier pills announce their text label (not color alone).
- [ ] New Order: qty decrease/increase and clear-field controls named; line remove named.
- [ ] Loan detail: share / edit tooltips; ledger row announces date + particulars + amount + balance as one unit; editable rows named for edit.

### Text scale

- [ ] Windows / browser text size or Flutter `textScaler` ~1.5×: Home primary actions and bottom nav remain usable (no clipped primary CTAs).
- [ ] New Order and loan detail primary CTAs remain reachable.

### Themes

- [ ] Spot-check status pills and overdue/due amounts in **Light** and **Dark** for readable contrast (no reliance on a high-contrast theme).
