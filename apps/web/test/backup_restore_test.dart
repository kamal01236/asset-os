@Tags(['unit'])
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:asset_os/application/local_repository.dart';
import 'package:asset_os/application/providers/app_providers.dart';
import 'package:asset_os/application/reminders/reminder_settings.dart';
import 'package:asset_os/application/verification/verification_settings.dart';
import 'package:asset_os/domain/verification/verification_models.dart';
import 'package:asset_os/infrastructure/db/app_database.dart';

import 'support/test_harness.dart';

/// Reads every backed-up table into value-equality sets so order doesn't matter.
Future<Map<String, Set<Object?>>> _tableSnapshot(AppDatabase db) async {
  return <String, Set<Object?>>{
    'customers': (await db.select(db.customers).get()).toSet(),
    'inventoryItems': (await db.select(db.inventoryItems).get()).toSet(),
    'rentals': (await db.select(db.rentals).get()).toSet(),
    'rentalItems': (await db.select(db.rentalItems).get()).toSet(),
    'rentalEvents': (await db.select(db.rentalEvents).get()).toSet(),
    'rentalNotes': (await db.select(db.rentalNotes).get()).toSet(),
    'depositLedger': (await db.select(db.depositLedger).get()).toSet(),
    'moneyLoans': (await db.select(db.moneyLoans).get()).toSet(),
    'moneyLoanEntries': (await db.select(db.moneyLoanEntries).get()).toSet(),
    'customerSubscriptions':
        (await db.select(db.customerSubscriptions).get()).toSet(),
    'appMeta': (await db.select(db.appMeta).get()).toSet(),
    'mediaAttachments': (await db.select(db.mediaAttachments).get()).toSet(),
  };
}

Map<String, Object?> _prefsSnapshot(SharedPreferences prefs) {
  return <String, Object?>{
    for (final String key in kBackupPreferenceKeys)
      if (prefs.get(key) != null) key: prefs.get(key),
  };
}

Future<void> _wipeAllTables(AppDatabase db) async {
  await db.transaction(() async {
    await db.delete(db.rentalNotes).go();
    await db.delete(db.rentalEvents).go();
    await db.delete(db.depositLedger).go();
    await db.delete(db.customerSubscriptions).go();
    await db.delete(db.moneyLoanEntries).go();
    await db.delete(db.moneyLoans).go();
    await db.delete(db.rentalItems).go();
    await db.delete(db.rentals).go();
    await db.delete(db.inventoryItems).go();
    await db.delete(db.customers).go();
    await db.delete(db.appMeta).go();
    await db.delete(db.mediaAttachments).go();
  });
}

void main() {
  group('backup round-trip', () {
    test('export -> wipe -> import restores all tables and preferences',
        () async {
      final LocalRepository repository = await bootRepo(seedDemo: true);
      final AppDatabase db = repository.database;
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // Exercise every preference value type (String + bool + int).
      await prefs.setString(kLocalePrefsKey, 'hi');
      await prefs.setString(kThemeModePrefsKey, 'light');
      await prefs.setString(kPreferredModePrefsKey, 'online');
      await prefs.setString(kOwnerWhatsAppPhoneKey, '9876543210');
      await prefs.setString(kOwnerWhatsAppCountryCodeKey, '91');
      await prefs.setBool(kHomeModulesCustomizedKey, true);
      await prefs.setBool(kRemindersEnabledKey, false);
      await prefs.setInt(kRemindersHourKey, 10);
      await prefs.setInt(kRemindersMinuteKey, 30);
      await prefs.setBool(kRemindersDueTomorrowKey, false);
      await prefs.setBool(kHandoverVerificationEnabledKey, true);
      await prefs.setString(
        kHandoverVerificationMethodKey,
        VerificationMethod.pin.name,
      );
      await prefs.setString(kHandoverPinKey, '4321');
      await prefs.setString(kConditionModeKey, ConditionMode.standard.name);

      await repository.attachMedia(
        'rental',
        'RNT-BACKUP-TEST',
        <int>[1, 2, 3],
      );

      // Sanity: there is data to round-trip.
      final Map<String, Set<Object?>> before = await _tableSnapshot(db);
      expect(before['customers'], isNotEmpty);
      expect(before['rentals'], isNotEmpty);
      expect(before['rentalItems'], isNotEmpty);

      final String json = await repository.exportBackupJson();

      // Snapshot AFTER export so appMeta includes the last-backup timestamp
      // that the export just wrote (it is part of the produced backup).
      final Map<String, Set<Object?>> exported = await _tableSnapshot(db);
      final Map<String, Object?> exportedPrefs = _prefsSnapshot(prefs);

      // Destroy everything, then restore from the backup.
      await _wipeAllTables(db);
      await prefs.clear();
      expect(await db.select(db.customers).get(), isEmpty);

      await repository.importBackupJson(json, replaceExisting: true);

      final Map<String, Set<Object?>> restored = await _tableSnapshot(db);
      final Map<String, Object?> restoredPrefs = _prefsSnapshot(prefs);

      for (final String table in exported.keys) {
        expect(
          restored[table],
          equals(exported[table]),
          reason: 'table "$table" did not round-trip',
        );
      }
      expect(restoredPrefs, equals(exportedPrefs));
      expect(restoredPrefs[kLocalePrefsKey], 'hi');
      expect(restoredPrefs[kThemeModePrefsKey], 'light');
      expect(restoredPrefs[kHomeModulesCustomizedKey], true);
      expect(restoredPrefs[kRemindersEnabledKey], false);
      expect(restoredPrefs[kRemindersHourKey], 10);
      expect(restoredPrefs[kHandoverPinKey], '4321');
      expect(restored['mediaAttachments'], isNotEmpty);
    });

    test('export envelope carries version + schema metadata', () async {
      final LocalRepository repository = await bootRepo(seedDemo: true);
      final Map<String, dynamic> envelope =
          jsonDecode(await repository.exportBackupJson())
              as Map<String, dynamic>;

      expect(envelope['formatVersion'], kBackupFormatVersion);
      expect(envelope['appSchemaVersion'], kSchemaBaselineVersion);
      expect(envelope['tables'], isA<Map<String, dynamic>>());
      expect(
        (envelope['tables'] as Map<String, dynamic>).keys,
        containsAll(<String>[
          'customers',
          'inventoryItems',
          'rentals',
          'rentalItems',
          'rentalEvents',
          'rentalNotes',
          'depositLedger',
          'moneyLoans',
          'moneyLoanEntries',
          'customerSubscriptions',
          'appMeta',
          'mediaAttachments',
        ]),
      );
      expect(envelope['preferences'], isA<Map<String, dynamic>>());
    });

    test('restore rejects an unsupported format version', () async {
      final LocalRepository repository = await bootRepo(seedDemo: true);
      final Map<String, dynamic> envelope =
          jsonDecode(await repository.exportBackupJson())
              as Map<String, dynamic>;
      envelope['formatVersion'] = kBackupFormatVersion + 1;

      expect(
        () => repository.importBackupJson(
          jsonEncode(envelope),
          replaceExisting: true,
        ),
        throwsA(
          isA<BackupRestoreException>().having(
            (BackupRestoreException e) => e.error,
            'error',
            BackupRestoreError.unsupportedFormatVersion,
          ),
        ),
      );
    });

    test('restore rejects a schema newer than this build', () async {
      final LocalRepository repository = await bootRepo(seedDemo: true);
      final Map<String, dynamic> envelope =
          jsonDecode(await repository.exportBackupJson())
              as Map<String, dynamic>;
      envelope['appSchemaVersion'] = kSchemaBaselineVersion + 1;

      expect(
        () => repository.importBackupJson(
          jsonEncode(envelope),
          replaceExisting: true,
        ),
        throwsA(
          isA<BackupRestoreException>().having(
            (BackupRestoreException e) => e.error,
            'error',
            BackupRestoreError.schemaTooNew,
          ),
        ),
      );
    });

    test('restore rejects malformed input', () async {
      final LocalRepository repository = await bootRepo(seedDemo: true);
      expect(
        () => repository.importBackupJson('not json', replaceExisting: true),
        throwsA(
          isA<BackupRestoreException>().having(
            (BackupRestoreException e) => e.error,
            'error',
            BackupRestoreError.invalidFormat,
          ),
        ),
      );
    });
  });
}
