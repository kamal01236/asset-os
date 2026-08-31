import 'package:asset_os/infrastructure/db/app_database.dart';
import 'package:asset_os/infrastructure/db/migrations/legacy_migrations.dart';

/// Prepares a v22-shaped DB (no `customer_subscriptions`, no
/// `rental_events.reference_code`) and runs legacy steps through v24.
Future<void> upgradeLegacyV22FixtureToV24(AppDatabase db) async {
  await db.customStatement('DROP TABLE IF EXISTS customer_subscriptions');
  await db.customStatement(
    'ALTER TABLE rental_events DROP COLUMN reference_code',
  );
  await db.customStatement('PRAGMA user_version = 22');
  await migrateLegacyToBaseline(db, db.createMigrator(), 22);
}

/// Seeds a v23-shaped DB (no [rental_events.reference_code]) on [db], then runs
/// the v24 legacy migration step.
Future<void> upgradeV23FixtureToV24(
  AppDatabase db, {
  String eventTitle = 'Payment received',
}) async {
  await db.into(db.customers).insert(
    CustomersCompanion.insert(
      id: 'CUS-V23',
      name: 'V23 Customer',
      phone: '9000000002',
      qrCode: 'customer:v23',
    ),
  );
  await db.into(db.rentals).insert(
    RentalsCompanion.insert(
      id: 'RNT-V23',
      customerId: 'CUS-V23',
      startedAt: DateTime.utc(2024, 6, 1),
      qrCode: 'rental:v23',
    ),
  );
  await db.into(db.rentalEvents).insert(
    RentalEventsCompanion.insert(
      rentalId: 'RNT-V23',
      title: eventTitle,
      subtitle: '₹100',
      at: DateTime.utc(2024, 6, 2),
    ),
  );

  await db.customStatement(
    'ALTER TABLE rental_events DROP COLUMN reference_code',
  );
  await db.customStatement('PRAGMA user_version = 23');
  await migrateLegacyToBaseline(db, db.createMigrator(), 23);
}
