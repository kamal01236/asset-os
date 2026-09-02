import 'package:flutter/foundation.dart';

import '../../domain/reminders/reminder_evaluator.dart';
import '../../domain/reminders/reminder_models.dart';
import '../../infrastructure/notifications/local_notifications.dart';
import '../../l10n/app_localizations.dart';
import '../local_repository.dart';
import 'reminder_settings.dart';

/// Opportunistic local reminder scheduling (Android) and web digest surfacing.
class ReminderScheduler {
  ReminderScheduler(this._repository);

  final LocalRepository _repository;

  Future<void> refreshScheduledReminders({
    required ReminderSettings settings,
    required AppLocalizations l10n,
    DateTime? asOf,
  }) async {
    if (!settings.enabled) {
      await cancelAll();
      return;
    }

    final DateTime now = asOf ?? DateTime.now();
    final String todayKey = _dateKey(now);
    final List<ReminderCandidate> candidates =
        await _repository.listReminderCandidates(asOf: now, settings: settings);
    final String body = buildDigestSummary(candidates, l10n);
    final String title = l10n.reminderDigestTitle;
    final int overdueCount = candidates
        .where((ReminderCandidate c) => c.kind == ReminderKind.overdue)
        .length;

    if (kIsWeb) {
      final String? lastDigest =
          await _repository.appMetaValue(kReminderLastDigestDateMetaKey);
      if (lastDigest == todayKey || body.isEmpty) {
        return;
      }
      await showImmediate(
        id: kOverduePingNotificationId,
        title: title,
        body: body,
        overdueCount: overdueCount,
      );
      await _repository.setAppMetaValue(
        kReminderLastDigestDateMetaKey,
        todayKey,
      );
      return;
    }

    if (body.isEmpty) {
      await cancelAll();
      return;
    }

    await scheduleDailyDigest(
      hour: settings.hour,
      minute: settings.minute,
      title: title,
      body: body,
    );

    if (overdueCount > 0) {
      final String? lastPing =
          await _repository.appMetaValue(kReminderLastOverduePingMetaKey);
      if (lastPing != todayKey) {
        await showImmediate(
          id: kOverduePingNotificationId,
          title: l10n.reminderOverduePingTitle,
          body: l10n.reminderOverduePingBody(overdueCount),
          overdueCount: overdueCount,
        );
        await _repository.setAppMetaValue(
          kReminderLastOverduePingMetaKey,
          todayKey,
        );
      }
    }
  }

  static String _dateKey(DateTime dateTime) {
    return '${dateTime.year}-'
        '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')}';
  }
}

/// Next local occurrence of [hour]:[minute] on or after [from].
DateTime nextDigestScheduleTime({
  required int hour,
  required int minute,
  required DateTime from,
}) {
  final DateTime candidate = DateTime(
    from.year,
    from.month,
    from.day,
    hour,
    minute,
  );
  if (!candidate.isBefore(from)) {
    return candidate;
  }
  return candidate.add(const Duration(days: 1));
}
