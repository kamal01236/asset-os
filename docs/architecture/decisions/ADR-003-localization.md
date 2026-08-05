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
- **UI chrome** (tabs, buttons, empty states, report headings, timeline titles/subtitles) is ARB-backed and localized at display (or report build) time.
- **Timeline / report chrome:** repositories write stable event keys (e.g. `returned`, `note_added`); UI and reports resolve them via `AppLocalizations`. Legacy English titles already in Drift are mapped for backwards compatibility.
- **Industry template catalog:** packs carry `en` + `hi` labels; import stores name/category in the **active UI locale**. Switching language later does not rewrite existing inventory rows.
- **Entity rows** (customer names, phones, IDs, inventory names already in the DB, user-entered notes) remain plain stored strings — not rewritten on language change.
- Language picker lives on the More tab.

### Adding another Indian language (e.g. Tamil / Marathi / Bengali)

1. Copy `app_en.arb` → `app_<code>.arb` and translate values.
2. Register `Locale('<code>')` in `AppLocalizations.supportedLocales` (regenerated from ARBs) and in `LocaleNotifier.supportedLanguageCodes`.
3. Add a radio option on More using the language's native name.
4. Extend industry template `*Hi`-style fields (or a locale map) if catalog seeds should import in that language.
5. No database or repository schema changes for UI chrome.

---

## Consequences

- All new user-visible chrome strings must be added to ARBs first.
- Widget tests must include `AppLocalizations` delegates (or pump `MainApp`).
- Tests that assert stored timeline titles should expect stable keys, not English display copy.
