import 'local_notifications_models.dart';
import 'local_notifications_stub.dart'
    if (dart.library.js_interop) 'local_notifications_web.dart'
    if (dart.library.io) 'local_notifications_android.dart' as impl;

export 'local_notifications_models.dart';

Future<void> initLocalNotifications() => impl.initLocalNotifications();

Future<void> scheduleDailyDigest({
  required int hour,
  required int minute,
  required String title,
  required String body,
}) {
  return impl.scheduleDailyDigest(
    hour: hour,
    minute: minute,
    title: title,
    body: body,
  );
}

Future<void> showImmediate({
  required int id,
  required String title,
  required String body,
  required int overdueCount,
}) {
  return impl.showImmediate(
    id: id,
    title: title,
    body: body,
    overdueCount: overdueCount,
  );
}

Future<void> cancelAll() => impl.cancelAll();

ReminderDigestPayload? get pendingWebDigest => impl.pendingWebDigest;

void clearWebDigest() => impl.clearWebDigest();

Future<bool> notificationsPermissionGranted() =>
    impl.notificationsPermissionGranted();

Future<bool> requestNotificationsPermission() =>
    impl.requestNotificationsPermission();

/// Stable ids for scheduled notifications (Android).
const int kDigestNotificationId = 1;
const int kOverduePingNotificationId = 2;
