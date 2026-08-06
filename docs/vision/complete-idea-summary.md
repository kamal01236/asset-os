---
title: "Asset Handover Platform — Complete Idea Summary"
version: "Draft 1.0"
status: draft
source: "Consolidated from Phases 1–18 (sole product SoT)"
last_updated: 2026-08-02
---

# Asset Handover Platform — Complete Idea Summary

This document is the **sole product source of truth** for Asset OS: a consolidated understanding of the full product vision (originally Phases 1–18).

It removes repetition, merges overlapping chapters, and **preserves every unique requirement, edge case, constraint, and strategic decision**. Use this as the primary “what are we building and why?” reference.

---

## How to read this document

| Section | Use when you need… |
|---------|-------------------|
| [1. Essence](#1-the-essence-in-one-page) | Elevator pitch and non-negotiables |
| [2. Problem & vision](#2-problem-vision--mission) | Why it exists |
| [3. Positioning & market](#3-positioning-market--monetization) | Who buys it and how it makes money |
| [4. Constitution](#4-product-constitution--decision-framework) | What never changes; how to decide |
| [5. Users & roles](#5-users-personas-roles--categories) | Who uses it day-to-day |
| [6. Version 1 scope](#6-version-1-scope-in--out) | What ships first / what is deferred |
| [7. Modules & data](#7-core-modules--domain-model) | What data and features exist |
| [8. Workflows](#8-workflows-verification--customer-experience) | How rentals actually run |
| [9. Architecture](#9-system-architecture--technology) | How it is built (local-first) |
| [10. Sync, backup, security](#10-operating-modes-sync-backup-security--privacy) | Cloud optional layer |
| [11. Backend & APIs](#11-backend--cloud-apis) | What the server may / may not do |
| [12. UX](#12-ux-architecture--screens) | Screens and interaction rules |
| [13. Platform future](#13-universal-platform--10-year-vision) | Extensibility beyond rentals |
| [14. Delivery plan](#14-delivery-plan-mvp-backlog--90-days) | What to build in what order |
| [15. Edge cases](#15-edge-cases-failures--degradation) | Failure modes checklist |
| [16. Final advice](#16-final-strategic-advice) | Marketing & discipline |

**Source-of-truth map (when chapters conflict):**

- Schema → Phase 14 (domain model)
- APIs → Phase 15
- UX screens → Phase 11
- Principles → Phases 13 + 18
- Backlog / MVP → Phase 17 (plus Phase 10 cut list)
- Workflows → Phase 5

---

## 1. The essence in one page

### What it is

A **privacy-first, offline-first, local-first Business Operating System for physical asset handovers**, expanding toward configurable business resources (see §13).

Businesses that already own assets use it to **lend, rent, issue, return, track, and maintain** those assets — without needing continuous internet, cloud accounts, or a customer-facing app.

### What it is not

Not a rental marketplace. Not ecommerce. Not ERP. Not accounting. Not payments. Not a social network. Not a WMS. Not a CRM clone.

### Core thesis

> **The business owns its data. The application helps manage it without forcing cloud dependency.**

> **The mobile application is the product. The backend is an optional service.**

> **The local database is the primary source of truth.**

### Five product promises

1. Business continues without internet.
2. Business data belongs to the user.
3. User decides where backups are stored.
4. User is never forced to buy cloud services.
5. A new user can operate it within minutes.

### Five value promises (to a shop owner)

1. Never lose track of an item.
2. Never forget who has it.
3. Never miss a return reminder.
4. Never lose business data because of internet issues.
5. Never pay for cloud features you don’t need.

### Marketing line (final advice)

**Do not** market Version 1 as a “Rental Management App.”

Market it as:

> **“The simplest way to manage, hand over, and track physical assets.”**

Rental is one supported workflow — not the product identity.

### North-star engineering rule

> Every feature must work locally first. Cloud support is added only after the local implementation is complete and stable.

Hard reliability bar:

> If every backend server is unavailable for an entire month, businesses must still operate normally.

---

## 2. Problem, vision & mission

### Problem

Across India and many developing markets, millions of businesses temporarily hand over physical assets every day (books, cameras, chairs, farm equipment, tools, medical devices, office gear, etc.).

Most still rely on **paper registers, notebooks, Excel, WhatsApp, phone calls, and memory**.

That causes:

| Pain | Concrete failures |
|------|-------------------|
| Customer tracking | Who has it? Contact? History? Outstanding returns? |
| Asset tracking | Available vs rented? Maintenance? Missing accessories? Damage history? |
| Verification | No proof of handover, return, terms, or condition |
| Communication | Manual calls / WhatsApp / reminders / due-date chasing |
| Data loss | Lost registers, dead phones, corrupted files, staff turnover |
| Cost / access | Existing software needs subscriptions, always-on cloud, desktops, servers, IT |

### Vision

Become the simplest, most reliable, privacy-focused platform for managing physical asset handovers anywhere.

- Every physical item has a **digital identity**.
- Every handover has **digital proof**.
- Every return is **traceable**.
- Every business remains in **control of its data**.

### Mission

A mobile-first app any business can use without technical knowledge, expensive servers, or permanent connectivity — fully operational offline, with **optional** cloud enhancements.

### Long-term expansion (same engine)

Library management · office asset issuance · employee equipment · school labs · medical device lending · vehicle handovers · warehouse movement · community sharing.

The product evolves from “rental app” → **universal Asset Handover Platform**.

---

## 3. Positioning, market & monetization

### Positioning continuum

```text
Paper Register  →  Excel  →  [This Platform]  →  ERP
```

Tagline:

> The easiest way to digitally hand over and manage physical assets.

Strategic identity:

> **The Operating System for Physical Asset Handover.**

### Real problem vs false problem

- False: “People cannot rent items.”
- Real: **Businesses cannot efficiently manage the lifecycle of physical assets after they are handed over.**

Competitors help customers *discover* rentals. This platform helps businesses *operate*.

### Markets

| Horizon | Segment | Characteristics |
|---------|---------|-----------------|
| Y1–2 Primary | MSME / local ops | 10–500 items, 1–20 staff, low tech skill, paper/Excel |
| Y3–5 Secondary | Growing orgs | Multi-branch, collaboration, sync, advanced reports |
| Y5+ Enterprise | Institutions | Universities, hospitals, government, large fleets |

**India first:** MSME density, Android-first, intermittent connectivity, cost sensitivity.

Primary examples: camera / event / furniture rentals, libraries, sports equipment, farm equipment groups.

### Product-led growth

Free must be **genuinely useful**. Premium sells **convenience**, not gatekeeping of core operations.

#### Free (must remain real)

- Unlimited inventory, customers, rentals
- Full offline operation
- Local notifications
- QR generation / scan
- Manual SMS / WhatsApp (open composer)
- Export reports
- Local encrypted backup

#### Premium (convenience / collaboration)

- Multi-device sync
- Staff accounts
- Auto cloud backup
- Automated reminders (gateway)
- Advanced reports / branding
- Priority support
- AI (future)

#### Enterprise

- Multi-branch, central admin, RBAC, SSO
- ERP integrations, audit exports, public API, SLA
- White-label options

#### Revenue streams (avoid transaction-fee dependency)

Subscriptions · enterprise licenses · white-label · SMS/WA services · AI (future) · setup/migration · industry modules.

### Competitive strengths

Offline-first · local-first · privacy-first · no customer app · low infra cost · configurable backup/retention · QR ops · modular expansion.

### Risks called out

- Feature bloat into ERP
- Sync over-complexity too early
- Early cloud dependency
- Education / onboarding of paper users
- Backup adoption
- Platform policy limits (SMS/WA/background)

---

## 4. Product constitution & decision framework

### Gate question for every feature

> Does this make it easier for a business to manage physical assets?

If no → probably not core.

### Feature evaluation checklist

1. Does it solve a daily problem?
2. Will most businesses use it?
3. Can it work without breaking offline?
4. Can it be disabled if unused?
5. Does it increase infrastructure cost?
6. Can it be an optional module instead of core?

### Decision matrix

| Bucket | Meaning | Examples |
|--------|---------|----------|
| **Core** | Must work offline, local SoT | Search, inventory, rental, return, local backup |
| **Optional** | Improves convenience | Cloud backup, sync, premium messaging |
| **Specialized** | Industry / vertical | Library ISBN fields, farm HP metadata |
| **Reject (for core)** | Wrong problem / wrong layer | Marketplace, social, full ERP, payments as core |

### Values every release should improve

Reliability · Simplicity · Performance · Privacy · Usability.

### What this product is / is not

**Is:** operational tool, business assistant, asset management / handover platform, local-first app.

**Is not:** social network, marketplace, CRM, ERP, accounting, payment app, full WMS.

Prefer **integrations** over rebuilding those systems.

### Ten commandments (never negotiate away)

1. Local DB is source of truth.
2. Cloud is optional.
3. User owns data.
4. Simplicity over feature count.
5. Offline is first-class.
6. Complexity must be justified.
7. Model **asset movement**, not only rentals.
8. Prefer configuration over deep customization.
9. Grow via modules.
10. Maintainability beats short-term convenience.

### Standing strategic practices

- **Offline Contract:** every new feature must declare offline behavior before coding.
- **6-month Constitution health reviews.**
- **ADR repository** for major decisions.
- **Industry Advisory Group** before expanding verticals.

### What should never change

Local primary · data ownership · offline first-class · simple core workflows · modular architecture.

---

## 5. Users, personas, roles & categories

### Target users

Serves **businesses**, not consumers. Consumers interact via SMS, OTP, WhatsApp, QR, receipts — **no customer app required** (optional later).

### Personas

| # | Persona | Needs |
|---|---------|-------|
| 1 | Small rental shop (camera, tools, furniture, decor) | Inventory, customers, rentals, return reminders |
| 2 | Library | Books, students, issue history, returns, search, QR |
| 3 | Educational institute | Lab gear, sports, projectors, laptops |
| 4 | Farm equipment provider | Tractor, seeder, pump, rotavator; **offline critical** |
| 5 | Event company | Huge inventory (chairs, lights, audio); many rentals |
| 6 | Corporate office | Employee laptops, monitors, access cards |
| 7 | Community orgs (societies, NGOs, centers) | Shared resources |

### Roles (V1)

#### Owner (full control)

Configure app · inventory · customers · rentals · returns · reports · backup · subscription.

#### Staff (limited; post-MVP / premium)

Can: search, create rentals, accept returns, view customers, scan QR.  
Cannot: delete DB, configure backups, buy subscriptions, delete owner account.

#### Customer (no app)

Receive SMS/WA · provide OTP · show QR · receive receipt (future).

### Business categories (first launch)

General Rental · Library · Farm Equipment · Construction · Electronics · Camera Rental · Furniture · Sports · Medical · Office Assets · Educational Institute · Event Rental · Photography Studio · Vehicle Rental · Other.

Selecting a category loads **inventory templates** (editable after import).

**Template examples:**

- Library: Book, Journal, Magazine, Calculator
- Farm: Tractor, Seeder, Rotavator, Water Pump
- Event: Chair, Table, Stage Panel, Speaker, LED Light
- Camera: DSLR, Lens, Battery, Memory Card, Tripod

**Business Templates (strategic add):** Library Edition, Camera Edition, Sports, Office, Farm, Construction — same engine, specialized defaults / terminology / starter inventory / workflows / reports.

---

## 6. Version 1 scope: in / out

### Primary objectives (V1)

Replace paper · stop forgotten rentals · track inventory & customers · reduce disputes · digital verification · work offline · minimize infra cost · allow optional cloud.

### Explicit non-objectives (V1)

Public marketplace · AI pricing · payment gateway · insurance · accounting / ERP integration · public reviews · delivery logistics · GPS tracking of assets.

Also cut from V1 per CTO review: AI · payments · staff accounts · enterprise permissions · WhatsApp Business API · multi-branch · automatic multi-device sync · video evidence · marketplace.

### MVP success criteria (must all work **without internet**)

Install → use **without registration** → add inventory → add customers → rent → return → instant search → generate QR → local reminders → export reports → **local backup**.

### MVP priority focus (excel at these five)

1. Customer search  
2. Inventory management  
3. Rental workflow  
4. Returns  
5. Local backup  

### Product differentiators

Offline-first · local-first · privacy-first · no customer app · minimal cloud dependency · configurable backup & retention · QR operations · low infra cost · modular future.

---

## 7. Core modules & domain model

### Core modules (V1)

| Module | Stores / does |
|--------|----------------|
| **Business Profile** | Name, owner, phone, address (opt), category, logo (opt) |
| **Customer** | Phone (primary lookup), name, photo/address/notes (opt), history, outstanding; trust score (future) |
| **Inventory** | Name, category, qty, available, condition, price, deposit, description, photos (opt), barcode, QR, accessories, status |
| **Rental** | Create / update / extend / return / cancel / archive; unique Order ID |
| **Verification** | OTP, PIN, QR, photo, checklist; signature (future); configurable |
| **Search** | One universal search: phone, name, item, order, QR, barcode |
| **Notifications** | Local: due tomorrow, overdue, maintenance, low stock — no cloud |
| **Reporting** | Daily / active / returned / overdue / availability / customer history; export PDF, Excel, CSV |
| **Backup** | Encrypted backup/restore, Drive, local export, ZIP |
| **Sync** | Optional event upload/download, conflicts, retry, progress |
| **Auth** | Optional cloud account, subscription, device registration, license |

### Storage categories

1. **Master** — profile, customers, inventory, categories, settings (always back up).  
2. **Operational** — rentals, returns, due dates, movements, order history.  
3. **Evidence** — photos, videos, documents, signatures (configurable retention; largest storage).

### Identity rules

- **Never use incremental IDs.** Every entity gets a **local UUID**.
- Installation creates durable **Business ID**, **Device ID**, **Owner ID**.
- Customer phone uniqueness is **per business** (same phone can exist in many businesses as separate records; optional later identity linking without merging data).
- Soft delete via `DeletedAt` (restore, audit, sync).

### Human Order ID vs internal UUID

- Display: `ORD-20260802-00421` (readable).
- Internal: UUID (unique / sync-safe).

### Logical data groups

System · Master · Transactions · Synchronization · Configuration.

### Core tables (authoritative field set)

> **Naming note:** Canonical long-term language is **Resource** (and Transaction); physical schema / module names below may lag. See §13 and [ADR-004](../architecture/decisions/ADR-004-business-resources.md).

**Business:** BusinessId, BusinessName, Category, OwnerName, Phone, Email, Address, Country, TimeZone, Currency, Created/Updated, SyncStatus. One business per installation.

**Device:** DeviceId, BusinessId, DeviceName, Platform, OS Version, App Version, RegisteredDate, LastSync. Statuses when connected: Registered / Blocked / Pending / Inactive.

**User / Owner / Staff (staff future):** UserId, BusinessId, Name, Phone, Role, Active, … Future roles: Owner, Staff, Manager, Administrator.

**Customer:** CustomerId, BusinessId, Name, Phone, Address, Email, PhotoPath, Notes, IsRegisteredPlatformUser, PlatformUserId (future), Created/Updated/DeletedAt. Indexes: Phone, Name, BusinessId.

**Category:** CategoryId, BusinessId, Name, Icon, Color, SortOrder.

**Inventory:** InventoryId, BusinessId, CategoryId, Name, Description, Quantity, AvailableQuantity, **ReservedQuantity**, **MaintenanceQuantity**, Unit, Barcode, QRCode, RentalPrice, Deposit, **Metadata (JSON)**, Status, Created/Updated. Indexes: Id, Category, Barcode, Name.

Supports **serialized** assets and **quantity-based** assets (one camera vs 100 chairs).

**Metadata examples (avoid schema churn):**

```json
{ "Lens": "18-55", "Sensor": "APS-C" }
{ "ISBN": "978...", "Edition": "3" }
{ "Horsepower": 45 }
```

**Rental:** RentalId, BusinessId, CustomerId, OrderNumber, Status, RentalDate, DueDate, ReturnDate, DepositAmount, RentalAmount, Discount, Notes, VerificationType, CreatedBy, CreatedAt. Indexes: OrderNumber, CustomerId, Status, DueDate.

**Rental Item:** RentalItemId, RentalId, InventoryId, Quantity, ReturnedQuantity, RentalPrice, Deposit, Status, Notes.

**Media:** references only (never blobs in DB) — MediaId, EntityType, EntityId, FilePath, ThumbnailPath, FileType, Size, Checksum, CreatedAt, RetentionDate.

**Audit:** AuditId, BusinessId, UserId, Event, Entity, EntityId, Details, CreatedAt.

**Notification:** NotificationId, EntityType, EntityId, NotificationType, ScheduledTime, TriggeredTime, Status.

**Settings / Sync Queue / Sync Metadata / Backup Metadata:** support configuration, event queue, and backup history.

### Inventory statuses

Available · Unavailable · Maintenance · Inactive (visible across the app).

### Domain rules (examples)

- Cannot rent unavailable inventory.
- Return quantity cannot exceed rented quantity.
- Order IDs unique.
- Inventory quantity cannot go negative.
- Cancel only **before handover**; after handover use return flow.

### Digital Asset Passport (strategic concept)

Every item accumulates: UUID · QR · creation date · rental history · maintenance history · optional media · status — permanent digital identity of the asset.

### Local file layout (files outside DB)

```text
database/
photos/
videos/
exports/
backup/
logs/
cache/
```

Benefits: smaller DB, easier cleanup, faster backups, better performance. Retention policies drive automatic cleanup.

### Size / retention guidance

- Active business DB often **&lt; 50 MB** excluding media.
- Defaults suggested: rentals forever; photos **~30 days**; videos **~7 days**; logs configurable.
- V1 recommendation: **photos only**; delay video until demand is proven.
- Selective backup checklist: profile, customers, inventory, rentals, media, settings.

---

## 8. Workflows, verification & customer experience

### Design targets

- Average rental: **30–60 seconds**.
- Owner productive in **~10 minutes** after install.
- Workflows must be: Fast · Verifiable · Offline · Configurable.

### Primary business flow

```text
Customer arrives
  → Search by phone (or name / Order ID / QR / recent)
  → Create customer if missing
  → Select inventory (multi-item OK)
  → Review summary (deposit, price, due date)
  → Confirm → Generate Order ID
  → Send SMS or WhatsApp (composer / premium auto later)
  → Rental Active
  → Customer returns
  → Search phone / item / Order ID
  → Verify condition
  → Close rental
```

Minimize screens and typing.

### Rental lifecycle

```text
Draft → Verified → Confirmed → Handed Over → Active
  → Return Requested (optional)
  → Returned → Verified → Closed → Archived
```

Every transition is audited.

### Multi-item rentals

One Order ID covers multiple line items (e.g. DSLR + tripod + battery + card).

### Verification engine (configurable)

Methods: OTP · PIN · QR · Photo · Checklist · Signature (future) · Manual.

**OTP modes:**

1. Offline local display (show code on owner device).
2. Open SMS composer (free).
3. Premium auto gateway (later).

**WhatsApp V1:** prefilled compose. Future: Business API.

### Reminders

Local engine: before due · due day · overdue ladders.

- Free: notify owner → open SMS/WA.
- Premium: optional auto-send.

### Condition modes

- **Basic** — simple status.
- **Standard** — notes + optional photo.
- **Advanced** — checklist, photos, videos (later), repair cost.

### Return edge workflows

| Case | Behavior |
|------|----------|
| Full return | Inventory restored; rental closed; audited |
| Partial return | Remaining qty tracked; rental stays **Active**; inventory updated |
| Damaged / lost | Condition + optional photo/notes; history retained; repair cost optional |
| Extend | New due date; reminders rescheduled |
| Cancel | Only before handover; after handover → return |

### Overdue visual bands

Green → Yellow → Orange (1–3 days) → Red (&gt; 3 days).

### Audit trail examples

Rental created · OTP verified · Reminder sent · Item returned · Extended · Photo captured · Customer updated · Backup completed.

### Customer experience

Never force a customer app. Customers get: confirmation · return reminder · order reference · OTP when required · receipt (future). Owner-centric, still professional outward.

### Future workflow add-ons (without redesigning V1)

Digital agreements · customer portal · payments · e-sign · insurance claims · AI damage detection · auto pricing · delivery scheduling · public booking links · self-service check-in.

---

## 9. System architecture & technology

### Architectural principles

1. **Local First** — all ops against local DB (customers, rentals, QR, reports, …).
2. **Offline First** — internet never required for normal ops.
3. **Cloud Optional** — backend enhances; never enables core ops.
4. **Modular Design** — features as modules behind interfaces.

### High-level layers

```text
Flutter Application
  Presentation  → UI / screens / widgets  (no business logic)
  Application   → use cases / commands / coordination
  Domain        → business rules
  Data          → repositories
  Local Storage → SQLite + encryption
  Optional      → Sync engine, Cloud API, Drive, SMS, WhatsApp
```

Presentation never talks to cloud directly. Everything flows through repositories → local storage.

### Data flow contrast

```text
Traditional SaaS: App → API → DB   (API down = app dead)
This platform:    App → Local DB → Optional Sync
```

### Technology stack

| Layer | Choice | Why |
|-------|--------|-----|
| Mobile | **Flutter** | Single codebase Android/iOS, offline ecosystem, performance |
| State | **Riverpod** | Compile-time safety, testability, DI, modular |
| DB | **SQLite + Drift** | Mature SQL, migrations, speed |
| Alt DB | Isar | If OO storage preferred |
| Encryption | **SQLCipher** | AES-256, protect copied DB files |
| Backend (optional) | **ASP.NET Core + PostgreSQL** | Auth/sync/backup metadata only |

### Suggested monorepo structure

```text
asset-platform/
  apps/mobile/
  packages/
    core/ inventory/ customer/ rental/
    sync/ messaging/ notifications/ backup/ authentication/
  shared/ models/ utilities/ constants/ localization/
  docs/
  scripts/
  backend/
```

New features = new modules; removing a module should not break others.

### Repository pattern

UI → Repository → SQLite (later + Cloud Sync). UI stays stable when sync appears.

### Universal search architecture

One box; auto-detect type:

| Input | Resolves to |
|-------|-------------|
| Phone | Customer |
| Name | Customer / Item |
| Order ID | Rental |
| QR / Barcode | Inventory / Item |

Results surface customer, current rental, item, history immediately. Target: **&lt; 100 ms**.

### QR architecture

Generated **locally**: Inventory UUID + Business ID + checksum. No internet.

### Configuration philosophy (owner control)

Auto backup · retention · photo/video retention · theme · language · reminder schedule · business category · cloud sync on/off.

### Performance goals

| Metric | Target |
|--------|--------|
| Cold start | &lt; 2 seconds |
| Customer search | &lt; 100 ms |
| Inventory search | Instant |
| Rental creation | &lt; 2 seconds (workflow &lt; 1 minute) |
| Reports | &lt; 5 seconds |
| Backup | Background; never block UI |

### Scalability path (no rewrite)

```text
Single Device → Offline Business → Cloud Backup
  → Multi-device Sync → Multi-branch → Enterprise
```

### Localization & accessibility

- Languages: English + Hindi first; more Indian languages later.
- Theme: light / dark / system; branding later.
- A11y: large fonts, screen readers, high contrast.
- Large touch targets; progressive disclosure; one primary action per screen.

### Engineering standards (handbook themes)

Clean Architecture · feature isolation · interface-driven design · feature flags · Result pattern for expected business outcomes · typed errors (Success / Validation / Permission Denied / Unexpected) · null safety · linting · flavors (Dev/Test/Staging/Prod) · gitflow · unit/widget/integration tests · CI: analyze → test → build → internal → manual prod.

**Background work:** opportunistic (respect OS battery limits); do not assume precise scheduling.

---

## 10. Operating modes, sync, backup, security & privacy

### Three operating modes

| Mode | Account | Backup | Sync | Typical user |
|------|---------|--------|------|--------------|
| **1. Standalone (default)** | None | Local only | No | Small shop, personal |
| **2. Protected** | Optional sign-in | Encrypted cloud/local recovery | No | Phone-loss protection |
| **3. Connected** | Required | Yes | Multi-device events | Staff, premium |

Registration remains optional: **use immediately**, create account only when enabling backup or cloud.

### Sync philosophy

- Sync **events**, never whole SQLite dumps.
- Never block UI / require immediate internet / wait on server.
- Payload = changed fields only.
- Cloud is an **event exchange**, not the operational DB.
- Each Connected device keeps its own local DB.

**Event fields:** EventId, BusinessId, DeviceId, Entity Type/Id, Operation, Timestamp, Version, Payload, Status.

**Queue states:** Pending → Uploading → Uploaded → Verified → Archived (also Failed).

**Retries:** exponential backoff (1m → 5m → 30m → 2h → 12h → daily).

**Triggers:** app start/close · manual · connectivity · charging (opt) · Wi-Fi (opt).

**V1 conflicts:** single-device → none.  
**Future conflicts:** timestamp → version → device priority → manual. Error code **SYNC002**.

**Do not implement multi-device sync until single-device workflow is validated** (CTO). Underestimated issues: simultaneous edits, clock skew, deletes, duplicates, partial sync, schema evolution.

### Backup ≠ Sync

| Backup | Sync |
|--------|------|
| Protect against loss | Keep devices consistent |
| Snapshot / archive | Continuous events |
| User-chosen destination | Connected mode |

**Destinations:** Local · Google Drive · OneDrive · Dropbox (future) · NAS (future) · company cloud (future).

**Backup sequence (principle):** freeze writes → export → compress → encrypt → checksum → upload/store → resume.

Wi-Fi / charging-only options. Encryption on archives.

### What backend may store (V1)

Auth · devices · subscriptions · sync metadata · backup **metadata** · recovery metadata · consent analytics.

### What backend must NOT store (V1)

Rentals · inventory · customer PII operational records · photos · notes · audit details · reports as system of record.

(Files live in user storage unless enterprise arrangement.)

### Security layers

- SQLCipher DB encryption
- Encrypted backup archives
- HTTPS / TLS
- Short-lived access + long-lived refresh tokens (Connected)
- Optional app PIN / biometrics
- Hide prices / phone numbers settings
- Device block / inactive states
- **No PII in server logs** (no names, phones, rental details)

### Privacy

Explicit consent for backup, sync, analytics, diagnostics — clear and revocable. Minimal cloud footprint eases GDPR-style compliance. Avoid vendor lock-in; export/restore must stay easy.

### Auth (when Connected / Protected)

Phone + OTP primary. Future: Google, Apple, Microsoft, Email.

---

## 11. Backend & cloud APIs

### Backend role

Optional companion. Never day-to-day business logic (no rental calc, inventory mgmt, customer search, reports, QR, local reminders, workflows).

### Service sketch

```text
Flutter → Local SQLite → Sync/Backup Engine
        → HTTPS → ASP.NET Core
           Auth | Sync | Device | Backup | Subscription | Future Notifications
        → PostgreSQL
```

**CTO addendum:** split early into **Identity Service** vs **Sync Service** (different scale/security profiles).

### API surface (conceptual)

- Auth: register / login / refresh / logout
- Device: register / status
- Sync: upload / download (sequence-number based) / status — **idempotent**; no duplicate processing
- Backup: register / history (metadata only)
- Subscription · minimal Business profile · consent Analytics · Health · Version (min app version)
- Future: notification send

**Stable error codes:** AUTH001/002 · SYNC001/002 (conflict) · BACKUP001 · DEVICE001.

**Environments:** Dev / Test / Staging / Prod separation.

**No V1 APIs** for inventory, customer CRUD, or rental operations on the server.

### Long-term optional cloud layers

Realtime collab · branches · enterprise · AI · ERP bridges · payments · portals.

---

## 12. UX architecture & screens

### UX principles

- WhatsApp-simple; productive in minutes.
- Fewer taps: search ≤2 · rental ≤6 · return ≤5.
- One primary action; progressive disclosure.
- Offline transparency (soft offline indicator).
- Dashboard answers **“what needs attention today?”** — not an analytics wall.

### Navigation

**Dashboard | Rentals | Inventory | Customers | More**

### First launch

Splash (no login, no ads) → Welcome (**Continue** or **Restore**) → minimal business setup → category templates.

### Screen inventory (V1)

| Area | Screens / content |
|------|-------------------|
| Dashboard | Today’s rentals/returns, overdue, inventory summary, quick actions, recent activity |
| Universal Search | Phone / name / item / order / QR / barcode |
| Customers | List (photo, name, phone, active rentals, status); Detail (history, notes, call/SMS/WA, edit); Add (phone+name required; photo/address/notes opt; save &lt;5s) |
| Inventory | List + filters (category, available, maintenance, inactive); Detail; Add |
| Rentals | Create (multi-item); Active list; Detail + timeline |
| Returns | Full / partial / damaged flows |
| More / Settings | Retention; Backup destinations & schedule; Privacy (PIN/biometrics/hide prices/numbers/disable analytics); About (app + DB version) — sectioned, not one endless list |

Future modules appear as add-ons without changing core flows.

---

## 13. Universal platform & 10-year vision

### Abstraction: Business Resources engine

Long-term domain stack (canonical product language; see [ADR-004](../architecture/decisions/ADR-004-business-resources.md)):

```text
Business → Resources → Transactions → Reports
```

| Concept | Meaning |
|---------|---------|
| **Business** | The installing operator (shop / gym / salon / …); one local installation = one business in V1 |
| **Resource** | Catalog unit: physical item, service, job, membership, digital asset, or financial record |
| **Transaction** | Universal action: counterparty + resource lines + status + timeline (today’s rental/order is the first shape) |
| **Reports** | Operational views and exports over resources and transactions (template-declared widgets; Share Reports is plain text) |

Related concepts that still matter:

- **Asset** (Digital Asset Passport) — identity and history for tracked physical items
- **Person** (customer / employee / member)

**Resource types** (configuration, not separate modules): Rental Item · Sale Item · Service · Job · Subscription · Membership · Loan · Financial · Custom.

**Industry mapping examples** (same engine, different config packs):

| Template flavor | Typical resource types |
|-----------------|------------------------|
| Camera / tool rental | Rental Item (+ accessories as resources) |
| Boutique / retail | Sale Item |
| Mechanic / repair | Job · Service · Sale Item (parts) |
| Gym / club | Membership · Subscription · Rental Item |
| Library | Loan · Rental Item |

Plus later: **Rule Engine** · **Workflow Engine** (optional approval/inspect steps) · **Metadata** · **Templates** · **Plugins**.

V1 still ships **rental-first** UX and may still say “Inventory” in the app until a rename phase. Schema table names in §7 remain historically named; epic names in §14 stay accurate for the backlog with a forward pointer to ADR-004.

### Plugin examples

Payments · maintenance · accounting · insurance · AI · marketplace · fleet · delivery.

### Enterprise future

Public API / webhooks · white-label · multi-tenant isolation · SSO · SLA.

### Globalization

Currency · timezone · locale · units.

### Evolution ladder

```text
Offline Register → Digital Rental → Asset Handover
  → Business Resources Platform → Configurable Business OS
```

**One engine + configuration**, not separate products per industry. Same DB, different config.

**Engine MVP complete (ADR-004 phases 1–5):** enabled resource types, Home presets, workflow status pipelines, dynamic catalog fields (`FieldDef` + `metadata` JSON), and composable report widgets. Further platform work (Transaction rename, new Home modules, AI, plugins) remains later — see ADR-004 later track.

### Governance for new modules

Does it fit constitution? Offline contract? Optional? Increases infra? Industry advisory validated?

---

## 14. Delivery plan: MVP, backlog & 90 days

### Development philosophy

1. Measurable user value.  
2. Independently testable.  
3. Deployable without unfinished modules.  

Gate: daily problem? needed for ops? used by ~80% weekly?

### Engineering stages (high level)

Foundation → Customer → Inventory → Rental → Dashboard → Notifications → Backup → Reports → **Sync (delayed)** → Premium.

Solo-dev path: release early, validate; ~8 two-week sprints → closed alpha (~4 months) as one estimate.

### Epics (backlog SoT)

Epic names below stay historically accurate (Inventory / Rentals). Long-term product language is **Resources / Transactions** — see [ADR-004](../architecture/decisions/ADR-004-business-resources.md) and §13.

| Epic | Focus | Notes |
|------|-------|-------|
| 1 Foundation | Bootstrap, DB, theme, business setup | Startup &lt;2s; offline |
| 2 Customers | CRUD, search, history | Duplicate phone **warning**; search &lt;100ms |
| 3 Inventory | Add/search/update/status | No negative qty; QR/barcode |
| 4 Rentals | Create, multi-item, search, timeline | All offline; reminders scheduled; audit |
| 5 Returns | Full, partial, damaged | Partial keeps Active |
| 6 Dashboard | Today / overdue / quick actions | |
| 7 Search | Universal | |
| 8 Notifications | Local reminder engine + SMS/WA actions | |
| 9 Reports | Rental + inventory; PDF/Excel/CSV | |
| 10 Backup/Restore | Encrypted local (+ Drive later) | |
| 11 Sync | **Post-MVP** | Idempotent; no dup downloads |
| 12 Settings/Security | Retention, privacy, about | |
| 13 Templates | **Post-MVP** | Business templates |

### Priority matrix

Must / Should / Could / Future — sync, AI, payments, enterprise in Future for early releases.

### 90-day CTO plan

| Month | Build | Exclude |
|-------|-------|---------|
| M1 | Foundation + customers + inventory | Sync, AI, payments, enterprise |
| M2 | Rental + return + dashboard + search | same |
| M3 | Notifications + backup + reports + perf + closed beta | same |

Path: polish offline register → 20–30 real businesses → refine → premium backup/sync → templates → advanced later.

### Definition of Done (include)

Localization readiness · accessibility basics · offline verification · audit events · tests · docs/migration notes where needed.

### Product metrics (examples)

Time to first rental · daily active use · overdue recovery · backup adoption · retention of free users · conversion only after free value proven.

---

## 15. Edge cases, failures & degradation

Nothing may block business operations. Always offer a next step.

### Communication / capture failures

| Failure | Degradation |
|---------|-------------|
| No internet | Continue fully local |
| Cloud / backend down | Queue sync; ops unchanged (even for a month) |
| Google Drive unavailable | Retry later; keep local backup |
| SMS unavailable | Offer WhatsApp |
| WhatsApp unavailable | Offer copy message |
| Camera unavailable | Continue without photo |
| QR scan fails | Manual search |
| SIM removed | No sync required |

### Data / device disasters

| Scenario | Outcome |
|----------|---------|
| Phone lost | Recover from backup if Protected/Connected; else same risk as paper register |
| Corrupted DB | Restore from backup |
| Device blocked (Connected) | Stop sync; local ops policy TBD per security rules |

### Operational edge cases

- Duplicate customer phone → **warn**, don’t silently merge across businesses.
- Partial returns · damaged/lost · cancel-before-handover only.
- Overdue color escalation.
- Soft deletes for restore/audit/sync.
- Reserved / maintenance quantities affect availability.
- Sync conflict (future) → SYNC002 + resolution path.
- Token expiry → refresh / re-auth without wiping local data.
- Background task killed by OS → opportunistic retry.
- Schema migration → never lose data on upgrade.

### Error UX principle

Explain · suggest next action · preserve user data · never show raw stack traces.

---

## 16. Final strategic advice

### What creates durable advantage

Not QR, OTP, or sync alone — **data ownership** + **local-first resilience** + **no customer app** + **optional registration** + **modular universal handover engine**.

### Biggest strategic risk

Losing focus across industries too early / shipping too much before product-market fit.

### Discipline over feature race

A reliable app used daily by a few hundred businesses beats a feature-rich platform that never sticks.

### Closing identity

> A resilient, local-first operating platform for managing the movement of physical assets between people and organizations.

Defining characteristics: data ownership · offline reliability · simplicity · modularity · long-term maintainability.

### One positioning change that matters

Market **asset handover**, not “rental management.” Same architecture. Larger market.

---

## Appendix A — Quality attributes

Continuously optimize for: Reliability · Maintainability · Security · Performance · Privacy · Extensibility. No feature may significantly compromise these.

### Engineering principles (short)

One responsibility per module · one SoT per entity · offline-first · cloud as enhancement · small testable components · stable interfaces · configuration over customization where appropriate.

### Cost evolution

Early: minimal cloud. Growth: sync capacity. Enterprise: dedicated services. Infra scales with demand — not day one.

---

## Appendix B — Source phase index

This summary consolidates content originally organized as Phases 1–18. The table maps those phase numbers to sections in **this document** (for historical reference only — there are no separate phase extract files).

| Phase | Title | Role in this summary |
|------:|-------|----------------------|
| 1 | Executive Summary, Vision & Problem | §2 |
| 2 | Scope, Personas, Requirements | §3, §5, §6, §7 modules |
| 3 | System Architecture Foundation | §9 |
| 4 | Data Architecture & Event Sync | §7, §10 |
| 5 | Lifecycle, Verification, Workflows | §8, §15 |
| 6 | Sync, Backup, Security, Backend | §10, §11 |
| 7 | Flutter Implementation Standards | §9 engineering |
| 8 | Business Strategy & Monetization | §3 |
| 9 | Engineering Roadmap | §14 |
| 10 | CTO Review & Recommendations | §6 cuts, §14 path, Asset Passport |
| 11 | PRD & Screen Spec | §12 |
| 12 | Universal Platform / 10-Year | §13 |
| 13 | Product Constitution | §4 |
| 14 | Complete Domain Model | §7 schema SoT |
| 15 | Backend API Spec | §11 SoT |
| 16 | Flutter Engineering Blueprint | §9 handbook |
| 17 | Backlog & MVP Plan | §14 SoT |
| 18 | Master Blueprint / Architecture Bible | §1, §4, §16 |

This file is the sole product SoT. Prefer it for onboarding and all product decisions.

---

## Appendix C — Quick “Offline Contract” template

For every new feature, document before implementation:

1. **Works fully offline?** Yes / Partial / Online-only (must justify).
2. **Local SoT entity impacted?**
3. **User-visible behavior when offline / cloud down?**
4. **Queued for sync?** What event shape?
5. **Backup implications?**
6. **Can it be a module / flag?**

If this cannot be answered clearly, the feature is not ready to build.
