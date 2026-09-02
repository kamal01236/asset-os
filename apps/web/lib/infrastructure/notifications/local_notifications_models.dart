/// Payload surfaced on web for the in-app digest banner.
class ReminderDigestPayload {
  const ReminderDigestPayload({
    required this.title,
    required this.body,
    required this.overdueCount,
  });

  final String title;
  final String body;
  final int overdueCount;

  bool get isEmpty => body.trim().isEmpty;
}

/// Test hook: records notification backend calls in VM/tests.
class NotificationCallLog {
  static final List<String> calls = <String>[];

  static void reset() => calls.clear();

  static void record(String call) => calls.add(call);
}
