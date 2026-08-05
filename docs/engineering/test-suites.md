# Test suites

Focused Flutter test runs via tags in `apps/web/dart_test.yaml` and `@Tags` on each `*_test.dart` file. Full `test` remains the default for CI and pre-push safety.

## How to run

From Windows PowerShell (repo root):

```powershell
.\scripts\wsl.ps1 test              # analyze + all tests
.\scripts\wsl.ps1 test all          # same
.\scripts\wsl.ps1 test unit
.\scripts\wsl.ps1 test widget
.\scripts\wsl.ps1 test integration
.\scripts\wsl.ps1 test orders
.\scripts\wsl.ps1 test pricing
```

From WSL:

```bash
./scripts/test.sh
./scripts/dev.sh test unit
./scripts/test.sh orders
./scripts/test.sh -- --tags "orders || pricing"   # passthrough escape hatch
```

Env knobs:

| Variable | Effect |
|----------|--------|
| `TEST_SKIP_ANALYZE=1` | Skip `flutter analyze` (tight loops only) |
| `TEST_CONCURRENCY=N` | Override `flutter test` concurrency |

Prefer **focused suites during feature work**; run **full `test` before PR/push**.

## Layer tags

Every suite file has exactly one:

| Tag | Meaning |
|-----|---------|
| `unit` | Pure logic / repository without full shell navigation |
| `widget` | Screen/flow widget tests (`testWidgets`) |
| `integration` | Cross-feature / shell-wide smoke |

## Domain tags

| Tag | Typical coverage |
|-----|------------------|
| `pricing` | Rental pricing math, repo persistence, line duration, open-ended |
| `orders` | New order flow, sale fulfillment, line qty, order bills |
| `returns` | Partial return, parent-unit issue/return |
| `inventory` | Inventory categories |
| `customers` | Customer balance, Unknown customer |
| `deposit` | Deposit wallet, order deposit |
| `search` | Min-length search / text rules |
| `shell` | App shell, Home KPIs, UX polish |
| `reports` | Report share / WhatsApp text |
| `notes` | Rental order notes |
| `labels` | Rental instance labels |

## Dependency → suite map

| Touched area | Run |
|--------------|-----|
| `core/pricing/**` | `test pricing` |
| `features/orders/**`, order repo create | `test orders` (+ `test pricing` if billing changed) |
| returns / partial return | `test returns` |
| inventory categories / add inventory | `test inventory` |
| customer balance / unknown customer | `test customers` |
| deposit wallet | `test deposit` |
| search widgets / `core/search` | `test search` |
| `app_shell` / home / multi-tab | `test shell` and/or `test integration` |
| reports / WhatsApp share | `test reports` |
| rental notes | `test notes` |
| instance labels | `test labels` |
| Unsure / schema migration / many areas | `test` (full) |
