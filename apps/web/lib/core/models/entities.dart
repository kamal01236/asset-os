import 'dart:convert';

import '../pricing/rental_pricing.dart';

export '../pricing/rental_pricing.dart' show BillingMode;

enum AssetStatus {
  available,
  rented,
  dueToday,
  overdue,
  archived,
}

extension AssetStatusX on AssetStatus {
  String get label {
    switch (this) {
      case AssetStatus.available:
        return 'Available';
      case AssetStatus.rented:
        return 'Rented';
      case AssetStatus.dueToday:
        return 'Due Today';
      case AssetStatus.overdue:
        return 'Overdue';
      case AssetStatus.archived:
        return 'Archived';
    }
  }
}

class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.isTrusted,
    required this.qrCode,
    this.depositBalance = 0,
  });

  final String id;
  final String name;
  final String phone;
  final bool isTrusted;
  final String qrCode;
  /// Wallet deposit balance in paise.
  final int depositBalance;

  Customer copyWith({
    String? name,
    String? phone,
    bool? isTrusted,
    int? depositBalance,
  }) => Customer(
    id: id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    isTrusted: isTrusted ?? this.isTrusted,
    qrCode: qrCode,
    depositBalance: depositBalance ?? this.depositBalance,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'phone': phone,
    'isTrusted': isTrusted,
    'qrCode': qrCode,
    'depositBalance': depositBalance,
  };

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: json['id'] as String,
    name: json['name'] as String,
    phone: json['phone'] as String,
    isTrusted: json['isTrusted'] as bool,
    qrCode: json['qrCode'] as String,
    depositBalance: (json['depositBalance'] as int?) ?? 0,
  );
}

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.availableUnits,
    required this.totalUnits,
    required this.status,
    required this.qrCode,
    this.notes,
    this.billingMode = BillingMode.weekly,
    this.rateAmount = 0,
    this.lateFeePerDay = 0,
    this.currencyCode = 'INR',
  });

  final String id;
  final String name;
  final String category;
  final int availableUnits;
  final int totalUnits;
  final AssetStatus status;
  final String qrCode;
  final String? notes;
  final BillingMode billingMode;
  final int rateAmount;
  final int lateFeePerDay;
  final String currencyCode;

  InventoryItem copyWith({
    int? availableUnits,
    AssetStatus? status,
    String? notes,
    BillingMode? billingMode,
    int? rateAmount,
    int? lateFeePerDay,
    String? currencyCode,
  }) => InventoryItem(
    id: id,
    name: name,
    category: category,
    availableUnits: availableUnits ?? this.availableUnits,
    totalUnits: totalUnits,
    status: status ?? this.status,
    qrCode: qrCode,
    notes: notes ?? this.notes,
    billingMode: billingMode ?? this.billingMode,
    rateAmount: rateAmount ?? this.rateAmount,
    lateFeePerDay: lateFeePerDay ?? this.lateFeePerDay,
    currencyCode: currencyCode ?? this.currencyCode,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'category': category,
    'availableUnits': availableUnits,
    'totalUnits': totalUnits,
    'status': status.name,
    'qrCode': qrCode,
    'notes': notes,
    'billingMode': billingMode.name,
    'rateAmount': rateAmount,
    'lateFeePerDay': lateFeePerDay,
    'currencyCode': currencyCode,
  };

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
    id: json['id'] as String,
    name: json['name'] as String,
    category: json['category'] as String,
    availableUnits: json['availableUnits'] as int,
    totalUnits: json['totalUnits'] as int,
    status: AssetStatus.values.byName(json['status'] as String),
    qrCode: json['qrCode'] as String,
    notes: json['notes'] as String?,
    billingMode: BillingMode.parse(json['billingMode'] as String?),
    rateAmount: (json['rateAmount'] as int?) ?? 0,
    lateFeePerDay: (json['lateFeePerDay'] as int?) ?? 0,
    currencyCode: (json['currencyCode'] as String?) ?? 'INR',
  );
}

class RentalEvent {
  const RentalEvent({
    required this.title,
    required this.subtitle,
    required this.at,
  });

  final String title;
  final String subtitle;
  final DateTime at;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'title': title,
    'subtitle': subtitle,
    'at': at.toIso8601String(),
  };

  factory RentalEvent.fromJson(Map<String, dynamic> json) => RentalEvent(
    title: json['title'] as String,
    subtitle: json['subtitle'] as String,
    at: DateTime.parse(json['at'] as String),
  );
}

/// Input for issuing one catalog unit with instance labels.
class RentalLineInput {
  const RentalLineInput({
    required this.itemId,
    required this.instanceName,
    required this.shortCode,
  });

  final String itemId;
  final String instanceName;
  final String shortCode;
}

/// One issued unit on a rental: catalog type + instance name/code.
class RentalLine {
  const RentalLine({
    required this.id,
    required this.itemId,
    required this.catalogName,
    required this.instanceName,
    required this.shortCode,
    this.returnedAt,
    this.baseAmount = 0,
    this.lateAmount = 0,
    this.depositApplied = 0,
    this.lateFeePerDay = 0,
  });

  final String id;
  final String itemId;
  final String catalogName;
  final String instanceName;
  final String shortCode;
  final DateTime? returnedAt;
  final int baseAmount;
  final int lateAmount;
  final int depositApplied;
  /// Catalog late fee used for open-line estimates (paise/day).
  final int lateFeePerDay;

  bool get isOpen => returnedAt == null;

  int get totalAmount => baseAmount + lateAmount;

  int get amountDueAfterDeposit =>
      (totalAmount - depositApplied).clamp(0, totalAmount);

  int lateAmountAsOf(DateTime due, DateTime asOf) {
    if (!isOpen) {
      return lateAmount;
    }
    return computeLateAmount(
      due: due,
      asOf: asOf,
      lateFeePerDay: lateFeePerDay,
    );
  }

  int totalAmountAsOf(DateTime due, DateTime asOf) {
    if (!isOpen) {
      return totalAmount;
    }
    return computeTotalAmount(
      baseAmount: baseAmount,
      lateAmount: lateAmountAsOf(due, asOf),
    );
  }

  /// e.g. `Novel · Harry Potter (NOV-042)`.
  String get displayLabel {
    final String catalog = catalogName.trim().isEmpty ? itemId : catalogName.trim();
    final String name = instanceName.trim();
    final String code = shortCode.trim();
    if (name.isEmpty && code.isEmpty) {
      return catalog;
    }
    if (name.isEmpty) {
      return '$catalog ($code)';
    }
    if (code.isEmpty) {
      return '$catalog · $name';
    }
    return '$catalog · $name ($code)';
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'itemId': itemId,
    'catalogName': catalogName,
    'instanceName': instanceName,
    'shortCode': shortCode,
    'returnedAt': returnedAt?.toIso8601String(),
    'baseAmount': baseAmount,
    'lateAmount': lateAmount,
    'depositApplied': depositApplied,
    'lateFeePerDay': lateFeePerDay,
  };

  factory RentalLine.fromJson(Map<String, dynamic> json) => RentalLine(
    id: (json['id'] as String?) ??
        'RLI-${json['itemId'] as String? ?? 'LEGACY'}',
    itemId: json['itemId'] as String,
    catalogName: (json['catalogName'] as String?) ?? '',
    instanceName: (json['instanceName'] as String?) ?? '',
    shortCode: (json['shortCode'] as String?) ?? 'LEGACY',
    returnedAt: json['returnedAt'] == null
        ? null
        : DateTime.parse(json['returnedAt'] as String),
    baseAmount: (json['baseAmount'] as int?) ?? 0,
    lateAmount: (json['lateAmount'] as int?) ?? 0,
    depositApplied: (json['depositApplied'] as int?) ?? 0,
    lateFeePerDay: (json['lateFeePerDay'] as int?) ?? 0,
  );
}

/// Thrown when an active rental already uses the same short code.
class DuplicateActiveShortCodeException implements Exception {
  DuplicateActiveShortCodeException(this.shortCode);

  final String shortCode;

  @override
  String toString() => 'Duplicate active short code: $shortCode';
}

/// Deposit wallet ledger entry types (stored as snake_case in Drift).
enum DepositLedgerType {
  topUp,
  apply,
  refund,
  adjust;

  String get storageValue {
    switch (this) {
      case DepositLedgerType.topUp:
        return 'top_up';
      case DepositLedgerType.apply:
        return 'apply';
      case DepositLedgerType.refund:
        return 'refund';
      case DepositLedgerType.adjust:
        return 'adjust';
    }
  }

  static DepositLedgerType parse(String? raw) {
    switch (raw) {
      case 'top_up':
        return DepositLedgerType.topUp;
      case 'apply':
        return DepositLedgerType.apply;
      case 'refund':
        return DepositLedgerType.refund;
      case 'adjust':
        return DepositLedgerType.adjust;
      default:
        return DepositLedgerType.adjust;
    }
  }
}

class DepositLedgerEntry {
  const DepositLedgerEntry({
    required this.id,
    required this.customerId,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.at,
    this.rentalId,
    this.note,
  });

  final String id;
  final String customerId;
  final String? rentalId;
  final DepositLedgerType type;
  /// Signed amount in paise (+ top-up, − apply/refund).
  final int amount;
  final int balanceAfter;
  final String? note;
  final DateTime at;
}

/// Result of settling a rental return against the customer deposit wallet.
class RentalReturnResult {
  const RentalReturnResult({
    required this.rentalId,
    required this.totalAmount,
    required this.depositApplied,
    required this.depositBalanceAfter,
    this.returnedLineIds = const <String>[],
    this.rentalClosed = true,
  });

  final String rentalId;
  final int totalAmount;
  final int depositApplied;
  final int depositBalanceAfter;
  final List<String> returnedLineIds;
  /// True when the parent rental has no open lines left.
  final bool rentalClosed;

  int get amountDue => (totalAmount - depositApplied).clamp(0, totalAmount);
}

/// Result of replacing a rental line (return + new rental).
class RentalReplaceResult {
  const RentalReplaceResult({
    required this.returnResult,
    required this.newRentalId,
  });

  final RentalReturnResult returnResult;
  final String newRentalId;
}

class Rental {
  const Rental({
    required this.id,
    required this.customerId,
    required this.lines,
    required this.startedAt,
    required this.dueAt,
    required this.timeline,
    required this.qrCode,
    this.returnedAt,
    this.nickname,
    this.billingMode = BillingMode.weekly,
    this.rateAmount = 0,
    this.lateFeePerDay = 0,
    this.baseAmount = 0,
    this.lateAmount = 0,
    this.totalAmount = 0,
    this.depositApplied = 0,
    this.durationUnits = 1,
    this.replacedFromRentalId,
  });

  final String id;
  final String customerId;
  final List<RentalLine> lines;
  final DateTime startedAt;
  final DateTime dueAt;
  final DateTime? returnedAt;
  final List<RentalEvent> timeline;
  final String qrCode;
  /// Per-rental nickname (used for SELF Known issues; not stored on customer).
  final String? nickname;
  final BillingMode billingMode;
  final int rateAmount;
  final int lateFeePerDay;
  final int baseAmount;
  final int lateAmount;
  final int totalAmount;
  /// Deposit applied from wallet at return (paise).
  final int depositApplied;
  final int durationUnits;
  final String? replacedFromRentalId;

  List<String> get itemIds =>
      lines.map((RentalLine line) => line.itemId).toList(growable: false);

  List<RentalLine> get openLines =>
      lines.where((RentalLine line) => line.isOpen).toList(growable: false);

  List<RentalLine> get returnedLines =>
      lines.where((RentalLine line) => !line.isOpen).toList(growable: false);

  bool get isActive => returnedAt == null;

  /// Cash still owed after deposit applied (finalized on returned rentals).
  int get amountDueAfterDeposit =>
      (totalAmount - depositApplied).clamp(0, totalAmount);

  /// Running late fee estimate for active rentals; finalized [lateAmount] when returned.
  int lateAmountAsOf(DateTime asOf) {
    if (!isActive) {
      return lateAmount;
    }
    int late = 0;
    for (final RentalLine line in lines) {
      late += line.lateAmountAsOf(dueAt, asOf);
    }
    return late;
  }

  int totalAmountAsOf(DateTime asOf) {
    if (!isActive) {
      return totalAmount;
    }
    int total = 0;
    for (final RentalLine line in lines) {
      total += line.totalAmountAsOf(dueAt, asOf);
    }
    return total;
  }

  AssetStatus statusFor(DateTime now) {
    if (!isActive) {
      return AssetStatus.archived;
    }
    if (dueAt.year == now.year &&
        dueAt.month == now.month &&
        dueAt.day == now.day) {
      return AssetStatus.dueToday;
    }
    if (dueAt.isBefore(now)) {
      return AssetStatus.overdue;
    }
    return AssetStatus.rented;
  }

  Rental copyWith({
    DateTime? returnedAt,
    List<RentalEvent>? timeline,
    String? nickname,
    List<RentalLine>? lines,
    BillingMode? billingMode,
    int? rateAmount,
    int? lateFeePerDay,
    int? baseAmount,
    int? lateAmount,
    int? totalAmount,
    int? depositApplied,
    int? durationUnits,
    DateTime? dueAt,
    String? replacedFromRentalId,
  }) => Rental(
    id: id,
    customerId: customerId,
    lines: lines ?? this.lines,
    startedAt: startedAt,
    dueAt: dueAt ?? this.dueAt,
    returnedAt: returnedAt ?? this.returnedAt,
    timeline: timeline ?? this.timeline,
    qrCode: qrCode,
    nickname: nickname ?? this.nickname,
    billingMode: billingMode ?? this.billingMode,
    rateAmount: rateAmount ?? this.rateAmount,
    lateFeePerDay: lateFeePerDay ?? this.lateFeePerDay,
    baseAmount: baseAmount ?? this.baseAmount,
    lateAmount: lateAmount ?? this.lateAmount,
    totalAmount: totalAmount ?? this.totalAmount,
    depositApplied: depositApplied ?? this.depositApplied,
    durationUnits: durationUnits ?? this.durationUnits,
    replacedFromRentalId: replacedFromRentalId ?? this.replacedFromRentalId,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'customerId': customerId,
    'itemIds': itemIds,
    'lines': lines.map((RentalLine line) => line.toJson()).toList(),
    'startedAt': startedAt.toIso8601String(),
    'dueAt': dueAt.toIso8601String(),
    'returnedAt': returnedAt?.toIso8601String(),
    'timeline': timeline.map((event) => event.toJson()).toList(),
    'qrCode': qrCode,
    'nickname': nickname,
    'billingMode': billingMode.name,
    'rateAmount': rateAmount,
    'lateFeePerDay': lateFeePerDay,
    'baseAmount': baseAmount,
    'lateAmount': lateAmount,
    'totalAmount': totalAmount,
    'depositApplied': depositApplied,
    'durationUnits': durationUnits,
    'replacedFromRentalId': replacedFromRentalId,
  };

  factory Rental.fromJson(Map<String, dynamic> json) {
    final List<RentalLine> lines;
    final Object? rawLines = json['lines'];
    if (rawLines is List<dynamic> && rawLines.isNotEmpty) {
      lines = rawLines
          .map((entry) => RentalLine.fromJson(entry as Map<String, dynamic>))
          .toList();
    } else {
      final List<String> ids =
          (json['itemIds'] as List<dynamic>? ?? const <dynamic>[]).cast<String>();
      lines = ids
          .map(
            (String id) => RentalLine(
              id: 'RLI-${json['id'] as String}-$id',
              itemId: id,
              catalogName: '',
              instanceName: '',
              shortCode: 'LEGACY',
            ),
          )
          .toList();
    }
    return Rental(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      lines: lines,
      startedAt: DateTime.parse(json['startedAt'] as String),
      dueAt: DateTime.parse(json['dueAt'] as String),
      returnedAt: json['returnedAt'] == null
          ? null
          : DateTime.parse(json['returnedAt'] as String),
      timeline: (json['timeline'] as List<dynamic>)
          .map((entry) => RentalEvent.fromJson(entry as Map<String, dynamic>))
          .toList(),
      qrCode: json['qrCode'] as String,
      nickname: json['nickname'] as String?,
      billingMode: BillingMode.parse(json['billingMode'] as String?),
      rateAmount: (json['rateAmount'] as int?) ?? 0,
      lateFeePerDay: (json['lateFeePerDay'] as int?) ?? 0,
      baseAmount: (json['baseAmount'] as int?) ?? 0,
      lateAmount: (json['lateAmount'] as int?) ?? 0,
      totalAmount: (json['totalAmount'] as int?) ?? 0,
      depositApplied: (json['depositApplied'] as int?) ?? 0,
      durationUnits: (json['durationUnits'] as int?) ?? 1,
      replacedFromRentalId: json['replacedFromRentalId'] as String?,
    );
  }
}

class AppDataSnapshot {
  const AppDataSnapshot({
    required this.customers,
    required this.inventory,
    required this.rentals,
  });

  final List<Customer> customers;
  final List<InventoryItem> inventory;
  final List<Rental> rentals;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'customers': customers.map((item) => item.toJson()).toList(),
    'inventory': inventory.map((item) => item.toJson()).toList(),
    'rentals': rentals.map((item) => item.toJson()).toList(),
  };

  factory AppDataSnapshot.fromJson(Map<String, dynamic> json) => AppDataSnapshot(
    customers: (json['customers'] as List<dynamic>)
        .map((entry) => Customer.fromJson(entry as Map<String, dynamic>))
        .toList(),
    inventory: (json['inventory'] as List<dynamic>)
        .map((entry) => InventoryItem.fromJson(entry as Map<String, dynamic>))
        .toList(),
    rentals: (json['rentals'] as List<dynamic>)
        .map((entry) => Rental.fromJson(entry as Map<String, dynamic>))
        .toList(),
  );

  String encode() => jsonEncode(toJson());

  factory AppDataSnapshot.decode(String source) {
    return AppDataSnapshot.fromJson(jsonDecode(source) as Map<String, dynamic>);
  }
}
