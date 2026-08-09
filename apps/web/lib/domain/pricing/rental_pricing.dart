/// Billing modes for inventory rental charges (stored as lowercase names).
enum BillingMode {
  daily,
  weekly,
  monthly,
  fixed,
  custom;

  static BillingMode parse(String? raw) {
    if (raw == null || raw.isEmpty) {
      return BillingMode.weekly;
    }
    for (final BillingMode mode in BillingMode.values) {
      if (mode.name == raw) {
        return mode;
      }
    }
    return BillingMode.weekly;
  }
}

/// Whole calendar days from [start] date to [end] date (time-of-day ignored).
int calendarDaysBetween(DateTime start, DateTime end) {
  final DateTime s = DateTime(start.year, start.month, start.day);
  final DateTime e = DateTime(end.year, end.month, end.day);
  return e.difference(s).inDays;
}

DateTime addCalendarMonths(DateTime start, int months) {
  final int totalMonths = start.month - 1 + months;
  final int year = start.year + totalMonths ~/ 12;
  final int month = totalMonths % 12 + 1;
  final int lastDay = DateTime(year, month + 1, 0).day;
  final int day = start.day > lastDay ? lastDay : start.day;
  return DateTime(
    year,
    month,
    day,
    start.hour,
    start.minute,
    start.second,
    start.millisecond,
    start.microsecond,
  );
}

/// Due date from checkout start + duration (or [customEnd] for custom mode).
DateTime computeDueAt({
  required DateTime start,
  required BillingMode mode,
  required int durationUnits,
  DateTime? customEnd,
}) {
  final int units = durationUnits < 1 ? 1 : durationUnits;
  switch (mode) {
    case BillingMode.daily:
      return start.add(Duration(days: units));
    case BillingMode.weekly:
      return start.add(Duration(days: units * 7));
    case BillingMode.monthly:
      return addCalendarMonths(start, units);
    case BillingMode.fixed:
      // Flat charge; [durationUnits] still sets expected return (days).
      return start.add(Duration(days: units));
    case BillingMode.custom:
      if (customEnd == null) {
        throw ArgumentError('customEnd is required for custom billing');
      }
      if (customEnd.isBefore(start)) {
        throw ArgumentError('customEnd must be on or after start');
      }
      return customEnd;
  }
}

/// Number of billable periods for [mode] over [start]..[due] (min 1).
int computePeriods({
  required BillingMode mode,
  required DateTime start,
  required DateTime due,
}) {
  final int days = calendarDaysBetween(start, due);
  switch (mode) {
    case BillingMode.fixed:
      return 1;
    case BillingMode.daily:
    case BillingMode.custom:
      return days < 1 ? 1 : days;
    case BillingMode.weekly:
      if (days < 1) {
        return 1;
      }
      return (days + 6) ~/ 7;
    case BillingMode.monthly:
      return _monthsSpanned(start, due);
  }
}

int _monthsSpanned(DateTime start, DateTime due) {
  int months = (due.year - start.year) * 12 + (due.month - start.month);
  if (due.day > start.day) {
    months += 1;
  }
  return months < 1 ? 1 : months;
}

/// Base charge in paise for one line (or rental-level rate).
int computeBaseAmount({
  required BillingMode mode,
  required int rateAmount,
  required DateTime start,
  required DateTime due,
}) {
  if (rateAmount <= 0) {
    return 0;
  }
  final int periods = computePeriods(mode: mode, start: start, due: due);
  return rateAmount * periods;
}

/// Overdue fee in paise: [lateFeePerDay] × whole days after due (0 if not overdue).
int computeLateAmount({
  required DateTime due,
  required DateTime asOf,
  required int lateFeePerDay,
}) {
  if (lateFeePerDay <= 0) {
    return 0;
  }
  final int overdueDays = calendarDaysBetween(due, asOf);
  if (overdueDays <= 0) {
    return 0;
  }
  return lateFeePerDay * overdueDays;
}

int computeTotalAmount({required int baseAmount, required int lateAmount}) {
  return baseAmount + lateAmount;
}

/// Format paise as display money (INR → ₹).
String formatMoney(int paise, {String currencyCode = 'INR'}) {
  final bool negative = paise < 0;
  final int abs = paise.abs();
  final int major = abs ~/ 100;
  final int minor = abs % 100;
  final String body = minor == 0
      ? '$major'
      : '$major.${minor.toString().padLeft(2, '0')}';
  final String signed = negative ? '-$body' : body;
  switch (currencyCode.toUpperCase()) {
    case 'INR':
      return '₹$signed';
    default:
      return '$currencyCode $signed';
  }
}

/// Parse a rupees field ("50", "50.5", "50.50") into paise. Empty → 0.
int parseRupeesToPaise(String raw) {
  final String trimmed = raw.trim().replaceAll(',', '');
  if (trimmed.isEmpty) {
    return 0;
  }
  final double? value = double.tryParse(trimmed);
  if (value == null || value.isNaN || value.isInfinite) {
    return 0;
  }
  return (value * 100).round();
}

/// Display paise as a rupees edit field value.
String paiseToRupeesField(int paise) {
  if (paise % 100 == 0) {
    return '${paise ~/ 100}';
  }
  return (paise / 100).toStringAsFixed(2);
}
