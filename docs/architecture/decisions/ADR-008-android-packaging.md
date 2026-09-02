# ADR-008: Android packaging (dual target with web)

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-09-01 |
| **Decision** | Ship **Flutter web** and a **dedicated Android app** from the same `apps/web` project |

---

## Context

[ADR-001](ADR-001-mobile-stack.md) shipped web first for fast feedback. Customers and field use now warrant a installable Android app while keeping the GitHub Pages web preview.

---

## Decision

- **One codebase:** `apps/web/lib/` shared by web and Android
- **Two hosts:** `web/` (WASM Drift, browser print) and `android/` (native SQLite, share sheet)
- **Play Store:** deferred; local debug APK via `flutter build apk --debug`
- **iOS / desktop:** not in scope unless explicitly requested

Platform-specific code stays behind conditional imports (`report_print`, `image_download`, Drift connection opener).

---

## Consequences

- Web WSL scripts unchanged; Android uses Windows-native PowerShell scripts (`adb`, emulator)
- Separate SQLite files per platform (no cross-device sync yet)
- Project rule allows committing `android/` under `apps/web`

---

## Related

- [ADR-001: Flutter Web Client](ADR-001-mobile-stack.md)
- [ADR-002: Local-First Foundation](ADR-002-local-first-foundation.md)
