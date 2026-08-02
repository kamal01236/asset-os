# ADR-001: Flutter Web Client

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-08-02 |
| **Decision** | Flutter for the web client (native packaging later) |

---

## Context

The Asset Handover Platform is an offline-first operational tool for physical asset handovers. Near-term delivery needs:

- A touch-friendly web client for local validation and customer feedback
- Fast iteration without native packaging or store submission
- Strong local persistence options for a future local-first source of truth
- A path to native Android/iOS later if feedback warrants it — without locking that in now

---

## Decision

Use **Flutter** as the application framework, shipping **web first**.

- Develop and validate in `apps/web`
- Publish static Flutter web builds to **Fly.io** (nginx) for customer feedback
- Defer native Android/iOS packaging until after feedback; platform choice remains open

For broader local-first architecture, stack context (Riverpod, Drift, SQLCipher), and module layout, see [Complete Idea Summary §9 — System architecture & technology](../../vision/complete-idea-summary.md#9-system-architecture--technology).

---

## Rationale

- **Single Dart codebase** can target web now and native later without rewriting core UX
- **Strong local persistence options** (Drift, Isar, sqflite) support a local-first source of truth
- **Mature plugin ecosystem** for QR, camera, and local notifications — needed when offline/native capabilities land
- **Web delivery on Fly.io** enables sharing a public URL for feedback without app stores

---

## Consequences

- The **local database remains the intended source of truth**; any future sync layer is additive and must not be required for core workflows
- Engineering skill and tooling center on Dart/Flutter for the client
- Current scripts and docs assume **web only** (Chrome / web-server / Fly.io); no emulator or APK workflow
- Native packaging decisions stay deferred until after customer feedback

---

## Related ADRs

| ID | Topic | Notes |
|----|-------|-------|
| [ADR-002](ADR-002-local-first-foundation.md) | Local DB foundation | Drift + Riverpod (accepted) |
| [ADR-003](ADR-003-localization.md) | UI localization | gen-l10n en + hi (accepted) |

## Future ADR placeholders

The following decisions are intentionally not written yet:

| ID | Topic | Notes |
|----|-------|-------|
| ADR-00x | Sync strategy | Multi-device sync approach; additive only |
| ADR-00x | Encryption | At-rest / backup encryption choices |
| ADR-00x | Backup format | Encrypted backup format and restore semantics |
| ADR-00x | Native packaging | Android/iOS delivery after feedback |
