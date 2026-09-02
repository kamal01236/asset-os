import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/app_providers.dart';
import '../../application/reminders/reminder_settings.dart';
import '../../infrastructure/l10n/l10n_ext.dart';
import '../../infrastructure/notifications/local_notifications.dart';
import '../theme/app_theme.dart';

/// Web-only digest banner (non-blocking); hidden when empty or dismissed.
class ReminderDigestBanner extends ConsumerStatefulWidget {
  const ReminderDigestBanner({
    required this.onView,
    super.key,
  });

  final VoidCallback onView;

  @override
  ConsumerState<ReminderDigestBanner> createState() =>
      _ReminderDigestBannerState();
}

class _ReminderDigestBannerState extends ConsumerState<ReminderDigestBanner> {
  bool _dismissed = false;

  Future<void> _dismissForToday() async {
    setState(() => _dismissed = true);
    clearWebDigest();
    final String todayKey = _dateKey(DateTime.now());
    await ref.read(repositoryProvider).setAppMetaValue(
          kReminderLastDigestDateMetaKey,
          todayKey,
        );
  }

  static String _dateKey(DateTime dateTime) {
    return '${dateTime.year}-'
        '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) {
      return const SizedBox.shrink();
    }
    final ReminderDigestPayload? payload = pendingWebDigest;
    if (payload == null || payload.isEmpty) {
      return const SizedBox.shrink();
    }

    final AppLocalizations l10n = context.l10n;
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color accent = payload.overdueCount > 0
        ? AppTheme.overdue
        : AppTheme.dueToday;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      color: accent.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.notifications_active_outlined, color: accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    payload.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    payload.body,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: <Widget>[
                      TextButton(
                        onPressed: widget.onView,
                        child: Text(l10n.reminderDigestBannerAction),
                      ),
                      TextButton(
                        onPressed: () => _dismissForToday(),
                        child: Text(l10n.reminderDigestBannerDismiss),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
