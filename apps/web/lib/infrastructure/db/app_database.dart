import 'package:drift/drift.dart';

import 'app_database_connection.dart';
import 'migrations/forward_migrations.dart';
import 'migrations/legacy_migrations.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// Fresh installs use [onCreate] at this version; legacy upgrades run through v24.
const int kSchemaBaselineVersion = 24;

@DriftDatabase(
  tables: <Type>[
    Customers,
    InventoryItems,
    Rentals,
    RentalItems,
    RentalEvents,
    RentalNotes,
    DepositLedger,
    AppMeta,
    MoneyLoans,
    MoneyLoanEntries,
    CustomerSubscriptions,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Production opener uses [driftDatabase]; pass an executor for tests.
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => kSchemaBaselineVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < kSchemaBaselineVersion) {
        await migrateLegacyToBaseline(this, m, from);
      }
      for (
        var v = from < kSchemaBaselineVersion ? kSchemaBaselineVersion : from;
        v < to;
        v++
      ) {
        await runForwardMigration(this, m, v + 1);
      }
    },
  );

  static QueryExecutor _openConnection() => openAppDatabase();
}
