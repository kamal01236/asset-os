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
  /// Mid-period: pro-rata interest on still-outstanding core through asOf.
  accruedThroughAsOf,
  /// Principal after capitalizing period-end interest (compound).
  principalAfterCapitalize,
  /// Principal unchanged after posting period-end interest due (simple).
  principalRemains,
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

enum _DeferredSliceKind { repayment, disbursement, openPeriod }

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

/// Pro-rata interest within one rate period from [from] to [to].
int proRataWithinPeriodInterestPaise({
  required int principalPaise,
  required int rateBps,
  required DateTime periodStart,
  required DateTime from,
  required DateTime to,
  required DateTime periodEnd,
  required MoneyRatePeriod ratePeriod,
}) {
  if (principalPaise <= 0 || rateBps <= 0) {
    return 0;
  }
  final DateTime start = _dateOnly(periodStart);
  final DateTime begin = _dateOnly(from);
  final DateTime end = _dateOnly(to);
  final DateTime boundary = _dateOnly(periodEnd);
  if (!end.isAfter(begin)) {
    return 0;
  }
  final double elapsedBegin = periodElapsedFraction(
    periodStart: start,
    at: begin,
    periodEnd: boundary,
    ratePeriod: ratePeriod,
  );
  final double elapsedEnd = periodElapsedFraction(
    periodStart: start,
    at: end,
    periodEnd: boundary,
    ratePeriod: ratePeriod,
  );
  final double fraction = (elapsedEnd - elapsedBegin).clamp(0.0, 1.0);
  if (fraction <= 0) {
    return 0;
  }
  final double rate = rateBps / 10000.0;
  return (principalPaise * rate * fraction).round();
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
/// interest plus full-period interest on the core outstanding either capitalizes
/// (compound) or posts as unpaid interest without changing principal (simple).
/// Repayments allocate by [MoneyLoan.prepaymentAllocation]: interest-first
/// clears unpaid/deferred interest then principal; principal-only leaves
/// unpaid interest unchanged.
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

  final bool isSimple = loan.interestKind == MoneyInterestKind.simple;
  int remainingPrincipal = loan.principalPaise < 0 ? 0 : loan.principalPaise;
  /// Interest from completed periods still owed (simple only; compound clears
  /// via capitalization).
  int postedUnpaidInterest = 0;
  /// Mid-period slice interest awaiting the next anniversary.
  int deferredInterest = 0;
  final List<_DeferredSlice> deferredSlices = <_DeferredSlice>[];
  /// Principal added via disbursement in the current incomplete/open period.
  /// Full-period interest excludes this; it is covered by remainder slices.
  int periodDisbursementsPaise = 0;
  int interestAccrued = 0;
  int totalPaid = 0;
  int totalAdjustments = 0;

  int unpaidInterestTotal() => postedUnpaidInterest + deferredInterest;

  void reduceDeferredSlices(int amount) {
    int left = amount;
    while (left > 0 && deferredSlices.isNotEmpty) {
      final _DeferredSlice first = deferredSlices.first;
      if (first.interestPaise <= left) {
        left -= first.interestPaise;
        deferredSlices.removeAt(0);
      } else {
        deferredSlices[0] = _DeferredSlice(
          kind: first.kind,
          entryId: first.entryId,
          basisPaise: first.basisPaise,
          from: first.from,
          to: first.to,
          interestPaise: first.interestPaise - left,
        );
        left = 0;
      }
    }
    deferredInterest = deferredSlices.fold<int>(
      0,
      (int sum, _DeferredSlice s) => sum + s.interestPaise,
    );
  }

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
      int remainingPay = pay;
      int toInterest = 0;
      int toPrincipal = 0;

      if (loan.prepaymentAllocation ==
              MoneyPrepaymentAllocation.interestThenPrincipal &&
          remainingPay > 0 &&
          unpaidInterestTotal() > 0) {
        final int owed = unpaidInterestTotal();
        toInterest = remainingPay > owed ? owed : remainingPay;
        remainingPay -= toInterest;
        // Posted unpaid first, then mid-period deferred slices.
        final int fromPosted =
            toInterest > postedUnpaidInterest ? postedUnpaidInterest : toInterest;
        postedUnpaidInterest -= fromPosted;
        final int fromDeferred = toInterest - fromPosted;
        if (fromDeferred > 0) {
          reduceDeferredSlices(fromDeferred);
        }
      }

      if (remainingPay > 0 && remainingPrincipal > 0) {
        toPrincipal =
            remainingPay > remainingPrincipal ? remainingPrincipal : remainingPay;
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

  /// Cap mid-period add-slices at [asOf] and accrue core outstanding through
  /// today. Does not capitalize — anniversary [postPeriodInterest] still owns
  /// period-end posting.
  void finalizeIncompletePeriodThroughAsOf({
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    if (!asOf.isAfter(periodStart) || loan.rateBps <= 0) {
      return;
    }

    // Cap disbursement deferred slices that were accrued to periodEnd.
    for (int i = deferredSlices.length - 1; i >= 0; i--) {
      final _DeferredSlice slice = deferredSlices[i];
      if (slice.kind != _DeferredSliceKind.disbursement) {
        continue;
      }
      final int capped = proRataWithinPeriodInterestPaise(
        principalPaise: slice.basisPaise,
        rateBps: loan.rateBps,
        periodStart: periodStart,
        from: slice.from,
        to: asOf,
        periodEnd: periodEnd,
        ratePeriod: loan.ratePeriod,
      );
      final int delta = slice.interestPaise - capped;
      if (delta == 0 && !slice.to.isAfter(asOf)) {
        continue;
      }
      deferredInterest -= delta;
      interestAccrued -= delta;
      if (capped <= 0) {
        deferredSlices.removeAt(i);
      } else {
        deferredSlices[i] = _DeferredSlice(
          kind: slice.kind,
          entryId: slice.entryId,
          basisPaise: slice.basisPaise,
          from: slice.from,
          to: asOf,
          interestPaise: capped,
        );
      }
      // Update or drop matching timeline preview rows.
      for (int t = timeline.length - 1; t >= 0; t--) {
        final LoanTimelineEvent ev = timeline[t];
        if (ev.kind != LoanTimelineKind.deferredAddSliceInterest) {
          continue;
        }
        if (slice.entryId != null && ev.entryId != slice.entryId) {
          continue;
        }
        if (capped <= 0) {
          timeline.removeAt(t);
        } else {
          timeline[t] = LoanTimelineEvent(
            kind: ev.kind,
            from: ev.from,
            through: asOf,
            at: ev.at,
            amountPaise: capped,
            principalBasisPaise: ev.principalBasisPaise,
            entryId: ev.entryId,
          );
        }
        break;
      }
    }

    final int corePrincipal =
        (remainingPrincipal - periodDisbursementsPaise).clamp(0, remainingPrincipal);
    final int coreInterest = proRataPeriodInterestPaise(
      principalPaise: corePrincipal,
      rateBps: loan.rateBps,
      from: periodStart,
      to: asOf,
      ratePeriod: loan.ratePeriod,
    );
    if (coreInterest <= 0) {
      return;
    }
    deferredInterest += coreInterest;
    deferredSlices.add(
      _DeferredSlice(
        kind: _DeferredSliceKind.openPeriod,
        entryId: null,
        basisPaise: corePrincipal,
        from: periodStart,
        to: asOf,
        interestPaise: coreInterest,
      ),
    );
    interestAccrued += coreInterest;
    timeline.add(
      LoanTimelineEvent(
        kind: LoanTimelineKind.accruedThroughAsOf,
        from: periodStart,
        through: asOf,
        at: asOf,
        amountPaise: coreInterest,
        principalBasisPaise: corePrincipal,
      ),
    );
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
    final int periodInterestTotal = deferredInterest + remainingInterest;
    if (periodInterestTotal <= 0) {
      deferredInterest = 0;
      deferredSlices.clear();
      periodDisbursementsPaise = 0;
      return;
    }
    // Deferred was already counted in interestAccrued at entry time.
    interestAccrued += remainingInterest;

    // Period-end order: repayment slices, then disbursement slices, then
    // full-period core, then principal after capitalize / remains.
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

    if (isSimple) {
      postedUnpaidInterest += periodInterestTotal;
      timeline.add(
        LoanTimelineEvent(
          kind: LoanTimelineKind.principalRemains,
          at: periodEnd,
          amountPaise: remainingPrincipal,
        ),
      );
    } else {
      remainingPrincipal += periodInterestTotal;
      timeline.add(
        LoanTimelineEvent(
          kind: LoanTimelineKind.principalAfterCapitalize,
          at: periodEnd,
          amountPaise: remainingPrincipal,
        ),
      );
    }
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
        // Incomplete period: include pro-rata interest through asOf on
        // outstanding core (and cap add-slices at asOf). Do not capitalize.
        finalizeIncompletePeriodThroughAsOf(
          periodStart: periodStart,
          periodEnd: periodEnd,
        );
        break;
      }

      postPeriodInterest(periodStart: periodStart, periodEnd: periodEnd);

      // Same-day boundary entries apply after interest posts / capitalizes.
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

  final int unpaidInterest = unpaidInterestTotal();
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
