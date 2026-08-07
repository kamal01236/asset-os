/// Report type for share-to-self WhatsApp summaries.
enum ReportType {
  summary,
  customerWise,
  inventoryWise,
  unitOccupancy,
}

/// Period presets for report date ranges.
enum ReportPeriod {
  daily,
  weekly,
  monthly,
  custom,
}

/// Inclusive local date range for filtering rentals.
class ReportDateRange {
  const ReportDateRange({
    required this.start,
    required this.end,
  });

  final DateTime start;
  final DateTime end;

  /// Resolve presets; [customStart]/[customEnd] used when [period] is custom.
  /// End is inclusive through end-of-day when a calendar date is chosen.
  factory ReportDateRange.resolve({
    required ReportPeriod period,
    required DateTime now,
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    final DateTime clock = now;
    switch (period) {
      case ReportPeriod.daily:
        final DateTime start = DateTime(clock.year, clock.month, clock.day);
        return ReportDateRange(start: start, end: clock);
      case ReportPeriod.weekly:
        return ReportDateRange(
          start: clock.subtract(const Duration(days: 7)),
          end: clock,
        );
      case ReportPeriod.monthly:
        final DateTime start = DateTime(clock.year, clock.month, 1);
        return ReportDateRange(start: start, end: clock);
      case ReportPeriod.custom:
        final DateTime rawStart = customStart ?? DateTime(clock.year, clock.month, clock.day);
        final DateTime rawEnd = customEnd ?? clock;
        final DateTime start = DateTime(rawStart.year, rawStart.month, rawStart.day);
        final DateTime end = DateTime(
          rawEnd.year,
          rawEnd.month,
          rawEnd.day,
          23,
          59,
          59,
          999,
        );
        if (end.isBefore(start)) {
          return ReportDateRange(start: end, end: start);
        }
        return ReportDateRange(start: start, end: end);
    }
  }
}
