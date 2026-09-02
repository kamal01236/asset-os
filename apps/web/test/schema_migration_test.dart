@Tags(['unit'])
library;

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/infrastructure/db/app_database.dart';
import 'package:asset_os/infrastructure/db/migrations/forward_migrations.dart';

import 'support/schema_fixtures.dart';

void main() {
  group('schema migrations', () {
    test('fresh install is v25 with all tables and key columns', () async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      expect(db.schemaVersion, kSchemaBaselineVersion);

      final List<String> tables = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name NOT LIKE 'sqlite_%' ORDER BY name",
          )
          .map((QueryRow row) => row.read<String>('name'))
          .get();

      expect(
        tables,
        containsAll(<String>[
          'app_meta',
          'customer_subscriptions',
          'customers',
          'deposit_ledger',
          'inventory_items',
          'media_attachments',
          'money_loan_entries',
          'money_loans',
          'rental_events',
          'rental_items',
          'rental_notes',
          'rentals',
        ]),
      );
      expect(tables.length, 12);

      final bool hasReferenceCode = await db
          .customSelect('PRAGMA table_info(rental_events)')
          .map((QueryRow row) => row.read<String>('name'))
          .get()
          .then((List<String> cols) => cols.contains('reference_code'));
      expect(hasReferenceCode, isTrue);

      final bool hasInterestAccrual = await db
          .customSelect('PRAGMA table_info(money_loans)')
          .map((QueryRow row) => row.read<String>('name'))
          .get()
          .then((List<String> cols) => cols.contains('interest_accrual'));
      expect(hasInterestAccrual, isTrue);

      final List<QueryRow> subscriptionTables = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name = 'customer_subscriptions'",
          )
          .get();
      expect(subscriptionTables, isNotEmpty);
    });

    test('legacy v22 upgrades to v24 without error', () async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await upgradeLegacyV22FixtureToV24(db);

      expect(db.schemaVersion, kSchemaBaselineVersion);

      final bool hasSubscriptions = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name = 'customer_subscriptions'",
          )
          .get()
          .then((List<QueryRow> rows) => rows.isNotEmpty);
      expect(hasSubscriptions, isTrue);
    });

    test('v23 to v24 preserves rental_events rows and adds reference_code',
        () async {
      const String eventTitle = 'Payment received';
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await upgradeV23FixtureToV24(db, eventTitle: eventTitle);

      expect(db.schemaVersion, kSchemaBaselineVersion);

      final bool hasReferenceCode = await db
          .customSelect('PRAGMA table_info(rental_events)')
          .map((QueryRow row) => row.read<String>('name'))
          .get()
          .then((List<String> cols) => cols.contains('reference_code'));
      expect(hasReferenceCode, isTrue);

      final RentalEventRow event = await (db.select(db.rentalEvents)
            ..where((t) => t.title.equals(eventTitle)))
          .getSingle();
      expect(event.rentalId, 'RNT-V23');
      expect(event.referenceCode, isNull);
    });

    test('v24 to v25 adds media_attachments table', () async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await db.customStatement('DROP TABLE IF EXISTS media_attachments');
      await db.customStatement('PRAGMA user_version = 24');

      final Migrator migrator = db.createMigrator();
      await runForwardMigration(db, migrator, 25);

      final bool hasMedia = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name = 'media_attachments'",
          )
          .get()
          .then((List<QueryRow> rows) => rows.isNotEmpty);
      expect(hasMedia, isTrue);
    });
  });
}
