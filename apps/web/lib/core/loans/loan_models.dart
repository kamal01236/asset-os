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

enum MoneyRatePeriod {
  monthly,
  yearly;

  static MoneyRatePeriod parse(String? raw) {
    if (raw == MoneyRatePeriod.yearly.name) {
      return MoneyRatePeriod.yearly;
    }
    return MoneyRatePeriod.monthly;
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

enum MoneyLoanEntryKind {
  payment,
  adjustment;

  static MoneyLoanEntryKind parse(String? raw) {
    if (raw == MoneyLoanEntryKind.adjustment.name) {
      return MoneyLoanEntryKind.adjustment;
    }
    return MoneyLoanEntryKind.payment;
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
  final MoneyInterestKind interestKind;
  final int rateBps;
  final MoneyRatePeriod ratePeriod;
  final DateTime interestStartedAt;
  final DateTime? interestEndedAt;
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
    DateTime? interestStartedAt,
    DateTime? interestEndedAt,
    bool clearInterestEndedAt = false,
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
      interestStartedAt: interestStartedAt ?? this.interestStartedAt,
      interestEndedAt:
          clearInterestEndedAt ? null : (interestEndedAt ?? this.interestEndedAt),
      status: status ?? this.status,
      closedAt: clearClosedAt ? null : (closedAt ?? this.closedAt),
      note: clearNote ? null : (note ?? this.note),
      createdAt: createdAt,
      entries: entries ?? this.entries,
    );
  }
}
