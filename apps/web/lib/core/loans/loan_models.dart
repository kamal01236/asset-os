/// Cash-loan direction relative to the business.
enum MoneyLoanDirection {
  given,
  taken;

  static MoneyLoanDirection parse(String? raw) {
    if (raw == MoneyLoanDirection.taken.name) {
      return MoneyLoanDirection.taken;
    }
    return MoneyLoanDirection.given;
  }
}

/// Legacy interest mode. Prefer [MoneyCapitalizationPolicy].
///
/// Kept for one release: [simple] maps to [MoneyCapitalizationPolicy.never],
/// [compound] maps to [MoneyCapitalizationPolicy.onScheduledCycle].
enum MoneyInterestKind {
  simple,
  compound;

  static MoneyInterestKind parse(String? raw) {
    if (raw == MoneyInterestKind.compound.name) {
      return MoneyInterestKind.compound;
    }
    return MoneyInterestKind.simple;
  }
}

/// Interest rate period (rate applies per this unit).
///
/// Legacy stored `daily` migrates to [yearly] with [MoneyInterestAccrual.daily365].
enum MoneyRatePeriod {
  monthly,
  yearly;

  static MoneyRatePeriod parse(String? raw) {
    if (raw == MoneyRatePeriod.yearly.name || raw == 'daily') {
      return MoneyRatePeriod.yearly;
    }
    return MoneyRatePeriod.monthly;
  }
}

/// How elapsed time is converted into a rate-period fraction.
///
/// [calendar] uses monthly/yearly calendar logic from [MoneyRatePeriod].
/// [daily365] uses ACT/365 (`days / 365`) against the stored rate.
enum MoneyInterestAccrual {
  calendar,
  daily365;

  static MoneyInterestAccrual parse(String? raw) {
    if (raw == MoneyInterestAccrual.daily365.name) {
      return MoneyInterestAccrual.daily365;
    }
    return MoneyInterestAccrual.calendar;
  }
}

/// When unpaid interest is merged into principal / balance.
enum MoneyCapitalizationPolicy {
  never,
  onPayment,
  onScheduledCycle,
  onBalanceDirectionChange,
  onLoanClosure,
  manual;

  static MoneyCapitalizationPolicy parse(String? raw) {
    switch (raw) {
      case 'onPayment':
        return MoneyCapitalizationPolicy.onPayment;
      case 'onScheduledCycle':
        return MoneyCapitalizationPolicy.onScheduledCycle;
      case 'onBalanceDirectionChange':
        return MoneyCapitalizationPolicy.onBalanceDirectionChange;
      case 'onLoanClosure':
        return MoneyCapitalizationPolicy.onLoanClosure;
      case 'manual':
        return MoneyCapitalizationPolicy.manual;
      case 'never':
      default:
        return MoneyCapitalizationPolicy.never;
    }
  }

  /// Map legacy simple/compound column when policy was not stored.
  static MoneyCapitalizationPolicy fromLegacyInterestKind(
    MoneyInterestKind kind,
  ) {
    return kind == MoneyInterestKind.compound
        ? MoneyCapitalizationPolicy.onScheduledCycle
        : MoneyCapitalizationPolicy.never;
  }

  /// Persist legacy column for one release.
  MoneyInterestKind get legacyInterestKind {
    return this == MoneyCapitalizationPolicy.onScheduledCycle
        ? MoneyInterestKind.compound
        : MoneyInterestKind.simple;
  }
}

/// Cycle used when [MoneyCapitalizationPolicy.onScheduledCycle] is selected.
enum MoneyCapitalizationCycle {
  monthly,
  quarterly,
  yearly;

  static MoneyCapitalizationCycle parse(String? raw) {
    if (raw == MoneyCapitalizationCycle.quarterly.name) {
      return MoneyCapitalizationCycle.quarterly;
    }
    if (raw == MoneyCapitalizationCycle.yearly.name) {
      return MoneyCapitalizationCycle.yearly;
    }
    return MoneyCapitalizationCycle.monthly;
  }

  /// Default cycle from calculation frequency.
  static MoneyCapitalizationCycle fromRatePeriod(MoneyRatePeriod period) {
    return switch (period) {
      MoneyRatePeriod.yearly => MoneyCapitalizationCycle.yearly,
      MoneyRatePeriod.monthly => MoneyCapitalizationCycle.monthly,
    };
  }
}

/// How repayments allocate between unpaid interest and principal.
enum MoneyPrepaymentAllocation {
  interestThenPrincipal,
  principalOnly;

  static MoneyPrepaymentAllocation parse(String? raw) {
    if (raw == MoneyPrepaymentAllocation.principalOnly.name) {
      return MoneyPrepaymentAllocation.principalOnly;
    }
    return MoneyPrepaymentAllocation.interestThenPrincipal;
  }
}

enum MoneyLoanStatus {
  pending,
  closed,
  cancelled;

  static MoneyLoanStatus parse(String? raw) {
    if (raw == MoneyLoanStatus.closed.name) {
      return MoneyLoanStatus.closed;
    }
    if (raw == MoneyLoanStatus.cancelled.name) {
      return MoneyLoanStatus.cancelled;
    }
    return MoneyLoanStatus.pending;
  }

  bool get isOpen => this == MoneyLoanStatus.pending;
}

/// Cash entry on a money loan.
///
/// Legacy stored kind `payment` parses as [repayment].
enum MoneyLoanEntryKind {
  repayment,
  disbursement,
  adjustment,
  capitalization;

  static MoneyLoanEntryKind parse(String? raw) {
    if (raw == MoneyLoanEntryKind.adjustment.name) {
      return MoneyLoanEntryKind.adjustment;
    }
    if (raw == MoneyLoanEntryKind.disbursement.name) {
      return MoneyLoanEntryKind.disbursement;
    }
    if (raw == MoneyLoanEntryKind.capitalization.name) {
      return MoneyLoanEntryKind.capitalization;
    }
    // Legacy `payment` and current `repayment`.
    return MoneyLoanEntryKind.repayment;
  }
}

/// One dated payment or adjustment on a cash loan.
class MoneyLoanEntry {
  const MoneyLoanEntry({
    required this.id,
    required this.loanId,
    required this.entryAt,
    required this.amountPaise,
    required this.kind,
    this.note,
  });

  final String id;
  final String loanId;
  final DateTime entryAt;
  final int amountPaise;
  final MoneyLoanEntryKind kind;
  final String? note;
}

/// Cash loan record (ledger header).
class MoneyLoan {
  const MoneyLoan({
    required this.id,
    required this.customerId,
    required this.direction,
    required this.principalPaise,
    required this.currencyCode,
    required this.interestKind,
    required this.rateBps,
    required this.ratePeriod,
    required this.interestStartedAt,
    required this.status,
    required this.createdAt,
    this.interestAccrual = MoneyInterestAccrual.calendar,
    this.capitalizationPolicy = MoneyCapitalizationPolicy.never,
    this.capitalizationCycle = MoneyCapitalizationCycle.monthly,
    this.prepaymentAllocation =
        MoneyPrepaymentAllocation.interestThenPrincipal,
    this.interestEndedAt,
    this.closedAt,
    this.note,
    this.entries = const <MoneyLoanEntry>[],
  });

  final String id;
  final String customerId;
  final MoneyLoanDirection direction;
  final int principalPaise;
  final String currencyCode;
  /// Legacy; prefer [capitalizationPolicy].
  final MoneyInterestKind interestKind;
  final int rateBps;
  final MoneyRatePeriod ratePeriod;
  final MoneyInterestAccrual interestAccrual;
  final MoneyCapitalizationPolicy capitalizationPolicy;
  final MoneyCapitalizationCycle capitalizationCycle;
  final DateTime interestStartedAt;
  final DateTime? interestEndedAt;
  final MoneyPrepaymentAllocation prepaymentAllocation;
  final MoneyLoanStatus status;
  final DateTime? closedAt;
  final String? note;
  final DateTime createdAt;
  final List<MoneyLoanEntry> entries;

  MoneyLoan copyWith({
    MoneyLoanDirection? direction,
    int? principalPaise,
    String? currencyCode,
    MoneyInterestKind? interestKind,
    int? rateBps,
    MoneyRatePeriod? ratePeriod,
    MoneyInterestAccrual? interestAccrual,
    MoneyCapitalizationPolicy? capitalizationPolicy,
    MoneyCapitalizationCycle? capitalizationCycle,
    DateTime? interestStartedAt,
    DateTime? interestEndedAt,
    bool clearInterestEndedAt = false,
    MoneyPrepaymentAllocation? prepaymentAllocation,
    MoneyLoanStatus? status,
    DateTime? closedAt,
    bool clearClosedAt = false,
    String? note,
    bool clearNote = false,
    List<MoneyLoanEntry>? entries,
  }) {
    return MoneyLoan(
      id: id,
      customerId: customerId,
      direction: direction ?? this.direction,
      principalPaise: principalPaise ?? this.principalPaise,
      currencyCode: currencyCode ?? this.currencyCode,
      interestKind: interestKind ?? this.interestKind,
      rateBps: rateBps ?? this.rateBps,
      ratePeriod: ratePeriod ?? this.ratePeriod,
      interestAccrual: interestAccrual ?? this.interestAccrual,
      capitalizationPolicy:
          capitalizationPolicy ?? this.capitalizationPolicy,
      capitalizationCycle:
          capitalizationCycle ?? this.capitalizationCycle,
      interestStartedAt: interestStartedAt ?? this.interestStartedAt,
      interestEndedAt:
          clearInterestEndedAt ? null : (interestEndedAt ?? this.interestEndedAt),
      prepaymentAllocation:
          prepaymentAllocation ?? this.prepaymentAllocation,
      status: status ?? this.status,
      closedAt: clearClosedAt ? null : (closedAt ?? this.closedAt),
      note: clearNote ? null : (note ?? this.note),
      createdAt: createdAt,
      entries: entries ?? this.entries,
    );
  }
}
