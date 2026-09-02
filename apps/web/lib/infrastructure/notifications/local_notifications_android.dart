import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'local_notifications_models.dart';
import 'local_notifications_stub.dart' as stub;

const String _channelId = 'hando_reminders';
const String _channelName = 'Hando reminders';
const String _channelDescription = 'Daily digest and overdue alerts';

const int kDigestNotificationId = 1;
const int kOverduePingNotificationId = 2;

final FlutterLocalNotificationsPlugin _plugin =
    FlutterLocalNotificationsPlugin();

bool _initialized = false;

bool get _isAndroidHost => Platform.isAndroid;

Future<void> initLocalNotifications() async {
  if (!_isAndroidHost) {
    return stub.initLocalNotifications();
  }
  if (_initialized) {
    return;
  }
  tz_data.initializeTimeZones();
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@drawable/ic_notification');
  const InitializationSettings settings = InitializationSettings(
    android: androidSettings,
  );
  await _plugin.initialize(settings);
  final AndroidFlutterLocalNotificationsPlugin? android =
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  await android?.createNotificationChannel(
    const AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.defaultImportance,
    ),
  );
  _initialized = true;
}

AndroidNotificationDetails _androidDetails({
  Importance importance = Importance.defaultImportance,
}) {
  return AndroidNotificationDetails(
    _channelId,
    _channelName,
    channelDescription: _channelDescription,
    importance: importance,
    priority: importance == Importance.high
        ? Priority.high
        : Priority.defaultPriority,
  );
}

tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
  final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
  tz.TZDateTime scheduled = tz.TZDateTime(
    tz.local,
    now.year,
    now.month,
    now.day,
    hour,
    minute,
  );
  if (scheduled.isBefore(now)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }
  return scheduled;
}

Future<void> scheduleDailyDigest({
  required int hour,
  required int minute,
  required String title,
  required String body,
}) async {
  if (!_isAndroidHost) {
    return stub.scheduleDailyDigest(
      hour: hour,
      minute: minute,
      title: title,
      body: body,
    );
  }
  await initLocalNotifications();
  await _plugin.zonedSchedule(
    kDigestNotificationId,
    title,
    body,
    _nextInstanceOfTime(hour, minute),
    NotificationDetails(android: _androidDetails()),
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.time,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
  );
}

Future<void> showImmediate({
  required int id,
  required String title,
  required String body,
  required int overdueCount,
}) async {
  if (!_isAndroidHost) {
    return stub.showImmediate(
      id: id,
      title: title,
      body: body,
      overdueCount: overdueCount,
    );
  }
  await initLocalNotifications();
  await _plugin.show(
    id,
    title,
    body,
    NotificationDetails(
      android: _androidDetails(
        importance: id == kOverduePingNotificationId
            ? Importance.high
            : Importance.defaultImportance,
      ),
    ),
  );
}

Future<void> cancelAll() async {
  if (!_isAndroidHost) {
    return stub.cancelAll();
  }
  await _plugin.cancelAll();
}

ReminderDigestPayload? get pendingWebDigest => stub.pendingWebDigest;

void clearWebDigest() => stub.clearWebDigest();

Future<bool> notificationsPermissionGranted() async {
  if (!_isAndroidHost) {
    return stub.notificationsPermissionGranted();
  }
  final AndroidFlutterLocalNotificationsPlugin? android =
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  final bool? enabled = await android?.areNotificationsEnabled();
  return enabled ?? false;
}

Future<bool> requestNotificationsPermission() async {
  if (!_isAndroidHost) {
    return stub.requestNotificationsPermission();
  }
  final AndroidFlutterLocalNotificationsPlugin? android =
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  final bool? granted = await android?.requestNotificationsPermission();
  return granted ?? false;
}
