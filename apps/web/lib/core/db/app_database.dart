import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: <Type>[
    Customers,
    InventoryItems,
    Rentals,
    RentalItems,
    RentalEvents,
    DepositLedger,
    AppMeta,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Production opener uses [driftDatabase]; pass an executor for tests.
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.addColumn(rentals, rentals.nickname);
      }
      if (from < 3) {
        await m.addColumn(rentalItems, rentalItems.instanceName);
        await m.addColumn(rentalItems, rentalItems.shortCode);
        // Backfill instance name from catalog; unique legacy short codes.
        await customStatement('''
          UPDATE rental_items
          SET instance_name = COALESCE(
            (SELECT name FROM inventory_items
             WHERE inventory_items.id = rental_items.item_id),
            ''
          )
          WHERE instance_name IS NULL OR instance_name = ''
        ''');
        await customStatement('''
          UPDATE rental_items
          SET short_code = upper('LEGACY-' || rental_id || '-' || item_id)
          WHERE short_code IS NULL
             OR short_code = ''
             OR upper(short_code) = 'LEGACY'
        ''');
      }
      if (from < 4) {
        await m.addColumn(inventoryItems, inventoryItems.billingMode);
        await m.addColumn(inventoryItems, inventoryItems.rateAmount);
        await m.addColumn(inventoryItems, inventoryItems.lateFeePerDay);
        await m.addColumn(inventoryItems, inventoryItems.currencyCode);
        await m.addColumn(rentals, rentals.billingMode);
        await m.addColumn(rentals, rentals.rateAmount);
        await m.addColumn(rentals, rentals.lateFeePerDay);
        await m.addColumn(rentals, rentals.baseAmount);
        await m.addColumn(rentals, rentals.lateAmount);
        await m.addColumn(rentals, rentals.totalAmount);
        await m.addColumn(rentals, rentals.durationUnits);
        await customStatement('''
          UPDATE inventory_items
          SET billing_mode = COALESCE(billing_mode, 'weekly'),
              rate_amount = COALESCE(rate_amount, 0),
              late_fee_per_day = COALESCE(late_fee_per_day, 0),
              currency_code = COALESCE(currency_code, 'INR')
        ''');
        await customStatement('''
          UPDATE rentals
          SET billing_mode = COALESCE(billing_mode, 'weekly'),
              rate_amount = COALESCE(rate_amount, 0),
              late_fee_per_day = COALESCE(late_fee_per_day, 0),
              base_amount = COALESCE(base_amount, 0),
              late_amount = COALESCE(late_amount, 0),
              total_amount = COALESCE(total_amount, 0),
              duration_units = COALESCE(duration_units, 1)
        ''');
      }
      if (from < 5) {
        await m.addColumn(customers, customers.depositBalance);
        await m.addColumn(rentals, rentals.depositApplied);
        await m.createTable(depositLedger);
        await customStatement('''
          UPDATE customers
          SET deposit_balance = COALESCE(deposit_balance, 0)
        ''');
        await customStatement('''
          UPDATE rentals
          SET deposit_applied = COALESCE(deposit_applied, 0)
        ''');
      }
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'asset_os',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }
}
