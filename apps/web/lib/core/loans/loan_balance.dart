import '../pricing/rental_pricing.dart';
import 'capitalization_policy.dart';
import 'loan_models.dart';

/// Readable timeline row kinds for the loan calculator surface.
enum LoanTimelineKind {
  /// Signed interest accrued between two consecutive timeline points.
  interestSegment,
  /// Unpaid interest merged into principal / balance.
  interestCapitalized,
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

enum _WalkKind {
  cash,
  scheduledBoundary,
  closure,
}

class _WalkPoint {
  const _WalkPoint({
    required this.at,
    required this.walkKind,
    this.entryKind,
    this.amountPaise = 0,
    this.isSyntheticPrincipal = false,
    this.entryId,
    this.note,
  });

  final DateTime at;
  final _WalkKind walkKind;
  final MoneyLoanEntryKind? entryKind;
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
    MoneyRatePeriod.daily => start.add(const Duration(days: 1)),
    MoneyRatePeriod.monthly => addCalendarMonths(start, 1),
    MoneyRatePeriod.yearly => addCalendarMonths(start, 12),
  };
}

/// Next capitalization cycle anniversary after [from].
DateTime nextCapitalizationCycleEnd(
  DateTime from,
  MoneyCapitalizationCycle cycle,
) {
  final DateTime start = _dateOnly(from);
  return switch (cycle) {
    MoneyCapitalizationCycle.monthly => addCalendarMonths(start, 1),
    MoneyCapitalizationCycle.quarterly => addCalendarMonths(start, 3),
    MoneyCapitalizationCycle.yearly => addCalendarMonths(start, 12),
  };
}

/// Fraction of one interest period elapsed from [periodStart] to [at].
///
/// Yearly: calendar months / 12 (6 months → 0.5). Partial first month falls
/// back to days / year length. Monthly: days / days-in-period.
/// Daily: days / 1 within the day period.
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
    case MoneyRatePeriod.daily:
      final int periodDays = calendarDaysBetween(start, boundary);
      final int elapsed = calendarDaysBetween(start, end);
      if (periodDays <= 0) {
        return 0.0;
      }
      return (elapsed / periodDays).clamp(0.0, 1.0);
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
/// Daily uses calendar days / 365. Yearly uses whole calendar months / 12.
/// Monthly walks month boundaries from [from].
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
    case MoneyRatePeriod.daily:
      return calendarDaysBetween(start, end) / 365.0;
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

int _sign(int value) {
  if (value > 0) {
    return 1;
  }
  if (value < 0) {
    return -1;
  }
  return 0;
}

/// Tentative outstanding after applying [point] without capitalization.
int _outstandingAfterCash({
  required LedgerState state,
  required _WalkPoint point,
  required MoneyPrepaymentAllocation allocation,
}) {
  int balance = state.balance;
  int unpaid = state.unpaidInterest;
  final MoneyLoanEntryKind? kind = point.entryKind;
  if (kind == MoneyLoanEntryKind.repayment) {
    final int pay = point.amountPaise < 0 ? 0 : point.amountPaise;
    int remainingPay = pay;
    if (allocation == MoneyPrepaymentAllocation.interestThenPrincipal &&
        remainingPay > 0 &&
        unpaid > 0) {
      final int toInterest =
          remainingPay > unpaid ? unpaid : remainingPay;
      remainingPay -= toInterest;
      unpaid -= toInterest;
    }
    if (remainingPay > 0) {
      balance -= remainingPay;
    }
  } else if (kind == MoneyLoanEntryKind.disbursement) {
    final int add = point.amountPaise < 0 ? 0 : point.amountPaise;
    balance += add;
  } else if (kind == MoneyLoanEntryKind.adjustment) {
    balance -= point.amountPaise;
  }
  return balance + unpaid;
}

/// Event-driven signed ledger: synthetic principal disbursement at
/// [MoneyLoan.interestStartedAt], plus all dated entries (including before
/// start). Interest always accrues into unpaid; capitalization follows the
/// loan's [MoneyCapitalizationPolicy].
LoanScenario computeLoanScenario({
  required MoneyLoan loan,
  DateTime? now,
  List<MoneyLoanEntry>? entriesOverride,
}) {
  final DateTime clock = now ?? DateTime.now();
  final DateTime asOf = resolveLoanAsOf(loan: loan, now: clock);
  final DateTime start = _dateOnly(loan.interestStartedAt);
  final InterestCapitalizationPolicy policy = capitalizationPolicyFor(loan);

  final List<_WalkPoint> points = <_WalkPoint>[
    _WalkPoint(
      at: start,
      walkKind: _WalkKind.cash,
      entryKind: MoneyLoanEntryKind.disbursement,
      amountPaise: loan.principalPaise < 0 ? 0 : loan.principalPaise,
      isSyntheticPrincipal: true,
    ),
  ];

  for (final MoneyLoanEntry entry in entriesOverride ?? loan.entries) {
    points.add(
      _WalkPoint(
        at: _dateOnly(entry.entryAt),
        walkKind: _WalkKind.cash,
        entryKind: entry.kind,
        amountPaise: entry.amountPaise,
        entryId: entry.id,
        note: entry.note,
      ),
    );
  }

  if (loan.capitalizationPolicy ==
      MoneyCapitalizationPolicy.onScheduledCycle) {
    DateTime boundary =
        nextCapitalizationCycleEnd(start, loan.capitalizationCycle);
    int guard = 0;
    while (!boundary.isAfter(asOf) && guard < 12000) {
      guard++;
      points.add(
        _WalkPoint(
          at: boundary,
          walkKind: _WalkKind.scheduledBoundary,
        ),
      );
      boundary =
          nextCapitalizationCycleEnd(boundary, loan.capitalizationCycle);
    }
  }

  if (loan.capitalizationPolicy == MoneyCapitalizationPolicy.onLoanClosure &&
      loan.status == MoneyLoanStatus.closed &&
      loan.closedAt != null) {
    final DateTime closed = _dateOnly(loan.closedAt!);
    if (!closed.isAfter(asOf)) {
      points.add(
        _WalkPoint(
          at: closed,
          walkKind: _WalkKind.closure,
        ),
      );
    }
  }

  points.sort((_WalkPoint a, _WalkPoint b) {
    final int byDate = a.at.compareTo(b.at);
    if (byDate != 0) {
      return byDate;
    }
    // Same day: scheduled/closure before cash; synthetic principal first.
    int rank(_WalkPoint p) {
      if (p.isSyntheticPrincipal) {
        return 0;
      }
      if (p.walkKind == _WalkKind.scheduledBoundary) {
        return 1;
      }
      if (p.walkKind == _WalkKind.closure) {
        return 2;
      }
      if (p.entryKind == MoneyLoanEntryKind.capitalization) {
        return 3;
      }
      return 4;
    }

    final int byRank = rank(a).compareTo(rank(b));
    if (byRank != 0) {
      return byRank;
    }
    return (a.entryId ?? '').compareTo(b.entryId ?? '');
  });

  final LedgerState state = LedgerState();
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
    if (state.balance != 0 && loan.rateBps > 0) {
      final int interest = signedInterestPaise(
        balancePaise: state.balance,
        rateBps: loan.rateBps,
        from: from,
        to: to,
        ratePeriod: loan.ratePeriod,
      );
      if (interest != 0) {
        interestAccrued += interest;
        state.unpaidInterest += interest;
        timeline.add(
          LoanTimelineEvent(
            kind: LoanTimelineKind.interestSegment,
            from: from,
            through: to,
            at: to,
            amountPaise: interest,
            principalBasisPaise: state.balance,
          ),
        );
      }
    }
    cursor = to;
  }

  void maybeCapitalize(LedgerHook hook, DateTime at) {
    if (state.unpaidInterest == 0) {
      return;
    }
    if (!policy.shouldCapitalize(
      loan: loan,
      state: state,
      hook: hook,
    )) {
      return;
    }
    final int amount = state.unpaidInterest;
    state.balance += amount;
    state.unpaidInterest = 0;
    timeline.add(
      LoanTimelineEvent(
        kind: LoanTimelineKind.interestCapitalized,
        at: at,
        amountPaise: amount,
      ),
    );
  }

  void applyCash(_WalkPoint point) {
    final MoneyLoanEntryKind kind = point.entryKind!;
    if (kind == MoneyLoanEntryKind.capitalization) {
      maybeCapitalize(LedgerHook.manualEntry, point.at);
      return;
    }

    if (kind == MoneyLoanEntryKind.repayment) {
      maybeCapitalize(LedgerHook.beforePayment, point.at);
      if (loan.capitalizationPolicy ==
          MoneyCapitalizationPolicy.onBalanceDirectionChange) {
        final int before = state.outstanding;
        final int after = _outstandingAfterCash(
          state: state,
          point: point,
          allocation: loan.prepaymentAllocation,
        );
        if (before != 0 && after != 0 && _sign(before) != _sign(after)) {
          maybeCapitalize(LedgerHook.beforeSignFlip, point.at);
        }
      }

      final int pay = point.amountPaise < 0 ? 0 : point.amountPaise;
      totalPaid += pay;
      int remainingPay = pay;
      int toInterest = 0;
      int toPrincipal = 0;

      if (loan.prepaymentAllocation ==
              MoneyPrepaymentAllocation.interestThenPrincipal &&
          remainingPay > 0 &&
          state.unpaidInterest > 0) {
        toInterest = remainingPay > state.unpaidInterest
            ? state.unpaidInterest
            : remainingPay;
        remainingPay -= toInterest;
        state.unpaidInterest -= toInterest;
      }

      if (remainingPay > 0) {
        toPrincipal = remainingPay;
        state.balance -= toPrincipal;
      }

      timeline.add(
        LoanTimelineEvent(
          kind: LoanTimelineKind.payment,
          at: point.at,
          amountPaise: pay,
          toInterestPaise: toInterest,
          toPrincipalPaise: toPrincipal,
          note: point.note,
          entryId: point.entryId,
        ),
      );
      return;
    }

    if (kind == MoneyLoanEntryKind.disbursement) {
      if (loan.capitalizationPolicy ==
          MoneyCapitalizationPolicy.onBalanceDirectionChange) {
        final int before = state.outstanding;
        final int after = _outstandingAfterCash(
          state: state,
          point: point,
          allocation: loan.prepaymentAllocation,
        );
        if (before != 0 && after != 0 && _sign(before) != _sign(after)) {
          maybeCapitalize(LedgerHook.beforeSignFlip, point.at);
        }
      }
      final int add = point.amountPaise < 0 ? 0 : point.amountPaise;
      state.balance += add;
      timeline.add(
        LoanTimelineEvent(
          kind: LoanTimelineKind.disbursement,
          at: point.at,
          amountPaise: add,
          toInterestPaise: 0,
          toPrincipalPaise: add,
          note: point.note,
          entryId: point.entryId,
        ),
      );
      return;
    }

    // Adjustment: positive reduces balance; negative increases it.
    if (loan.capitalizationPolicy ==
        MoneyCapitalizationPolicy.onBalanceDirectionChange) {
      final int before = state.outstanding;
      final int after = _outstandingAfterCash(
        state: state,
        point: point,
        allocation: loan.prepaymentAllocation,
      );
      if (before != 0 && after != 0 && _sign(before) != _sign(after)) {
        maybeCapitalize(LedgerHook.beforeSignFlip, point.at);
      }
    }
    totalAdjustments += point.amountPaise;
    state.balance -= point.amountPaise;
    timeline.add(
      LoanTimelineEvent(
        kind: LoanTimelineKind.adjustment,
        at: point.at,
        amountPaise: point.amountPaise,
        toInterestPaise: 0,
        toPrincipalPaise: point.amountPaise,
        note: point.note,
        entryId: point.entryId,
      ),
    );
  }

  for (final _WalkPoint point in points) {
    if (point.at.isAfter(asOf)) {
      break;
    }
    accrueTo(point.at);
    switch (point.walkKind) {
      case _WalkKind.scheduledBoundary:
        maybeCapitalize(LedgerHook.scheduledBoundary, point.at);
      case _WalkKind.closure:
        maybeCapitalize(LedgerHook.atClosure, point.at);
      case _WalkKind.cash:
        applyCash(point);
    }
  }
  accrueTo(asOf);
  if (loan.capitalizationPolicy == MoneyCapitalizationPolicy.onLoanClosure &&
      loan.status == MoneyLoanStatus.closed) {
    maybeCapitalize(LedgerHook.atClosure, asOf);
  }

  final int pending = state.outstanding;
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
    remainingPrincipalPaise: state.balance,
    unpaidInterestPaise: state.unpaidInterest,
    asOf: asOf,
    timeline: timeline,
  );
}
