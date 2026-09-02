import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/app_providers.dart';
import '../../../application/reminders/reminder_scheduler.dart';
import '../../../application/reminders/reminder_settings.dart';
import '../../../domain/config/app_branding.dart';
import '../../../infrastructure/l10n/l10n_ext.dart';
import '../../../infrastructure/notifications/local_notifications.dart';

/// More → Reminders settings (enable, schedule, per-kind toggles).
class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  bool _permissionGranted = true;
  bool _checkingPermission = true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPermission());
  }

  Future<void> _loadPermission() async {
    if (kIsWeb) {
      setState(() {
        _permissionGranted = true;
        _checkingPermission = false;
      });
      return;
    }
    final bool granted = await notificationsPermissionGranted();
    if (!mounted) {
      return;
    }
    setState(() {
      _permissionGranted = granted;
      _checkingPermission = false;
    });
  }

  Future<void> _refreshScheduler(ReminderSettings settings) async {
    final ReminderScheduler scheduler =
        ReminderScheduler(ref.read(repositoryProvider));
    await scheduler.refreshScheduledReminders(
      settings: settings,
      l10n: context.l10n,
    );
  }

  Future<void> _persist(ReminderSettings settings, {bool snack = false}) async {
    await ref.read(reminderSettingsProvider.notifier).update(settings);
    await _refreshScheduler(settings);
    if (!mounted || !snack) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.remindersSaved)),
    );
  }

  Future<void> _pickTime(ReminderSettings settings) async {
    final TimeOfDay initial = TimeOfDay(hour: settings.hour, minute: settings.minute);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null || !mounted) {
      return;
    }
    await _persist(
      settings.copyWith(hour: picked.hour, minute: picked.minute),
      snack: true,
    );
  }

  Future<void> _requestPermission() async {
    final AppLocalizations l10n = context.l10n;
    final bool granted = await requestNotificationsPermission();
    if (!mounted) {
      return;
    }
    setState(() => _permissionGranted = granted);
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.remindersPermissionDenied)),
      );
    }
  }

  String _formatTime(ReminderSettings settings) {
    final TimeOfDay time = TimeOfDay(hour: settings.hour, minute: settings.minute);
    return time.format(context);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ReminderSettings settings = ref.watch(reminderSettingsProvider);
    final bool showAndroidPermission =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.remindersTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            l10n.remindersSubtitle(kAppDisplayName),
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Card(
            child: SwitchListTile(
              title: Text(l10n.remindersEnabledLabel),
              subtitle: Text(l10n.remindersEnabledHelp),
              value: settings.enabled,
              onChanged: (bool value) {
                unawaited(_persist(settings.copyWith(enabled: value), snack: true));
              },
            ),
          ),
          if (settings.enabled) ...<Widget>[
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                title: Text(l10n.remindersTimeLabel),
                subtitle: Text(_formatTime(settings)),
                trailing: const Icon(Icons.schedule_outlined),
                onTap: () => unawaited(_pickTime(settings)),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: <Widget>[
                  SwitchListTile(
                    title: Text(l10n.remindersDueTomorrowLabel),
                    value: settings.dueTomorrow,
                    onChanged: (bool value) => unawaited(
                      _persist(settings.copyWith(dueTomorrow: value)),
                    ),
                  ),
                  SwitchListTile(
                    title: Text(l10n.remindersDueTodayLabel),
                    value: settings.dueToday,
                    onChanged: (bool value) => unawaited(
                      _persist(settings.copyWith(dueToday: value)),
                    ),
                  ),
                  SwitchListTile(
                    title: Text(l10n.remindersOverdueLabel),
                    value: settings.overdue,
                    onChanged: (bool value) => unawaited(
                      _persist(settings.copyWith(overdue: value)),
                    ),
                  ),
                  SwitchListTile(
                    title: Text(l10n.remindersLowStockLabel),
                    value: settings.lowStock,
                    onChanged: (bool value) => unawaited(
                      _persist(settings.copyWith(lowStock: value)),
                    ),
                  ),
                  SwitchListTile(
                    title: Text(l10n.remindersLoansDueLabel),
                    value: settings.loansDue,
                    onChanged: (bool value) => unawaited(
                      _persist(settings.copyWith(loansDue: value)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.remindersLowStockThresholdLabel,
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.remindersLowStockThresholdHelp,
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        IconButton(
                          onPressed: settings.lowStockThreshold > 0
                              ? () => unawaited(
                                    _persist(
                                      settings.copyWith(
                                        lowStockThreshold:
                                            settings.lowStockThreshold - 1,
                                      ),
                                    ),
                                  )
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          '${settings.lowStockThreshold}',
                          style: textTheme.titleLarge,
                        ),
                        IconButton(
                          onPressed: settings.lowStockThreshold < 5
                              ? () => unawaited(
                                    _persist(
                                      settings.copyWith(
                                        lowStockThreshold:
                                            settings.lowStockThreshold + 1,
                                      ),
                                    ),
                                  )
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (showAndroidPermission &&
              settings.enabled &&
              !_checkingPermission &&
              !_permissionGranted) ...<Widget>[
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.remindersPermissionTitle,
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.remindersPermissionBody,
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: () => unawaited(_requestPermission()),
                      icon: const Icon(Icons.notifications_active_outlined),
                      label: Text(l10n.remindersPermissionAction),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
