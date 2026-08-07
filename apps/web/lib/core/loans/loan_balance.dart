import '../pricing/rental_pricing.dart';
import 'loan_models.dart';

/// Readable timeline row kinds for the loan calculator surface.
enum LoanTimelineKind {
  start,
  /// Full-period interest when no mid-period slices (legacy / simple periods).
  interestSegment,
  /// Mid-period preview: pro-rata interest on a repaid slice (adds at period end).
  deferredSliceInterest,
  /// Mid-period preview: pro-rata interest on added principal → period end.
  deferredAddSliceInterest,
  /// Period-end restatement of interest on one mid-period repayment.
  periodEndSliceInterest,
  /// Period-end restatement of interest on one mid-period disbursement.
  periodEndAddSliceInterest,
  /// Full-period interest on principal outstanding for the whole period.
  remainingPeriodInterest,
  /// Principal after capitalizing period-end interest.
  principalAfterCapitalize,
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
  /// End of accrual window when [at] is the posting date (period end).
  final DateTime? through;
  final int amountPaise;
  final int toInterestPaise;
  final int toPrincipalPaise;
  final String? note;
  final String? entryId;
  /// Principal used when posting interest for a completed period / repaid slice.
  final int? principalBasisPaise;
}

enum _DeferredSliceKind { repayment, disbursement }

class _DeferredSlice {
  const _DeferredSlice({
    required this.kind,
    required this.entryId,
    required this.basisPaise,
    required this.from,
    required this.to,
    required this.interestPaise,
  });

  final _DeferredSliceKind kind;
  final String? entryId;
  final int basisPaise;
  final DateTime from;
  final DateTime to;
  final int interestPaise;
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

/// Pro-rata interest for [principalPaise] from [addedAt] through the rest of
/// the interest period ending at [periodEnd].
int proRataRemainderPeriodInterestPaise({
  required int principalPaise,
  required int rateBps,
  required DateTime periodStart,
  required DateTime addedAt,
  required DateTime periodEnd,
  required MoneyRatePeriod ratePeriod,
}) {
  if (principalPaise <= 0 || rateBps <= 0) {
    return 0;
  }
  final DateTime start = _dateOnly(periodStart);
  final DateTime added = _dateOnly(addedAt);
  final DateTime end = _dateOnly(periodEnd);
  if (!end.isAfter(added)) {
    return 0;
  }
  final double elapsed = periodElapsedFraction(
    periodStart: start,
    at: added,
    periodEnd: end,
    ratePeriod: ratePeriod,
  );
  final double remainder = (1.0 - elapsed).clamp(0.0, 1.0);
  if (remainder <= 0) {
    return 0;
  }
  final double rate = rateBps / 10000.0;
  return (principalPaise * rate * remainder).round();
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

/// Walk chronologically: mid-period repayments reduce principal and defer
/// pro-rata interest on the repaid slice; disbursements increase principal and
/// defer remainder-of-period interest; at each period anniversary, deferred
/// interest plus full-period interest on the core outstanding capitalizes.
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
  int deferredInterest = 0;
  final List<_DeferredSlice> deferredSlices = <_DeferredSlice>[];
  /// Principal added via disbursement in the current incomplete/open period.
  /// Full-period interest excludes this; it is covered by remainder slices.
  int periodDisbursementsPaise = 0;
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

  void accrueRepaidSliceInterest({
    required int principalReduced,
    required DateTime periodStart,
    required DateTime at,
    String? entryId,
  }) {
    if (principalReduced <= 0 || loan.rateBps <= 0) {
      return;
    }
    final int slice = proRataPeriodInterestPaise(
      principalPaise: principalReduced,
      rateBps: loan.rateBps,
      from: periodStart,
      to: at,
      ratePeriod: loan.ratePeriod,
    );
    if (slice <= 0) {
      return;
    }
    deferredInterest += slice;
    deferredSlices.add(
      _DeferredSlice(
        kind: _DeferredSliceKind.repayment,
        entryId: entryId,
        basisPaise: principalReduced,
        from: periodStart,
        to: at,
        interestPaise: slice,
      ),
    );
    interestAccrued += slice;
    timeline.add(
      LoanTimelineEvent(
        kind: LoanTimelineKind.deferredSliceInterest,
        from: periodStart,
        at: at,
        amountPaise: slice,
        principalBasisPaise: principalReduced,
        entryId: entryId,
      ),
    );
  }

  void accrueAddedSliceInterest({
    required int principalAdded,
    required DateTime periodStart,
    required DateTime addedAt,
    required DateTime periodEnd,
    String? entryId,
  }) {
    if (principalAdded <= 0 || loan.rateBps <= 0) {
      return;
    }
    final int slice = proRataRemainderPeriodInterestPaise(
      principalPaise: principalAdded,
      rateBps: loan.rateBps,
      periodStart: periodStart,
      addedAt: addedAt,
      periodEnd: periodEnd,
      ratePeriod: loan.ratePeriod,
    );
    if (slice <= 0) {
      return;
    }
    deferredInterest += slice;
    deferredSlices.add(
      _DeferredSlice(
        kind: _DeferredSliceKind.disbursement,
        entryId: entryId,
        basisPaise: principalAdded,
        from: addedAt,
        to: periodEnd,
        interestPaise: slice,
      ),
    );
    interestAccrued += slice;
    timeline.add(
      LoanTimelineEvent(
        kind: LoanTimelineKind.deferredAddSliceInterest,
        from: addedAt,
        through: periodEnd,
        at: addedAt,
        amountPaise: slice,
        principalBasisPaise: principalAdded,
        entryId: entryId,
      ),
    );
  }

  void applySignedAmount({
    required int amount,
    required MoneyLoanEntryKind kind,
    required DateTime at,
    required String entryId,
    String? note,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) {
    if (kind == MoneyLoanEntryKind.repayment) {
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
      if (periodStart != null && toPrincipal > 0) {
        accrueRepaidSliceInterest(
          principalReduced: toPrincipal,
          periodStart: periodStart,
          at: at,
          entryId: entryId,
        );
      }
      return;
    }

    if (kind == MoneyLoanEntryKind.disbursement) {
      final int add = amount < 0 ? 0 : amount;
      if (add > 0) {
        remainingPrincipal += add;
        if (periodStart != null) {
          periodDisbursementsPaise += add;
        }
      }
      timeline.add(
        LoanTimelineEvent(
          kind: LoanTimelineKind.disbursement,
          at: at,
          amountPaise: add,
          toInterestPaise: 0,
          toPrincipalPaise: add,
          note: note,
          entryId: entryId,
        ),
      );
      if (periodStart != null &&
          periodEnd != null &&
          add > 0) {
        accrueAddedSliceInterest(
          principalAdded: add,
          periodStart: periodStart,
          addedAt: at,
          periodEnd: periodEnd,
          entryId: entryId,
        );
      }
      return;
    }

    // Adjustment: positive reduces principal; negative increases it.
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
      if (periodStart != null && toPrincipal > 0) {
        accrueRepaidSliceInterest(
          principalReduced: toPrincipal,
          periodStart: periodStart,
          at: at,
          entryId: entryId,
        );
      }
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
    // Full-period leg = principal at period start minus repayments (and
    // positive adjustments), floored at 0. Equivalently: remaining principal
    // minus mid-period disbursements (those earn only via remainder slices).
    final int fullPeriodBasis =
        (remainingPrincipal - periodDisbursementsPaise).clamp(0, remainingPrincipal);
    final int remainingInterest =
        fullPeriodBasis > 0 && loan.rateBps > 0
            ? periodInterestPaise(
                principalPaise: fullPeriodBasis,
                kind: loan.interestKind,
                rateBps: loan.rateBps,
              )
            : 0;
    final int total = deferredInterest + remainingInterest;
    if (total <= 0) {
      deferredInterest = 0;
      deferredSlices.clear();
      periodDisbursementsPaise = 0;
      return;
    }
    // Deferred was already counted in interestAccrued at entry time.
    interestAccrued += remainingInterest;

    // Period-end order: repayment slices, then disbursement slices, then
    // full-period core, then principal after capitalize.
    final List<_DeferredSlice> repaySlices = deferredSlices
        .where((s) => s.kind == _DeferredSliceKind.repayment)
        .toList();
    final List<_DeferredSlice> addSlices = deferredSlices
        .where((s) => s.kind == _DeferredSliceKind.disbursement)
        .toList();

    for (final _DeferredSlice slice in repaySlices) {
      timeline.add(
        LoanTimelineEvent(
          kind: LoanTimelineKind.periodEndSliceInterest,
          from: slice.from,
          through: slice.to,
          at: periodEnd,
          amountPaise: slice.interestPaise,
          principalBasisPaise: slice.basisPaise,
          entryId: slice.entryId,
        ),
      );
    }
    for (final _DeferredSlice slice in addSlices) {
      timeline.add(
        LoanTimelineEvent(
          kind: LoanTimelineKind.periodEndAddSliceInterest,
          from: slice.from,
          through: slice.to,
          at: periodEnd,
          amountPaise: slice.interestPaise,
          principalBasisPaise: slice.basisPaise,
          entryId: slice.entryId,
        ),
      );
    }

    if (remainingInterest > 0) {
      timeline.add(
        LoanTimelineEvent(
          kind: LoanTimelineKind.remainingPeriodInterest,
          from: periodStart,
          at: periodEnd,
          amountPaise: remainingInterest,
          principalBasisPaise: fullPeriodBasis,
        ),
      );
    }

    remainingPrincipal += total;
    timeline.add(
      LoanTimelineEvent(
        kind: LoanTimelineKind.principalAfterCapitalize,
        at: periodEnd,
        amountPaise: remainingPrincipal,
      ),
    );
    deferredInterest = 0;
    deferredSlices.clear();
    periodDisbursementsPaise = 0;
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
      // Mid-period entries: repay / add principal + defer pro-rata slices.
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
          periodStart: periodStart,
          periodEnd: periodEnd,
        );
        entryIndex++;
      }

      if (periodEnd.isAfter(asOf)) {
        // Incomplete period: keep deferred slice interest; no full-period
        // interest on remaining principal until the anniversary.
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
        final DateTime nextEnd =
            nextInterestPeriodEnd(periodEnd, loan.ratePeriod);
        applySignedAmount(
          amount: entry.amountPaise,
          kind: entry.kind,
          at: at,
          entryId: entry.id,
          note: entry.note,
          periodStart: periodEnd,
          periodEnd: nextEnd,
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
        periodStart: periodStart,
        periodEnd: periodEnd,
      );
      entryIndex++;
    }
  }

  final int unpaidInterest = deferredInterest;
  final int pending = remainingPrincipal + deferredInterest;
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
