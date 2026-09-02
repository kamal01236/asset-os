import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/reminders/reminder_evaluator.dart';

const String kRemindersEnabledKey = 'asset_os_reminders_enabled';
const String kRemindersHourKey = 'asset_os_reminders_hour';
const String kRemindersMinuteKey = 'asset_os_reminders_minute';
const String kRemindersDueTomorrowKey = 'asset_os_reminders_due_tomorrow';
const String kRemindersDueTodayKey = 'asset_os_reminders_due_today';
const String kRemindersOverdueKey = 'asset_os_reminders_overdue';
const String kRemindersLowStockKey = 'asset_os_reminders_low_stock';
const String kRemindersLoansDueKey = 'asset_os_reminders_loans_due';
const String kLowStockThresholdKey = 'asset_os_low_stock_threshold';

/// AppMeta keys for reminder dedupe (see [ReminderScheduler]).
const String kReminderLastDigestDateMetaKey = 'reminder_last_digest_date';
const String kReminderLastOverduePingMetaKey = 'reminder_last_overdue_ping';

class ReminderSettings {
  const ReminderSettings({
    required this.enabled,
    required this.hour,
    required this.minute,
    required this.dueTomorrow,
    required this.dueToday,
    required this.overdue,
    required this.lowStock,
    required this.loansDue,
    required this.lowStockThreshold,
  });

  final bool enabled;
  final int hour;
  final int minute;
  final bool dueTomorrow;
  final bool dueToday;
  final bool overdue;
  final bool lowStock;
  final bool loansDue;
  final int lowStockThreshold;

  ReminderSettingsFilter get filter => ReminderSettingsFilter(
        dueTomorrow: dueTomorrow,
        dueToday: dueToday,
        overdue: overdue,
        lowStock: lowStock,
        loansDue: loansDue,
      );

  ReminderSettings copyWith({
    bool? enabled,
    int? hour,
    int? minute,
    bool? dueTomorrow,
    bool? dueToday,
    bool? overdue,
    bool? lowStock,
    bool? loansDue,
    int? lowStockThreshold,
  }) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      dueTomorrow: dueTomorrow ?? this.dueTomorrow,
      dueToday: dueToday ?? this.dueToday,
      overdue: overdue ?? this.overdue,
      lowStock: lowStock ?? this.lowStock,
      loansDue: loansDue ?? this.loansDue,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
    );
  }

  static ReminderSettings fromPreferences(SharedPreferences preferences) {
    return ReminderSettings(
      enabled: preferences.getBool(kRemindersEnabledKey) ?? true,
      hour: preferences.getInt(kRemindersHourKey) ?? 9,
      minute: preferences.getInt(kRemindersMinuteKey) ?? 0,
      dueTomorrow: preferences.getBool(kRemindersDueTomorrowKey) ?? true,
      dueToday: preferences.getBool(kRemindersDueTodayKey) ?? true,
      overdue: preferences.getBool(kRemindersOverdueKey) ?? true,
      lowStock: preferences.getBool(kRemindersLowStockKey) ?? true,
      loansDue: preferences.getBool(kRemindersLoansDueKey) ?? true,
      lowStockThreshold: preferences.getInt(kLowStockThresholdKey) ?? 0,
    );
  }

  Future<void> persist(SharedPreferences preferences) async {
    await preferences.setBool(kRemindersEnabledKey, enabled);
    await preferences.setInt(kRemindersHourKey, hour);
    await preferences.setInt(kRemindersMinuteKey, minute);
    await preferences.setBool(kRemindersDueTomorrowKey, dueTomorrow);
    await preferences.setBool(kRemindersDueTodayKey, dueToday);
    await preferences.setBool(kRemindersOverdueKey, overdue);
    await preferences.setBool(kRemindersLowStockKey, lowStock);
    await preferences.setBool(kRemindersLoansDueKey, loansDue);
    await preferences.setInt(kLowStockThresholdKey, lowStockThreshold);
  }
}
