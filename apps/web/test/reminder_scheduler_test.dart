@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:asset_os/application/reminders/reminder_scheduler.dart';
import 'package:asset_os/application/reminders/reminder_settings.dart';
import 'package:asset_os/infrastructure/notifications/local_notifications_models.dart';
import 'package:asset_os/l10n/app_localizations_en.dart';

import 'support/test_harness.dart';

void main() {
  final AppLocalizationsEn l10n = AppLocalizationsEn();

  group('nextDigestScheduleTime', () {
    test('returns same-day time when still ahead', () {
      final DateTime from = DateTime(2026, 3, 10, 8, 30);
      final DateTime next = nextDigestScheduleTime(hour: 9, minute: 0, from: from);
      expect(next, DateTime(2026, 3, 10, 9, 0));
    });

    test('rolls to tomorrow after configured time', () {
      final DateTime from = DateTime(2026, 3, 10, 10, 0);
      final DateTime next = nextDigestScheduleTime(hour: 9, minute: 0, from: from);
      expect(next, DateTime(2026, 3, 11, 9, 0));
    });
  });

  group('ReminderScheduler', () {
    setUp(NotificationCallLog.reset);

    test('disabled settings cancel all notifications', () async {
      final repository = await bootRepo(seedDemo: true);
      const ReminderSettings settings = ReminderSettings(
        enabled: false,
        hour: 9,
        minute: 0,
        dueTomorrow: true,
        dueToday: true,
        overdue: true,
        lowStock: true,
        loansDue: true,
        lowStockThreshold: 0,
      );
      await ReminderScheduler(repository).refreshScheduledReminders(
        settings: settings,
        l10n: l10n,
      );
      expect(NotificationCallLog.calls, contains('cancelAll'));
    });

    test('enabled settings schedule daily digest at configured time', () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      final repository = await bootRepo(seedDemo: true);
      const ReminderSettings settings = ReminderSettings(
        enabled: true,
        hour: 9,
        minute: 0,
        dueTomorrow: true,
        dueToday: true,
        overdue: true,
        lowStock: true,
        loansDue: true,
        lowStockThreshold: 0,
      );
      await ReminderScheduler(repository).refreshScheduledReminders(
        settings: settings,
        l10n: l10n,
        asOf: DateTime(2026, 3, 10, 8),
      );
      expect(
        NotificationCallLog.calls.any(
          (String call) => call.startsWith('scheduleDailyDigest:9:0:'),
        ),
        isTrue,
      );
    });
  });
}
