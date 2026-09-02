import 'local_notifications_models.dart';

ReminderDigestPayload? _pendingWebDigest;

Future<void> initLocalNotifications() async {}

Future<void> scheduleDailyDigest({
  required int hour,
  required int minute,
  required String title,
  required String body,
}) async {}

Future<void> showImmediate({
  required int id,
  required String title,
  required String body,
  required int overdueCount,
}) async {
  if (body.trim().isEmpty) {
    return;
  }
  _pendingWebDigest = ReminderDigestPayload(
    title: title,
    body: body,
    overdueCount: overdueCount,
  );
}

Future<void> cancelAll() async {
  _pendingWebDigest = null;
}

ReminderDigestPayload? get pendingWebDigest => _pendingWebDigest;

void clearWebDigest() {
  _pendingWebDigest = null;
}

Future<bool> notificationsPermissionGranted() async => true;

Future<bool> requestNotificationsPermission() async => true;
