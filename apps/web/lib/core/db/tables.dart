import 'package:drift/drift.dart';

@DataClassName('CustomerRow')
class Customers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text()();
  BoolColumn get isTrusted => boolean().withDefault(const Constant(false))();
  TextColumn get qrCode => text()();

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

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('RentalRow')
class Rentals extends Table {
  TextColumn get id => text()();
  TextColumn get customerId => text().references(Customers, #id)();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get dueAt => dateTime()();
  DateTimeColumn get returnedAt => dateTime().nullable()();
  TextColumn get qrCode => text()();
  /// Per-rental display name (required when issuing to SELF Known).
  TextColumn get nickname => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DataClassName('RentalItemRow')
class RentalItems extends Table {
  TextColumn get rentalId => text().references(Rentals, #id)();
  TextColumn get itemId => text().references(InventoryItems, #id)();
  /// Copy/title for this issue (e.g. novel title); not inventory master.
  TextColumn get instanceName => text().withDefault(const Constant(''))();
  /// Short tracking code unique among active rental lines (case-insensitive).
  TextColumn get shortCode => text().withDefault(const Constant('LEGACY'))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{rentalId, itemId};
}

@DataClassName('RentalEventRow')
class RentalEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get rentalId => text().references(Rentals, #id)();
  TextColumn get title => text()();
  TextColumn get subtitle => text()();
  DateTimeColumn get at => dateTime()();
}

/// Key/value flags (e.g. SharedPreferences snapshot migration).
@DataClassName('AppMetaRow')
class AppMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{key};
}
