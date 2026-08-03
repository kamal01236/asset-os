// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CustomersTable extends Customers
    with TableInfo<$CustomersTable, CustomerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isTrustedMeta = const VerificationMeta(
    'isTrusted',
  );
  @override
  late final GeneratedColumn<bool> isTrusted = GeneratedColumn<bool>(
    'is_trusted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_trusted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _qrCodeMeta = const VerificationMeta('qrCode');
  @override
  late final GeneratedColumn<String> qrCode = GeneratedColumn<String>(
    'qr_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, phone, isTrusted, qrCode];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customers';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    } else if (isInserting) {
      context.missing(_phoneMeta);
    }
    if (data.containsKey('is_trusted')) {
      context.handle(
        _isTrustedMeta,
        isTrusted.isAcceptableOrUnknown(data['is_trusted']!, _isTrustedMeta),
      );
    }
    if (data.containsKey('qr_code')) {
      context.handle(
        _qrCodeMeta,
        qrCode.isAcceptableOrUnknown(data['qr_code']!, _qrCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_qrCodeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomerRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      )!,
      isTrusted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_trusted'],
      )!,
      qrCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}qr_code'],
      )!,
    );
  }

  @override
  $CustomersTable createAlias(String alias) {
    return $CustomersTable(attachedDatabase, alias);
  }
}

class CustomerRow extends DataClass implements Insertable<CustomerRow> {
  final String id;
  final String name;
  final String phone;
  final bool isTrusted;
  final String qrCode;
  const CustomerRow({
    required this.id,
    required this.name,
    required this.phone,
    required this.isTrusted,
    required this.qrCode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['phone'] = Variable<String>(phone);
    map['is_trusted'] = Variable<bool>(isTrusted);
    map['qr_code'] = Variable<String>(qrCode);
    return map;
  }

  CustomersCompanion toCompanion(bool nullToAbsent) {
    return CustomersCompanion(
      id: Value(id),
      name: Value(name),
      phone: Value(phone),
      isTrusted: Value(isTrusted),
      qrCode: Value(qrCode),
    );
  }

  factory CustomerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomerRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String>(json['phone']),
      isTrusted: serializer.fromJson<bool>(json['isTrusted']),
      qrCode: serializer.fromJson<String>(json['qrCode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String>(phone),
      'isTrusted': serializer.toJson<bool>(isTrusted),
      'qrCode': serializer.toJson<String>(qrCode),
    };
  }

  CustomerRow copyWith({
    String? id,
    String? name,
    String? phone,
    bool? isTrusted,
    String? qrCode,
  }) => CustomerRow(
    id: id ?? this.id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    isTrusted: isTrusted ?? this.isTrusted,
    qrCode: qrCode ?? this.qrCode,
  );
  CustomerRow copyWithCompanion(CustomersCompanion data) {
    return CustomerRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      isTrusted: data.isTrusted.present ? data.isTrusted.value : this.isTrusted,
      qrCode: data.qrCode.present ? data.qrCode.value : this.qrCode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomerRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('isTrusted: $isTrusted, ')
          ..write('qrCode: $qrCode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, phone, isTrusted, qrCode);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomerRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.isTrusted == this.isTrusted &&
          other.qrCode == this.qrCode);
}

class CustomersCompanion extends UpdateCompanion<CustomerRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> phone;
  final Value<bool> isTrusted;
  final Value<String> qrCode;
  final Value<int> rowid;
  const CustomersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.isTrusted = const Value.absent(),
    this.qrCode = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomersCompanion.insert({
    required String id,
    required String name,
    required String phone,
    this.isTrusted = const Value.absent(),
    required String qrCode,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       phone = Value(phone),
       qrCode = Value(qrCode);
  static Insertable<CustomerRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<bool>? isTrusted,
    Expression<String>? qrCode,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (isTrusted != null) 'is_trusted': isTrusted,
      if (qrCode != null) 'qr_code': qrCode,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? phone,
    Value<bool>? isTrusted,
    Value<String>? qrCode,
    Value<int>? rowid,
  }) {
    return CustomersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      isTrusted: isTrusted ?? this.isTrusted,
      qrCode: qrCode ?? this.qrCode,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (isTrusted.present) {
      map['is_trusted'] = Variable<bool>(isTrusted.value);
    }
    if (qrCode.present) {
      map['qr_code'] = Variable<String>(qrCode.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('isTrusted: $isTrusted, ')
          ..write('qrCode: $qrCode, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InventoryItemsTable extends InventoryItems
    with TableInfo<$InventoryItemsTable, InventoryItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventoryItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _availableUnitsMeta = const VerificationMeta(
    'availableUnits',
  );
  @override
  late final GeneratedColumn<int> availableUnits = GeneratedColumn<int>(
    'available_units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalUnitsMeta = const VerificationMeta(
    'totalUnits',
  );
  @override
  late final GeneratedColumn<int> totalUnits = GeneratedColumn<int>(
    'total_units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _qrCodeMeta = const VerificationMeta('qrCode');
  @override
  late final GeneratedColumn<String> qrCode = GeneratedColumn<String>(
    'qr_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _billingModeMeta = const VerificationMeta(
    'billingMode',
  );
  @override
  late final GeneratedColumn<String> billingMode = GeneratedColumn<String>(
    'billing_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('weekly'),
  );
  static const VerificationMeta _rateAmountMeta = const VerificationMeta(
    'rateAmount',
  );
  @override
  late final GeneratedColumn<int> rateAmount = GeneratedColumn<int>(
    'rate_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lateFeePerDayMeta = const VerificationMeta(
    'lateFeePerDay',
  );
  @override
  late final GeneratedColumn<int> lateFeePerDay = GeneratedColumn<int>(
    'late_fee_per_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('INR'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    category,
    availableUnits,
    totalUnits,
    status,
    qrCode,
    notes,
    billingMode,
    rateAmount,
    lateFeePerDay,
    currencyCode,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<InventoryItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('available_units')) {
      context.handle(
        _availableUnitsMeta,
        availableUnits.isAcceptableOrUnknown(
          data['available_units']!,
          _availableUnitsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_availableUnitsMeta);
    }
    if (data.containsKey('total_units')) {
      context.handle(
        _totalUnitsMeta,
        totalUnits.isAcceptableOrUnknown(data['total_units']!, _totalUnitsMeta),
      );
    } else if (isInserting) {
      context.missing(_totalUnitsMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('qr_code')) {
      context.handle(
        _qrCodeMeta,
        qrCode.isAcceptableOrUnknown(data['qr_code']!, _qrCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_qrCodeMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('billing_mode')) {
      context.handle(
        _billingModeMeta,
        billingMode.isAcceptableOrUnknown(
          data['billing_mode']!,
          _billingModeMeta,
        ),
      );
    }
    if (data.containsKey('rate_amount')) {
      context.handle(
        _rateAmountMeta,
        rateAmount.isAcceptableOrUnknown(data['rate_amount']!, _rateAmountMeta),
      );
    }
    if (data.containsKey('late_fee_per_day')) {
      context.handle(
        _lateFeePerDayMeta,
        lateFeePerDay.isAcceptableOrUnknown(
          data['late_fee_per_day']!,
          _lateFeePerDayMeta,
        ),
      );
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InventoryItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventoryItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      availableUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}available_units'],
      )!,
      totalUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_units'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      qrCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}qr_code'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      billingMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}billing_mode'],
      )!,
      rateAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rate_amount'],
      )!,
      lateFeePerDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}late_fee_per_day'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
    );
  }

  @override
  $InventoryItemsTable createAlias(String alias) {
    return $InventoryItemsTable(attachedDatabase, alias);
  }
}

class InventoryItemRow extends DataClass
    implements Insertable<InventoryItemRow> {
  final String id;
  final String name;
  final String category;
  final int availableUnits;
  final int totalUnits;
  final String status;
  final String qrCode;
  final String? notes;

  /// `daily` | `weekly` | `monthly` | `fixed` | `custom`
  final String billingMode;

  /// Rate in paise (minor units).
  final int rateAmount;

  /// Optional overdue fee per day in paise.
  final int lateFeePerDay;
  final String currencyCode;
  const InventoryItemRow({
    required this.id,
    required this.name,
    required this.category,
    required this.availableUnits,
    required this.totalUnits,
    required this.status,
    required this.qrCode,
    this.notes,
    required this.billingMode,
    required this.rateAmount,
    required this.lateFeePerDay,
    required this.currencyCode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['category'] = Variable<String>(category);
    map['available_units'] = Variable<int>(availableUnits);
    map['total_units'] = Variable<int>(totalUnits);
    map['status'] = Variable<String>(status);
    map['qr_code'] = Variable<String>(qrCode);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['billing_mode'] = Variable<String>(billingMode);
    map['rate_amount'] = Variable<int>(rateAmount);
    map['late_fee_per_day'] = Variable<int>(lateFeePerDay);
    map['currency_code'] = Variable<String>(currencyCode);
    return map;
  }

  InventoryItemsCompanion toCompanion(bool nullToAbsent) {
    return InventoryItemsCompanion(
      id: Value(id),
      name: Value(name),
      category: Value(category),
      availableUnits: Value(availableUnits),
      totalUnits: Value(totalUnits),
      status: Value(status),
      qrCode: Value(qrCode),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      billingMode: Value(billingMode),
      rateAmount: Value(rateAmount),
      lateFeePerDay: Value(lateFeePerDay),
      currencyCode: Value(currencyCode),
    );
  }

  factory InventoryItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventoryItemRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String>(json['category']),
      availableUnits: serializer.fromJson<int>(json['availableUnits']),
      totalUnits: serializer.fromJson<int>(json['totalUnits']),
      status: serializer.fromJson<String>(json['status']),
      qrCode: serializer.fromJson<String>(json['qrCode']),
      notes: serializer.fromJson<String?>(json['notes']),
      billingMode: serializer.fromJson<String>(json['billingMode']),
      rateAmount: serializer.fromJson<int>(json['rateAmount']),
      lateFeePerDay: serializer.fromJson<int>(json['lateFeePerDay']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String>(category),
      'availableUnits': serializer.toJson<int>(availableUnits),
      'totalUnits': serializer.toJson<int>(totalUnits),
      'status': serializer.toJson<String>(status),
      'qrCode': serializer.toJson<String>(qrCode),
      'notes': serializer.toJson<String?>(notes),
      'billingMode': serializer.toJson<String>(billingMode),
      'rateAmount': serializer.toJson<int>(rateAmount),
      'lateFeePerDay': serializer.toJson<int>(lateFeePerDay),
      'currencyCode': serializer.toJson<String>(currencyCode),
    };
  }

  InventoryItemRow copyWith({
    String? id,
    String? name,
    String? category,
    int? availableUnits,
    int? totalUnits,
    String? status,
    String? qrCode,
    Value<String?> notes = const Value.absent(),
    String? billingMode,
    int? rateAmount,
    int? lateFeePerDay,
    String? currencyCode,
  }) => InventoryItemRow(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category ?? this.category,
    availableUnits: availableUnits ?? this.availableUnits,
    totalUnits: totalUnits ?? this.totalUnits,
    status: status ?? this.status,
    qrCode: qrCode ?? this.qrCode,
    notes: notes.present ? notes.value : this.notes,
    billingMode: billingMode ?? this.billingMode,
    rateAmount: rateAmount ?? this.rateAmount,
    lateFeePerDay: lateFeePerDay ?? this.lateFeePerDay,
    currencyCode: currencyCode ?? this.currencyCode,
  );
  InventoryItemRow copyWithCompanion(InventoryItemsCompanion data) {
    return InventoryItemRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      availableUnits: data.availableUnits.present
          ? data.availableUnits.value
          : this.availableUnits,
      totalUnits: data.totalUnits.present
          ? data.totalUnits.value
          : this.totalUnits,
      status: data.status.present ? data.status.value : this.status,
      qrCode: data.qrCode.present ? data.qrCode.value : this.qrCode,
      notes: data.notes.present ? data.notes.value : this.notes,
      billingMode: data.billingMode.present
          ? data.billingMode.value
          : this.billingMode,
      rateAmount: data.rateAmount.present
          ? data.rateAmount.value
          : this.rateAmount,
      lateFeePerDay: data.lateFeePerDay.present
          ? data.lateFeePerDay.value
          : this.lateFeePerDay,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventoryItemRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('availableUnits: $availableUnits, ')
          ..write('totalUnits: $totalUnits, ')
          ..write('status: $status, ')
          ..write('qrCode: $qrCode, ')
          ..write('notes: $notes, ')
          ..write('billingMode: $billingMode, ')
          ..write('rateAmount: $rateAmount, ')
          ..write('lateFeePerDay: $lateFeePerDay, ')
          ..write('currencyCode: $currencyCode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    category,
    availableUnits,
    totalUnits,
    status,
    qrCode,
    notes,
    billingMode,
    rateAmount,
    lateFeePerDay,
    currencyCode,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventoryItemRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.category == this.category &&
          other.availableUnits == this.availableUnits &&
          other.totalUnits == this.totalUnits &&
          other.status == this.status &&
          other.qrCode == this.qrCode &&
          other.notes == this.notes &&
          other.billingMode == this.billingMode &&
          other.rateAmount == this.rateAmount &&
          other.lateFeePerDay == this.lateFeePerDay &&
          other.currencyCode == this.currencyCode);
}

class InventoryItemsCompanion extends UpdateCompanion<InventoryItemRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> category;
  final Value<int> availableUnits;
  final Value<int> totalUnits;
  final Value<String> status;
  final Value<String> qrCode;
  final Value<String?> notes;
  final Value<String> billingMode;
  final Value<int> rateAmount;
  final Value<int> lateFeePerDay;
  final Value<String> currencyCode;
  final Value<int> rowid;
  const InventoryItemsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.availableUnits = const Value.absent(),
    this.totalUnits = const Value.absent(),
    this.status = const Value.absent(),
    this.qrCode = const Value.absent(),
    this.notes = const Value.absent(),
    this.billingMode = const Value.absent(),
    this.rateAmount = const Value.absent(),
    this.lateFeePerDay = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InventoryItemsCompanion.insert({
    required String id,
    required String name,
    required String category,
    required int availableUnits,
    required int totalUnits,
    required String status,
    required String qrCode,
    this.notes = const Value.absent(),
    this.billingMode = const Value.absent(),
    this.rateAmount = const Value.absent(),
    this.lateFeePerDay = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       category = Value(category),
       availableUnits = Value(availableUnits),
       totalUnits = Value(totalUnits),
       status = Value(status),
       qrCode = Value(qrCode);
  static Insertable<InventoryItemRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? category,
    Expression<int>? availableUnits,
    Expression<int>? totalUnits,
    Expression<String>? status,
    Expression<String>? qrCode,
    Expression<String>? notes,
    Expression<String>? billingMode,
    Expression<int>? rateAmount,
    Expression<int>? lateFeePerDay,
    Expression<String>? currencyCode,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (availableUnits != null) 'available_units': availableUnits,
      if (totalUnits != null) 'total_units': totalUnits,
      if (status != null) 'status': status,
      if (qrCode != null) 'qr_code': qrCode,
      if (notes != null) 'notes': notes,
      if (billingMode != null) 'billing_mode': billingMode,
      if (rateAmount != null) 'rate_amount': rateAmount,
      if (lateFeePerDay != null) 'late_fee_per_day': lateFeePerDay,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InventoryItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? category,
    Value<int>? availableUnits,
    Value<int>? totalUnits,
    Value<String>? status,
    Value<String>? qrCode,
    Value<String?>? notes,
    Value<String>? billingMode,
    Value<int>? rateAmount,
    Value<int>? lateFeePerDay,
    Value<String>? currencyCode,
    Value<int>? rowid,
  }) {
    return InventoryItemsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      availableUnits: availableUnits ?? this.availableUnits,
      totalUnits: totalUnits ?? this.totalUnits,
      status: status ?? this.status,
      qrCode: qrCode ?? this.qrCode,
      notes: notes ?? this.notes,
      billingMode: billingMode ?? this.billingMode,
      rateAmount: rateAmount ?? this.rateAmount,
      lateFeePerDay: lateFeePerDay ?? this.lateFeePerDay,
      currencyCode: currencyCode ?? this.currencyCode,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (availableUnits.present) {
      map['available_units'] = Variable<int>(availableUnits.value);
    }
    if (totalUnits.present) {
      map['total_units'] = Variable<int>(totalUnits.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (qrCode.present) {
      map['qr_code'] = Variable<String>(qrCode.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (billingMode.present) {
      map['billing_mode'] = Variable<String>(billingMode.value);
    }
    if (rateAmount.present) {
      map['rate_amount'] = Variable<int>(rateAmount.value);
    }
    if (lateFeePerDay.present) {
      map['late_fee_per_day'] = Variable<int>(lateFeePerDay.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventoryItemsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('availableUnits: $availableUnits, ')
          ..write('totalUnits: $totalUnits, ')
          ..write('status: $status, ')
          ..write('qrCode: $qrCode, ')
          ..write('notes: $notes, ')
          ..write('billingMode: $billingMode, ')
          ..write('rateAmount: $rateAmount, ')
          ..write('lateFeePerDay: $lateFeePerDay, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RentalsTable extends Rentals with TableInfo<$RentalsTable, RentalRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RentalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customerIdMeta = const VerificationMeta(
    'customerId',
  );
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
    'customer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<DateTime> dueAt = GeneratedColumn<DateTime>(
    'due_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _returnedAtMeta = const VerificationMeta(
    'returnedAt',
  );
  @override
  late final GeneratedColumn<DateTime> returnedAt = GeneratedColumn<DateTime>(
    'returned_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _qrCodeMeta = const VerificationMeta('qrCode');
  @override
  late final GeneratedColumn<String> qrCode = GeneratedColumn<String>(
    'qr_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nicknameMeta = const VerificationMeta(
    'nickname',
  );
  @override
  late final GeneratedColumn<String> nickname = GeneratedColumn<String>(
    'nickname',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _billingModeMeta = const VerificationMeta(
    'billingMode',
  );
  @override
  late final GeneratedColumn<String> billingMode = GeneratedColumn<String>(
    'billing_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('weekly'),
  );
  static const VerificationMeta _rateAmountMeta = const VerificationMeta(
    'rateAmount',
  );
  @override
  late final GeneratedColumn<int> rateAmount = GeneratedColumn<int>(
    'rate_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lateFeePerDayMeta = const VerificationMeta(
    'lateFeePerDay',
  );
  @override
  late final GeneratedColumn<int> lateFeePerDay = GeneratedColumn<int>(
    'late_fee_per_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _baseAmountMeta = const VerificationMeta(
    'baseAmount',
  );
  @override
  late final GeneratedColumn<int> baseAmount = GeneratedColumn<int>(
    'base_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lateAmountMeta = const VerificationMeta(
    'lateAmount',
  );
  @override
  late final GeneratedColumn<int> lateAmount = GeneratedColumn<int>(
    'late_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<int> totalAmount = GeneratedColumn<int>(
    'total_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _durationUnitsMeta = const VerificationMeta(
    'durationUnits',
  );
  @override
  late final GeneratedColumn<int> durationUnits = GeneratedColumn<int>(
    'duration_units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    customerId,
    startedAt,
    dueAt,
    returnedAt,
    qrCode,
    nickname,
    billingMode,
    rateAmount,
    lateFeePerDay,
    baseAmount,
    lateAmount,
    totalAmount,
    durationUnits,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rentals';
  @override
  VerificationContext validateIntegrity(
    Insertable<RentalRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
        _customerIdMeta,
        customerId.isAcceptableOrUnknown(data['customer_id']!, _customerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    } else if (isInserting) {
      context.missing(_dueAtMeta);
    }
    if (data.containsKey('returned_at')) {
      context.handle(
        _returnedAtMeta,
        returnedAt.isAcceptableOrUnknown(data['returned_at']!, _returnedAtMeta),
      );
    }
    if (data.containsKey('qr_code')) {
      context.handle(
        _qrCodeMeta,
        qrCode.isAcceptableOrUnknown(data['qr_code']!, _qrCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_qrCodeMeta);
    }
    if (data.containsKey('nickname')) {
      context.handle(
        _nicknameMeta,
        nickname.isAcceptableOrUnknown(data['nickname']!, _nicknameMeta),
      );
    }
    if (data.containsKey('billing_mode')) {
      context.handle(
        _billingModeMeta,
        billingMode.isAcceptableOrUnknown(
          data['billing_mode']!,
          _billingModeMeta,
        ),
      );
    }
    if (data.containsKey('rate_amount')) {
      context.handle(
        _rateAmountMeta,
        rateAmount.isAcceptableOrUnknown(data['rate_amount']!, _rateAmountMeta),
      );
    }
    if (data.containsKey('late_fee_per_day')) {
      context.handle(
        _lateFeePerDayMeta,
        lateFeePerDay.isAcceptableOrUnknown(
          data['late_fee_per_day']!,
          _lateFeePerDayMeta,
        ),
      );
    }
    if (data.containsKey('base_amount')) {
      context.handle(
        _baseAmountMeta,
        baseAmount.isAcceptableOrUnknown(data['base_amount']!, _baseAmountMeta),
      );
    }
    if (data.containsKey('late_amount')) {
      context.handle(
        _lateAmountMeta,
        lateAmount.isAcceptableOrUnknown(data['late_amount']!, _lateAmountMeta),
      );
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    }
    if (data.containsKey('duration_units')) {
      context.handle(
        _durationUnitsMeta,
        durationUnits.isAcceptableOrUnknown(
          data['duration_units']!,
          _durationUnitsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RentalRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RentalRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_at'],
      )!,
      returnedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}returned_at'],
      ),
      qrCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}qr_code'],
      )!,
      nickname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nickname'],
      ),
      billingMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}billing_mode'],
      )!,
      rateAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rate_amount'],
      )!,
      lateFeePerDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}late_fee_per_day'],
      )!,
      baseAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_amount'],
      )!,
      lateAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}late_amount'],
      )!,
      totalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_amount'],
      )!,
      durationUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_units'],
      )!,
    );
  }

  @override
  $RentalsTable createAlias(String alias) {
    return $RentalsTable(attachedDatabase, alias);
  }
}

class RentalRow extends DataClass implements Insertable<RentalRow> {
  final String id;
  final String customerId;
  final DateTime startedAt;
  final DateTime dueAt;
  final DateTime? returnedAt;
  final String qrCode;

  /// Per-rental display name (required when issuing to SELF Known).
  final String? nickname;

  /// Snapshot of billing at issue (`daily`/`weekly`/`monthly`/`fixed`/`custom`).
  final String billingMode;

  /// Snapshot rate in paise (primary/first line).
  final int rateAmount;

  /// Snapshot late fee per day in paise (sum of lines).
  final int lateFeePerDay;
  final int baseAmount;
  final int lateAmount;
  final int totalAmount;

  /// Chosen duration (e.g. 1 week → 1; fixed due-days still stored here).
  final int durationUnits;
  const RentalRow({
    required this.id,
    required this.customerId,
    required this.startedAt,
    required this.dueAt,
    this.returnedAt,
    required this.qrCode,
    this.nickname,
    required this.billingMode,
    required this.rateAmount,
    required this.lateFeePerDay,
    required this.baseAmount,
    required this.lateAmount,
    required this.totalAmount,
    required this.durationUnits,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['customer_id'] = Variable<String>(customerId);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['due_at'] = Variable<DateTime>(dueAt);
    if (!nullToAbsent || returnedAt != null) {
      map['returned_at'] = Variable<DateTime>(returnedAt);
    }
    map['qr_code'] = Variable<String>(qrCode);
    if (!nullToAbsent || nickname != null) {
      map['nickname'] = Variable<String>(nickname);
    }
    map['billing_mode'] = Variable<String>(billingMode);
    map['rate_amount'] = Variable<int>(rateAmount);
    map['late_fee_per_day'] = Variable<int>(lateFeePerDay);
    map['base_amount'] = Variable<int>(baseAmount);
    map['late_amount'] = Variable<int>(lateAmount);
    map['total_amount'] = Variable<int>(totalAmount);
    map['duration_units'] = Variable<int>(durationUnits);
    return map;
  }

  RentalsCompanion toCompanion(bool nullToAbsent) {
    return RentalsCompanion(
      id: Value(id),
      customerId: Value(customerId),
      startedAt: Value(startedAt),
      dueAt: Value(dueAt),
      returnedAt: returnedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(returnedAt),
      qrCode: Value(qrCode),
      nickname: nickname == null && nullToAbsent
          ? const Value.absent()
          : Value(nickname),
      billingMode: Value(billingMode),
      rateAmount: Value(rateAmount),
      lateFeePerDay: Value(lateFeePerDay),
      baseAmount: Value(baseAmount),
      lateAmount: Value(lateAmount),
      totalAmount: Value(totalAmount),
      durationUnits: Value(durationUnits),
    );
  }

  factory RentalRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RentalRow(
      id: serializer.fromJson<String>(json['id']),
      customerId: serializer.fromJson<String>(json['customerId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      dueAt: serializer.fromJson<DateTime>(json['dueAt']),
      returnedAt: serializer.fromJson<DateTime?>(json['returnedAt']),
      qrCode: serializer.fromJson<String>(json['qrCode']),
      nickname: serializer.fromJson<String?>(json['nickname']),
      billingMode: serializer.fromJson<String>(json['billingMode']),
      rateAmount: serializer.fromJson<int>(json['rateAmount']),
      lateFeePerDay: serializer.fromJson<int>(json['lateFeePerDay']),
      baseAmount: serializer.fromJson<int>(json['baseAmount']),
      lateAmount: serializer.fromJson<int>(json['lateAmount']),
      totalAmount: serializer.fromJson<int>(json['totalAmount']),
      durationUnits: serializer.fromJson<int>(json['durationUnits']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'customerId': serializer.toJson<String>(customerId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'dueAt': serializer.toJson<DateTime>(dueAt),
      'returnedAt': serializer.toJson<DateTime?>(returnedAt),
      'qrCode': serializer.toJson<String>(qrCode),
      'nickname': serializer.toJson<String?>(nickname),
      'billingMode': serializer.toJson<String>(billingMode),
      'rateAmount': serializer.toJson<int>(rateAmount),
      'lateFeePerDay': serializer.toJson<int>(lateFeePerDay),
      'baseAmount': serializer.toJson<int>(baseAmount),
      'lateAmount': serializer.toJson<int>(lateAmount),
      'totalAmount': serializer.toJson<int>(totalAmount),
      'durationUnits': serializer.toJson<int>(durationUnits),
    };
  }

  RentalRow copyWith({
    String? id,
    String? customerId,
    DateTime? startedAt,
    DateTime? dueAt,
    Value<DateTime?> returnedAt = const Value.absent(),
    String? qrCode,
    Value<String?> nickname = const Value.absent(),
    String? billingMode,
    int? rateAmount,
    int? lateFeePerDay,
    int? baseAmount,
    int? lateAmount,
    int? totalAmount,
    int? durationUnits,
  }) => RentalRow(
    id: id ?? this.id,
    customerId: customerId ?? this.customerId,
    startedAt: startedAt ?? this.startedAt,
    dueAt: dueAt ?? this.dueAt,
    returnedAt: returnedAt.present ? returnedAt.value : this.returnedAt,
    qrCode: qrCode ?? this.qrCode,
    nickname: nickname.present ? nickname.value : this.nickname,
    billingMode: billingMode ?? this.billingMode,
    rateAmount: rateAmount ?? this.rateAmount,
    lateFeePerDay: lateFeePerDay ?? this.lateFeePerDay,
    baseAmount: baseAmount ?? this.baseAmount,
    lateAmount: lateAmount ?? this.lateAmount,
    totalAmount: totalAmount ?? this.totalAmount,
    durationUnits: durationUnits ?? this.durationUnits,
  );
  RentalRow copyWithCompanion(RentalsCompanion data) {
    return RentalRow(
      id: data.id.present ? data.id.value : this.id,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      returnedAt: data.returnedAt.present
          ? data.returnedAt.value
          : this.returnedAt,
      qrCode: data.qrCode.present ? data.qrCode.value : this.qrCode,
      nickname: data.nickname.present ? data.nickname.value : this.nickname,
      billingMode: data.billingMode.present
          ? data.billingMode.value
          : this.billingMode,
      rateAmount: data.rateAmount.present
          ? data.rateAmount.value
          : this.rateAmount,
      lateFeePerDay: data.lateFeePerDay.present
          ? data.lateFeePerDay.value
          : this.lateFeePerDay,
      baseAmount: data.baseAmount.present
          ? data.baseAmount.value
          : this.baseAmount,
      lateAmount: data.lateAmount.present
          ? data.lateAmount.value
          : this.lateAmount,
      totalAmount: data.totalAmount.present
          ? data.totalAmount.value
          : this.totalAmount,
      durationUnits: data.durationUnits.present
          ? data.durationUnits.value
          : this.durationUnits,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RentalRow(')
          ..write('id: $id, ')
          ..write('customerId: $customerId, ')
          ..write('startedAt: $startedAt, ')
          ..write('dueAt: $dueAt, ')
          ..write('returnedAt: $returnedAt, ')
          ..write('qrCode: $qrCode, ')
          ..write('nickname: $nickname, ')
          ..write('billingMode: $billingMode, ')
          ..write('rateAmount: $rateAmount, ')
          ..write('lateFeePerDay: $lateFeePerDay, ')
          ..write('baseAmount: $baseAmount, ')
          ..write('lateAmount: $lateAmount, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('durationUnits: $durationUnits')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    customerId,
    startedAt,
    dueAt,
    returnedAt,
    qrCode,
    nickname,
    billingMode,
    rateAmount,
    lateFeePerDay,
    baseAmount,
    lateAmount,
    totalAmount,
    durationUnits,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RentalRow &&
          other.id == this.id &&
          other.customerId == this.customerId &&
          other.startedAt == this.startedAt &&
          other.dueAt == this.dueAt &&
          other.returnedAt == this.returnedAt &&
          other.qrCode == this.qrCode &&
          other.nickname == this.nickname &&
          other.billingMode == this.billingMode &&
          other.rateAmount == this.rateAmount &&
          other.lateFeePerDay == this.lateFeePerDay &&
          other.baseAmount == this.baseAmount &&
          other.lateAmount == this.lateAmount &&
          other.totalAmount == this.totalAmount &&
          other.durationUnits == this.durationUnits);
}

class RentalsCompanion extends UpdateCompanion<RentalRow> {
  final Value<String> id;
  final Value<String> customerId;
  final Value<DateTime> startedAt;
  final Value<DateTime> dueAt;
  final Value<DateTime?> returnedAt;
  final Value<String> qrCode;
  final Value<String?> nickname;
  final Value<String> billingMode;
  final Value<int> rateAmount;
  final Value<int> lateFeePerDay;
  final Value<int> baseAmount;
  final Value<int> lateAmount;
  final Value<int> totalAmount;
  final Value<int> durationUnits;
  final Value<int> rowid;
  const RentalsCompanion({
    this.id = const Value.absent(),
    this.customerId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.returnedAt = const Value.absent(),
    this.qrCode = const Value.absent(),
    this.nickname = const Value.absent(),
    this.billingMode = const Value.absent(),
    this.rateAmount = const Value.absent(),
    this.lateFeePerDay = const Value.absent(),
    this.baseAmount = const Value.absent(),
    this.lateAmount = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.durationUnits = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RentalsCompanion.insert({
    required String id,
    required String customerId,
    required DateTime startedAt,
    required DateTime dueAt,
    this.returnedAt = const Value.absent(),
    required String qrCode,
    this.nickname = const Value.absent(),
    this.billingMode = const Value.absent(),
    this.rateAmount = const Value.absent(),
    this.lateFeePerDay = const Value.absent(),
    this.baseAmount = const Value.absent(),
    this.lateAmount = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.durationUnits = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       customerId = Value(customerId),
       startedAt = Value(startedAt),
       dueAt = Value(dueAt),
       qrCode = Value(qrCode);
  static Insertable<RentalRow> custom({
    Expression<String>? id,
    Expression<String>? customerId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? dueAt,
    Expression<DateTime>? returnedAt,
    Expression<String>? qrCode,
    Expression<String>? nickname,
    Expression<String>? billingMode,
    Expression<int>? rateAmount,
    Expression<int>? lateFeePerDay,
    Expression<int>? baseAmount,
    Expression<int>? lateAmount,
    Expression<int>? totalAmount,
    Expression<int>? durationUnits,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (customerId != null) 'customer_id': customerId,
      if (startedAt != null) 'started_at': startedAt,
      if (dueAt != null) 'due_at': dueAt,
      if (returnedAt != null) 'returned_at': returnedAt,
      if (qrCode != null) 'qr_code': qrCode,
      if (nickname != null) 'nickname': nickname,
      if (billingMode != null) 'billing_mode': billingMode,
      if (rateAmount != null) 'rate_amount': rateAmount,
      if (lateFeePerDay != null) 'late_fee_per_day': lateFeePerDay,
      if (baseAmount != null) 'base_amount': baseAmount,
      if (lateAmount != null) 'late_amount': lateAmount,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (durationUnits != null) 'duration_units': durationUnits,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RentalsCompanion copyWith({
    Value<String>? id,
    Value<String>? customerId,
    Value<DateTime>? startedAt,
    Value<DateTime>? dueAt,
    Value<DateTime?>? returnedAt,
    Value<String>? qrCode,
    Value<String?>? nickname,
    Value<String>? billingMode,
    Value<int>? rateAmount,
    Value<int>? lateFeePerDay,
    Value<int>? baseAmount,
    Value<int>? lateAmount,
    Value<int>? totalAmount,
    Value<int>? durationUnits,
    Value<int>? rowid,
  }) {
    return RentalsCompanion(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      startedAt: startedAt ?? this.startedAt,
      dueAt: dueAt ?? this.dueAt,
      returnedAt: returnedAt ?? this.returnedAt,
      qrCode: qrCode ?? this.qrCode,
      nickname: nickname ?? this.nickname,
      billingMode: billingMode ?? this.billingMode,
      rateAmount: rateAmount ?? this.rateAmount,
      lateFeePerDay: lateFeePerDay ?? this.lateFeePerDay,
      baseAmount: baseAmount ?? this.baseAmount,
      lateAmount: lateAmount ?? this.lateAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      durationUnits: durationUnits ?? this.durationUnits,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<DateTime>(dueAt.value);
    }
    if (returnedAt.present) {
      map['returned_at'] = Variable<DateTime>(returnedAt.value);
    }
    if (qrCode.present) {
      map['qr_code'] = Variable<String>(qrCode.value);
    }
    if (nickname.present) {
      map['nickname'] = Variable<String>(nickname.value);
    }
    if (billingMode.present) {
      map['billing_mode'] = Variable<String>(billingMode.value);
    }
    if (rateAmount.present) {
      map['rate_amount'] = Variable<int>(rateAmount.value);
    }
    if (lateFeePerDay.present) {
      map['late_fee_per_day'] = Variable<int>(lateFeePerDay.value);
    }
    if (baseAmount.present) {
      map['base_amount'] = Variable<int>(baseAmount.value);
    }
    if (lateAmount.present) {
      map['late_amount'] = Variable<int>(lateAmount.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<int>(totalAmount.value);
    }
    if (durationUnits.present) {
      map['duration_units'] = Variable<int>(durationUnits.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RentalsCompanion(')
          ..write('id: $id, ')
          ..write('customerId: $customerId, ')
          ..write('startedAt: $startedAt, ')
          ..write('dueAt: $dueAt, ')
          ..write('returnedAt: $returnedAt, ')
          ..write('qrCode: $qrCode, ')
          ..write('nickname: $nickname, ')
          ..write('billingMode: $billingMode, ')
          ..write('rateAmount: $rateAmount, ')
          ..write('lateFeePerDay: $lateFeePerDay, ')
          ..write('baseAmount: $baseAmount, ')
          ..write('lateAmount: $lateAmount, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('durationUnits: $durationUnits, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RentalItemsTable extends RentalItems
    with TableInfo<$RentalItemsTable, RentalItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RentalItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rentalIdMeta = const VerificationMeta(
    'rentalId',
  );
  @override
  late final GeneratedColumn<String> rentalId = GeneratedColumn<String>(
    'rental_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _instanceNameMeta = const VerificationMeta(
    'instanceName',
  );
  @override
  late final GeneratedColumn<String> instanceName = GeneratedColumn<String>(
    'instance_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _shortCodeMeta = const VerificationMeta(
    'shortCode',
  );
  @override
  late final GeneratedColumn<String> shortCode = GeneratedColumn<String>(
    'short_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('LEGACY'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    rentalId,
    itemId,
    instanceName,
    shortCode,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rental_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<RentalItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('rental_id')) {
      context.handle(
        _rentalIdMeta,
        rentalId.isAcceptableOrUnknown(data['rental_id']!, _rentalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_rentalIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('instance_name')) {
      context.handle(
        _instanceNameMeta,
        instanceName.isAcceptableOrUnknown(
          data['instance_name']!,
          _instanceNameMeta,
        ),
      );
    }
    if (data.containsKey('short_code')) {
      context.handle(
        _shortCodeMeta,
        shortCode.isAcceptableOrUnknown(data['short_code']!, _shortCodeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {rentalId, itemId};
  @override
  RentalItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RentalItemRow(
      rentalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rental_id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      instanceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instance_name'],
      )!,
      shortCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}short_code'],
      )!,
    );
  }

  @override
  $RentalItemsTable createAlias(String alias) {
    return $RentalItemsTable(attachedDatabase, alias);
  }
}

class RentalItemRow extends DataClass implements Insertable<RentalItemRow> {
  final String rentalId;
  final String itemId;

  /// Copy/title for this issue (e.g. novel title); not inventory master.
  final String instanceName;

  /// Short tracking code unique among active rental lines (case-insensitive).
  final String shortCode;
  const RentalItemRow({
    required this.rentalId,
    required this.itemId,
    required this.instanceName,
    required this.shortCode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['rental_id'] = Variable<String>(rentalId);
    map['item_id'] = Variable<String>(itemId);
    map['instance_name'] = Variable<String>(instanceName);
    map['short_code'] = Variable<String>(shortCode);
    return map;
  }

  RentalItemsCompanion toCompanion(bool nullToAbsent) {
    return RentalItemsCompanion(
      rentalId: Value(rentalId),
      itemId: Value(itemId),
      instanceName: Value(instanceName),
      shortCode: Value(shortCode),
    );
  }

  factory RentalItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RentalItemRow(
      rentalId: serializer.fromJson<String>(json['rentalId']),
      itemId: serializer.fromJson<String>(json['itemId']),
      instanceName: serializer.fromJson<String>(json['instanceName']),
      shortCode: serializer.fromJson<String>(json['shortCode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rentalId': serializer.toJson<String>(rentalId),
      'itemId': serializer.toJson<String>(itemId),
      'instanceName': serializer.toJson<String>(instanceName),
      'shortCode': serializer.toJson<String>(shortCode),
    };
  }

  RentalItemRow copyWith({
    String? rentalId,
    String? itemId,
    String? instanceName,
    String? shortCode,
  }) => RentalItemRow(
    rentalId: rentalId ?? this.rentalId,
    itemId: itemId ?? this.itemId,
    instanceName: instanceName ?? this.instanceName,
    shortCode: shortCode ?? this.shortCode,
  );
  RentalItemRow copyWithCompanion(RentalItemsCompanion data) {
    return RentalItemRow(
      rentalId: data.rentalId.present ? data.rentalId.value : this.rentalId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      instanceName: data.instanceName.present
          ? data.instanceName.value
          : this.instanceName,
      shortCode: data.shortCode.present ? data.shortCode.value : this.shortCode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RentalItemRow(')
          ..write('rentalId: $rentalId, ')
          ..write('itemId: $itemId, ')
          ..write('instanceName: $instanceName, ')
          ..write('shortCode: $shortCode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(rentalId, itemId, instanceName, shortCode);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RentalItemRow &&
          other.rentalId == this.rentalId &&
          other.itemId == this.itemId &&
          other.instanceName == this.instanceName &&
          other.shortCode == this.shortCode);
}

class RentalItemsCompanion extends UpdateCompanion<RentalItemRow> {
  final Value<String> rentalId;
  final Value<String> itemId;
  final Value<String> instanceName;
  final Value<String> shortCode;
  final Value<int> rowid;
  const RentalItemsCompanion({
    this.rentalId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.instanceName = const Value.absent(),
    this.shortCode = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RentalItemsCompanion.insert({
    required String rentalId,
    required String itemId,
    this.instanceName = const Value.absent(),
    this.shortCode = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : rentalId = Value(rentalId),
       itemId = Value(itemId);
  static Insertable<RentalItemRow> custom({
    Expression<String>? rentalId,
    Expression<String>? itemId,
    Expression<String>? instanceName,
    Expression<String>? shortCode,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (rentalId != null) 'rental_id': rentalId,
      if (itemId != null) 'item_id': itemId,
      if (instanceName != null) 'instance_name': instanceName,
      if (shortCode != null) 'short_code': shortCode,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RentalItemsCompanion copyWith({
    Value<String>? rentalId,
    Value<String>? itemId,
    Value<String>? instanceName,
    Value<String>? shortCode,
    Value<int>? rowid,
  }) {
    return RentalItemsCompanion(
      rentalId: rentalId ?? this.rentalId,
      itemId: itemId ?? this.itemId,
      instanceName: instanceName ?? this.instanceName,
      shortCode: shortCode ?? this.shortCode,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rentalId.present) {
      map['rental_id'] = Variable<String>(rentalId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (instanceName.present) {
      map['instance_name'] = Variable<String>(instanceName.value);
    }
    if (shortCode.present) {
      map['short_code'] = Variable<String>(shortCode.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RentalItemsCompanion(')
          ..write('rentalId: $rentalId, ')
          ..write('itemId: $itemId, ')
          ..write('instanceName: $instanceName, ')
          ..write('shortCode: $shortCode, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RentalEventsTable extends RentalEvents
    with TableInfo<$RentalEventsTable, RentalEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RentalEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _rentalIdMeta = const VerificationMeta(
    'rentalId',
  );
  @override
  late final GeneratedColumn<String> rentalId = GeneratedColumn<String>(
    'rental_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subtitleMeta = const VerificationMeta(
    'subtitle',
  );
  @override
  late final GeneratedColumn<String> subtitle = GeneratedColumn<String>(
    'subtitle',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, rentalId, title, subtitle, at];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rental_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<RentalEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('rental_id')) {
      context.handle(
        _rentalIdMeta,
        rentalId.isAcceptableOrUnknown(data['rental_id']!, _rentalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_rentalIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('subtitle')) {
      context.handle(
        _subtitleMeta,
        subtitle.isAcceptableOrUnknown(data['subtitle']!, _subtitleMeta),
      );
    } else if (isInserting) {
      context.missing(_subtitleMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RentalEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RentalEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      rentalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rental_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      subtitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtitle'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
    );
  }

  @override
  $RentalEventsTable createAlias(String alias) {
    return $RentalEventsTable(attachedDatabase, alias);
  }
}

class RentalEventRow extends DataClass implements Insertable<RentalEventRow> {
  final int id;
  final String rentalId;
  final String title;
  final String subtitle;
  final DateTime at;
  const RentalEventRow({
    required this.id,
    required this.rentalId,
    required this.title,
    required this.subtitle,
    required this.at,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['rental_id'] = Variable<String>(rentalId);
    map['title'] = Variable<String>(title);
    map['subtitle'] = Variable<String>(subtitle);
    map['at'] = Variable<DateTime>(at);
    return map;
  }

  RentalEventsCompanion toCompanion(bool nullToAbsent) {
    return RentalEventsCompanion(
      id: Value(id),
      rentalId: Value(rentalId),
      title: Value(title),
      subtitle: Value(subtitle),
      at: Value(at),
    );
  }

  factory RentalEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RentalEventRow(
      id: serializer.fromJson<int>(json['id']),
      rentalId: serializer.fromJson<String>(json['rentalId']),
      title: serializer.fromJson<String>(json['title']),
      subtitle: serializer.fromJson<String>(json['subtitle']),
      at: serializer.fromJson<DateTime>(json['at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'rentalId': serializer.toJson<String>(rentalId),
      'title': serializer.toJson<String>(title),
      'subtitle': serializer.toJson<String>(subtitle),
      'at': serializer.toJson<DateTime>(at),
    };
  }

  RentalEventRow copyWith({
    int? id,
    String? rentalId,
    String? title,
    String? subtitle,
    DateTime? at,
  }) => RentalEventRow(
    id: id ?? this.id,
    rentalId: rentalId ?? this.rentalId,
    title: title ?? this.title,
    subtitle: subtitle ?? this.subtitle,
    at: at ?? this.at,
  );
  RentalEventRow copyWithCompanion(RentalEventsCompanion data) {
    return RentalEventRow(
      id: data.id.present ? data.id.value : this.id,
      rentalId: data.rentalId.present ? data.rentalId.value : this.rentalId,
      title: data.title.present ? data.title.value : this.title,
      subtitle: data.subtitle.present ? data.subtitle.value : this.subtitle,
      at: data.at.present ? data.at.value : this.at,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RentalEventRow(')
          ..write('id: $id, ')
          ..write('rentalId: $rentalId, ')
          ..write('title: $title, ')
          ..write('subtitle: $subtitle, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, rentalId, title, subtitle, at);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RentalEventRow &&
          other.id == this.id &&
          other.rentalId == this.rentalId &&
          other.title == this.title &&
          other.subtitle == this.subtitle &&
          other.at == this.at);
}

class RentalEventsCompanion extends UpdateCompanion<RentalEventRow> {
  final Value<int> id;
  final Value<String> rentalId;
  final Value<String> title;
  final Value<String> subtitle;
  final Value<DateTime> at;
  const RentalEventsCompanion({
    this.id = const Value.absent(),
    this.rentalId = const Value.absent(),
    this.title = const Value.absent(),
    this.subtitle = const Value.absent(),
    this.at = const Value.absent(),
  });
  RentalEventsCompanion.insert({
    this.id = const Value.absent(),
    required String rentalId,
    required String title,
    required String subtitle,
    required DateTime at,
  }) : rentalId = Value(rentalId),
       title = Value(title),
       subtitle = Value(subtitle),
       at = Value(at);
  static Insertable<RentalEventRow> custom({
    Expression<int>? id,
    Expression<String>? rentalId,
    Expression<String>? title,
    Expression<String>? subtitle,
    Expression<DateTime>? at,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (rentalId != null) 'rental_id': rentalId,
      if (title != null) 'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      if (at != null) 'at': at,
    });
  }

  RentalEventsCompanion copyWith({
    Value<int>? id,
    Value<String>? rentalId,
    Value<String>? title,
    Value<String>? subtitle,
    Value<DateTime>? at,
  }) {
    return RentalEventsCompanion(
      id: id ?? this.id,
      rentalId: rentalId ?? this.rentalId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      at: at ?? this.at,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (rentalId.present) {
      map['rental_id'] = Variable<String>(rentalId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (subtitle.present) {
      map['subtitle'] = Variable<String>(subtitle.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RentalEventsCompanion(')
          ..write('id: $id, ')
          ..write('rentalId: $rentalId, ')
          ..write('title: $title, ')
          ..write('subtitle: $subtitle, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }
}

class $AppMetaTable extends AppMeta with TableInfo<$AppMetaTable, AppMetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppMetaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppMetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppMetaRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppMetaTable createAlias(String alias) {
    return $AppMetaTable(attachedDatabase, alias);
  }
}

class AppMetaRow extends DataClass implements Insertable<AppMetaRow> {
  final String key;
  final String value;
  const AppMetaRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppMetaCompanion toCompanion(bool nullToAbsent) {
    return AppMetaCompanion(key: Value(key), value: Value(value));
  }

  factory AppMetaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppMetaRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppMetaRow copyWith({String? key, String? value}) =>
      AppMetaRow(key: key ?? this.key, value: value ?? this.value);
  AppMetaRow copyWithCompanion(AppMetaCompanion data) {
    return AppMetaRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppMetaRow &&
          other.key == this.key &&
          other.value == this.value);
}

class AppMetaCompanion extends UpdateCompanion<AppMetaRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppMetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppMetaRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppMetaCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppMetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CustomersTable customers = $CustomersTable(this);
  late final $InventoryItemsTable inventoryItems = $InventoryItemsTable(this);
  late final $RentalsTable rentals = $RentalsTable(this);
  late final $RentalItemsTable rentalItems = $RentalItemsTable(this);
  late final $RentalEventsTable rentalEvents = $RentalEventsTable(this);
  late final $AppMetaTable appMeta = $AppMetaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    customers,
    inventoryItems,
    rentals,
    rentalItems,
    rentalEvents,
    appMeta,
  ];
}

typedef $$CustomersTableCreateCompanionBuilder =
    CustomersCompanion Function({
      required String id,
      required String name,
      required String phone,
      Value<bool> isTrusted,
      required String qrCode,
      Value<int> rowid,
    });
typedef $$CustomersTableUpdateCompanionBuilder =
    CustomersCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> phone,
      Value<bool> isTrusted,
      Value<String> qrCode,
      Value<int> rowid,
    });

class $$CustomersTableFilterComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isTrusted => $composableBuilder(
    column: $table.isTrusted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get qrCode => $composableBuilder(
    column: $table.qrCode,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CustomersTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isTrusted => $composableBuilder(
    column: $table.isTrusted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get qrCode => $composableBuilder(
    column: $table.qrCode,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<bool> get isTrusted =>
      $composableBuilder(column: $table.isTrusted, builder: (column) => column);

  GeneratedColumn<String> get qrCode =>
      $composableBuilder(column: $table.qrCode, builder: (column) => column);
}

class $$CustomersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomersTable,
          CustomerRow,
          $$CustomersTableFilterComposer,
          $$CustomersTableOrderingComposer,
          $$CustomersTableAnnotationComposer,
          $$CustomersTableCreateCompanionBuilder,
          $$CustomersTableUpdateCompanionBuilder,
          (
            CustomerRow,
            BaseReferences<_$AppDatabase, $CustomersTable, CustomerRow>,
          ),
          CustomerRow,
          PrefetchHooks Function()
        > {
  $$CustomersTableTableManager(_$AppDatabase db, $CustomersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<bool> isTrusted = const Value.absent(),
                Value<String> qrCode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomersCompanion(
                id: id,
                name: name,
                phone: phone,
                isTrusted: isTrusted,
                qrCode: qrCode,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String phone,
                Value<bool> isTrusted = const Value.absent(),
                required String qrCode,
                Value<int> rowid = const Value.absent(),
              }) => CustomersCompanion.insert(
                id: id,
                name: name,
                phone: phone,
                isTrusted: isTrusted,
                qrCode: qrCode,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomersTable,
      CustomerRow,
      $$CustomersTableFilterComposer,
      $$CustomersTableOrderingComposer,
      $$CustomersTableAnnotationComposer,
      $$CustomersTableCreateCompanionBuilder,
      $$CustomersTableUpdateCompanionBuilder,
      (
        CustomerRow,
        BaseReferences<_$AppDatabase, $CustomersTable, CustomerRow>,
      ),
      CustomerRow,
      PrefetchHooks Function()
    >;
typedef $$InventoryItemsTableCreateCompanionBuilder =
    InventoryItemsCompanion Function({
      required String id,
      required String name,
      required String category,
      required int availableUnits,
      required int totalUnits,
      required String status,
      required String qrCode,
      Value<String?> notes,
      Value<String> billingMode,
      Value<int> rateAmount,
      Value<int> lateFeePerDay,
      Value<String> currencyCode,
      Value<int> rowid,
    });
typedef $$InventoryItemsTableUpdateCompanionBuilder =
    InventoryItemsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> category,
      Value<int> availableUnits,
      Value<int> totalUnits,
      Value<String> status,
      Value<String> qrCode,
      Value<String?> notes,
      Value<String> billingMode,
      Value<int> rateAmount,
      Value<int> lateFeePerDay,
      Value<String> currencyCode,
      Value<int> rowid,
    });

class $$InventoryItemsTableFilterComposer
    extends Composer<_$AppDatabase, $InventoryItemsTable> {
  $$InventoryItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get availableUnits => $composableBuilder(
    column: $table.availableUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalUnits => $composableBuilder(
    column: $table.totalUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get qrCode => $composableBuilder(
    column: $table.qrCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get billingMode => $composableBuilder(
    column: $table.billingMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rateAmount => $composableBuilder(
    column: $table.rateAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lateFeePerDay => $composableBuilder(
    column: $table.lateFeePerDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InventoryItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $InventoryItemsTable> {
  $$InventoryItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get availableUnits => $composableBuilder(
    column: $table.availableUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalUnits => $composableBuilder(
    column: $table.totalUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get qrCode => $composableBuilder(
    column: $table.qrCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get billingMode => $composableBuilder(
    column: $table.billingMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rateAmount => $composableBuilder(
    column: $table.rateAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lateFeePerDay => $composableBuilder(
    column: $table.lateFeePerDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InventoryItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InventoryItemsTable> {
  $$InventoryItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get availableUnits => $composableBuilder(
    column: $table.availableUnits,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalUnits => $composableBuilder(
    column: $table.totalUnits,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get qrCode =>
      $composableBuilder(column: $table.qrCode, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get billingMode => $composableBuilder(
    column: $table.billingMode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rateAmount => $composableBuilder(
    column: $table.rateAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lateFeePerDay => $composableBuilder(
    column: $table.lateFeePerDay,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );
}

class $$InventoryItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InventoryItemsTable,
          InventoryItemRow,
          $$InventoryItemsTableFilterComposer,
          $$InventoryItemsTableOrderingComposer,
          $$InventoryItemsTableAnnotationComposer,
          $$InventoryItemsTableCreateCompanionBuilder,
          $$InventoryItemsTableUpdateCompanionBuilder,
          (
            InventoryItemRow,
            BaseReferences<
              _$AppDatabase,
              $InventoryItemsTable,
              InventoryItemRow
            >,
          ),
          InventoryItemRow,
          PrefetchHooks Function()
        > {
  $$InventoryItemsTableTableManager(
    _$AppDatabase db,
    $InventoryItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InventoryItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InventoryItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InventoryItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> availableUnits = const Value.absent(),
                Value<int> totalUnits = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> qrCode = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> billingMode = const Value.absent(),
                Value<int> rateAmount = const Value.absent(),
                Value<int> lateFeePerDay = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InventoryItemsCompanion(
                id: id,
                name: name,
                category: category,
                availableUnits: availableUnits,
                totalUnits: totalUnits,
                status: status,
                qrCode: qrCode,
                notes: notes,
                billingMode: billingMode,
                rateAmount: rateAmount,
                lateFeePerDay: lateFeePerDay,
                currencyCode: currencyCode,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String category,
                required int availableUnits,
                required int totalUnits,
                required String status,
                required String qrCode,
                Value<String?> notes = const Value.absent(),
                Value<String> billingMode = const Value.absent(),
                Value<int> rateAmount = const Value.absent(),
                Value<int> lateFeePerDay = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InventoryItemsCompanion.insert(
                id: id,
                name: name,
                category: category,
                availableUnits: availableUnits,
                totalUnits: totalUnits,
                status: status,
                qrCode: qrCode,
                notes: notes,
                billingMode: billingMode,
                rateAmount: rateAmount,
                lateFeePerDay: lateFeePerDay,
                currencyCode: currencyCode,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InventoryItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InventoryItemsTable,
      InventoryItemRow,
      $$InventoryItemsTableFilterComposer,
      $$InventoryItemsTableOrderingComposer,
      $$InventoryItemsTableAnnotationComposer,
      $$InventoryItemsTableCreateCompanionBuilder,
      $$InventoryItemsTableUpdateCompanionBuilder,
      (
        InventoryItemRow,
        BaseReferences<_$AppDatabase, $InventoryItemsTable, InventoryItemRow>,
      ),
      InventoryItemRow,
      PrefetchHooks Function()
    >;
typedef $$RentalsTableCreateCompanionBuilder =
    RentalsCompanion Function({
      required String id,
      required String customerId,
      required DateTime startedAt,
      required DateTime dueAt,
      Value<DateTime?> returnedAt,
      required String qrCode,
      Value<String?> nickname,
      Value<String> billingMode,
      Value<int> rateAmount,
      Value<int> lateFeePerDay,
      Value<int> baseAmount,
      Value<int> lateAmount,
      Value<int> totalAmount,
      Value<int> durationUnits,
      Value<int> rowid,
    });
typedef $$RentalsTableUpdateCompanionBuilder =
    RentalsCompanion Function({
      Value<String> id,
      Value<String> customerId,
      Value<DateTime> startedAt,
      Value<DateTime> dueAt,
      Value<DateTime?> returnedAt,
      Value<String> qrCode,
      Value<String?> nickname,
      Value<String> billingMode,
      Value<int> rateAmount,
      Value<int> lateFeePerDay,
      Value<int> baseAmount,
      Value<int> lateAmount,
      Value<int> totalAmount,
      Value<int> durationUnits,
      Value<int> rowid,
    });

class $$RentalsTableFilterComposer
    extends Composer<_$AppDatabase, $RentalsTable> {
  $$RentalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get returnedAt => $composableBuilder(
    column: $table.returnedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get qrCode => $composableBuilder(
    column: $table.qrCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get billingMode => $composableBuilder(
    column: $table.billingMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rateAmount => $composableBuilder(
    column: $table.rateAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lateFeePerDay => $composableBuilder(
    column: $table.lateFeePerDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseAmount => $composableBuilder(
    column: $table.baseAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lateAmount => $composableBuilder(
    column: $table.lateAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationUnits => $composableBuilder(
    column: $table.durationUnits,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RentalsTableOrderingComposer
    extends Composer<_$AppDatabase, $RentalsTable> {
  $$RentalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get returnedAt => $composableBuilder(
    column: $table.returnedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get qrCode => $composableBuilder(
    column: $table.qrCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get billingMode => $composableBuilder(
    column: $table.billingMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rateAmount => $composableBuilder(
    column: $table.rateAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lateFeePerDay => $composableBuilder(
    column: $table.lateFeePerDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseAmount => $composableBuilder(
    column: $table.baseAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lateAmount => $composableBuilder(
    column: $table.lateAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationUnits => $composableBuilder(
    column: $table.durationUnits,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RentalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RentalsTable> {
  $$RentalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get customerId => $composableBuilder(
    column: $table.customerId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<DateTime> get returnedAt => $composableBuilder(
    column: $table.returnedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get qrCode =>
      $composableBuilder(column: $table.qrCode, builder: (column) => column);

  GeneratedColumn<String> get nickname =>
      $composableBuilder(column: $table.nickname, builder: (column) => column);

  GeneratedColumn<String> get billingMode => $composableBuilder(
    column: $table.billingMode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rateAmount => $composableBuilder(
    column: $table.rateAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lateFeePerDay => $composableBuilder(
    column: $table.lateFeePerDay,
    builder: (column) => column,
  );

  GeneratedColumn<int> get baseAmount => $composableBuilder(
    column: $table.baseAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lateAmount => $composableBuilder(
    column: $table.lateAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationUnits => $composableBuilder(
    column: $table.durationUnits,
    builder: (column) => column,
  );
}

class $$RentalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RentalsTable,
          RentalRow,
          $$RentalsTableFilterComposer,
          $$RentalsTableOrderingComposer,
          $$RentalsTableAnnotationComposer,
          $$RentalsTableCreateCompanionBuilder,
          $$RentalsTableUpdateCompanionBuilder,
          (RentalRow, BaseReferences<_$AppDatabase, $RentalsTable, RentalRow>),
          RentalRow,
          PrefetchHooks Function()
        > {
  $$RentalsTableTableManager(_$AppDatabase db, $RentalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RentalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RentalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RentalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> customerId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime> dueAt = const Value.absent(),
                Value<DateTime?> returnedAt = const Value.absent(),
                Value<String> qrCode = const Value.absent(),
                Value<String?> nickname = const Value.absent(),
                Value<String> billingMode = const Value.absent(),
                Value<int> rateAmount = const Value.absent(),
                Value<int> lateFeePerDay = const Value.absent(),
                Value<int> baseAmount = const Value.absent(),
                Value<int> lateAmount = const Value.absent(),
                Value<int> totalAmount = const Value.absent(),
                Value<int> durationUnits = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RentalsCompanion(
                id: id,
                customerId: customerId,
                startedAt: startedAt,
                dueAt: dueAt,
                returnedAt: returnedAt,
                qrCode: qrCode,
                nickname: nickname,
                billingMode: billingMode,
                rateAmount: rateAmount,
                lateFeePerDay: lateFeePerDay,
                baseAmount: baseAmount,
                lateAmount: lateAmount,
                totalAmount: totalAmount,
                durationUnits: durationUnits,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String customerId,
                required DateTime startedAt,
                required DateTime dueAt,
                Value<DateTime?> returnedAt = const Value.absent(),
                required String qrCode,
                Value<String?> nickname = const Value.absent(),
                Value<String> billingMode = const Value.absent(),
                Value<int> rateAmount = const Value.absent(),
                Value<int> lateFeePerDay = const Value.absent(),
                Value<int> baseAmount = const Value.absent(),
                Value<int> lateAmount = const Value.absent(),
                Value<int> totalAmount = const Value.absent(),
                Value<int> durationUnits = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RentalsCompanion.insert(
                id: id,
                customerId: customerId,
                startedAt: startedAt,
                dueAt: dueAt,
                returnedAt: returnedAt,
                qrCode: qrCode,
                nickname: nickname,
                billingMode: billingMode,
                rateAmount: rateAmount,
                lateFeePerDay: lateFeePerDay,
                baseAmount: baseAmount,
                lateAmount: lateAmount,
                totalAmount: totalAmount,
                durationUnits: durationUnits,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RentalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RentalsTable,
      RentalRow,
      $$RentalsTableFilterComposer,
      $$RentalsTableOrderingComposer,
      $$RentalsTableAnnotationComposer,
      $$RentalsTableCreateCompanionBuilder,
      $$RentalsTableUpdateCompanionBuilder,
      (RentalRow, BaseReferences<_$AppDatabase, $RentalsTable, RentalRow>),
      RentalRow,
      PrefetchHooks Function()
    >;
typedef $$RentalItemsTableCreateCompanionBuilder =
    RentalItemsCompanion Function({
      required String rentalId,
      required String itemId,
      Value<String> instanceName,
      Value<String> shortCode,
      Value<int> rowid,
    });
typedef $$RentalItemsTableUpdateCompanionBuilder =
    RentalItemsCompanion Function({
      Value<String> rentalId,
      Value<String> itemId,
      Value<String> instanceName,
      Value<String> shortCode,
      Value<int> rowid,
    });

class $$RentalItemsTableFilterComposer
    extends Composer<_$AppDatabase, $RentalItemsTable> {
  $$RentalItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get rentalId => $composableBuilder(
    column: $table.rentalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get instanceName => $composableBuilder(
    column: $table.instanceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shortCode => $composableBuilder(
    column: $table.shortCode,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RentalItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $RentalItemsTable> {
  $$RentalItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get rentalId => $composableBuilder(
    column: $table.rentalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get instanceName => $composableBuilder(
    column: $table.instanceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shortCode => $composableBuilder(
    column: $table.shortCode,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RentalItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RentalItemsTable> {
  $$RentalItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get rentalId =>
      $composableBuilder(column: $table.rentalId, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get instanceName => $composableBuilder(
    column: $table.instanceName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get shortCode =>
      $composableBuilder(column: $table.shortCode, builder: (column) => column);
}

class $$RentalItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RentalItemsTable,
          RentalItemRow,
          $$RentalItemsTableFilterComposer,
          $$RentalItemsTableOrderingComposer,
          $$RentalItemsTableAnnotationComposer,
          $$RentalItemsTableCreateCompanionBuilder,
          $$RentalItemsTableUpdateCompanionBuilder,
          (
            RentalItemRow,
            BaseReferences<_$AppDatabase, $RentalItemsTable, RentalItemRow>,
          ),
          RentalItemRow,
          PrefetchHooks Function()
        > {
  $$RentalItemsTableTableManager(_$AppDatabase db, $RentalItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RentalItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RentalItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RentalItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> rentalId = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> instanceName = const Value.absent(),
                Value<String> shortCode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RentalItemsCompanion(
                rentalId: rentalId,
                itemId: itemId,
                instanceName: instanceName,
                shortCode: shortCode,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String rentalId,
                required String itemId,
                Value<String> instanceName = const Value.absent(),
                Value<String> shortCode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RentalItemsCompanion.insert(
                rentalId: rentalId,
                itemId: itemId,
                instanceName: instanceName,
                shortCode: shortCode,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RentalItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RentalItemsTable,
      RentalItemRow,
      $$RentalItemsTableFilterComposer,
      $$RentalItemsTableOrderingComposer,
      $$RentalItemsTableAnnotationComposer,
      $$RentalItemsTableCreateCompanionBuilder,
      $$RentalItemsTableUpdateCompanionBuilder,
      (
        RentalItemRow,
        BaseReferences<_$AppDatabase, $RentalItemsTable, RentalItemRow>,
      ),
      RentalItemRow,
      PrefetchHooks Function()
    >;
typedef $$RentalEventsTableCreateCompanionBuilder =
    RentalEventsCompanion Function({
      Value<int> id,
      required String rentalId,
      required String title,
      required String subtitle,
      required DateTime at,
    });
typedef $$RentalEventsTableUpdateCompanionBuilder =
    RentalEventsCompanion Function({
      Value<int> id,
      Value<String> rentalId,
      Value<String> title,
      Value<String> subtitle,
      Value<DateTime> at,
    });

class $$RentalEventsTableFilterComposer
    extends Composer<_$AppDatabase, $RentalEventsTable> {
  $$RentalEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rentalId => $composableBuilder(
    column: $table.rentalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RentalEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $RentalEventsTable> {
  $$RentalEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rentalId => $composableBuilder(
    column: $table.rentalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RentalEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RentalEventsTable> {
  $$RentalEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get rentalId =>
      $composableBuilder(column: $table.rentalId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get subtitle =>
      $composableBuilder(column: $table.subtitle, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);
}

class $$RentalEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RentalEventsTable,
          RentalEventRow,
          $$RentalEventsTableFilterComposer,
          $$RentalEventsTableOrderingComposer,
          $$RentalEventsTableAnnotationComposer,
          $$RentalEventsTableCreateCompanionBuilder,
          $$RentalEventsTableUpdateCompanionBuilder,
          (
            RentalEventRow,
            BaseReferences<_$AppDatabase, $RentalEventsTable, RentalEventRow>,
          ),
          RentalEventRow,
          PrefetchHooks Function()
        > {
  $$RentalEventsTableTableManager(_$AppDatabase db, $RentalEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RentalEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RentalEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RentalEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> rentalId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> subtitle = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
              }) => RentalEventsCompanion(
                id: id,
                rentalId: rentalId,
                title: title,
                subtitle: subtitle,
                at: at,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String rentalId,
                required String title,
                required String subtitle,
                required DateTime at,
              }) => RentalEventsCompanion.insert(
                id: id,
                rentalId: rentalId,
                title: title,
                subtitle: subtitle,
                at: at,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RentalEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RentalEventsTable,
      RentalEventRow,
      $$RentalEventsTableFilterComposer,
      $$RentalEventsTableOrderingComposer,
      $$RentalEventsTableAnnotationComposer,
      $$RentalEventsTableCreateCompanionBuilder,
      $$RentalEventsTableUpdateCompanionBuilder,
      (
        RentalEventRow,
        BaseReferences<_$AppDatabase, $RentalEventsTable, RentalEventRow>,
      ),
      RentalEventRow,
      PrefetchHooks Function()
    >;
typedef $$AppMetaTableCreateCompanionBuilder =
    AppMetaCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppMetaTableUpdateCompanionBuilder =
    AppMetaCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppMetaTableFilterComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppMetaTable> {
  $$AppMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppMetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppMetaTable,
          AppMetaRow,
          $$AppMetaTableFilterComposer,
          $$AppMetaTableOrderingComposer,
          $$AppMetaTableAnnotationComposer,
          $$AppMetaTableCreateCompanionBuilder,
          $$AppMetaTableUpdateCompanionBuilder,
          (
            AppMetaRow,
            BaseReferences<_$AppDatabase, $AppMetaTable, AppMetaRow>,
          ),
          AppMetaRow,
          PrefetchHooks Function()
        > {
  $$AppMetaTableTableManager(_$AppDatabase db, $AppMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppMetaCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) =>
                  AppMetaCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppMetaTable,
      AppMetaRow,
      $$AppMetaTableFilterComposer,
      $$AppMetaTableOrderingComposer,
      $$AppMetaTableAnnotationComposer,
      $$AppMetaTableCreateCompanionBuilder,
      $$AppMetaTableUpdateCompanionBuilder,
      (AppMetaRow, BaseReferences<_$AppDatabase, $AppMetaTable, AppMetaRow>),
      AppMetaRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db, _db.customers);
  $$InventoryItemsTableTableManager get inventoryItems =>
      $$InventoryItemsTableTableManager(_db, _db.inventoryItems);
  $$RentalsTableTableManager get rentals =>
      $$RentalsTableTableManager(_db, _db.rentals);
  $$RentalItemsTableTableManager get rentalItems =>
      $$RentalItemsTableTableManager(_db, _db.rentalItems);
  $$RentalEventsTableTableManager get rentalEvents =>
      $$RentalEventsTableTableManager(_db, _db.rentalEvents);
  $$AppMetaTableTableManager get appMeta =>
      $$AppMetaTableTableManager(_db, _db.appMeta);
}
