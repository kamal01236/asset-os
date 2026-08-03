import 'dart:convert';

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
  });

  final String id;
  final String name;
  final String phone;
  final bool isTrusted;
  final String qrCode;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'phone': phone,
    'isTrusted': isTrusted,
    'qrCode': qrCode,
  };

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: json['id'] as String,
    name: json['name'] as String,
    phone: json['phone'] as String,
    isTrusted: json['isTrusted'] as bool,
    qrCode: json['qrCode'] as String,
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
  });

  final String id;
  final String name;
  final String category;
  final int availableUnits;
  final int totalUnits;
  final AssetStatus status;
  final String qrCode;
  final String? notes;

  InventoryItem copyWith({
    int? availableUnits,
    AssetStatus? status,
    String? notes,
  }) => InventoryItem(
    id: id,
    name: name,
    category: category,
    availableUnits: availableUnits ?? this.availableUnits,
    totalUnits: totalUnits,
    status: status ?? this.status,
    qrCode: qrCode,
    notes: notes ?? this.notes,
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
    required this.itemId,
    required this.catalogName,
    required this.instanceName,
    required this.shortCode,
  });

  final String itemId;
  final String catalogName;
  final String instanceName;
  final String shortCode;

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
    'itemId': itemId,
    'catalogName': catalogName,
    'instanceName': instanceName,
    'shortCode': shortCode,
  };

  factory RentalLine.fromJson(Map<String, dynamic> json) => RentalLine(
    itemId: json['itemId'] as String,
    catalogName: (json['catalogName'] as String?) ?? '',
    instanceName: (json['instanceName'] as String?) ?? '',
    shortCode: (json['shortCode'] as String?) ?? 'LEGACY',
  );
}

/// Thrown when an active rental already uses the same short code.
class DuplicateActiveShortCodeException implements Exception {
  DuplicateActiveShortCodeException(this.shortCode);

  final String shortCode;

  @override
  String toString() => 'Duplicate active short code: $shortCode';
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

  List<String> get itemIds =>
      lines.map((RentalLine line) => line.itemId).toList(growable: false);

  bool get isActive => returnedAt == null;

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
  }) => Rental(
    id: id,
    customerId: customerId,
    lines: lines ?? this.lines,
    startedAt: startedAt,
    dueAt: dueAt,
    returnedAt: returnedAt ?? this.returnedAt,
    timeline: timeline ?? this.timeline,
    qrCode: qrCode,
    nickname: nickname ?? this.nickname,
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
