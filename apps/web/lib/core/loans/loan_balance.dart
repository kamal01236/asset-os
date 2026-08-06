import 'dart:math' as math;

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
  /// Principal used when accruing an interest segment.
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

/// Accrue interest on [principalPaise] from [from] to [to] (date-only).
int accrueInterestPaise({
  required int principalPaise,
  required DateTime from,
  required DateTime to,
  required MoneyInterestKind kind,
  required int rateBps,
  required MoneyRatePeriod ratePeriod,
}) {
  final DateTime start = _dateOnly(from);
  final DateTime end = _dateOnly(to);
  final int days = calendarDaysBetween(start, end);
  if (principalPaise <= 0 || days <= 0 || rateBps <= 0) {
    return 0;
  }

  final double rate = rateBps / 10000.0;
  final double periods = switch (ratePeriod) {
    MoneyRatePeriod.monthly => days / 30.0,
    MoneyRatePeriod.yearly => days / 365.0,
  };

  if (kind == MoneyInterestKind.simple) {
    return (principalPaise * rate * periods).round();
  }
  return (principalPaise * (math.pow(1 + rate, periods) - 1)).round();
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

/// Walk chronologically: accrue to each entry, apply interest-first, then as-of.
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
  int unpaidInterest = 0;
  int interestAccrued = 0;
  int totalPaid = 0;
  int totalAdjustments = 0;
  DateTime cursor = start;

  final List<LoanTimelineEvent> timeline = <LoanTimelineEvent>[
    LoanTimelineEvent(
      kind: LoanTimelineKind.start,
      at: start,
      amountPaise: loan.principalPaise,
    ),
  ];

  void accrueTo(DateTime eventDate) {
    final DateTime target = _dateOnly(eventDate);
    if (!target.isAfter(cursor) || remainingPrincipal <= 0) {
      cursor = target.isBefore(cursor) ? cursor : target;
      return;
    }
    final int interest = accrueInterestPaise(
      principalPaise: remainingPrincipal,
      from: cursor,
      to: target,
      kind: loan.interestKind,
      rateBps: loan.rateBps,
      ratePeriod: loan.ratePeriod,
    );
    if (interest > 0) {
      unpaidInterest += interest;
      interestAccrued += interest;
      timeline.add(
        LoanTimelineEvent(
          kind: LoanTimelineKind.interestSegment,
          from: cursor,
          at: target,
          amountPaise: interest,
          principalBasisPaise: remainingPrincipal,
        ),
      );
    }
    cursor = target;
  }

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
      int remaining = pay;
      int toInterest = 0;
      int toPrincipal = 0;
      if (remaining > 0 && unpaidInterest > 0) {
        toInterest = remaining > unpaidInterest ? unpaidInterest : remaining;
        unpaidInterest -= toInterest;
        remaining -= toInterest;
      }
      if (remaining > 0 && remainingPrincipal > 0) {
        toPrincipal =
            remaining > remainingPrincipal ? remainingPrincipal : remaining;
        remainingPrincipal -= toPrincipal;
      }
      timeline.add(
        LoanTimelineEvent(
          kind: LoanTimelineKind.payment,
          at: at,
          amountPaise: pay,
          toInterestPaise: toInterest,
          toPrincipalPaise: toPrincipal,
          note: note,
          entryId: entryId,
        ),
      );
      return;
    }

    // Adjustment: positive reduces outstanding (interest then principal);
    // negative increases remaining principal.
    totalAdjustments += amount;
    if (amount > 0) {
      int remaining = amount;
      int toInterest = 0;
      int toPrincipal = 0;
      if (remaining > 0 && unpaidInterest > 0) {
        toInterest = remaining > unpaidInterest ? unpaidInterest : remaining;
        unpaidInterest -= toInterest;
        remaining -= toInterest;
      }
      if (remaining > 0 && remainingPrincipal > 0) {
        toPrincipal =
            remaining > remainingPrincipal ? remainingPrincipal : remaining;
        remainingPrincipal -= toPrincipal;
      }
      timeline.add(
        LoanTimelineEvent(
          kind: LoanTimelineKind.adjustment,
          at: at,
          amountPaise: amount,
          toInterestPaise: toInterest,
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

  for (final MoneyLoanEntry entry in entries) {
    final DateTime at = _dateOnly(entry.entryAt);
    // Skip entries before start for accrual cursor; still show application.
    if (at.isBefore(start)) {
      applySignedAmount(
        amount: entry.amountPaise,
        kind: entry.kind,
        at: at,
        entryId: entry.id,
        note: entry.note,
      );
      continue;
    }
    accrueTo(at);
    applySignedAmount(
      amount: entry.amountPaise,
      kind: entry.kind,
      at: at,
      entryId: entry.id,
      note: entry.note,
    );
  }

  if (!asOf.isBefore(start)) {
    accrueTo(asOf);
  }

  final int pending = remainingPrincipal + unpaidInterest;
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
