import '../pricing/rental_pricing.dart';
import 'loan_models.dart';

/// Readable timeline row kinds for the loan calculator surface.
enum LoanTimelineKind {
  start,
  interestSegment,
  payment,
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
    this.toInterestPaise = 0,
    this.toPrincipalPaise = 0,
    this.note,
    this.entryId,
    this.principalBasisPaise,
  });

  final LoanTimelineKind kind;
  final DateTime at;
  final DateTime? from;
  final int amountPaise;
  final int toInterestPaise;
  final int toPrincipalPaise;
  final String? note;
  final String? entryId;
  /// Principal used when posting interest for a completed period.
  final int? principalBasisPaise;
}

/// Current scenario snapshot produced by [computeLoanScenario].
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

/// Interest for one completed period on [principalPaise] at [rateBps].
///
/// Simple and compound are identical for a single period (`P * r`). Multi-period
/// compound growth comes from capitalizing each completed period in
/// [computeLoanScenario].
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
  // Multi-period compound growth comes from capitalizing each period.
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

/// Walk chronologically: mid-period payments reduce principal only; interest
/// posts only at completed period boundaries and capitalizes into principal.
LoanScenario computeLoanScenario({
  required MoneyLoan loan,
  DateTime? now,
  List<MoneyLoanEntry>? entriesOverride,
}) {
  final DateTime clock = now ?? DateTime.now();
  final DateTime asOf = resolveLoanAsOf(loan: loan, now: clock);
  final DateTime start = _dateOnly(loan.interestStartedAt);
  final List<MoneyLoanEntry> entries = List<MoneyLoanEntry>.from(
    entriesOverride ?? loan.entries,
  )..sort((MoneyLoanEntry a, MoneyLoanEntry b) {
      final int byDate = _dateOnly(a.entryAt).compareTo(_dateOnly(b.entryAt));
      if (byDate != 0) {
        return byDate;
      }
      return a.id.compareTo(b.id);
    });

  int remainingPrincipal = loan.principalPaise < 0 ? 0 : loan.principalPaise;
  int interestAccrued = 0;
  int totalPaid = 0;
  int totalAdjustments = 0;

  final List<LoanTimelineEvent> timeline = <LoanTimelineEvent>[
    LoanTimelineEvent(
      kind: LoanTimelineKind.start,
      at: start,
      amountPaise: loan.principalPaise,
    ),
  ];

  void applySignedAmount({
    required int amount,
    required MoneyLoanEntryKind kind,
    required DateTime at,
    required String entryId,
    String? note,
  }) {
    if (kind == MoneyLoanEntryKind.payment) {
      final int pay = amount < 0 ? 0 : amount;
      totalPaid += pay;
      int toPrincipal = 0;
      if (pay > 0 && remainingPrincipal > 0) {
        toPrincipal = pay > remainingPrincipal ? remainingPrincipal : pay;
        remainingPrincipal -= toPrincipal;
      }
      timeline.add(
        LoanTimelineEvent(
          kind: LoanTimelineKind.payment,
          at: at,
          amountPaise: pay,
          toInterestPaise: 0,
          toPrincipalPaise: toPrincipal,
          note: note,
          entryId: entryId,
        ),
      );
      return;
    }

    // Adjustment: positive reduces principal; negative increases it.
    // No separate unpaid interest mid-period (capitalized immediately at posts).
    totalAdjustments += amount;
    if (amount > 0) {
      int toPrincipal = 0;
      if (remainingPrincipal > 0) {
        toPrincipal =
            amount > remainingPrincipal ? remainingPrincipal : amount;
        remainingPrincipal -= toPrincipal;
      }
      timeline.add(
        LoanTimelineEvent(
          kind: LoanTimelineKind.adjustment,
          at: at,
          amountPaise: amount,
          toInterestPaise: 0,
          toPrincipalPaise: toPrincipal,
          note: note,
          entryId: entryId,
        ),
      );
    } else if (amount < 0) {
      remainingPrincipal += -amount;
      timeline.add(
        LoanTimelineEvent(
          kind: LoanTimelineKind.adjustment,
          at: at,
          amountPaise: amount,
          toPrincipalPaise: amount,
          note: note,
          entryId: entryId,
        ),
      );
    } else {
      timeline.add(
        LoanTimelineEvent(
          kind: LoanTimelineKind.adjustment,
          at: at,
          amountPaise: 0,
          note: note,
          entryId: entryId,
        ),
      );
    }
  }

  void postPeriodInterest({
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    if (remainingPrincipal <= 0 || loan.rateBps <= 0) {
      return;
    }
    final int interest = periodInterestPaise(
      principalPaise: remainingPrincipal,
      kind: loan.interestKind,
      rateBps: loan.rateBps,
    );
    if (interest <= 0) {
      return;
    }
    interestAccrued += interest;
    timeline.add(
      LoanTimelineEvent(
        kind: LoanTimelineKind.interestSegment,
        from: periodStart,
        at: periodEnd,
        amountPaise: interest,
        principalBasisPaise: remainingPrincipal,
      ),
    );
    // Capitalize immediately so pending stays principal-only.
    remainingPrincipal += interest;
  }

  int entryIndex = 0;

  // Entries dated before interest start: apply to principal, no interest yet.
  while (entryIndex < entries.length) {
    final MoneyLoanEntry entry = entries[entryIndex];
    final DateTime at = _dateOnly(entry.entryAt);
    if (!at.isBefore(start)) {
      break;
    }
    applySignedAmount(
      amount: entry.amountPaise,
      kind: entry.kind,
      at: at,
      entryId: entry.id,
      note: entry.note,
    );
    entryIndex++;
  }

  if (!asOf.isBefore(start)) {
    DateTime periodStart = start;
    DateTime periodEnd = nextInterestPeriodEnd(periodStart, loan.ratePeriod);

    while (true) {
      // Mid-period (and pre-boundary) entries: principal only.
      while (entryIndex < entries.length) {
        final MoneyLoanEntry entry = entries[entryIndex];
        final DateTime at = _dateOnly(entry.entryAt);
        if (at.isAfter(asOf) || !at.isBefore(periodEnd)) {
          break;
        }
        applySignedAmount(
          amount: entry.amountPaise,
          kind: entry.kind,
          at: at,
          entryId: entry.id,
          note: entry.note,
        );
        entryIndex++;
      }

      if (periodEnd.isAfter(asOf)) {
        // Incomplete period: no fractional interest; apply remaining ≤ asOf.
        break;
      }

      postPeriodInterest(periodStart: periodStart, periodEnd: periodEnd);

      // Same-day boundary entries apply after interest capitalizes.
      while (entryIndex < entries.length) {
        final MoneyLoanEntry entry = entries[entryIndex];
        final DateTime at = _dateOnly(entry.entryAt);
        if (at.isAfter(asOf) || at.isAfter(periodEnd)) {
          break;
        }
        if (at.isBefore(periodEnd)) {
          break;
        }
        applySignedAmount(
          amount: entry.amountPaise,
          kind: entry.kind,
          at: at,
          entryId: entry.id,
          note: entry.note,
        );
        entryIndex++;
      }

      periodStart = periodEnd;
      periodEnd = nextInterestPeriodEnd(periodStart, loan.ratePeriod);
    }

    while (entryIndex < entries.length) {
      final MoneyLoanEntry entry = entries[entryIndex];
      final DateTime at = _dateOnly(entry.entryAt);
      if (at.isAfter(asOf)) {
        break;
      }
      applySignedAmount(
        amount: entry.amountPaise,
        kind: entry.kind,
        at: at,
        entryId: entry.id,
        note: entry.note,
      );
      entryIndex++;
    }
  }

  // Pending is principal only (interest already capitalized when posted).
  const int unpaidInterest = 0;
  final int pending = remainingPrincipal;
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
    remainingPrincipalPaise: remainingPrincipal,
    unpaidInterestPaise: unpaidInterest,
    asOf: asOf,
    timeline: timeline,
  );
}
