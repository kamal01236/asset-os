import 'local_notifications_models.dart';

Future<void> initLocalNotifications() async {
  NotificationCallLog.record('initLocalNotifications');
}

Future<void> scheduleDailyDigest({
  required int hour,
  required int minute,
  required String title,
  required String body,
}) async {
  NotificationCallLog.record(
    'scheduleDailyDigest:$hour:$minute:$title:$body',
  );
}

Future<void> showImmediate({
  required int id,
  required String title,
  required String body,
  required int overdueCount,
}) async {
  NotificationCallLog.record('showImmediate:$id:$title:$body');
}

Future<void> cancelAll() async {
  NotificationCallLog.record('cancelAll');
}

ReminderDigestPayload? get pendingWebDigest => null;

void clearWebDigest() {}

Future<bool> notificationsPermissionGranted() async => false;

Future<bool> requestNotificationsPermission() async => false;
