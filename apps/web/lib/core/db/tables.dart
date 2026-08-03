import 'package:drift/drift.dart';

@DataClassName('CustomerRow')
class Customers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text()();
  BoolColumn get isTrusted => boolean().withDefault(const Constant(false))();
  TextColumn get qrCode => text()();
  /// Wallet deposit balance in paise.
  IntColumn get depositBalance => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('InventoryItemRow')
class InventoryItems extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  IntColumn get availableUnits => integer()();
  IntColumn get totalUnits => integer()();
  TextColumn get status => text()();
  TextColumn get qrCode => text()();
  TextColumn get notes => text().nullable()();
  /// `daily` | `weekly` | `monthly` | `fixed` | `custom`
  TextColumn get billingMode => text().withDefault(const Constant('weekly'))();
  /// Rate in paise (minor units).
  IntColumn get rateAmount => integer().withDefault(const Constant(0))();
  /// Optional overdue fee per day in paise.
  IntColumn get lateFeePerDay => integer().withDefault(const Constant(0))();
  TextColumn get currencyCode => text().withDefault(const Constant('INR'))();
  /// When true, rentals may omit a due date (open-ended accrual until return).
  BoolColumn get dueDateOptional =>
      boolean().withDefault(const Constant(false))();
  /// When true, each issued unit needs instance name + short code (parent catalog).
  BoolColumn get requiresUnitIdentity =>
      boolean().withDefault(const Constant(true))();
  /// `rental` | `general` — catalog default for New Order Rent/Sell.
  TextColumn get defaultItemKind =>
      text().withDefault(const Constant('rental'))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('RentalRow')
class Rentals extends Table {
  TextColumn get id => text()();
  TextColumn get customerId => text().references(Customers, #id)();
  DateTimeColumn get startedAt => dateTime()();
  /// Null for open-ended rentals (no fixed due date).
  DateTimeColumn get dueAt => dateTime().nullable()();
  DateTimeColumn get returnedAt => dateTime().nullable()();
  TextColumn get qrCode => text()();
  /// Optional per-rental display name (e.g. Unknown path nickname).
  TextColumn get nickname => text().nullable()();
  /// Snapshot of billing at issue (`daily`/`weekly`/`monthly`/`fixed`/`custom`).
  TextColumn get billingMode => text().withDefault(const Constant('weekly'))();
  /// Snapshot rate in paise (primary/first line).
  IntColumn get rateAmount => integer().withDefault(const Constant(0))();
  /// Snapshot late fee per day in paise (sum of lines).
  IntColumn get lateFeePerDay => integer().withDefault(const Constant(0))();
  IntColumn get baseAmount => integer().withDefault(const Constant(0))();
  IntColumn get lateAmount => integer().withDefault(const Constant(0))();
  IntColumn get totalAmount => integer().withDefault(const Constant(0))();
  /// Deposit applied from customer wallet at return (paise).
  IntColumn get depositApplied => integer().withDefault(const Constant(0))();
  /// Chosen duration (e.g. 1 week → 1; fixed due-days still stored here).
  IntColumn get durationUnits => integer().withDefault(const Constant(1))();
  /// Set when this rental was opened as a replacement for a line on another rental.
  TextColumn get replacedFromRentalId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('RentalItemRow')
class RentalItems extends Table {
  /// Line id (e.g. RLI-…); allows multiple units of the same catalog item.
  TextColumn get id => text()();
  TextColumn get rentalId => text().references(Rentals, #id)();
  TextColumn get itemId => text().references(InventoryItems, #id)();
  /// Copy/title for this issue (e.g. novel title); not inventory master.
  TextColumn get instanceName => text().withDefault(const Constant(''))();
  /// Short tracking code unique among open rental lines (case-insensitive).
  TextColumn get shortCode => text().withDefault(const Constant('LEGACY'))();
  /// Null while the line is still out; set on partial or full return.
  DateTimeColumn get returnedAt => dateTime().nullable()();
  /// Line base charge in paise (snapshot at issue).
  IntColumn get baseAmount => integer().withDefault(const Constant(0))();
  /// Finalized late fee in paise (set on return).
  IntColumn get lateAmount => integer().withDefault(const Constant(0))();
  /// Deposit applied from wallet for this line (paise).
  IntColumn get depositApplied => integer().withDefault(const Constant(0))();
  /// `rent` | `sell` — how this line was issued.
  TextColumn get fulfillment => text().withDefault(const Constant('rent'))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('RentalEventRow')
class RentalEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get rentalId => text().references(Rentals, #id)();
  TextColumn get title => text()();
  TextColumn get subtitle => text()();
  DateTimeColumn get at => dateTime()();
}

/// Append-only deposit wallet ledger (`top_up` | `apply` | `refund` | `adjust`).
@DataClassName('DepositLedgerRow')
class DepositLedger extends Table {
  TextColumn get id => text()();
  TextColumn get customerId => text().references(Customers, #id)();
  TextColumn get rentalId => text().nullable().references(Rentals, #id)();
  /// `top_up` | `apply` | `refund` | `adjust`
  TextColumn get type => text()();
  /// Signed amount in paise (+ top-up, − apply/refund).
  IntColumn get amount => integer()();
  IntColumn get balanceAfter => integer()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get at => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// Key/value flags (e.g. SharedPreferences snapshot migration).
@DataClassName('AppMetaRow')
class AppMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{key};
}
