import '../pricing/rental_pricing.dart';
import 'loan_models.dart';

/// Readable timeline row kinds for the loan calculator surface.
enum LoanTimelineKind {
  /// Signed interest accrued between two consecutive timeline points.
  interestSegment,
  payment,
  disbursement,
  adjustment,
  pendingAsOf,
}

/// One plain-language calculator timeline row.
class LoanTimelineEvent {
  const LoanTimelineEvent({
    required this.kind,
    required this.at,
    required this.amountPaise,
    this.from,
    this.through,
    this.toInterestPaise = 0,
    this.toPrincipalPaise = 0,
    this.note,
    this.entryId,
    this.principalBasisPaise,
  });

  final LoanTimelineKind kind;
  final DateTime at;
  final DateTime? from;
  /// End of the accrual window for [interestSegment] rows.
  final DateTime? through;
  final int amountPaise;
  final int toInterestPaise;
  final int toPrincipalPaise;
  final String? note;
  final String? entryId;
  /// Signed balance used as the interest basis for a segment.
  final int? principalBasisPaise;
}

class _LedgerEvent {
  const _LedgerEvent({
    required this.at,
    required this.kind,
    required this.amountPaise,
    required this.isSyntheticPrincipal,
    this.entryId,
    this.note,
  });

  final DateTime at;
  final MoneyLoanEntryKind kind;
  final int amountPaise;
  final bool isSyntheticPrincipal;
  final String? entryId;
  final String? note;
}

/// Current scenario snapshot produced by [computeLoanScenario].
///
/// [pendingPaise], [remainingPrincipalPaise], and [unpaidInterestPaise] are
/// signed. Negative balance / unpaid means reverse interest (overpay credit).
class LoanScenario {
  const LoanScenario({
    required this.principalPaise,
    required this.interestAccruedPaise,
    required this.totalPaidPaise,
    required this.totalAdjustmentsPaise,
    required this.pendingPaise,
    required this.remainingPrincipalPaise,
    required this.unpaidInterestPaise,
    required this.asOf,
    required this.timeline,
  });

  final int principalPaise;
  final int interestAccruedPaise;
  final int totalPaidPaise;
  /// Net adjustments (positive = forgiveness / credit).
  final int totalAdjustmentsPaise;
  final int pendingPaise;
  final int remainingPrincipalPaise;
  final int unpaidInterestPaise;
  final DateTime asOf;
  final List<LoanTimelineEvent> timeline;
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// Next period anniversary after [from] for [ratePeriod].
DateTime nextInterestPeriodEnd(DateTime from, MoneyRatePeriod ratePeriod) {
  final DateTime start = _dateOnly(from);
  return switch (ratePeriod) {
    MoneyRatePeriod.monthly => addCalendarMonths(start, 1),
    MoneyRatePeriod.yearly => addCalendarMonths(start, 12),
  };
}

/// Fraction of one interest period elapsed from [periodStart] to [at].
///
/// Yearly: calendar months / 12 (6 months → 0.5). Partial first month falls
/// back to days / year length. Monthly: days / days-in-period.
double periodElapsedFraction({
  required DateTime periodStart,
  required DateTime at,
  required DateTime periodEnd,
  required MoneyRatePeriod ratePeriod,
}) {
  final DateTime start = _dateOnly(periodStart);
  final DateTime end = _dateOnly(at);
  final DateTime boundary = _dateOnly(periodEnd);
  if (!end.isAfter(start)) {
    return 0.0;
  }
  switch (ratePeriod) {
    case MoneyRatePeriod.yearly:
      int months =
          (end.year - start.year) * 12 + (end.month - start.month);
      if (end.day < start.day) {
        months -= 1;
      }
      if (months <= 0) {
        final int yearDays = calendarDaysBetween(start, boundary);
        final int elapsed = calendarDaysBetween(start, end);
        if (yearDays <= 0) {
          return 0.0;
        }
        return (elapsed / yearDays).clamp(0.0, 1.0);
      }
      return (months / 12.0).clamp(0.0, 1.0);
    case MoneyRatePeriod.monthly:
      final int periodDays = calendarDaysBetween(start, boundary);
      final int elapsed = calendarDaysBetween(start, end);
      if (periodDays <= 0) {
        return 0.0;
      }
      return (elapsed / periodDays).clamp(0.0, 1.0);
  }
}

/// Accrual fraction of rate periods between arbitrary [from] and [to].
///
/// Yearly uses whole calendar months / 12 (partial month before the first
/// whole month uses days / year length). Monthly walks month boundaries from
/// [from], summing days / days-in-period for each segment.
double accrualFraction({
  required DateTime from,
  required DateTime to,
  required MoneyRatePeriod ratePeriod,
}) {
  final DateTime start = _dateOnly(from);
  final DateTime end = _dateOnly(to);
  if (!end.isAfter(start)) {
    return 0.0;
  }
  switch (ratePeriod) {
    case MoneyRatePeriod.yearly:
      int months =
          (end.year - start.year) * 12 + (end.month - start.month);
      if (end.day < start.day) {
        months -= 1;
      }
      if (months <= 0) {
        final DateTime yearEnd =
            nextInterestPeriodEnd(start, MoneyRatePeriod.yearly);
        final int yearDays = calendarDaysBetween(start, yearEnd);
        final int elapsed = calendarDaysBetween(start, end);
        if (yearDays <= 0) {
          return 0.0;
        }
        return elapsed / yearDays;
      }
      return months / 12.0;
    case MoneyRatePeriod.monthly:
      double fraction = 0.0;
      DateTime cursor = start;
      int guard = 0;
      while (cursor.isBefore(end) && guard < 12000) {
        guard++;
        final DateTime periodEnd =
            nextInterestPeriodEnd(cursor, MoneyRatePeriod.monthly);
        final DateTime segmentEnd =
            end.isBefore(periodEnd) ? end : periodEnd;
        final int periodDays = calendarDaysBetween(cursor, periodEnd);
        final int elapsed = calendarDaysBetween(cursor, segmentEnd);
        if (periodDays > 0 && elapsed > 0) {
          fraction += elapsed / periodDays;
        }
        cursor = periodEnd;
      }
      return fraction;
  }
}

/// Pro-rata interest for [principalPaise] from [from] to [to] within one
/// rate period that begins at [from].
int proRataPeriodInterestPaise({
  required int principalPaise,
  required int rateBps,
  required DateTime from,
  required DateTime to,
  required MoneyRatePeriod ratePeriod,
}) {
  if (principalPaise <= 0 || rateBps <= 0) {
    return 0;
  }
  final DateTime start = _dateOnly(from);
  final DateTime end = _dateOnly(to);
  if (!end.isAfter(start)) {
    return 0;
  }
  final DateTime periodEnd = nextInterestPeriodEnd(start, ratePeriod);
  final double fraction = periodElapsedFraction(
    periodStart: start,
    at: end,
    periodEnd: periodEnd,
    ratePeriod: ratePeriod,
  );
  if (fraction <= 0) {
    return 0;
  }
  final double rate = rateBps / 10000.0;
  return (principalPaise * rate * fraction).round();
}

/// Signed interest on [balancePaise] from [from] to [to].
///
/// Zero balance accrues nothing. Negative balance yields reverse interest.
int signedInterestPaise({
  required int balancePaise,
  required int rateBps,
  required DateTime from,
  required DateTime to,
  required MoneyRatePeriod ratePeriod,
}) {
  if (balancePaise == 0 || rateBps <= 0) {
    return 0;
  }
  final double fraction = accrualFraction(
    from: from,
    to: to,
    ratePeriod: ratePeriod,
  );
  if (fraction == 0) {
    return 0;
  }
  final double rate = rateBps / 10000.0;
  return (balancePaise * rate * fraction).round();
}

/// Interest for one completed period on [principalPaise] at [rateBps].
int periodInterestPaise({
  required int principalPaise,
  required MoneyInterestKind kind,
  required int rateBps,
}) {
  if (principalPaise <= 0 || rateBps <= 0) {
    return 0;
  }
  final double rate = rateBps / 10000.0;
  // One period: simple P*r and compound P*((1+r)-1) are the same.
  switch (kind) {
    case MoneyInterestKind.simple:
    case MoneyInterestKind.compound:
      return (principalPaise * rate).round();
  }
}

/// Cap as-of for accrual: closed loans use closedAt; optional end caps earlier.
DateTime resolveLoanAsOf({
  required MoneyLoan loan,
  required DateTime now,
}) {
  DateTime asOf = _dateOnly(now);
  if (loan.status == MoneyLoanStatus.closed && loan.closedAt != null) {
    final DateTime closed = _dateOnly(loan.closedAt!);
    if (closed.isBefore(asOf)) {
      asOf = closed;
    }
  }
  final DateTime? ended = loan.interestEndedAt;
  if (ended != null) {
    final DateTime end = _dateOnly(ended);
    if (end.isBefore(asOf)) {
      asOf = end;
    }
  }
  return asOf;
}

/// Event-driven signed ledger: synthetic principal disbursement at
/// [MoneyLoan.interestStartedAt], plus all dated entries (including before
/// start). Interest accrues only between consecutive timeline points from the
/// signed outstanding balance. Simple keeps signed unpaid interest; compound
/// capitalizes into the balance between events. Overpay may go negative and
/// earn reverse interest.
LoanScenario computeLoanScenario({
  required MoneyLoan loan,
  DateTime? now,
  List<MoneyLoanEntry>? entriesOverride,
}) {
  final DateTime clock = now ?? DateTime.now();
  final DateTime asOf = resolveLoanAsOf(loan: loan, now: clock);
  final DateTime start = _dateOnly(loan.interestStartedAt);
  final bool isSimple = loan.interestKind == MoneyInterestKind.simple;

  final List<_LedgerEvent> events = <_LedgerEvent>[
    _LedgerEvent(
      at: start,
      kind: MoneyLoanEntryKind.disbursement,
      amountPaise: loan.principalPaise < 0 ? 0 : loan.principalPaise,
      isSyntheticPrincipal: true,
      entryId: null,
    ),
  ];

  for (final MoneyLoanEntry entry in entriesOverride ?? loan.entries) {
    events.add(
      _LedgerEvent(
        at: _dateOnly(entry.entryAt),
        kind: entry.kind,
        amountPaise: entry.amountPaise,
        isSyntheticPrincipal: false,
        entryId: entry.id,
        note: entry.note,
      ),
    );
  }

  events.sort((_LedgerEvent a, _LedgerEvent b) {
    final int byDate = a.at.compareTo(b.at);
    if (byDate != 0) {
      return byDate;
    }
    if (a.isSyntheticPrincipal != b.isSyntheticPrincipal) {
      return a.isSyntheticPrincipal ? -1 : 1;
    }
    return (a.entryId ?? '').compareTo(b.entryId ?? '');
  });

  int balance = 0;
  int unpaidInterest = 0;
  int interestAccrued = 0;
  int totalPaid = 0;
  int totalAdjustments = 0;
  DateTime? cursor;
  final List<LoanTimelineEvent> timeline = <LoanTimelineEvent>[];

  void accrueTo(DateTime to) {
    if (cursor == null) {
      cursor = to;
      return;
    }
    if (!to.isAfter(cursor!)) {
      return;
    }
    final DateTime from = cursor!;
    if (balance != 0 && loan.rateBps > 0) {
      final int interest = signedInterestPaise(
        balancePaise: balance,
        rateBps: loan.rateBps,
        from: from,
        to: to,
        ratePeriod: loan.ratePeriod,
      );
      if (interest != 0) {
        interestAccrued += interest;
        timeline.add(
          LoanTimelineEvent(
            kind: LoanTimelineKind.interestSegment,
            from: from,
            through: to,
            at: to,
            amountPaise: interest,
            principalBasisPaise: balance,
          ),
        );
        if (isSimple) {
          unpaidInterest += interest;
        } else {
          balance += interest;
        }
      }
    }
    cursor = to;
  }

  void applyEvent(_LedgerEvent event) {
    if (event.kind == MoneyLoanEntryKind.repayment) {
      final int pay = event.amountPaise < 0 ? 0 : event.amountPaise;
      totalPaid += pay;
      int remainingPay = pay;
      int toInterest = 0;
      int toPrincipal = 0;

      if (loan.prepaymentAllocation ==
              MoneyPrepaymentAllocation.interestThenPrincipal &&
          remainingPay > 0 &&
          unpaidInterest > 0) {
        toInterest =
            remainingPay > unpaidInterest ? unpaidInterest : remainingPay;
        remainingPay -= toInterest;
        unpaidInterest -= toInterest;
      }

      if (remainingPay > 0) {
        toPrincipal = remainingPay;
        balance -= toPrincipal;
        remainingPay = 0;
      }

      timeline.add(
        LoanTimelineEvent(
          kind: LoanTimelineKind.payment,
          at: event.at,
          amountPaise: pay,
          toInterestPaise: toInterest,
          toPrincipalPaise: toPrincipal,
          note: event.note,
          entryId: event.entryId,
        ),
      );
      return;
    }

    if (event.kind == MoneyLoanEntryKind.disbursement) {
      final int add = event.amountPaise < 0 ? 0 : event.amountPaise;
      balance += add;
      timeline.add(
        LoanTimelineEvent(
          kind: LoanTimelineKind.disbursement,
          at: event.at,
          amountPaise: add,
          toInterestPaise: 0,
          toPrincipalPaise: add,
          note: event.note,
          entryId: event.entryId,
        ),
      );
      return;
    }

    // Adjustment: positive reduces balance; negative increases it.
    totalAdjustments += event.amountPaise;
    balance -= event.amountPaise;
    timeline.add(
      LoanTimelineEvent(
        kind: LoanTimelineKind.adjustment,
        at: event.at,
        amountPaise: event.amountPaise,
        toInterestPaise: 0,
        toPrincipalPaise: event.amountPaise,
        note: event.note,
        entryId: event.entryId,
      ),
    );
  }

  for (final _LedgerEvent event in events) {
    if (event.at.isAfter(asOf)) {
      break;
    }
    accrueTo(event.at);
    applyEvent(event);
  }
  accrueTo(asOf);

  final int pending = balance + unpaidInterest;
  timeline.add(
    LoanTimelineEvent(
      kind: LoanTimelineKind.pendingAsOf,
      at: asOf,
      amountPaise: pending,
    ),
  );

  return LoanScenario(
    principalPaise: loan.principalPaise,
    interestAccruedPaise: interestAccrued,
    totalPaidPaise: totalPaid,
    totalAdjustmentsPaise: totalAdjustments,
    pendingPaise: pending,
    remainingPrincipalPaise: balance,
    unpaidInterestPaise: unpaidInterest,
    asOf: asOf,
    timeline: timeline,
  );
}
