import 'dart:convert';

import '../pricing/rental_pricing.dart';

export '../pricing/rental_pricing.dart' show BillingMode;

/// Catalog default for New Order Rent/Sell (`rental` | `general`).
enum InventoryItemKind {
  rental,
  general;

  String get storageValue => name;

  static InventoryItemKind parse(String? raw) {
    switch (raw) {
      case 'general':
        return InventoryItemKind.general;
      default:
        return InventoryItemKind.rental;
    }
  }
}

/// How a rental line was issued (`rent` | `sell`).
enum LineFulfillment {
  rent,
  sell;

  String get storageValue => name;

  static LineFulfillment parse(String? raw) {
    switch (raw) {
      case 'sell':
        return LineFulfillment.sell;
      default:
        return LineFulfillment.rent;
    }
  }
}

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
    this.dueDateOptional = false,
    this.requiresUnitIdentity = true,
    this.defaultItemKind = InventoryItemKind.rental,
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
  final bool dueDateOptional;
  /// Parent catalog (e.g. Novels): each unit needs name/id at issue.
  final bool requiresUnitIdentity;
  /// Default Rent/Sell mode when adding this item to an order.
  final InventoryItemKind defaultItemKind;

  bool get isGeneral => defaultItemKind == InventoryItemKind.general;

  InventoryItem copyWith({
    int? availableUnits,
    int? totalUnits,
    AssetStatus? status,
    String? notes,
    BillingMode? billingMode,
    int? rateAmount,
    int? lateFeePerDay,
    String? currencyCode,
    bool? dueDateOptional,
    bool? requiresUnitIdentity,
    InventoryItemKind? defaultItemKind,
  }) => InventoryItem(
    id: id,
    name: name,
    category: category,
    availableUnits: availableUnits ?? this.availableUnits,
    totalUnits: totalUnits ?? this.totalUnits,
    status: status ?? this.status,
    qrCode: qrCode,
    notes: notes ?? this.notes,
    billingMode: billingMode ?? this.billingMode,
    rateAmount: rateAmount ?? this.rateAmount,
    lateFeePerDay: lateFeePerDay ?? this.lateFeePerDay,
    currencyCode: currencyCode ?? this.currencyCode,
    dueDateOptional: dueDateOptional ?? this.dueDateOptional,
    requiresUnitIdentity: requiresUnitIdentity ?? this.requiresUnitIdentity,
    defaultItemKind: defaultItemKind ?? this.defaultItemKind,
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
    'dueDateOptional': dueDateOptional,
    'requiresUnitIdentity': requiresUnitIdentity,
    'defaultItemKind': defaultItemKind.storageValue,
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
    dueDateOptional: (json['dueDateOptional'] as bool?) ?? false,
    requiresUnitIdentity: (json['requiresUnitIdentity'] as bool?) ?? true,
    defaultItemKind: InventoryItemKind.parse(json['defaultItemKind'] as String?),
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

/// Kind for append-only order notes (`general` | `terms` | `measurement`).
enum RentalNoteKind {
  general,
  terms,
  measurement;

  String get storageValue => name;

  static RentalNoteKind parse(String? raw) {
    switch (raw) {
      case 'terms':
        return RentalNoteKind.terms;
      case 'measurement':
        return RentalNoteKind.measurement;
      default:
        return RentalNoteKind.general;
    }
  }
}

/// One append-only note on a rental order (optionally linked to a line).
class RentalNote {
  const RentalNote({
    required this.id,
    required this.rentalId,
    required this.kind,
    required this.body,
    required this.createdAt,
    this.rentalItemId,
  });

  final String id;
  final String rentalId;
  final String? rentalItemId;
  final RentalNoteKind kind;
  final String body;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'rentalId': rentalId,
    'rentalItemId': rentalItemId,
    'kind': kind.storageValue,
    'body': body,
    'createdAt': createdAt.toIso8601String(),
  };

  factory RentalNote.fromJson(Map<String, dynamic> json) => RentalNote(
    id: json['id'] as String,
    rentalId: json['rentalId'] as String,
    rentalItemId: json['rentalItemId'] as String?,
    kind: RentalNoteKind.parse(json['kind'] as String?),
    body: json['body'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

/// Input for issuing one catalog unit with instance labels.
class RentalLineInput {
  const RentalLineInput({
    required this.itemId,
    required this.instanceName,
    required this.shortCode,
    this.durationUnits,
    this.customEnd,
    this.openEnded,
    this.fulfillment = LineFulfillment.rent,
    this.manualSaleAmountPaise,
  });

  final String itemId;
  final String instanceName;
  final String shortCode;

  /// When set, overrides parent [LocalRepository.createRental] duration for this line.
  final int? durationUnits;

  /// Custom due date for this line when billing mode is custom.
  final DateTime? customEnd;

  /// When set, overrides parent open-ended flag for this line.
  final bool? openEnded;

  /// Rent (duration) or Sell (manual amount, auto-closed).
  final LineFulfillment fulfillment;

  /// Required when [fulfillment] is [LineFulfillment.sell] (paise, > 0).
  final int? manualSaleAmountPaise;

  bool get isSell => fulfillment == LineFulfillment.sell;
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
    this.billingMode = BillingMode.weekly,
    this.rateAmount = 0,
    this.fulfillment = LineFulfillment.rent,
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
  /// Catalog billing mode used for open-ended accrual estimates.
  final BillingMode billingMode;
  /// Catalog rate (paise) used for open-ended accrual estimates.
  final int rateAmount;
  final LineFulfillment fulfillment;

  bool get isOpen => returnedAt == null;

  bool get isSell => fulfillment == LineFulfillment.sell;

  int get totalAmount => baseAmount + lateAmount;

  int get amountDueAfterDeposit =>
      (totalAmount - depositApplied).clamp(0, totalAmount);

  int baseAmountAsOf(DateTime startedAt, DateTime? due, DateTime asOf) {
    if (!isOpen) {
      return baseAmount;
    }
    if (due == null) {
      return computeBaseAmount(
        mode: billingMode,
        rateAmount: rateAmount,
        start: startedAt,
        due: asOf,
      );
    }
    return baseAmount;
  }

  int lateAmountAsOf(DateTime? due, DateTime asOf) {
    if (!isOpen) {
      return lateAmount;
    }
    if (due == null) {
      return 0;
    }
    return computeLateAmount(
      due: due,
      asOf: asOf,
      lateFeePerDay: lateFeePerDay,
    );
  }

  int totalAmountAsOf(DateTime startedAt, DateTime? due, DateTime asOf) {
    if (!isOpen) {
      return totalAmount;
    }
    return computeTotalAmount(
      baseAmount: baseAmountAsOf(startedAt, due, asOf),
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
    'billingMode': billingMode.name,
    'rateAmount': rateAmount,
    'fulfillment': fulfillment.storageValue,
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
    billingMode: BillingMode.parse(json['billingMode'] as String?),
    rateAmount: (json['rateAmount'] as int?) ?? 0,
    fulfillment: LineFulfillment.parse(json['fulfillment'] as String?),
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

/// Result of cancelling an active order with deposit settlement.
class OrderCancelResult {
  const OrderCancelResult({
    required this.rentalId,
    required this.amountKeptPaise,
    required this.amountReturnedPaise,
    required this.depositBalanceAfter,
  });

  final String rentalId;
  final int amountKeptPaise;
  final int amountReturnedPaise;
  final int depositBalanceAfter;
}

class Rental {
  const Rental({
    required this.id,
    required this.customerId,
    required this.lines,
    required this.startedAt,
    this.dueAt,
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
    this.notes = const <RentalNote>[],
  });

  final String id;
  final String customerId;
  final List<RentalLine> lines;
  final DateTime startedAt;
  /// Null for open-ended rentals (no fixed due date).
  final DateTime? dueAt;
  final DateTime? returnedAt;
  final List<RentalEvent> timeline;
  final String qrCode;
  /// Optional per-rental display name (e.g. Unknown path); not a Customer row.
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
  /// Append-only order notes (newest first when loaded from DB).
  final List<RentalNote> notes;

  List<String> get itemIds =>
      lines.map((RentalLine line) => line.itemId).toList(growable: false);

  List<RentalLine> get openLines =>
      lines.where((RentalLine line) => line.isOpen).toList(growable: false);

  List<RentalLine> get returnedLines =>
      lines.where((RentalLine line) => !line.isOpen).toList(growable: false);

  bool get isActive => returnedAt == null;

  bool get hasDueDate => dueAt != null;

  bool get isOpenEnded => isActive && dueAt == null;

  /// Cash still owed after deposit applied (finalized on returned rentals).
  int get amountDueAfterDeposit =>
      (totalAmount - depositApplied).clamp(0, totalAmount);

  /// Running late fee estimate for active rentals; finalized [lateAmount] when returned.
  int lateAmountAsOf(DateTime asOf) {
    if (!isActive) {
      return lateAmount;
    }
    if (dueAt == null) {
      return 0;
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
      total += line.totalAmountAsOf(startedAt, dueAt, asOf);
    }
    return total;
  }

  AssetStatus statusFor(DateTime now) {
    if (!isActive) {
      return AssetStatus.archived;
    }
    final DateTime? due = dueAt;
    if (due == null) {
      return AssetStatus.rented;
    }
    if (due.year == now.year &&
        due.month == now.month &&
        due.day == now.day) {
      return AssetStatus.dueToday;
    }
    if (due.isBefore(now)) {
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
    List<RentalNote>? notes,
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
    notes: notes ?? this.notes,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'customerId': customerId,
    'itemIds': itemIds,
    'lines': lines.map((RentalLine line) => line.toJson()).toList(),
    'startedAt': startedAt.toIso8601String(),
    'dueAt': dueAt?.toIso8601String(),
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
    'notes': notes.map((RentalNote note) => note.toJson()).toList(),
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
      dueAt: json['dueAt'] == null
          ? null
          : DateTime.parse(json['dueAt'] as String),
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
      notes: (json['notes'] as List<dynamic>? ?? const <dynamic>[])
          .map((entry) => RentalNote.fromJson(entry as Map<String, dynamic>))
          .toList(),
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
