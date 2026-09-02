@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:asset_os/application/local_repository.dart';
import 'package:asset_os/application/privacy/privacy_settings.dart';
import 'package:asset_os/application/providers/app_providers.dart';
import 'package:asset_os/presentation/privacy/privacy_display.dart';

void main() {
  group('PrivacySettings', () {
    test('prefs round-trip all keys', () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      const PrivacySettings settings = PrivacySettings(
        appLockEnabled: true,
        appLockPin: '1234',
        biometricEnabled: true,
        hidePrices: true,
        hidePhoneNumbers: true,
        mediaRetentionDays: 14,
        analyticsDisabled: false,
      );
      await settings.persist(prefs);
      final PrivacySettings loaded = PrivacySettings.fromPreferences(prefs);
      expect(loaded.appLockEnabled, isTrue);
      expect(loaded.appLockPin, '1234');
      expect(loaded.biometricEnabled, isTrue);
      expect(loaded.hidePrices, isTrue);
      expect(loaded.hidePhoneNumbers, isTrue);
      expect(loaded.mediaRetentionDays, 14);
      expect(loaded.analyticsDisabled, isFalse);
    });

    test('backup keys include privacy prefs', () {
      expect(kBackupPreferenceKeys, contains(kAppLockEnabledKey));
      expect(kBackupPreferenceKeys, contains(kAppLockPinKey));
      expect(kBackupPreferenceKeys, contains(kHidePricesKey));
      expect(kBackupPreferenceKeys, contains(kMediaRetentionDaysKey));
    });
  });

  group('privacy_display', () {
    testWidgets('masks money and phone when enabled', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        kHidePricesKey: true,
        kHidePhoneNumbersKey: true,
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (BuildContext context, WidgetRef ref, _) {
                return Text(
                  '${displayMoney(context, ref, 50000)} '
                  '${displayPhone(context, ref, '9876543210')}',
                );
              },
            ),
          ),
        ),
      );

      expect(find.textContaining(kMaskedMoneyDisplay), findsOneWidget);
      expect(find.textContaining('98'), findsOneWidget);
      expect(find.textContaining('9876543210'), findsNothing);
    });

    test('maskPhone partial format', () {
      expect(maskPhone('9876543210'), '98•••••210');
      expect(maskPhone('12'), kMaskedMoneyDisplay);
    });
  });
}
