# ADR-003: UI Localization (English + Hindi)

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-08-02 |
| **Decision** | Flutter `gen-l10n` with English default and Hindi selectable |

---

## Context

Hando's web client targets Indian operators. Chrome UI must be localizable without coupling translations to Drift repositories or seeded demo data. English remains the default first-launch locale; Hindi ships now; more Indian languages should not require architecture changes.

---

## Decision

- Use Flutter official **gen-l10n** (`apps/web/l10n.yaml`, ARB files under `apps/web/lib/l10n/`).
- Supported locales now: `en` (default), `hi`.
- Persist the user's choice in SharedPreferences (`asset_os_locale`) via `localeProvider`.
- Brand display name (`kAppDisplayName`) stays an untranslated constant.
- Seeded entity names, phones, IDs, and industry pack item names stay as data — only UI chrome is ARB-backed.
- Language picker lives on the More tab.

### Adding another Indian language (e.g. Tamil / Marathi / Bengali)

1. Copy `app_en.arb` → `app_<code>.arb` and translate values.
2. Register `Locale('<code>')` in `AppLocalizations.supportedLocales` (regenerated from ARBs) and in `LocaleNotifier.supportedLanguageCodes`.
3. Add a radio option on More using the language's native name.
4. No database or repository changes for UI chrome.

---

## Consequences

- All new user-visible chrome strings must be added to ARBs first.
- Widget tests must include `AppLocalizations` delegates (or pump `MainApp`).
- Timeline / seed narrative text may remain English until treated as content localization separately.
