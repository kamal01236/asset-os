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
  static const VerificationMeta _depositBalanceMeta = const VerificationMeta(
    'depositBalance',
  );
  @override
  late final GeneratedColumn<int> depositBalance = GeneratedColumn<int>(
    'deposit_balance',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    phone,
    isTrusted,
    qrCode,
    depositBalance,
  ];
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
    if (data.containsKey('deposit_balance')) {
      context.handle(
        _depositBalanceMeta,
        depositBalance.isAcceptableOrUnknown(
          data['deposit_balance']!,
          _depositBalanceMeta,
        ),
      );
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
      depositBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deposit_balance'],
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

  /// Wallet deposit balance in paise.
  final int depositBalance;
  const CustomerRow({
    required this.id,
    required this.name,
    required this.phone,
    required this.isTrusted,
    required this.qrCode,
    required this.depositBalance,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['phone'] = Variable<String>(phone);
    map['is_trusted'] = Variable<bool>(isTrusted);
    map['qr_code'] = Variable<String>(qrCode);
    map['deposit_balance'] = Variable<int>(depositBalance);
    return map;
  }

  CustomersCompanion toCompanion(bool nullToAbsent) {
    return CustomersCompanion(
      id: Value(id),
      name: Value(name),
      phone: Value(phone),
      isTrusted: Value(isTrusted),
      qrCode: Value(qrCode),
      depositBalance: Value(depositBalance),
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
      depositBalance: serializer.fromJson<int>(json['depositBalance']),
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
      'depositBalance': serializer.toJson<int>(depositBalance),
    };
  }

  CustomerRow copyWith({
    String? id,
    String? name,
    String? phone,
    bool? isTrusted,
    String? qrCode,
    int? depositBalance,
  }) => CustomerRow(
    id: id ?? this.id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    isTrusted: isTrusted ?? this.isTrusted,
    qrCode: qrCode ?? this.qrCode,
    depositBalance: depositBalance ?? this.depositBalance,
  );
  CustomerRow copyWithCompanion(CustomersCompanion data) {
    return CustomerRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      isTrusted: data.isTrusted.present ? data.isTrusted.value : this.isTrusted,
      qrCode: data.qrCode.present ? data.qrCode.value : this.qrCode,
      depositBalance: data.depositBalance.present
          ? data.depositBalance.value
          : this.depositBalance,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomerRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('isTrusted: $isTrusted, ')
          ..write('qrCode: $qrCode, ')
          ..write('depositBalance: $depositBalance')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, phone, isTrusted, qrCode, depositBalance);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomerRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.isTrusted == this.isTrusted &&
          other.qrCode == this.qrCode &&
          other.depositBalance == this.depositBalance);
}

class CustomersCompanion extends UpdateCompanion<CustomerRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> phone;
  final Value<bool> isTrusted;
  final Value<String> qrCode;
  final Value<int> depositBalance;
  final Value<int> rowid;
  const CustomersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.isTrusted = const Value.absent(),
    this.qrCode = const Value.absent(),
    this.depositBalance = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomersCompanion.insert({
    required String id,
    required String name,
    required String phone,
    this.isTrusted = const Value.absent(),
    required String qrCode,
    this.depositBalance = const Value.absent(),
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
    Expression<int>? depositBalance,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (isTrusted != null) 'is_trusted': isTrusted,
      if (qrCode != null) 'qr_code': qrCode,
      if (depositBalance != null) 'deposit_balance': depositBalance,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? phone,
    Value<bool>? isTrusted,
    Value<String>? qrCode,
    Value<int>? depositBalance,
    Value<int>? rowid,
  }) {
    return CustomersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      isTrusted: isTrusted ?? this.isTrusted,
      qrCode: qrCode ?? this.qrCode,
      depositBalance: depositBalance ?? this.depositBalance,
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
    if (depositBalance.present) {
      map['deposit_balance'] = Variable<int>(depositBalance.value);
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
          ..write('depositBalance: $depositBalance, ')
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
  static const VerificationMeta _dueDateOptionalMeta = const VerificationMeta(
    'dueDateOptional',
  );
  @override
  late final GeneratedColumn<bool> dueDateOptional = GeneratedColumn<bool>(
    'due_date_optional',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("due_date_optional" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _requiresUnitIdentityMeta =
      const VerificationMeta('requiresUnitIdentity');
  @override
  late final GeneratedColumn<bool> requiresUnitIdentity = GeneratedColumn<bool>(
    'requires_unit_identity',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("requires_unit_identity" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _unitCodePrefixMeta = const VerificationMeta(
    'unitCodePrefix',
  );
  @override
  late final GeneratedColumn<String> unitCodePrefix = GeneratedColumn<String>(
    'unit_code_prefix',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _allowsDynamicPricingMeta =
      const VerificationMeta('allowsDynamicPricing');
  @override
  late final GeneratedColumn<bool> allowsDynamicPricing = GeneratedColumn<bool>(
    'allows_dynamic_pricing',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("allows_dynamic_pricing" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _defaultItemKindMeta = const VerificationMeta(
    'defaultItemKind',
  );
  @override
  late final GeneratedColumn<String> defaultItemKind = GeneratedColumn<String>(
    'default_item_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('rental'),
  );
  static const VerificationMeta _metadataMeta = const VerificationMeta(
    'metadata',
  );
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
    'metadata',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _catalogActiveMeta = const VerificationMeta(
    'catalogActive',
  );
  @override
  late final GeneratedColumn<bool> catalogActive = GeneratedColumn<bool>(
    'catalog_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("catalog_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _securityDepositPaiseMeta =
      const VerificationMeta('securityDepositPaise');
  @override
  late final GeneratedColumn<int> securityDepositPaise = GeneratedColumn<int>(
    'security_deposit_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
    dueDateOptional,
    requiresUnitIdentity,
    unitCodePrefix,
    allowsDynamicPricing,
    defaultItemKind,
    metadata,
    catalogActive,
    securityDepositPaise,
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
    if (data.containsKey('due_date_optional')) {
      context.handle(
        _dueDateOptionalMeta,
        dueDateOptional.isAcceptableOrUnknown(
          data['due_date_optional']!,
          _dueDateOptionalMeta,
        ),
      );
    }
    if (data.containsKey('requires_unit_identity')) {
      context.handle(
        _requiresUnitIdentityMeta,
        requiresUnitIdentity.isAcceptableOrUnknown(
          data['requires_unit_identity']!,
          _requiresUnitIdentityMeta,
        ),
      );
    }
    if (data.containsKey('unit_code_prefix')) {
      context.handle(
        _unitCodePrefixMeta,
        unitCodePrefix.isAcceptableOrUnknown(
          data['unit_code_prefix']!,
          _unitCodePrefixMeta,
        ),
      );
    }
    if (data.containsKey('allows_dynamic_pricing')) {
      context.handle(
        _allowsDynamicPricingMeta,
        allowsDynamicPricing.isAcceptableOrUnknown(
          data['allows_dynamic_pricing']!,
          _allowsDynamicPricingMeta,
        ),
      );
    }
    if (data.containsKey('default_item_kind')) {
      context.handle(
        _defaultItemKindMeta,
        defaultItemKind.isAcceptableOrUnknown(
          data['default_item_kind']!,
          _defaultItemKindMeta,
        ),
      );
    }
    if (data.containsKey('metadata')) {
      context.handle(
        _metadataMeta,
        metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta),
      );
    }
    if (data.containsKey('catalog_active')) {
      context.handle(
        _catalogActiveMeta,
        catalogActive.isAcceptableOrUnknown(
          data['catalog_active']!,
          _catalogActiveMeta,
        ),
      );
    }
    if (data.containsKey('security_deposit_paise')) {
      context.handle(
        _securityDepositPaiseMeta,
        securityDepositPaise.isAcceptableOrUnknown(
          data['security_deposit_paise']!,
          _securityDepositPaiseMeta,
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
      dueDateOptional: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}due_date_optional'],
      )!,
      requiresUnitIdentity: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}requires_unit_identity'],
      )!,
      unitCodePrefix: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit_code_prefix'],
      ),
      allowsDynamicPricing: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}allows_dynamic_pricing'],
      )!,
      defaultItemKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_item_kind'],
      )!,
      metadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata'],
      ),
      catalogActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}catalog_active'],
      )!,
      securityDepositPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}security_deposit_paise'],
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

  /// When true, rentals may omit a due date (open-ended accrual until return).
  final bool dueDateOptional;

  /// When true, each issued unit needs instance name + short code (parent catalog).
  final bool requiresUnitIdentity;

  /// Optional short-code pool prefix (e.g. `SEAT` → SEAT-001…N from [totalUnits]).
  final String? unitCodePrefix;

  /// When true, New Order may override catalog [rateAmount] for that rental line.
  final bool allowsDynamicPricing;

  /// Full [ResourceType] set (`rental` | `sale` | `service` | …). Legacy `general` → `sale`.
  final String defaultItemKind;

  /// JSON map of dynamic field values ([FieldDef] ids → values).
  final String? metadata;

  /// When false, hidden from New Order and the default Resources list.
  final bool catalogActive;

  /// Suggested security/advance per unit for rent-like items (paise).
  final int securityDepositPaise;
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
    required this.dueDateOptional,
    required this.requiresUnitIdentity,
    this.unitCodePrefix,
    required this.allowsDynamicPricing,
    required this.defaultItemKind,
    this.metadata,
    required this.catalogActive,
    required this.securityDepositPaise,
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
    map['due_date_optional'] = Variable<bool>(dueDateOptional);
    map['requires_unit_identity'] = Variable<bool>(requiresUnitIdentity);
    if (!nullToAbsent || unitCodePrefix != null) {
      map['unit_code_prefix'] = Variable<String>(unitCodePrefix);
    }
    map['allows_dynamic_pricing'] = Variable<bool>(allowsDynamicPricing);
    map['default_item_kind'] = Variable<String>(defaultItemKind);
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    map['catalog_active'] = Variable<bool>(catalogActive);
    map['security_deposit_paise'] = Variable<int>(securityDepositPaise);
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
      dueDateOptional: Value(dueDateOptional),
      requiresUnitIdentity: Value(requiresUnitIdentity),
      unitCodePrefix: unitCodePrefix == null && nullToAbsent
          ? const Value.absent()
          : Value(unitCodePrefix),
      allowsDynamicPricing: Value(allowsDynamicPricing),
      defaultItemKind: Value(defaultItemKind),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
      catalogActive: Value(catalogActive),
      securityDepositPaise: Value(securityDepositPaise),
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
      dueDateOptional: serializer.fromJson<bool>(json['dueDateOptional']),
      requiresUnitIdentity: serializer.fromJson<bool>(
        json['requiresUnitIdentity'],
      ),
      unitCodePrefix: serializer.fromJson<String?>(json['unitCodePrefix']),
      allowsDynamicPricing: serializer.fromJson<bool>(
        json['allowsDynamicPricing'],
      ),
      defaultItemKind: serializer.fromJson<String>(json['defaultItemKind']),
      metadata: serializer.fromJson<String?>(json['metadata']),
      catalogActive: serializer.fromJson<bool>(json['catalogActive']),
      securityDepositPaise: serializer.fromJson<int>(
        json['securityDepositPaise'],
      ),
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
      'dueDateOptional': serializer.toJson<bool>(dueDateOptional),
      'requiresUnitIdentity': serializer.toJson<bool>(requiresUnitIdentity),
      'unitCodePrefix': serializer.toJson<String?>(unitCodePrefix),
      'allowsDynamicPricing': serializer.toJson<bool>(allowsDynamicPricing),
      'defaultItemKind': serializer.toJson<String>(defaultItemKind),
      'metadata': serializer.toJson<String?>(metadata),
      'catalogActive': serializer.toJson<bool>(catalogActive),
      'securityDepositPaise': serializer.toJson<int>(securityDepositPaise),
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
    bool? dueDateOptional,
    bool? requiresUnitIdentity,
    Value<String?> unitCodePrefix = const Value.absent(),
    bool? allowsDynamicPricing,
    String? defaultItemKind,
    Value<String?> metadata = const Value.absent(),
    bool? catalogActive,
    int? securityDepositPaise,
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
    dueDateOptional: dueDateOptional ?? this.dueDateOptional,
    requiresUnitIdentity: requiresUnitIdentity ?? this.requiresUnitIdentity,
    unitCodePrefix: unitCodePrefix.present
        ? unitCodePrefix.value
        : this.unitCodePrefix,
    allowsDynamicPricing: allowsDynamicPricing ?? this.allowsDynamicPricing,
    defaultItemKind: defaultItemKind ?? this.defaultItemKind,
    metadata: metadata.present ? metadata.value : this.metadata,
    catalogActive: catalogActive ?? this.catalogActive,
    securityDepositPaise: securityDepositPaise ?? this.securityDepositPaise,
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
      dueDateOptional: data.dueDateOptional.present
          ? data.dueDateOptional.value
          : this.dueDateOptional,
      requiresUnitIdentity: data.requiresUnitIdentity.present
          ? data.requiresUnitIdentity.value
          : this.requiresUnitIdentity,
      unitCodePrefix: data.unitCodePrefix.present
          ? data.unitCodePrefix.value
          : this.unitCodePrefix,
      allowsDynamicPricing: data.allowsDynamicPricing.present
          ? data.allowsDynamicPricing.value
          : this.allowsDynamicPricing,
      defaultItemKind: data.defaultItemKind.present
          ? data.defaultItemKind.value
          : this.defaultItemKind,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      catalogActive: data.catalogActive.present
          ? data.catalogActive.value
          : this.catalogActive,
      securityDepositPaise: data.securityDepositPaise.present
          ? data.securityDepositPaise.value
          : this.securityDepositPaise,
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
          ..write('currencyCode: $currencyCode, ')
          ..write('dueDateOptional: $dueDateOptional, ')
          ..write('requiresUnitIdentity: $requiresUnitIdentity, ')
          ..write('unitCodePrefix: $unitCodePrefix, ')
          ..write('allowsDynamicPricing: $allowsDynamicPricing, ')
          ..write('defaultItemKind: $defaultItemKind, ')
          ..write('metadata: $metadata, ')
          ..write('catalogActive: $catalogActive, ')
          ..write('securityDepositPaise: $securityDepositPaise')
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
    dueDateOptional,
    requiresUnitIdentity,
    unitCodePrefix,
    allowsDynamicPricing,
    defaultItemKind,
    metadata,
    catalogActive,
    securityDepositPaise,
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
          other.currencyCode == this.currencyCode &&
          other.dueDateOptional == this.dueDateOptional &&
          other.requiresUnitIdentity == this.requiresUnitIdentity &&
          other.unitCodePrefix == this.unitCodePrefix &&
          other.allowsDynamicPricing == this.allowsDynamicPricing &&
          other.defaultItemKind == this.defaultItemKind &&
          other.metadata == this.metadata &&
          other.catalogActive == this.catalogActive &&
          other.securityDepositPaise == this.securityDepositPaise);
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
  final Value<bool> dueDateOptional;
  final Value<bool> requiresUnitIdentity;
  final Value<String?> unitCodePrefix;
  final Value<bool> allowsDynamicPricing;
  final Value<String> defaultItemKind;
  final Value<String?> metadata;
  final Value<bool> catalogActive;
  final Value<int> securityDepositPaise;
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
    this.dueDateOptional = const Value.absent(),
    this.requiresUnitIdentity = const Value.absent(),
    this.unitCodePrefix = const Value.absent(),
    this.allowsDynamicPricing = const Value.absent(),
    this.defaultItemKind = const Value.absent(),
    this.metadata = const Value.absent(),
    this.catalogActive = const Value.absent(),
    this.securityDepositPaise = const Value.absent(),
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
    this.dueDateOptional = const Value.absent(),
    this.requiresUnitIdentity = const Value.absent(),
    this.unitCodePrefix = const Value.absent(),
    this.allowsDynamicPricing = const Value.absent(),
    this.defaultItemKind = const Value.absent(),
    this.metadata = const Value.absent(),
    this.catalogActive = const Value.absent(),
    this.securityDepositPaise = const Value.absent(),
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
    Expression<bool>? dueDateOptional,
    Expression<bool>? requiresUnitIdentity,
    Expression<String>? unitCodePrefix,
    Expression<bool>? allowsDynamicPricing,
    Expression<String>? defaultItemKind,
    Expression<String>? metadata,
    Expression<bool>? catalogActive,
    Expression<int>? securityDepositPaise,
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
      if (dueDateOptional != null) 'due_date_optional': dueDateOptional,
      if (requiresUnitIdentity != null)
        'requires_unit_identity': requiresUnitIdentity,
      if (unitCodePrefix != null) 'unit_code_prefix': unitCodePrefix,
      if (allowsDynamicPricing != null)
        'allows_dynamic_pricing': allowsDynamicPricing,
      if (defaultItemKind != null) 'default_item_kind': defaultItemKind,
      if (metadata != null) 'metadata': metadata,
      if (catalogActive != null) 'catalog_active': catalogActive,
      if (securityDepositPaise != null)
        'security_deposit_paise': securityDepositPaise,
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
    Value<bool>? dueDateOptional,
    Value<bool>? requiresUnitIdentity,
    Value<String?>? unitCodePrefix,
    Value<bool>? allowsDynamicPricing,
    Value<String>? defaultItemKind,
    Value<String?>? metadata,
    Value<bool>? catalogActive,
    Value<int>? securityDepositPaise,
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
      dueDateOptional: dueDateOptional ?? this.dueDateOptional,
      requiresUnitIdentity: requiresUnitIdentity ?? this.requiresUnitIdentity,
      unitCodePrefix: unitCodePrefix ?? this.unitCodePrefix,
      allowsDynamicPricing: allowsDynamicPricing ?? this.allowsDynamicPricing,
      defaultItemKind: defaultItemKind ?? this.defaultItemKind,
      metadata: metadata ?? this.metadata,
      catalogActive: catalogActive ?? this.catalogActive,
      securityDepositPaise: securityDepositPaise ?? this.securityDepositPaise,
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
    if (dueDateOptional.present) {
      map['due_date_optional'] = Variable<bool>(dueDateOptional.value);
    }
    if (requiresUnitIdentity.present) {
      map['requires_unit_identity'] = Variable<bool>(
        requiresUnitIdentity.value,
      );
    }
    if (unitCodePrefix.present) {
      map['unit_code_prefix'] = Variable<String>(unitCodePrefix.value);
    }
    if (allowsDynamicPricing.present) {
      map['allows_dynamic_pricing'] = Variable<bool>(
        allowsDynamicPricing.value,
      );
    }
    if (defaultItemKind.present) {
      map['default_item_kind'] = Variable<String>(defaultItemKind.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (catalogActive.present) {
      map['catalog_active'] = Variable<bool>(catalogActive.value);
    }
    if (securityDepositPaise.present) {
      map['security_deposit_paise'] = Variable<int>(securityDepositPaise.value);
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
          ..write('dueDateOptional: $dueDateOptional, ')
          ..write('requiresUnitIdentity: $requiresUnitIdentity, ')
          ..write('unitCodePrefix: $unitCodePrefix, ')
          ..write('allowsDynamicPricing: $allowsDynamicPricing, ')
          ..write('defaultItemKind: $defaultItemKind, ')
          ..write('metadata: $metadata, ')
          ..write('catalogActive: $catalogActive, ')
          ..write('securityDepositPaise: $securityDepositPaise, ')
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
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
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
  static const VerificationMeta _depositAppliedMeta = const VerificationMeta(
    'depositApplied',
  );
  @override
  late final GeneratedColumn<int> depositApplied = GeneratedColumn<int>(
    'deposit_applied',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _depositAmountMeta = const VerificationMeta(
    'depositAmount',
  );
  @override
  late final GeneratedColumn<int> depositAmount = GeneratedColumn<int>(
    'deposit_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sellPaidPaiseMeta = const VerificationMeta(
    'sellPaidPaise',
  );
  @override
  late final GeneratedColumn<int> sellPaidPaise = GeneratedColumn<int>(
    'sell_paid_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sellDiscountPaiseMeta = const VerificationMeta(
    'sellDiscountPaise',
  );
  @override
  late final GeneratedColumn<int> sellDiscountPaise = GeneratedColumn<int>(
    'sell_discount_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _orderStatusMeta = const VerificationMeta(
    'orderStatus',
  );
  @override
  late final GeneratedColumn<String> orderStatus = GeneratedColumn<String>(
    'order_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('open'),
  );
  static const VerificationMeta _workflowStatusMeta = const VerificationMeta(
    'workflowStatus',
  );
  @override
  late final GeneratedColumn<String> workflowStatus = GeneratedColumn<String>(
    'workflow_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _replacedFromRentalIdMeta =
      const VerificationMeta('replacedFromRentalId');
  @override
  late final GeneratedColumn<String> replacedFromRentalId =
      GeneratedColumn<String>(
        'replaced_from_rental_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
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
    depositApplied,
    depositAmount,
    sellPaidPaise,
    sellDiscountPaise,
    orderStatus,
    workflowStatus,
    durationUnits,
    replacedFromRentalId,
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
    if (data.containsKey('deposit_applied')) {
      context.handle(
        _depositAppliedMeta,
        depositApplied.isAcceptableOrUnknown(
          data['deposit_applied']!,
          _depositAppliedMeta,
        ),
      );
    }
    if (data.containsKey('deposit_amount')) {
      context.handle(
        _depositAmountMeta,
        depositAmount.isAcceptableOrUnknown(
          data['deposit_amount']!,
          _depositAmountMeta,
        ),
      );
    }
    if (data.containsKey('sell_paid_paise')) {
      context.handle(
        _sellPaidPaiseMeta,
        sellPaidPaise.isAcceptableOrUnknown(
          data['sell_paid_paise']!,
          _sellPaidPaiseMeta,
        ),
      );
    }
    if (data.containsKey('sell_discount_paise')) {
      context.handle(
        _sellDiscountPaiseMeta,
        sellDiscountPaise.isAcceptableOrUnknown(
          data['sell_discount_paise']!,
          _sellDiscountPaiseMeta,
        ),
      );
    }
    if (data.containsKey('order_status')) {
      context.handle(
        _orderStatusMeta,
        orderStatus.isAcceptableOrUnknown(
          data['order_status']!,
          _orderStatusMeta,
        ),
      );
    }
    if (data.containsKey('workflow_status')) {
      context.handle(
        _workflowStatusMeta,
        workflowStatus.isAcceptableOrUnknown(
          data['workflow_status']!,
          _workflowStatusMeta,
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
    if (data.containsKey('replaced_from_rental_id')) {
      context.handle(
        _replacedFromRentalIdMeta,
        replacedFromRentalId.isAcceptableOrUnknown(
          data['replaced_from_rental_id']!,
          _replacedFromRentalIdMeta,
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
      ),
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
      depositApplied: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deposit_applied'],
      )!,
      depositAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deposit_amount'],
      )!,
      sellPaidPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sell_paid_paise'],
      )!,
      sellDiscountPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sell_discount_paise'],
      )!,
      orderStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_status'],
      )!,
      workflowStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workflow_status'],
      ),
      durationUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_units'],
      )!,
      replacedFromRentalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}replaced_from_rental_id'],
      ),
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

  /// Null for open-ended rentals (no fixed due date).
  final DateTime? dueAt;
  final DateTime? returnedAt;
  final String qrCode;

  /// Optional per-rental display name (e.g. Unknown path nickname).
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

  /// Deposit applied from order deposit at return (paise).
  final int depositApplied;

  /// Token/advance held on this order (paise). Original amount; applied tracked separately.
  final int depositAmount;

  /// Cash applied toward sell lines (paise).
  final int sellPaidPaise;

  /// Forgiven sell shortfall (paise); unpaid sell = sell due − paid − discount.
  final int sellDiscountPaise;

  /// `open` | `completed` | `cancelled`
  final String orderStatus;

  /// Template workflow status id (nullable; null → derive from [orderStatus]).
  final String? workflowStatus;

  /// Chosen duration (e.g. 1 week → 1; fixed due-days still stored here).
  final int durationUnits;

  /// Set when this rental was opened as a replacement for a line on another rental.
  final String? replacedFromRentalId;
  const RentalRow({
    required this.id,
    required this.customerId,
    required this.startedAt,
    this.dueAt,
    this.returnedAt,
    required this.qrCode,
    this.nickname,
    required this.billingMode,
    required this.rateAmount,
    required this.lateFeePerDay,
    required this.baseAmount,
    required this.lateAmount,
    required this.totalAmount,
    required this.depositApplied,
    required this.depositAmount,
    required this.sellPaidPaise,
    required this.sellDiscountPaise,
    required this.orderStatus,
    this.workflowStatus,
    required this.durationUnits,
    this.replacedFromRentalId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['customer_id'] = Variable<String>(customerId);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || dueAt != null) {
      map['due_at'] = Variable<DateTime>(dueAt);
    }
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
    map['deposit_applied'] = Variable<int>(depositApplied);
    map['deposit_amount'] = Variable<int>(depositAmount);
    map['sell_paid_paise'] = Variable<int>(sellPaidPaise);
    map['sell_discount_paise'] = Variable<int>(sellDiscountPaise);
    map['order_status'] = Variable<String>(orderStatus);
    if (!nullToAbsent || workflowStatus != null) {
      map['workflow_status'] = Variable<String>(workflowStatus);
    }
    map['duration_units'] = Variable<int>(durationUnits);
    if (!nullToAbsent || replacedFromRentalId != null) {
      map['replaced_from_rental_id'] = Variable<String>(replacedFromRentalId);
    }
    return map;
  }

  RentalsCompanion toCompanion(bool nullToAbsent) {
    return RentalsCompanion(
      id: Value(id),
      customerId: Value(customerId),
      startedAt: Value(startedAt),
      dueAt: dueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(dueAt),
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
      depositApplied: Value(depositApplied),
      depositAmount: Value(depositAmount),
      sellPaidPaise: Value(sellPaidPaise),
      sellDiscountPaise: Value(sellDiscountPaise),
      orderStatus: Value(orderStatus),
      workflowStatus: workflowStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(workflowStatus),
      durationUnits: Value(durationUnits),
      replacedFromRentalId: replacedFromRentalId == null && nullToAbsent
          ? const Value.absent()
          : Value(replacedFromRentalId),
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
      dueAt: serializer.fromJson<DateTime?>(json['dueAt']),
      returnedAt: serializer.fromJson<DateTime?>(json['returnedAt']),
      qrCode: serializer.fromJson<String>(json['qrCode']),
      nickname: serializer.fromJson<String?>(json['nickname']),
      billingMode: serializer.fromJson<String>(json['billingMode']),
      rateAmount: serializer.fromJson<int>(json['rateAmount']),
      lateFeePerDay: serializer.fromJson<int>(json['lateFeePerDay']),
      baseAmount: serializer.fromJson<int>(json['baseAmount']),
      lateAmount: serializer.fromJson<int>(json['lateAmount']),
      totalAmount: serializer.fromJson<int>(json['totalAmount']),
      depositApplied: serializer.fromJson<int>(json['depositApplied']),
      depositAmount: serializer.fromJson<int>(json['depositAmount']),
      sellPaidPaise: serializer.fromJson<int>(json['sellPaidPaise']),
      sellDiscountPaise: serializer.fromJson<int>(json['sellDiscountPaise']),
      orderStatus: serializer.fromJson<String>(json['orderStatus']),
      workflowStatus: serializer.fromJson<String?>(json['workflowStatus']),
      durationUnits: serializer.fromJson<int>(json['durationUnits']),
      replacedFromRentalId: serializer.fromJson<String?>(
        json['replacedFromRentalId'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'customerId': serializer.toJson<String>(customerId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'dueAt': serializer.toJson<DateTime?>(dueAt),
      'returnedAt': serializer.toJson<DateTime?>(returnedAt),
      'qrCode': serializer.toJson<String>(qrCode),
      'nickname': serializer.toJson<String?>(nickname),
      'billingMode': serializer.toJson<String>(billingMode),
      'rateAmount': serializer.toJson<int>(rateAmount),
      'lateFeePerDay': serializer.toJson<int>(lateFeePerDay),
      'baseAmount': serializer.toJson<int>(baseAmount),
      'lateAmount': serializer.toJson<int>(lateAmount),
      'totalAmount': serializer.toJson<int>(totalAmount),
      'depositApplied': serializer.toJson<int>(depositApplied),
      'depositAmount': serializer.toJson<int>(depositAmount),
      'sellPaidPaise': serializer.toJson<int>(sellPaidPaise),
      'sellDiscountPaise': serializer.toJson<int>(sellDiscountPaise),
      'orderStatus': serializer.toJson<String>(orderStatus),
      'workflowStatus': serializer.toJson<String?>(workflowStatus),
      'durationUnits': serializer.toJson<int>(durationUnits),
      'replacedFromRentalId': serializer.toJson<String?>(replacedFromRentalId),
    };
  }

  RentalRow copyWith({
    String? id,
    String? customerId,
    DateTime? startedAt,
    Value<DateTime?> dueAt = const Value.absent(),
    Value<DateTime?> returnedAt = const Value.absent(),
    String? qrCode,
    Value<String?> nickname = const Value.absent(),
    String? billingMode,
    int? rateAmount,
    int? lateFeePerDay,
    int? baseAmount,
    int? lateAmount,
    int? totalAmount,
    int? depositApplied,
    int? depositAmount,
    int? sellPaidPaise,
    int? sellDiscountPaise,
    String? orderStatus,
    Value<String?> workflowStatus = const Value.absent(),
    int? durationUnits,
    Value<String?> replacedFromRentalId = const Value.absent(),
  }) => RentalRow(
    id: id ?? this.id,
    customerId: customerId ?? this.customerId,
    startedAt: startedAt ?? this.startedAt,
    dueAt: dueAt.present ? dueAt.value : this.dueAt,
    returnedAt: returnedAt.present ? returnedAt.value : this.returnedAt,
    qrCode: qrCode ?? this.qrCode,
    nickname: nickname.present ? nickname.value : this.nickname,
    billingMode: billingMode ?? this.billingMode,
    rateAmount: rateAmount ?? this.rateAmount,
    lateFeePerDay: lateFeePerDay ?? this.lateFeePerDay,
    baseAmount: baseAmount ?? this.baseAmount,
    lateAmount: lateAmount ?? this.lateAmount,
    totalAmount: totalAmount ?? this.totalAmount,
    depositApplied: depositApplied ?? this.depositApplied,
    depositAmount: depositAmount ?? this.depositAmount,
    sellPaidPaise: sellPaidPaise ?? this.sellPaidPaise,
    sellDiscountPaise: sellDiscountPaise ?? this.sellDiscountPaise,
    orderStatus: orderStatus ?? this.orderStatus,
    workflowStatus: workflowStatus.present
        ? workflowStatus.value
        : this.workflowStatus,
    durationUnits: durationUnits ?? this.durationUnits,
    replacedFromRentalId: replacedFromRentalId.present
        ? replacedFromRentalId.value
        : this.replacedFromRentalId,
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
      depositApplied: data.depositApplied.present
          ? data.depositApplied.value
          : this.depositApplied,
      depositAmount: data.depositAmount.present
          ? data.depositAmount.value
          : this.depositAmount,
      sellPaidPaise: data.sellPaidPaise.present
          ? data.sellPaidPaise.value
          : this.sellPaidPaise,
      sellDiscountPaise: data.sellDiscountPaise.present
          ? data.sellDiscountPaise.value
          : this.sellDiscountPaise,
      orderStatus: data.orderStatus.present
          ? data.orderStatus.value
          : this.orderStatus,
      workflowStatus: data.workflowStatus.present
          ? data.workflowStatus.value
          : this.workflowStatus,
      durationUnits: data.durationUnits.present
          ? data.durationUnits.value
          : this.durationUnits,
      replacedFromRentalId: data.replacedFromRentalId.present
          ? data.replacedFromRentalId.value
          : this.replacedFromRentalId,
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
          ..write('depositApplied: $depositApplied, ')
          ..write('depositAmount: $depositAmount, ')
          ..write('sellPaidPaise: $sellPaidPaise, ')
          ..write('sellDiscountPaise: $sellDiscountPaise, ')
          ..write('orderStatus: $orderStatus, ')
          ..write('workflowStatus: $workflowStatus, ')
          ..write('durationUnits: $durationUnits, ')
          ..write('replacedFromRentalId: $replacedFromRentalId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
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
    depositApplied,
    depositAmount,
    sellPaidPaise,
    sellDiscountPaise,
    orderStatus,
    workflowStatus,
    durationUnits,
    replacedFromRentalId,
  ]);
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
          other.depositApplied == this.depositApplied &&
          other.depositAmount == this.depositAmount &&
          other.sellPaidPaise == this.sellPaidPaise &&
          other.sellDiscountPaise == this.sellDiscountPaise &&
          other.orderStatus == this.orderStatus &&
          other.workflowStatus == this.workflowStatus &&
          other.durationUnits == this.durationUnits &&
          other.replacedFromRentalId == this.replacedFromRentalId);
}

class RentalsCompanion extends UpdateCompanion<RentalRow> {
  final Value<String> id;
  final Value<String> customerId;
  final Value<DateTime> startedAt;
  final Value<DateTime?> dueAt;
  final Value<DateTime?> returnedAt;
  final Value<String> qrCode;
  final Value<String?> nickname;
  final Value<String> billingMode;
  final Value<int> rateAmount;
  final Value<int> lateFeePerDay;
  final Value<int> baseAmount;
  final Value<int> lateAmount;
  final Value<int> totalAmount;
  final Value<int> depositApplied;
  final Value<int> depositAmount;
  final Value<int> sellPaidPaise;
  final Value<int> sellDiscountPaise;
  final Value<String> orderStatus;
  final Value<String?> workflowStatus;
  final Value<int> durationUnits;
  final Value<String?> replacedFromRentalId;
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
    this.depositApplied = const Value.absent(),
    this.depositAmount = const Value.absent(),
    this.sellPaidPaise = const Value.absent(),
    this.sellDiscountPaise = const Value.absent(),
    this.orderStatus = const Value.absent(),
    this.workflowStatus = const Value.absent(),
    this.durationUnits = const Value.absent(),
    this.replacedFromRentalId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RentalsCompanion.insert({
    required String id,
    required String customerId,
    required DateTime startedAt,
    this.dueAt = const Value.absent(),
    this.returnedAt = const Value.absent(),
    required String qrCode,
    this.nickname = const Value.absent(),
    this.billingMode = const Value.absent(),
    this.rateAmount = const Value.absent(),
    this.lateFeePerDay = const Value.absent(),
    this.baseAmount = const Value.absent(),
    this.lateAmount = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.depositApplied = const Value.absent(),
    this.depositAmount = const Value.absent(),
    this.sellPaidPaise = const Value.absent(),
    this.sellDiscountPaise = const Value.absent(),
    this.orderStatus = const Value.absent(),
    this.workflowStatus = const Value.absent(),
    this.durationUnits = const Value.absent(),
    this.replacedFromRentalId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       customerId = Value(customerId),
       startedAt = Value(startedAt),
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
    Expression<int>? depositApplied,
    Expression<int>? depositAmount,
    Expression<int>? sellPaidPaise,
    Expression<int>? sellDiscountPaise,
    Expression<String>? orderStatus,
    Expression<String>? workflowStatus,
    Expression<int>? durationUnits,
    Expression<String>? replacedFromRentalId,
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
      if (depositApplied != null) 'deposit_applied': depositApplied,
      if (depositAmount != null) 'deposit_amount': depositAmount,
      if (sellPaidPaise != null) 'sell_paid_paise': sellPaidPaise,
      if (sellDiscountPaise != null) 'sell_discount_paise': sellDiscountPaise,
      if (orderStatus != null) 'order_status': orderStatus,
      if (workflowStatus != null) 'workflow_status': workflowStatus,
      if (durationUnits != null) 'duration_units': durationUnits,
      if (replacedFromRentalId != null)
        'replaced_from_rental_id': replacedFromRentalId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RentalsCompanion copyWith({
    Value<String>? id,
    Value<String>? customerId,
    Value<DateTime>? startedAt,
    Value<DateTime?>? dueAt,
    Value<DateTime?>? returnedAt,
    Value<String>? qrCode,
    Value<String?>? nickname,
    Value<String>? billingMode,
    Value<int>? rateAmount,
    Value<int>? lateFeePerDay,
    Value<int>? baseAmount,
    Value<int>? lateAmount,
    Value<int>? totalAmount,
    Value<int>? depositApplied,
    Value<int>? depositAmount,
    Value<int>? sellPaidPaise,
    Value<int>? sellDiscountPaise,
    Value<String>? orderStatus,
    Value<String?>? workflowStatus,
    Value<int>? durationUnits,
    Value<String?>? replacedFromRentalId,
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
      depositApplied: depositApplied ?? this.depositApplied,
      depositAmount: depositAmount ?? this.depositAmount,
      sellPaidPaise: sellPaidPaise ?? this.sellPaidPaise,
      sellDiscountPaise: sellDiscountPaise ?? this.sellDiscountPaise,
      orderStatus: orderStatus ?? this.orderStatus,
      workflowStatus: workflowStatus ?? this.workflowStatus,
      durationUnits: durationUnits ?? this.durationUnits,
      replacedFromRentalId: replacedFromRentalId ?? this.replacedFromRentalId,
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
    if (depositApplied.present) {
      map['deposit_applied'] = Variable<int>(depositApplied.value);
    }
    if (depositAmount.present) {
      map['deposit_amount'] = Variable<int>(depositAmount.value);
    }
    if (sellPaidPaise.present) {
      map['sell_paid_paise'] = Variable<int>(sellPaidPaise.value);
    }
    if (sellDiscountPaise.present) {
      map['sell_discount_paise'] = Variable<int>(sellDiscountPaise.value);
    }
    if (orderStatus.present) {
      map['order_status'] = Variable<String>(orderStatus.value);
    }
    if (workflowStatus.present) {
      map['workflow_status'] = Variable<String>(workflowStatus.value);
    }
    if (durationUnits.present) {
      map['duration_units'] = Variable<int>(durationUnits.value);
    }
    if (replacedFromRentalId.present) {
      map['replaced_from_rental_id'] = Variable<String>(
        replacedFromRentalId.value,
      );
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
          ..write('depositApplied: $depositApplied, ')
          ..write('depositAmount: $depositAmount, ')
          ..write('sellPaidPaise: $sellPaidPaise, ')
          ..write('sellDiscountPaise: $sellDiscountPaise, ')
          ..write('orderStatus: $orderStatus, ')
          ..write('workflowStatus: $workflowStatus, ')
          ..write('durationUnits: $durationUnits, ')
          ..write('replacedFromRentalId: $replacedFromRentalId, ')
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
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _depositAppliedMeta = const VerificationMeta(
    'depositApplied',
  );
  @override
  late final GeneratedColumn<int> depositApplied = GeneratedColumn<int>(
    'deposit_applied',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  static const VerificationMeta _fulfillmentMeta = const VerificationMeta(
    'fulfillment',
  );
  @override
  late final GeneratedColumn<String> fulfillment = GeneratedColumn<String>(
    'fulfillment',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('rent'),
  );
  static const VerificationMeta _returnDispositionMeta = const VerificationMeta(
    'returnDisposition',
  );
  @override
  late final GeneratedColumn<String> returnDisposition =
      GeneratedColumn<String>(
        'return_disposition',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    rentalId,
    itemId,
    instanceName,
    shortCode,
    returnedAt,
    baseAmount,
    lateAmount,
    depositApplied,
    billingMode,
    rateAmount,
    lateFeePerDay,
    fulfillment,
    returnDisposition,
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
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
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
    if (data.containsKey('returned_at')) {
      context.handle(
        _returnedAtMeta,
        returnedAt.isAcceptableOrUnknown(data['returned_at']!, _returnedAtMeta),
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
    if (data.containsKey('deposit_applied')) {
      context.handle(
        _depositAppliedMeta,
        depositApplied.isAcceptableOrUnknown(
          data['deposit_applied']!,
          _depositAppliedMeta,
        ),
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
    if (data.containsKey('fulfillment')) {
      context.handle(
        _fulfillmentMeta,
        fulfillment.isAcceptableOrUnknown(
          data['fulfillment']!,
          _fulfillmentMeta,
        ),
      );
    }
    if (data.containsKey('return_disposition')) {
      context.handle(
        _returnDispositionMeta,
        returnDisposition.isAcceptableOrUnknown(
          data['return_disposition']!,
          _returnDispositionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RentalItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RentalItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
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
      returnedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}returned_at'],
      ),
      baseAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_amount'],
      )!,
      lateAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}late_amount'],
      )!,
      depositApplied: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deposit_applied'],
      )!,
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
      fulfillment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fulfillment'],
      )!,
      returnDisposition: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}return_disposition'],
      ),
    );
  }

  @override
  $RentalItemsTable createAlias(String alias) {
    return $RentalItemsTable(attachedDatabase, alias);
  }
}

class RentalItemRow extends DataClass implements Insertable<RentalItemRow> {
  /// Line id (e.g. RLI-…); allows multiple units of the same catalog item.
  final String id;
  final String rentalId;
  final String itemId;

  /// Copy/title for this issue (e.g. novel title); not inventory master.
  final String instanceName;

  /// Short tracking code unique among open rental lines (case-insensitive).
  final String shortCode;

  /// Null while the line is still out; set on partial or full return.
  final DateTime? returnedAt;

  /// Line base charge in paise (snapshot at issue).
  final int baseAmount;

  /// Finalized late fee in paise (set on return).
  final int lateAmount;

  /// Deposit applied from wallet for this line (paise).
  final int depositApplied;

  /// Frozen billing mode at issue (`daily`/`weekly`/…).
  final String billingMode;

  /// Frozen rate in paise at issue (catalog or dynamic override).
  final int rateAmount;

  /// Frozen late fee per day in paise at issue.
  final int lateFeePerDay;

  /// `rent` | `sell` — how this line was issued.
  final String fulfillment;

  /// How a closed rent line settled: `returned` | `lost` (null on open / legacy).
  final String? returnDisposition;
  const RentalItemRow({
    required this.id,
    required this.rentalId,
    required this.itemId,
    required this.instanceName,
    required this.shortCode,
    this.returnedAt,
    required this.baseAmount,
    required this.lateAmount,
    required this.depositApplied,
    required this.billingMode,
    required this.rateAmount,
    required this.lateFeePerDay,
    required this.fulfillment,
    this.returnDisposition,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['rental_id'] = Variable<String>(rentalId);
    map['item_id'] = Variable<String>(itemId);
    map['instance_name'] = Variable<String>(instanceName);
    map['short_code'] = Variable<String>(shortCode);
    if (!nullToAbsent || returnedAt != null) {
      map['returned_at'] = Variable<DateTime>(returnedAt);
    }
    map['base_amount'] = Variable<int>(baseAmount);
    map['late_amount'] = Variable<int>(lateAmount);
    map['deposit_applied'] = Variable<int>(depositApplied);
    map['billing_mode'] = Variable<String>(billingMode);
    map['rate_amount'] = Variable<int>(rateAmount);
    map['late_fee_per_day'] = Variable<int>(lateFeePerDay);
    map['fulfillment'] = Variable<String>(fulfillment);
    if (!nullToAbsent || returnDisposition != null) {
      map['return_disposition'] = Variable<String>(returnDisposition);
    }
    return map;
  }

  RentalItemsCompanion toCompanion(bool nullToAbsent) {
    return RentalItemsCompanion(
      id: Value(id),
      rentalId: Value(rentalId),
      itemId: Value(itemId),
      instanceName: Value(instanceName),
      shortCode: Value(shortCode),
      returnedAt: returnedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(returnedAt),
      baseAmount: Value(baseAmount),
      lateAmount: Value(lateAmount),
      depositApplied: Value(depositApplied),
      billingMode: Value(billingMode),
      rateAmount: Value(rateAmount),
      lateFeePerDay: Value(lateFeePerDay),
      fulfillment: Value(fulfillment),
      returnDisposition: returnDisposition == null && nullToAbsent
          ? const Value.absent()
          : Value(returnDisposition),
    );
  }

  factory RentalItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RentalItemRow(
      id: serializer.fromJson<String>(json['id']),
      rentalId: serializer.fromJson<String>(json['rentalId']),
      itemId: serializer.fromJson<String>(json['itemId']),
      instanceName: serializer.fromJson<String>(json['instanceName']),
      shortCode: serializer.fromJson<String>(json['shortCode']),
      returnedAt: serializer.fromJson<DateTime?>(json['returnedAt']),
      baseAmount: serializer.fromJson<int>(json['baseAmount']),
      lateAmount: serializer.fromJson<int>(json['lateAmount']),
      depositApplied: serializer.fromJson<int>(json['depositApplied']),
      billingMode: serializer.fromJson<String>(json['billingMode']),
      rateAmount: serializer.fromJson<int>(json['rateAmount']),
      lateFeePerDay: serializer.fromJson<int>(json['lateFeePerDay']),
      fulfillment: serializer.fromJson<String>(json['fulfillment']),
      returnDisposition: serializer.fromJson<String?>(
        json['returnDisposition'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'rentalId': serializer.toJson<String>(rentalId),
      'itemId': serializer.toJson<String>(itemId),
      'instanceName': serializer.toJson<String>(instanceName),
      'shortCode': serializer.toJson<String>(shortCode),
      'returnedAt': serializer.toJson<DateTime?>(returnedAt),
      'baseAmount': serializer.toJson<int>(baseAmount),
      'lateAmount': serializer.toJson<int>(lateAmount),
      'depositApplied': serializer.toJson<int>(depositApplied),
      'billingMode': serializer.toJson<String>(billingMode),
      'rateAmount': serializer.toJson<int>(rateAmount),
      'lateFeePerDay': serializer.toJson<int>(lateFeePerDay),
      'fulfillment': serializer.toJson<String>(fulfillment),
      'returnDisposition': serializer.toJson<String?>(returnDisposition),
    };
  }

  RentalItemRow copyWith({
    String? id,
    String? rentalId,
    String? itemId,
    String? instanceName,
    String? shortCode,
    Value<DateTime?> returnedAt = const Value.absent(),
    int? baseAmount,
    int? lateAmount,
    int? depositApplied,
    String? billingMode,
    int? rateAmount,
    int? lateFeePerDay,
    String? fulfillment,
    Value<String?> returnDisposition = const Value.absent(),
  }) => RentalItemRow(
    id: id ?? this.id,
    rentalId: rentalId ?? this.rentalId,
    itemId: itemId ?? this.itemId,
    instanceName: instanceName ?? this.instanceName,
    shortCode: shortCode ?? this.shortCode,
    returnedAt: returnedAt.present ? returnedAt.value : this.returnedAt,
    baseAmount: baseAmount ?? this.baseAmount,
    lateAmount: lateAmount ?? this.lateAmount,
    depositApplied: depositApplied ?? this.depositApplied,
    billingMode: billingMode ?? this.billingMode,
    rateAmount: rateAmount ?? this.rateAmount,
    lateFeePerDay: lateFeePerDay ?? this.lateFeePerDay,
    fulfillment: fulfillment ?? this.fulfillment,
    returnDisposition: returnDisposition.present
        ? returnDisposition.value
        : this.returnDisposition,
  );
  RentalItemRow copyWithCompanion(RentalItemsCompanion data) {
    return RentalItemRow(
      id: data.id.present ? data.id.value : this.id,
      rentalId: data.rentalId.present ? data.rentalId.value : this.rentalId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      instanceName: data.instanceName.present
          ? data.instanceName.value
          : this.instanceName,
      shortCode: data.shortCode.present ? data.shortCode.value : this.shortCode,
      returnedAt: data.returnedAt.present
          ? data.returnedAt.value
          : this.returnedAt,
      baseAmount: data.baseAmount.present
          ? data.baseAmount.value
          : this.baseAmount,
      lateAmount: data.lateAmount.present
          ? data.lateAmount.value
          : this.lateAmount,
      depositApplied: data.depositApplied.present
          ? data.depositApplied.value
          : this.depositApplied,
      billingMode: data.billingMode.present
          ? data.billingMode.value
          : this.billingMode,
      rateAmount: data.rateAmount.present
          ? data.rateAmount.value
          : this.rateAmount,
      lateFeePerDay: data.lateFeePerDay.present
          ? data.lateFeePerDay.value
          : this.lateFeePerDay,
      fulfillment: data.fulfillment.present
          ? data.fulfillment.value
          : this.fulfillment,
      returnDisposition: data.returnDisposition.present
          ? data.returnDisposition.value
          : this.returnDisposition,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RentalItemRow(')
          ..write('id: $id, ')
          ..write('rentalId: $rentalId, ')
          ..write('itemId: $itemId, ')
          ..write('instanceName: $instanceName, ')
          ..write('shortCode: $shortCode, ')
          ..write('returnedAt: $returnedAt, ')
          ..write('baseAmount: $baseAmount, ')
          ..write('lateAmount: $lateAmount, ')
          ..write('depositApplied: $depositApplied, ')
          ..write('billingMode: $billingMode, ')
          ..write('rateAmount: $rateAmount, ')
          ..write('lateFeePerDay: $lateFeePerDay, ')
          ..write('fulfillment: $fulfillment, ')
          ..write('returnDisposition: $returnDisposition')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    rentalId,
    itemId,
    instanceName,
    shortCode,
    returnedAt,
    baseAmount,
    lateAmount,
    depositApplied,
    billingMode,
    rateAmount,
    lateFeePerDay,
    fulfillment,
    returnDisposition,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RentalItemRow &&
          other.id == this.id &&
          other.rentalId == this.rentalId &&
          other.itemId == this.itemId &&
          other.instanceName == this.instanceName &&
          other.shortCode == this.shortCode &&
          other.returnedAt == this.returnedAt &&
          other.baseAmount == this.baseAmount &&
          other.lateAmount == this.lateAmount &&
          other.depositApplied == this.depositApplied &&
          other.billingMode == this.billingMode &&
          other.rateAmount == this.rateAmount &&
          other.lateFeePerDay == this.lateFeePerDay &&
          other.fulfillment == this.fulfillment &&
          other.returnDisposition == this.returnDisposition);
}

class RentalItemsCompanion extends UpdateCompanion<RentalItemRow> {
  final Value<String> id;
  final Value<String> rentalId;
  final Value<String> itemId;
  final Value<String> instanceName;
  final Value<String> shortCode;
  final Value<DateTime?> returnedAt;
  final Value<int> baseAmount;
  final Value<int> lateAmount;
  final Value<int> depositApplied;
  final Value<String> billingMode;
  final Value<int> rateAmount;
  final Value<int> lateFeePerDay;
  final Value<String> fulfillment;
  final Value<String?> returnDisposition;
  final Value<int> rowid;
  const RentalItemsCompanion({
    this.id = const Value.absent(),
    this.rentalId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.instanceName = const Value.absent(),
    this.shortCode = const Value.absent(),
    this.returnedAt = const Value.absent(),
    this.baseAmount = const Value.absent(),
    this.lateAmount = const Value.absent(),
    this.depositApplied = const Value.absent(),
    this.billingMode = const Value.absent(),
    this.rateAmount = const Value.absent(),
    this.lateFeePerDay = const Value.absent(),
    this.fulfillment = const Value.absent(),
    this.returnDisposition = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RentalItemsCompanion.insert({
    required String id,
    required String rentalId,
    required String itemId,
    this.instanceName = const Value.absent(),
    this.shortCode = const Value.absent(),
    this.returnedAt = const Value.absent(),
    this.baseAmount = const Value.absent(),
    this.lateAmount = const Value.absent(),
    this.depositApplied = const Value.absent(),
    this.billingMode = const Value.absent(),
    this.rateAmount = const Value.absent(),
    this.lateFeePerDay = const Value.absent(),
    this.fulfillment = const Value.absent(),
    this.returnDisposition = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       rentalId = Value(rentalId),
       itemId = Value(itemId);
  static Insertable<RentalItemRow> custom({
    Expression<String>? id,
    Expression<String>? rentalId,
    Expression<String>? itemId,
    Expression<String>? instanceName,
    Expression<String>? shortCode,
    Expression<DateTime>? returnedAt,
    Expression<int>? baseAmount,
    Expression<int>? lateAmount,
    Expression<int>? depositApplied,
    Expression<String>? billingMode,
    Expression<int>? rateAmount,
    Expression<int>? lateFeePerDay,
    Expression<String>? fulfillment,
    Expression<String>? returnDisposition,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (rentalId != null) 'rental_id': rentalId,
      if (itemId != null) 'item_id': itemId,
      if (instanceName != null) 'instance_name': instanceName,
      if (shortCode != null) 'short_code': shortCode,
      if (returnedAt != null) 'returned_at': returnedAt,
      if (baseAmount != null) 'base_amount': baseAmount,
      if (lateAmount != null) 'late_amount': lateAmount,
      if (depositApplied != null) 'deposit_applied': depositApplied,
      if (billingMode != null) 'billing_mode': billingMode,
      if (rateAmount != null) 'rate_amount': rateAmount,
      if (lateFeePerDay != null) 'late_fee_per_day': lateFeePerDay,
      if (fulfillment != null) 'fulfillment': fulfillment,
      if (returnDisposition != null) 'return_disposition': returnDisposition,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RentalItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? rentalId,
    Value<String>? itemId,
    Value<String>? instanceName,
    Value<String>? shortCode,
    Value<DateTime?>? returnedAt,
    Value<int>? baseAmount,
    Value<int>? lateAmount,
    Value<int>? depositApplied,
    Value<String>? billingMode,
    Value<int>? rateAmount,
    Value<int>? lateFeePerDay,
    Value<String>? fulfillment,
    Value<String?>? returnDisposition,
    Value<int>? rowid,
  }) {
    return RentalItemsCompanion(
      id: id ?? this.id,
      rentalId: rentalId ?? this.rentalId,
      itemId: itemId ?? this.itemId,
      instanceName: instanceName ?? this.instanceName,
      shortCode: shortCode ?? this.shortCode,
      returnedAt: returnedAt ?? this.returnedAt,
      baseAmount: baseAmount ?? this.baseAmount,
      lateAmount: lateAmount ?? this.lateAmount,
      depositApplied: depositApplied ?? this.depositApplied,
      billingMode: billingMode ?? this.billingMode,
      rateAmount: rateAmount ?? this.rateAmount,
      lateFeePerDay: lateFeePerDay ?? this.lateFeePerDay,
      fulfillment: fulfillment ?? this.fulfillment,
      returnDisposition: returnDisposition ?? this.returnDisposition,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
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
    if (returnedAt.present) {
      map['returned_at'] = Variable<DateTime>(returnedAt.value);
    }
    if (baseAmount.present) {
      map['base_amount'] = Variable<int>(baseAmount.value);
    }
    if (lateAmount.present) {
      map['late_amount'] = Variable<int>(lateAmount.value);
    }
    if (depositApplied.present) {
      map['deposit_applied'] = Variable<int>(depositApplied.value);
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
    if (fulfillment.present) {
      map['fulfillment'] = Variable<String>(fulfillment.value);
    }
    if (returnDisposition.present) {
      map['return_disposition'] = Variable<String>(returnDisposition.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RentalItemsCompanion(')
          ..write('id: $id, ')
          ..write('rentalId: $rentalId, ')
          ..write('itemId: $itemId, ')
          ..write('instanceName: $instanceName, ')
          ..write('shortCode: $shortCode, ')
          ..write('returnedAt: $returnedAt, ')
          ..write('baseAmount: $baseAmount, ')
          ..write('lateAmount: $lateAmount, ')
          ..write('depositApplied: $depositApplied, ')
          ..write('billingMode: $billingMode, ')
          ..write('rateAmount: $rateAmount, ')
          ..write('lateFeePerDay: $lateFeePerDay, ')
          ..write('fulfillment: $fulfillment, ')
          ..write('returnDisposition: $returnDisposition, ')
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

class $RentalNotesTable extends RentalNotes
    with TableInfo<$RentalNotesTable, RentalNoteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RentalNotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _rentalItemIdMeta = const VerificationMeta(
    'rentalItemId',
  );
  @override
  late final GeneratedColumn<String> rentalItemId = GeneratedColumn<String>(
    'rental_item_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('general'),
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    rentalId,
    rentalItemId,
    kind,
    body,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rental_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<RentalNoteRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('rental_id')) {
      context.handle(
        _rentalIdMeta,
        rentalId.isAcceptableOrUnknown(data['rental_id']!, _rentalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_rentalIdMeta);
    }
    if (data.containsKey('rental_item_id')) {
      context.handle(
        _rentalItemIdMeta,
        rentalItemId.isAcceptableOrUnknown(
          data['rental_item_id']!,
          _rentalItemIdMeta,
        ),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RentalNoteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RentalNoteRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      rentalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rental_id'],
      )!,
      rentalItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rental_item_id'],
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $RentalNotesTable createAlias(String alias) {
    return $RentalNotesTable(attachedDatabase, alias);
  }
}

class RentalNoteRow extends DataClass implements Insertable<RentalNoteRow> {
  final String id;
  final String rentalId;
  final String? rentalItemId;

  /// `general` | `terms` | `measurement`
  final String kind;
  final String body;
  final DateTime createdAt;
  const RentalNoteRow({
    required this.id,
    required this.rentalId,
    this.rentalItemId,
    required this.kind,
    required this.body,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['rental_id'] = Variable<String>(rentalId);
    if (!nullToAbsent || rentalItemId != null) {
      map['rental_item_id'] = Variable<String>(rentalItemId);
    }
    map['kind'] = Variable<String>(kind);
    map['body'] = Variable<String>(body);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  RentalNotesCompanion toCompanion(bool nullToAbsent) {
    return RentalNotesCompanion(
      id: Value(id),
      rentalId: Value(rentalId),
      rentalItemId: rentalItemId == null && nullToAbsent
          ? const Value.absent()
          : Value(rentalItemId),
      kind: Value(kind),
      body: Value(body),
      createdAt: Value(createdAt),
    );
  }

  factory RentalNoteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RentalNoteRow(
      id: serializer.fromJson<String>(json['id']),
      rentalId: serializer.fromJson<String>(json['rentalId']),
      rentalItemId: serializer.fromJson<String?>(json['rentalItemId']),
      kind: serializer.fromJson<String>(json['kind']),
      body: serializer.fromJson<String>(json['body']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'rentalId': serializer.toJson<String>(rentalId),
      'rentalItemId': serializer.toJson<String?>(rentalItemId),
      'kind': serializer.toJson<String>(kind),
      'body': serializer.toJson<String>(body),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  RentalNoteRow copyWith({
    String? id,
    String? rentalId,
    Value<String?> rentalItemId = const Value.absent(),
    String? kind,
    String? body,
    DateTime? createdAt,
  }) => RentalNoteRow(
    id: id ?? this.id,
    rentalId: rentalId ?? this.rentalId,
    rentalItemId: rentalItemId.present ? rentalItemId.value : this.rentalItemId,
    kind: kind ?? this.kind,
    body: body ?? this.body,
    createdAt: createdAt ?? this.createdAt,
  );
  RentalNoteRow copyWithCompanion(RentalNotesCompanion data) {
    return RentalNoteRow(
      id: data.id.present ? data.id.value : this.id,
      rentalId: data.rentalId.present ? data.rentalId.value : this.rentalId,
      rentalItemId: data.rentalItemId.present
          ? data.rentalItemId.value
          : this.rentalItemId,
      kind: data.kind.present ? data.kind.value : this.kind,
      body: data.body.present ? data.body.value : this.body,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RentalNoteRow(')
          ..write('id: $id, ')
          ..write('rentalId: $rentalId, ')
          ..write('rentalItemId: $rentalItemId, ')
          ..write('kind: $kind, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, rentalId, rentalItemId, kind, body, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RentalNoteRow &&
          other.id == this.id &&
          other.rentalId == this.rentalId &&
          other.rentalItemId == this.rentalItemId &&
          other.kind == this.kind &&
          other.body == this.body &&
          other.createdAt == this.createdAt);
}

class RentalNotesCompanion extends UpdateCompanion<RentalNoteRow> {
  final Value<String> id;
  final Value<String> rentalId;
  final Value<String?> rentalItemId;
  final Value<String> kind;
  final Value<String> body;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const RentalNotesCompanion({
    this.id = const Value.absent(),
    this.rentalId = const Value.absent(),
    this.rentalItemId = const Value.absent(),
    this.kind = const Value.absent(),
    this.body = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RentalNotesCompanion.insert({
    required String id,
    required String rentalId,
    this.rentalItemId = const Value.absent(),
    this.kind = const Value.absent(),
    required String body,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       rentalId = Value(rentalId),
       body = Value(body),
       createdAt = Value(createdAt);
  static Insertable<RentalNoteRow> custom({
    Expression<String>? id,
    Expression<String>? rentalId,
    Expression<String>? rentalItemId,
    Expression<String>? kind,
    Expression<String>? body,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (rentalId != null) 'rental_id': rentalId,
      if (rentalItemId != null) 'rental_item_id': rentalItemId,
      if (kind != null) 'kind': kind,
      if (body != null) 'body': body,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RentalNotesCompanion copyWith({
    Value<String>? id,
    Value<String>? rentalId,
    Value<String?>? rentalItemId,
    Value<String>? kind,
    Value<String>? body,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return RentalNotesCompanion(
      id: id ?? this.id,
      rentalId: rentalId ?? this.rentalId,
      rentalItemId: rentalItemId ?? this.rentalItemId,
      kind: kind ?? this.kind,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (rentalId.present) {
      map['rental_id'] = Variable<String>(rentalId.value);
    }
    if (rentalItemId.present) {
      map['rental_item_id'] = Variable<String>(rentalItemId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RentalNotesCompanion(')
          ..write('id: $id, ')
          ..write('rentalId: $rentalId, ')
          ..write('rentalItemId: $rentalItemId, ')
          ..write('kind: $kind, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DepositLedgerTable extends DepositLedger
    with TableInfo<$DepositLedgerTable, DepositLedgerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DepositLedgerTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _rentalIdMeta = const VerificationMeta(
    'rentalId',
  );
  @override
  late final GeneratedColumn<String> rentalId = GeneratedColumn<String>(
    'rental_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _balanceAfterMeta = const VerificationMeta(
    'balanceAfter',
  );
  @override
  late final GeneratedColumn<int> balanceAfter = GeneratedColumn<int>(
    'balance_after',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  List<GeneratedColumn> get $columns => [
    id,
    customerId,
    rentalId,
    type,
    amount,
    balanceAfter,
    note,
    at,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'deposit_ledger';
  @override
  VerificationContext validateIntegrity(
    Insertable<DepositLedgerRow> instance, {
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
    if (data.containsKey('rental_id')) {
      context.handle(
        _rentalIdMeta,
        rentalId.isAcceptableOrUnknown(data['rental_id']!, _rentalIdMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('balance_after')) {
      context.handle(
        _balanceAfterMeta,
        balanceAfter.isAcceptableOrUnknown(
          data['balance_after']!,
          _balanceAfterMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_balanceAfterMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
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
  DepositLedgerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DepositLedgerRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      )!,
      rentalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rental_id'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      balanceAfter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}balance_after'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
    );
  }

  @override
  $DepositLedgerTable createAlias(String alias) {
    return $DepositLedgerTable(attachedDatabase, alias);
  }
}

class DepositLedgerRow extends DataClass
    implements Insertable<DepositLedgerRow> {
  final String id;
  final String customerId;
  final String? rentalId;

  /// `top_up` | `apply` | `refund` | `adjust`
  final String type;

  /// Signed amount in paise (+ top-up, − apply/refund).
  final int amount;
  final int balanceAfter;
  final String? note;
  final DateTime at;
  const DepositLedgerRow({
    required this.id,
    required this.customerId,
    this.rentalId,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    this.note,
    required this.at,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['customer_id'] = Variable<String>(customerId);
    if (!nullToAbsent || rentalId != null) {
      map['rental_id'] = Variable<String>(rentalId);
    }
    map['type'] = Variable<String>(type);
    map['amount'] = Variable<int>(amount);
    map['balance_after'] = Variable<int>(balanceAfter);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['at'] = Variable<DateTime>(at);
    return map;
  }

  DepositLedgerCompanion toCompanion(bool nullToAbsent) {
    return DepositLedgerCompanion(
      id: Value(id),
      customerId: Value(customerId),
      rentalId: rentalId == null && nullToAbsent
          ? const Value.absent()
          : Value(rentalId),
      type: Value(type),
      amount: Value(amount),
      balanceAfter: Value(balanceAfter),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      at: Value(at),
    );
  }

  factory DepositLedgerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DepositLedgerRow(
      id: serializer.fromJson<String>(json['id']),
      customerId: serializer.fromJson<String>(json['customerId']),
      rentalId: serializer.fromJson<String?>(json['rentalId']),
      type: serializer.fromJson<String>(json['type']),
      amount: serializer.fromJson<int>(json['amount']),
      balanceAfter: serializer.fromJson<int>(json['balanceAfter']),
      note: serializer.fromJson<String?>(json['note']),
      at: serializer.fromJson<DateTime>(json['at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'customerId': serializer.toJson<String>(customerId),
      'rentalId': serializer.toJson<String?>(rentalId),
      'type': serializer.toJson<String>(type),
      'amount': serializer.toJson<int>(amount),
      'balanceAfter': serializer.toJson<int>(balanceAfter),
      'note': serializer.toJson<String?>(note),
      'at': serializer.toJson<DateTime>(at),
    };
  }

  DepositLedgerRow copyWith({
    String? id,
    String? customerId,
    Value<String?> rentalId = const Value.absent(),
    String? type,
    int? amount,
    int? balanceAfter,
    Value<String?> note = const Value.absent(),
    DateTime? at,
  }) => DepositLedgerRow(
    id: id ?? this.id,
    customerId: customerId ?? this.customerId,
    rentalId: rentalId.present ? rentalId.value : this.rentalId,
    type: type ?? this.type,
    amount: amount ?? this.amount,
    balanceAfter: balanceAfter ?? this.balanceAfter,
    note: note.present ? note.value : this.note,
    at: at ?? this.at,
  );
  DepositLedgerRow copyWithCompanion(DepositLedgerCompanion data) {
    return DepositLedgerRow(
      id: data.id.present ? data.id.value : this.id,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      rentalId: data.rentalId.present ? data.rentalId.value : this.rentalId,
      type: data.type.present ? data.type.value : this.type,
      amount: data.amount.present ? data.amount.value : this.amount,
      balanceAfter: data.balanceAfter.present
          ? data.balanceAfter.value
          : this.balanceAfter,
      note: data.note.present ? data.note.value : this.note,
      at: data.at.present ? data.at.value : this.at,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DepositLedgerRow(')
          ..write('id: $id, ')
          ..write('customerId: $customerId, ')
          ..write('rentalId: $rentalId, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('balanceAfter: $balanceAfter, ')
          ..write('note: $note, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    customerId,
    rentalId,
    type,
    amount,
    balanceAfter,
    note,
    at,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DepositLedgerRow &&
          other.id == this.id &&
          other.customerId == this.customerId &&
          other.rentalId == this.rentalId &&
          other.type == this.type &&
          other.amount == this.amount &&
          other.balanceAfter == this.balanceAfter &&
          other.note == this.note &&
          other.at == this.at);
}

class DepositLedgerCompanion extends UpdateCompanion<DepositLedgerRow> {
  final Value<String> id;
  final Value<String> customerId;
  final Value<String?> rentalId;
  final Value<String> type;
  final Value<int> amount;
  final Value<int> balanceAfter;
  final Value<String?> note;
  final Value<DateTime> at;
  final Value<int> rowid;
  const DepositLedgerCompanion({
    this.id = const Value.absent(),
    this.customerId = const Value.absent(),
    this.rentalId = const Value.absent(),
    this.type = const Value.absent(),
    this.amount = const Value.absent(),
    this.balanceAfter = const Value.absent(),
    this.note = const Value.absent(),
    this.at = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DepositLedgerCompanion.insert({
    required String id,
    required String customerId,
    this.rentalId = const Value.absent(),
    required String type,
    required int amount,
    required int balanceAfter,
    this.note = const Value.absent(),
    required DateTime at,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       customerId = Value(customerId),
       type = Value(type),
       amount = Value(amount),
       balanceAfter = Value(balanceAfter),
       at = Value(at);
  static Insertable<DepositLedgerRow> custom({
    Expression<String>? id,
    Expression<String>? customerId,
    Expression<String>? rentalId,
    Expression<String>? type,
    Expression<int>? amount,
    Expression<int>? balanceAfter,
    Expression<String>? note,
    Expression<DateTime>? at,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (customerId != null) 'customer_id': customerId,
      if (rentalId != null) 'rental_id': rentalId,
      if (type != null) 'type': type,
      if (amount != null) 'amount': amount,
      if (balanceAfter != null) 'balance_after': balanceAfter,
      if (note != null) 'note': note,
      if (at != null) 'at': at,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DepositLedgerCompanion copyWith({
    Value<String>? id,
    Value<String>? customerId,
    Value<String?>? rentalId,
    Value<String>? type,
    Value<int>? amount,
    Value<int>? balanceAfter,
    Value<String?>? note,
    Value<DateTime>? at,
    Value<int>? rowid,
  }) {
    return DepositLedgerCompanion(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      rentalId: rentalId ?? this.rentalId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      note: note ?? this.note,
      at: at ?? this.at,
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
    if (rentalId.present) {
      map['rental_id'] = Variable<String>(rentalId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (balanceAfter.present) {
      map['balance_after'] = Variable<int>(balanceAfter.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DepositLedgerCompanion(')
          ..write('id: $id, ')
          ..write('customerId: $customerId, ')
          ..write('rentalId: $rentalId, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('balanceAfter: $balanceAfter, ')
          ..write('note: $note, ')
          ..write('at: $at, ')
          ..write('rowid: $rowid')
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

class $MoneyLoansTable extends MoneyLoans
    with TableInfo<$MoneyLoansTable, MoneyLoanRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MoneyLoansTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _principalPaiseMeta = const VerificationMeta(
    'principalPaise',
  );
  @override
  late final GeneratedColumn<int> principalPaise = GeneratedColumn<int>(
    'principal_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
  static const VerificationMeta _interestKindMeta = const VerificationMeta(
    'interestKind',
  );
  @override
  late final GeneratedColumn<String> interestKind = GeneratedColumn<String>(
    'interest_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('simple'),
  );
  static const VerificationMeta _rateBpsMeta = const VerificationMeta(
    'rateBps',
  );
  @override
  late final GeneratedColumn<int> rateBps = GeneratedColumn<int>(
    'rate_bps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _ratePeriodMeta = const VerificationMeta(
    'ratePeriod',
  );
  @override
  late final GeneratedColumn<String> ratePeriod = GeneratedColumn<String>(
    'rate_period',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('monthly'),
  );
  static const VerificationMeta _interestAccrualMeta = const VerificationMeta(
    'interestAccrual',
  );
  @override
  late final GeneratedColumn<String> interestAccrual = GeneratedColumn<String>(
    'interest_accrual',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('calendar'),
  );
  static const VerificationMeta _capitalizationPolicyMeta =
      const VerificationMeta('capitalizationPolicy');
  @override
  late final GeneratedColumn<String> capitalizationPolicy =
      GeneratedColumn<String>(
        'capitalization_policy',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('never'),
      );
  static const VerificationMeta _capitalizationCycleMeta =
      const VerificationMeta('capitalizationCycle');
  @override
  late final GeneratedColumn<String> capitalizationCycle =
      GeneratedColumn<String>(
        'capitalization_cycle',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('monthly'),
      );
  static const VerificationMeta _interestStartedAtMeta = const VerificationMeta(
    'interestStartedAt',
  );
  @override
  late final GeneratedColumn<DateTime> interestStartedAt =
      GeneratedColumn<DateTime>(
        'interest_started_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _interestEndedAtMeta = const VerificationMeta(
    'interestEndedAt',
  );
  @override
  late final GeneratedColumn<DateTime> interestEndedAt =
      GeneratedColumn<DateTime>(
        'interest_ended_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _prepaymentAllocationMeta =
      const VerificationMeta('prepaymentAllocation');
  @override
  late final GeneratedColumn<String> prepaymentAllocation =
      GeneratedColumn<String>(
        'prepayment_allocation',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('interestThenPrincipal'),
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _closedAtMeta = const VerificationMeta(
    'closedAt',
  );
  @override
  late final GeneratedColumn<DateTime> closedAt = GeneratedColumn<DateTime>(
    'closed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    customerId,
    direction,
    principalPaise,
    currencyCode,
    interestKind,
    rateBps,
    ratePeriod,
    interestAccrual,
    capitalizationPolicy,
    capitalizationCycle,
    interestStartedAt,
    interestEndedAt,
    prepaymentAllocation,
    status,
    closedAt,
    note,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'money_loans';
  @override
  VerificationContext validateIntegrity(
    Insertable<MoneyLoanRow> instance, {
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
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('principal_paise')) {
      context.handle(
        _principalPaiseMeta,
        principalPaise.isAcceptableOrUnknown(
          data['principal_paise']!,
          _principalPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_principalPaiseMeta);
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
    if (data.containsKey('interest_kind')) {
      context.handle(
        _interestKindMeta,
        interestKind.isAcceptableOrUnknown(
          data['interest_kind']!,
          _interestKindMeta,
        ),
      );
    }
    if (data.containsKey('rate_bps')) {
      context.handle(
        _rateBpsMeta,
        rateBps.isAcceptableOrUnknown(data['rate_bps']!, _rateBpsMeta),
      );
    }
    if (data.containsKey('rate_period')) {
      context.handle(
        _ratePeriodMeta,
        ratePeriod.isAcceptableOrUnknown(data['rate_period']!, _ratePeriodMeta),
      );
    }
    if (data.containsKey('interest_accrual')) {
      context.handle(
        _interestAccrualMeta,
        interestAccrual.isAcceptableOrUnknown(
          data['interest_accrual']!,
          _interestAccrualMeta,
        ),
      );
    }
    if (data.containsKey('capitalization_policy')) {
      context.handle(
        _capitalizationPolicyMeta,
        capitalizationPolicy.isAcceptableOrUnknown(
          data['capitalization_policy']!,
          _capitalizationPolicyMeta,
        ),
      );
    }
    if (data.containsKey('capitalization_cycle')) {
      context.handle(
        _capitalizationCycleMeta,
        capitalizationCycle.isAcceptableOrUnknown(
          data['capitalization_cycle']!,
          _capitalizationCycleMeta,
        ),
      );
    }
    if (data.containsKey('interest_started_at')) {
      context.handle(
        _interestStartedAtMeta,
        interestStartedAt.isAcceptableOrUnknown(
          data['interest_started_at']!,
          _interestStartedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_interestStartedAtMeta);
    }
    if (data.containsKey('interest_ended_at')) {
      context.handle(
        _interestEndedAtMeta,
        interestEndedAt.isAcceptableOrUnknown(
          data['interest_ended_at']!,
          _interestEndedAtMeta,
        ),
      );
    }
    if (data.containsKey('prepayment_allocation')) {
      context.handle(
        _prepaymentAllocationMeta,
        prepaymentAllocation.isAcceptableOrUnknown(
          data['prepayment_allocation']!,
          _prepaymentAllocationMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('closed_at')) {
      context.handle(
        _closedAtMeta,
        closedAt.isAcceptableOrUnknown(data['closed_at']!, _closedAtMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MoneyLoanRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MoneyLoanRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      customerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_id'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction'],
      )!,
      principalPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}principal_paise'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      interestKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}interest_kind'],
      )!,
      rateBps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rate_bps'],
      )!,
      ratePeriod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rate_period'],
      )!,
      interestAccrual: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}interest_accrual'],
      )!,
      capitalizationPolicy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}capitalization_policy'],
      )!,
      capitalizationCycle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}capitalization_cycle'],
      )!,
      interestStartedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}interest_started_at'],
      )!,
      interestEndedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}interest_ended_at'],
      ),
      prepaymentAllocation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prepayment_allocation'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      closedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}closed_at'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MoneyLoansTable createAlias(String alias) {
    return $MoneyLoansTable(attachedDatabase, alias);
  }
}

class MoneyLoanRow extends DataClass implements Insertable<MoneyLoanRow> {
  final String id;
  final String customerId;

  /// `given` | `taken`
  final String direction;

  /// Principal in paise.
  final int principalPaise;
  final String currencyCode;

  /// Legacy `simple` | `compound` (prefer [capitalizationPolicy]).
  final String interestKind;

  /// Rate in basis points (100 bps = 1%).
  final int rateBps;

  /// Rate period: `monthly` | `yearly` (legacy `daily` migrated to yearly).
  final String ratePeriod;

  /// Accrual basis: `calendar` | `daily365` (ACT/365).
  final String interestAccrual;

  /// `never` | `onPayment` | `onScheduledCycle` | `onBalanceDirectionChange` |
  /// `onLoanClosure` | `manual`
  final String capitalizationPolicy;

  /// `monthly` | `quarterly` | `yearly` (when policy is onScheduledCycle)
  final String capitalizationCycle;

  /// Date money was first given / interest clock start.
  final DateTime interestStartedAt;

  /// Optional due / maturity; caps accrual when before as-of.
  final DateTime? interestEndedAt;

  /// `interestThenPrincipal` | `principalOnly`
  final String prepaymentAllocation;

  /// `pending` | `closed` | `cancelled`
  final String status;
  final DateTime? closedAt;
  final String? note;
  final DateTime createdAt;
  const MoneyLoanRow({
    required this.id,
    required this.customerId,
    required this.direction,
    required this.principalPaise,
    required this.currencyCode,
    required this.interestKind,
    required this.rateBps,
    required this.ratePeriod,
    required this.interestAccrual,
    required this.capitalizationPolicy,
    required this.capitalizationCycle,
    required this.interestStartedAt,
    this.interestEndedAt,
    required this.prepaymentAllocation,
    required this.status,
    this.closedAt,
    this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['customer_id'] = Variable<String>(customerId);
    map['direction'] = Variable<String>(direction);
    map['principal_paise'] = Variable<int>(principalPaise);
    map['currency_code'] = Variable<String>(currencyCode);
    map['interest_kind'] = Variable<String>(interestKind);
    map['rate_bps'] = Variable<int>(rateBps);
    map['rate_period'] = Variable<String>(ratePeriod);
    map['interest_accrual'] = Variable<String>(interestAccrual);
    map['capitalization_policy'] = Variable<String>(capitalizationPolicy);
    map['capitalization_cycle'] = Variable<String>(capitalizationCycle);
    map['interest_started_at'] = Variable<DateTime>(interestStartedAt);
    if (!nullToAbsent || interestEndedAt != null) {
      map['interest_ended_at'] = Variable<DateTime>(interestEndedAt);
    }
    map['prepayment_allocation'] = Variable<String>(prepaymentAllocation);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || closedAt != null) {
      map['closed_at'] = Variable<DateTime>(closedAt);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MoneyLoansCompanion toCompanion(bool nullToAbsent) {
    return MoneyLoansCompanion(
      id: Value(id),
      customerId: Value(customerId),
      direction: Value(direction),
      principalPaise: Value(principalPaise),
      currencyCode: Value(currencyCode),
      interestKind: Value(interestKind),
      rateBps: Value(rateBps),
      ratePeriod: Value(ratePeriod),
      interestAccrual: Value(interestAccrual),
      capitalizationPolicy: Value(capitalizationPolicy),
      capitalizationCycle: Value(capitalizationCycle),
      interestStartedAt: Value(interestStartedAt),
      interestEndedAt: interestEndedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(interestEndedAt),
      prepaymentAllocation: Value(prepaymentAllocation),
      status: Value(status),
      closedAt: closedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(closedAt),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory MoneyLoanRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MoneyLoanRow(
      id: serializer.fromJson<String>(json['id']),
      customerId: serializer.fromJson<String>(json['customerId']),
      direction: serializer.fromJson<String>(json['direction']),
      principalPaise: serializer.fromJson<int>(json['principalPaise']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      interestKind: serializer.fromJson<String>(json['interestKind']),
      rateBps: serializer.fromJson<int>(json['rateBps']),
      ratePeriod: serializer.fromJson<String>(json['ratePeriod']),
      interestAccrual: serializer.fromJson<String>(json['interestAccrual']),
      capitalizationPolicy: serializer.fromJson<String>(
        json['capitalizationPolicy'],
      ),
      capitalizationCycle: serializer.fromJson<String>(
        json['capitalizationCycle'],
      ),
      interestStartedAt: serializer.fromJson<DateTime>(
        json['interestStartedAt'],
      ),
      interestEndedAt: serializer.fromJson<DateTime?>(json['interestEndedAt']),
      prepaymentAllocation: serializer.fromJson<String>(
        json['prepaymentAllocation'],
      ),
      status: serializer.fromJson<String>(json['status']),
      closedAt: serializer.fromJson<DateTime?>(json['closedAt']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'customerId': serializer.toJson<String>(customerId),
      'direction': serializer.toJson<String>(direction),
      'principalPaise': serializer.toJson<int>(principalPaise),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'interestKind': serializer.toJson<String>(interestKind),
      'rateBps': serializer.toJson<int>(rateBps),
      'ratePeriod': serializer.toJson<String>(ratePeriod),
      'interestAccrual': serializer.toJson<String>(interestAccrual),
      'capitalizationPolicy': serializer.toJson<String>(capitalizationPolicy),
      'capitalizationCycle': serializer.toJson<String>(capitalizationCycle),
      'interestStartedAt': serializer.toJson<DateTime>(interestStartedAt),
      'interestEndedAt': serializer.toJson<DateTime?>(interestEndedAt),
      'prepaymentAllocation': serializer.toJson<String>(prepaymentAllocation),
      'status': serializer.toJson<String>(status),
      'closedAt': serializer.toJson<DateTime?>(closedAt),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MoneyLoanRow copyWith({
    String? id,
    String? customerId,
    String? direction,
    int? principalPaise,
    String? currencyCode,
    String? interestKind,
    int? rateBps,
    String? ratePeriod,
    String? interestAccrual,
    String? capitalizationPolicy,
    String? capitalizationCycle,
    DateTime? interestStartedAt,
    Value<DateTime?> interestEndedAt = const Value.absent(),
    String? prepaymentAllocation,
    String? status,
    Value<DateTime?> closedAt = const Value.absent(),
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
  }) => MoneyLoanRow(
    id: id ?? this.id,
    customerId: customerId ?? this.customerId,
    direction: direction ?? this.direction,
    principalPaise: principalPaise ?? this.principalPaise,
    currencyCode: currencyCode ?? this.currencyCode,
    interestKind: interestKind ?? this.interestKind,
    rateBps: rateBps ?? this.rateBps,
    ratePeriod: ratePeriod ?? this.ratePeriod,
    interestAccrual: interestAccrual ?? this.interestAccrual,
    capitalizationPolicy: capitalizationPolicy ?? this.capitalizationPolicy,
    capitalizationCycle: capitalizationCycle ?? this.capitalizationCycle,
    interestStartedAt: interestStartedAt ?? this.interestStartedAt,
    interestEndedAt: interestEndedAt.present
        ? interestEndedAt.value
        : this.interestEndedAt,
    prepaymentAllocation: prepaymentAllocation ?? this.prepaymentAllocation,
    status: status ?? this.status,
    closedAt: closedAt.present ? closedAt.value : this.closedAt,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  MoneyLoanRow copyWithCompanion(MoneyLoansCompanion data) {
    return MoneyLoanRow(
      id: data.id.present ? data.id.value : this.id,
      customerId: data.customerId.present
          ? data.customerId.value
          : this.customerId,
      direction: data.direction.present ? data.direction.value : this.direction,
      principalPaise: data.principalPaise.present
          ? data.principalPaise.value
          : this.principalPaise,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      interestKind: data.interestKind.present
          ? data.interestKind.value
          : this.interestKind,
      rateBps: data.rateBps.present ? data.rateBps.value : this.rateBps,
      ratePeriod: data.ratePeriod.present
          ? data.ratePeriod.value
          : this.ratePeriod,
      interestAccrual: data.interestAccrual.present
          ? data.interestAccrual.value
          : this.interestAccrual,
      capitalizationPolicy: data.capitalizationPolicy.present
          ? data.capitalizationPolicy.value
          : this.capitalizationPolicy,
      capitalizationCycle: data.capitalizationCycle.present
          ? data.capitalizationCycle.value
          : this.capitalizationCycle,
      interestStartedAt: data.interestStartedAt.present
          ? data.interestStartedAt.value
          : this.interestStartedAt,
      interestEndedAt: data.interestEndedAt.present
          ? data.interestEndedAt.value
          : this.interestEndedAt,
      prepaymentAllocation: data.prepaymentAllocation.present
          ? data.prepaymentAllocation.value
          : this.prepaymentAllocation,
      status: data.status.present ? data.status.value : this.status,
      closedAt: data.closedAt.present ? data.closedAt.value : this.closedAt,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MoneyLoanRow(')
          ..write('id: $id, ')
          ..write('customerId: $customerId, ')
          ..write('direction: $direction, ')
          ..write('principalPaise: $principalPaise, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('interestKind: $interestKind, ')
          ..write('rateBps: $rateBps, ')
          ..write('ratePeriod: $ratePeriod, ')
          ..write('interestAccrual: $interestAccrual, ')
          ..write('capitalizationPolicy: $capitalizationPolicy, ')
          ..write('capitalizationCycle: $capitalizationCycle, ')
          ..write('interestStartedAt: $interestStartedAt, ')
          ..write('interestEndedAt: $interestEndedAt, ')
          ..write('prepaymentAllocation: $prepaymentAllocation, ')
          ..write('status: $status, ')
          ..write('closedAt: $closedAt, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    customerId,
    direction,
    principalPaise,
    currencyCode,
    interestKind,
    rateBps,
    ratePeriod,
    interestAccrual,
    capitalizationPolicy,
    capitalizationCycle,
    interestStartedAt,
    interestEndedAt,
    prepaymentAllocation,
    status,
    closedAt,
    note,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MoneyLoanRow &&
          other.id == this.id &&
          other.customerId == this.customerId &&
          other.direction == this.direction &&
          other.principalPaise == this.principalPaise &&
          other.currencyCode == this.currencyCode &&
          other.interestKind == this.interestKind &&
          other.rateBps == this.rateBps &&
          other.ratePeriod == this.ratePeriod &&
          other.interestAccrual == this.interestAccrual &&
          other.capitalizationPolicy == this.capitalizationPolicy &&
          other.capitalizationCycle == this.capitalizationCycle &&
          other.interestStartedAt == this.interestStartedAt &&
          other.interestEndedAt == this.interestEndedAt &&
          other.prepaymentAllocation == this.prepaymentAllocation &&
          other.status == this.status &&
          other.closedAt == this.closedAt &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class MoneyLoansCompanion extends UpdateCompanion<MoneyLoanRow> {
  final Value<String> id;
  final Value<String> customerId;
  final Value<String> direction;
  final Value<int> principalPaise;
  final Value<String> currencyCode;
  final Value<String> interestKind;
  final Value<int> rateBps;
  final Value<String> ratePeriod;
  final Value<String> interestAccrual;
  final Value<String> capitalizationPolicy;
  final Value<String> capitalizationCycle;
  final Value<DateTime> interestStartedAt;
  final Value<DateTime?> interestEndedAt;
  final Value<String> prepaymentAllocation;
  final Value<String> status;
  final Value<DateTime?> closedAt;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const MoneyLoansCompanion({
    this.id = const Value.absent(),
    this.customerId = const Value.absent(),
    this.direction = const Value.absent(),
    this.principalPaise = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.interestKind = const Value.absent(),
    this.rateBps = const Value.absent(),
    this.ratePeriod = const Value.absent(),
    this.interestAccrual = const Value.absent(),
    this.capitalizationPolicy = const Value.absent(),
    this.capitalizationCycle = const Value.absent(),
    this.interestStartedAt = const Value.absent(),
    this.interestEndedAt = const Value.absent(),
    this.prepaymentAllocation = const Value.absent(),
    this.status = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MoneyLoansCompanion.insert({
    required String id,
    required String customerId,
    required String direction,
    required int principalPaise,
    this.currencyCode = const Value.absent(),
    this.interestKind = const Value.absent(),
    this.rateBps = const Value.absent(),
    this.ratePeriod = const Value.absent(),
    this.interestAccrual = const Value.absent(),
    this.capitalizationPolicy = const Value.absent(),
    this.capitalizationCycle = const Value.absent(),
    required DateTime interestStartedAt,
    this.interestEndedAt = const Value.absent(),
    this.prepaymentAllocation = const Value.absent(),
    this.status = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       customerId = Value(customerId),
       direction = Value(direction),
       principalPaise = Value(principalPaise),
       interestStartedAt = Value(interestStartedAt),
       createdAt = Value(createdAt);
  static Insertable<MoneyLoanRow> custom({
    Expression<String>? id,
    Expression<String>? customerId,
    Expression<String>? direction,
    Expression<int>? principalPaise,
    Expression<String>? currencyCode,
    Expression<String>? interestKind,
    Expression<int>? rateBps,
    Expression<String>? ratePeriod,
    Expression<String>? interestAccrual,
    Expression<String>? capitalizationPolicy,
    Expression<String>? capitalizationCycle,
    Expression<DateTime>? interestStartedAt,
    Expression<DateTime>? interestEndedAt,
    Expression<String>? prepaymentAllocation,
    Expression<String>? status,
    Expression<DateTime>? closedAt,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (customerId != null) 'customer_id': customerId,
      if (direction != null) 'direction': direction,
      if (principalPaise != null) 'principal_paise': principalPaise,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (interestKind != null) 'interest_kind': interestKind,
      if (rateBps != null) 'rate_bps': rateBps,
      if (ratePeriod != null) 'rate_period': ratePeriod,
      if (interestAccrual != null) 'interest_accrual': interestAccrual,
      if (capitalizationPolicy != null)
        'capitalization_policy': capitalizationPolicy,
      if (capitalizationCycle != null)
        'capitalization_cycle': capitalizationCycle,
      if (interestStartedAt != null) 'interest_started_at': interestStartedAt,
      if (interestEndedAt != null) 'interest_ended_at': interestEndedAt,
      if (prepaymentAllocation != null)
        'prepayment_allocation': prepaymentAllocation,
      if (status != null) 'status': status,
      if (closedAt != null) 'closed_at': closedAt,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MoneyLoansCompanion copyWith({
    Value<String>? id,
    Value<String>? customerId,
    Value<String>? direction,
    Value<int>? principalPaise,
    Value<String>? currencyCode,
    Value<String>? interestKind,
    Value<int>? rateBps,
    Value<String>? ratePeriod,
    Value<String>? interestAccrual,
    Value<String>? capitalizationPolicy,
    Value<String>? capitalizationCycle,
    Value<DateTime>? interestStartedAt,
    Value<DateTime?>? interestEndedAt,
    Value<String>? prepaymentAllocation,
    Value<String>? status,
    Value<DateTime?>? closedAt,
    Value<String?>? note,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return MoneyLoansCompanion(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      direction: direction ?? this.direction,
      principalPaise: principalPaise ?? this.principalPaise,
      currencyCode: currencyCode ?? this.currencyCode,
      interestKind: interestKind ?? this.interestKind,
      rateBps: rateBps ?? this.rateBps,
      ratePeriod: ratePeriod ?? this.ratePeriod,
      interestAccrual: interestAccrual ?? this.interestAccrual,
      capitalizationPolicy: capitalizationPolicy ?? this.capitalizationPolicy,
      capitalizationCycle: capitalizationCycle ?? this.capitalizationCycle,
      interestStartedAt: interestStartedAt ?? this.interestStartedAt,
      interestEndedAt: interestEndedAt ?? this.interestEndedAt,
      prepaymentAllocation: prepaymentAllocation ?? this.prepaymentAllocation,
      status: status ?? this.status,
      closedAt: closedAt ?? this.closedAt,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
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
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (principalPaise.present) {
      map['principal_paise'] = Variable<int>(principalPaise.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (interestKind.present) {
      map['interest_kind'] = Variable<String>(interestKind.value);
    }
    if (rateBps.present) {
      map['rate_bps'] = Variable<int>(rateBps.value);
    }
    if (ratePeriod.present) {
      map['rate_period'] = Variable<String>(ratePeriod.value);
    }
    if (interestAccrual.present) {
      map['interest_accrual'] = Variable<String>(interestAccrual.value);
    }
    if (capitalizationPolicy.present) {
      map['capitalization_policy'] = Variable<String>(
        capitalizationPolicy.value,
      );
    }
    if (capitalizationCycle.present) {
      map['capitalization_cycle'] = Variable<String>(capitalizationCycle.value);
    }
    if (interestStartedAt.present) {
      map['interest_started_at'] = Variable<DateTime>(interestStartedAt.value);
    }
    if (interestEndedAt.present) {
      map['interest_ended_at'] = Variable<DateTime>(interestEndedAt.value);
    }
    if (prepaymentAllocation.present) {
      map['prepayment_allocation'] = Variable<String>(
        prepaymentAllocation.value,
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (closedAt.present) {
      map['closed_at'] = Variable<DateTime>(closedAt.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MoneyLoansCompanion(')
          ..write('id: $id, ')
          ..write('customerId: $customerId, ')
          ..write('direction: $direction, ')
          ..write('principalPaise: $principalPaise, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('interestKind: $interestKind, ')
          ..write('rateBps: $rateBps, ')
          ..write('ratePeriod: $ratePeriod, ')
          ..write('interestAccrual: $interestAccrual, ')
          ..write('capitalizationPolicy: $capitalizationPolicy, ')
          ..write('capitalizationCycle: $capitalizationCycle, ')
          ..write('interestStartedAt: $interestStartedAt, ')
          ..write('interestEndedAt: $interestEndedAt, ')
          ..write('prepaymentAllocation: $prepaymentAllocation, ')
          ..write('status: $status, ')
          ..write('closedAt: $closedAt, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MoneyLoanEntriesTable extends MoneyLoanEntries
    with TableInfo<$MoneyLoanEntriesTable, MoneyLoanEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MoneyLoanEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _loanIdMeta = const VerificationMeta('loanId');
  @override
  late final GeneratedColumn<String> loanId = GeneratedColumn<String>(
    'loan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entryAtMeta = const VerificationMeta(
    'entryAt',
  );
  @override
  late final GeneratedColumn<DateTime> entryAt = GeneratedColumn<DateTime>(
    'entry_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountPaiseMeta = const VerificationMeta(
    'amountPaise',
  );
  @override
  late final GeneratedColumn<int> amountPaise = GeneratedColumn<int>(
    'amount_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    loanId,
    entryAt,
    amountPaise,
    kind,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'money_loan_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<MoneyLoanEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('loan_id')) {
      context.handle(
        _loanIdMeta,
        loanId.isAcceptableOrUnknown(data['loan_id']!, _loanIdMeta),
      );
    } else if (isInserting) {
      context.missing(_loanIdMeta);
    }
    if (data.containsKey('entry_at')) {
      context.handle(
        _entryAtMeta,
        entryAt.isAcceptableOrUnknown(data['entry_at']!, _entryAtMeta),
      );
    } else if (isInserting) {
      context.missing(_entryAtMeta);
    }
    if (data.containsKey('amount_paise')) {
      context.handle(
        _amountPaiseMeta,
        amountPaise.isAcceptableOrUnknown(
          data['amount_paise']!,
          _amountPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountPaiseMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MoneyLoanEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MoneyLoanEntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      loanId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}loan_id'],
      )!,
      entryAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}entry_at'],
      )!,
      amountPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_paise'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $MoneyLoanEntriesTable createAlias(String alias) {
    return $MoneyLoanEntriesTable(attachedDatabase, alias);
  }
}

class MoneyLoanEntryRow extends DataClass
    implements Insertable<MoneyLoanEntryRow> {
  final String id;
  final String loanId;
  final DateTime entryAt;

  /// Payment: positive amount toward the loan. Adjustment: signed correction.
  final int amountPaise;

  /// `repayment` | `disbursement` | `adjustment` | `capitalization`
  /// (legacy `payment` reads as repayment)
  final String kind;
  final String? note;
  const MoneyLoanEntryRow({
    required this.id,
    required this.loanId,
    required this.entryAt,
    required this.amountPaise,
    required this.kind,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['loan_id'] = Variable<String>(loanId);
    map['entry_at'] = Variable<DateTime>(entryAt);
    map['amount_paise'] = Variable<int>(amountPaise);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  MoneyLoanEntriesCompanion toCompanion(bool nullToAbsent) {
    return MoneyLoanEntriesCompanion(
      id: Value(id),
      loanId: Value(loanId),
      entryAt: Value(entryAt),
      amountPaise: Value(amountPaise),
      kind: Value(kind),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory MoneyLoanEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MoneyLoanEntryRow(
      id: serializer.fromJson<String>(json['id']),
      loanId: serializer.fromJson<String>(json['loanId']),
      entryAt: serializer.fromJson<DateTime>(json['entryAt']),
      amountPaise: serializer.fromJson<int>(json['amountPaise']),
      kind: serializer.fromJson<String>(json['kind']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'loanId': serializer.toJson<String>(loanId),
      'entryAt': serializer.toJson<DateTime>(entryAt),
      'amountPaise': serializer.toJson<int>(amountPaise),
      'kind': serializer.toJson<String>(kind),
      'note': serializer.toJson<String?>(note),
    };
  }

  MoneyLoanEntryRow copyWith({
    String? id,
    String? loanId,
    DateTime? entryAt,
    int? amountPaise,
    String? kind,
    Value<String?> note = const Value.absent(),
  }) => MoneyLoanEntryRow(
    id: id ?? this.id,
    loanId: loanId ?? this.loanId,
    entryAt: entryAt ?? this.entryAt,
    amountPaise: amountPaise ?? this.amountPaise,
    kind: kind ?? this.kind,
    note: note.present ? note.value : this.note,
  );
  MoneyLoanEntryRow copyWithCompanion(MoneyLoanEntriesCompanion data) {
    return MoneyLoanEntryRow(
      id: data.id.present ? data.id.value : this.id,
      loanId: data.loanId.present ? data.loanId.value : this.loanId,
      entryAt: data.entryAt.present ? data.entryAt.value : this.entryAt,
      amountPaise: data.amountPaise.present
          ? data.amountPaise.value
          : this.amountPaise,
      kind: data.kind.present ? data.kind.value : this.kind,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MoneyLoanEntryRow(')
          ..write('id: $id, ')
          ..write('loanId: $loanId, ')
          ..write('entryAt: $entryAt, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('kind: $kind, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, loanId, entryAt, amountPaise, kind, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MoneyLoanEntryRow &&
          other.id == this.id &&
          other.loanId == this.loanId &&
          other.entryAt == this.entryAt &&
          other.amountPaise == this.amountPaise &&
          other.kind == this.kind &&
          other.note == this.note);
}

class MoneyLoanEntriesCompanion extends UpdateCompanion<MoneyLoanEntryRow> {
  final Value<String> id;
  final Value<String> loanId;
  final Value<DateTime> entryAt;
  final Value<int> amountPaise;
  final Value<String> kind;
  final Value<String?> note;
  final Value<int> rowid;
  const MoneyLoanEntriesCompanion({
    this.id = const Value.absent(),
    this.loanId = const Value.absent(),
    this.entryAt = const Value.absent(),
    this.amountPaise = const Value.absent(),
    this.kind = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MoneyLoanEntriesCompanion.insert({
    required String id,
    required String loanId,
    required DateTime entryAt,
    required int amountPaise,
    required String kind,
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       loanId = Value(loanId),
       entryAt = Value(entryAt),
       amountPaise = Value(amountPaise),
       kind = Value(kind);
  static Insertable<MoneyLoanEntryRow> custom({
    Expression<String>? id,
    Expression<String>? loanId,
    Expression<DateTime>? entryAt,
    Expression<int>? amountPaise,
    Expression<String>? kind,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (loanId != null) 'loan_id': loanId,
      if (entryAt != null) 'entry_at': entryAt,
      if (amountPaise != null) 'amount_paise': amountPaise,
      if (kind != null) 'kind': kind,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MoneyLoanEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? loanId,
    Value<DateTime>? entryAt,
    Value<int>? amountPaise,
    Value<String>? kind,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return MoneyLoanEntriesCompanion(
      id: id ?? this.id,
      loanId: loanId ?? this.loanId,
      entryAt: entryAt ?? this.entryAt,
      amountPaise: amountPaise ?? this.amountPaise,
      kind: kind ?? this.kind,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (loanId.present) {
      map['loan_id'] = Variable<String>(loanId.value);
    }
    if (entryAt.present) {
      map['entry_at'] = Variable<DateTime>(entryAt.value);
    }
    if (amountPaise.present) {
      map['amount_paise'] = Variable<int>(amountPaise.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MoneyLoanEntriesCompanion(')
          ..write('id: $id, ')
          ..write('loanId: $loanId, ')
          ..write('entryAt: $entryAt, ')
          ..write('amountPaise: $amountPaise, ')
          ..write('kind: $kind, ')
          ..write('note: $note, ')
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
  late final $RentalNotesTable rentalNotes = $RentalNotesTable(this);
  late final $DepositLedgerTable depositLedger = $DepositLedgerTable(this);
  late final $AppMetaTable appMeta = $AppMetaTable(this);
  late final $MoneyLoansTable moneyLoans = $MoneyLoansTable(this);
  late final $MoneyLoanEntriesTable moneyLoanEntries = $MoneyLoanEntriesTable(
    this,
  );
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
    rentalNotes,
    depositLedger,
    appMeta,
    moneyLoans,
    moneyLoanEntries,
  ];
}

typedef $$CustomersTableCreateCompanionBuilder =
    CustomersCompanion Function({
      required String id,
      required String name,
      required String phone,
      Value<bool> isTrusted,
      required String qrCode,
      Value<int> depositBalance,
      Value<int> rowid,
    });
typedef $$CustomersTableUpdateCompanionBuilder =
    CustomersCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> phone,
      Value<bool> isTrusted,
      Value<String> qrCode,
      Value<int> depositBalance,
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

  ColumnFilters<int> get depositBalance => $composableBuilder(
    column: $table.depositBalance,
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

  ColumnOrderings<int> get depositBalance => $composableBuilder(
    column: $table.depositBalance,
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

  GeneratedColumn<int> get depositBalance => $composableBuilder(
    column: $table.depositBalance,
    builder: (column) => column,
  );
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
                Value<int> depositBalance = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomersCompanion(
                id: id,
                name: name,
                phone: phone,
                isTrusted: isTrusted,
                qrCode: qrCode,
                depositBalance: depositBalance,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String phone,
                Value<bool> isTrusted = const Value.absent(),
                required String qrCode,
                Value<int> depositBalance = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomersCompanion.insert(
                id: id,
                name: name,
                phone: phone,
                isTrusted: isTrusted,
                qrCode: qrCode,
                depositBalance: depositBalance,
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
      Value<bool> dueDateOptional,
      Value<bool> requiresUnitIdentity,
      Value<String?> unitCodePrefix,
      Value<bool> allowsDynamicPricing,
      Value<String> defaultItemKind,
      Value<String?> metadata,
      Value<bool> catalogActive,
      Value<int> securityDepositPaise,
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
      Value<bool> dueDateOptional,
      Value<bool> requiresUnitIdentity,
      Value<String?> unitCodePrefix,
      Value<bool> allowsDynamicPricing,
      Value<String> defaultItemKind,
      Value<String?> metadata,
      Value<bool> catalogActive,
      Value<int> securityDepositPaise,
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

  ColumnFilters<bool> get dueDateOptional => $composableBuilder(
    column: $table.dueDateOptional,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get requiresUnitIdentity => $composableBuilder(
    column: $table.requiresUnitIdentity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unitCodePrefix => $composableBuilder(
    column: $table.unitCodePrefix,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get allowsDynamicPricing => $composableBuilder(
    column: $table.allowsDynamicPricing,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultItemKind => $composableBuilder(
    column: $table.defaultItemKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get catalogActive => $composableBuilder(
    column: $table.catalogActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get securityDepositPaise => $composableBuilder(
    column: $table.securityDepositPaise,
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

  ColumnOrderings<bool> get dueDateOptional => $composableBuilder(
    column: $table.dueDateOptional,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get requiresUnitIdentity => $composableBuilder(
    column: $table.requiresUnitIdentity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unitCodePrefix => $composableBuilder(
    column: $table.unitCodePrefix,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get allowsDynamicPricing => $composableBuilder(
    column: $table.allowsDynamicPricing,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultItemKind => $composableBuilder(
    column: $table.defaultItemKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get catalogActive => $composableBuilder(
    column: $table.catalogActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get securityDepositPaise => $composableBuilder(
    column: $table.securityDepositPaise,
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

  GeneratedColumn<bool> get dueDateOptional => $composableBuilder(
    column: $table.dueDateOptional,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get requiresUnitIdentity => $composableBuilder(
    column: $table.requiresUnitIdentity,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unitCodePrefix => $composableBuilder(
    column: $table.unitCodePrefix,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get allowsDynamicPricing => $composableBuilder(
    column: $table.allowsDynamicPricing,
    builder: (column) => column,
  );

  GeneratedColumn<String> get defaultItemKind => $composableBuilder(
    column: $table.defaultItemKind,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<bool> get catalogActive => $composableBuilder(
    column: $table.catalogActive,
    builder: (column) => column,
  );

  GeneratedColumn<int> get securityDepositPaise => $composableBuilder(
    column: $table.securityDepositPaise,
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
                Value<bool> dueDateOptional = const Value.absent(),
                Value<bool> requiresUnitIdentity = const Value.absent(),
                Value<String?> unitCodePrefix = const Value.absent(),
                Value<bool> allowsDynamicPricing = const Value.absent(),
                Value<String> defaultItemKind = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<bool> catalogActive = const Value.absent(),
                Value<int> securityDepositPaise = const Value.absent(),
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
                dueDateOptional: dueDateOptional,
                requiresUnitIdentity: requiresUnitIdentity,
                unitCodePrefix: unitCodePrefix,
                allowsDynamicPricing: allowsDynamicPricing,
                defaultItemKind: defaultItemKind,
                metadata: metadata,
                catalogActive: catalogActive,
                securityDepositPaise: securityDepositPaise,
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
                Value<bool> dueDateOptional = const Value.absent(),
                Value<bool> requiresUnitIdentity = const Value.absent(),
                Value<String?> unitCodePrefix = const Value.absent(),
                Value<bool> allowsDynamicPricing = const Value.absent(),
                Value<String> defaultItemKind = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<bool> catalogActive = const Value.absent(),
                Value<int> securityDepositPaise = const Value.absent(),
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
                dueDateOptional: dueDateOptional,
                requiresUnitIdentity: requiresUnitIdentity,
                unitCodePrefix: unitCodePrefix,
                allowsDynamicPricing: allowsDynamicPricing,
                defaultItemKind: defaultItemKind,
                metadata: metadata,
                catalogActive: catalogActive,
                securityDepositPaise: securityDepositPaise,
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
      Value<DateTime?> dueAt,
      Value<DateTime?> returnedAt,
      required String qrCode,
      Value<String?> nickname,
      Value<String> billingMode,
      Value<int> rateAmount,
      Value<int> lateFeePerDay,
      Value<int> baseAmount,
      Value<int> lateAmount,
      Value<int> totalAmount,
      Value<int> depositApplied,
      Value<int> depositAmount,
      Value<int> sellPaidPaise,
      Value<int> sellDiscountPaise,
      Value<String> orderStatus,
      Value<String?> workflowStatus,
      Value<int> durationUnits,
      Value<String?> replacedFromRentalId,
      Value<int> rowid,
    });
typedef $$RentalsTableUpdateCompanionBuilder =
    RentalsCompanion Function({
      Value<String> id,
      Value<String> customerId,
      Value<DateTime> startedAt,
      Value<DateTime?> dueAt,
      Value<DateTime?> returnedAt,
      Value<String> qrCode,
      Value<String?> nickname,
      Value<String> billingMode,
      Value<int> rateAmount,
      Value<int> lateFeePerDay,
      Value<int> baseAmount,
      Value<int> lateAmount,
      Value<int> totalAmount,
      Value<int> depositApplied,
      Value<int> depositAmount,
      Value<int> sellPaidPaise,
      Value<int> sellDiscountPaise,
      Value<String> orderStatus,
      Value<String?> workflowStatus,
      Value<int> durationUnits,
      Value<String?> replacedFromRentalId,
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

  ColumnFilters<int> get depositApplied => $composableBuilder(
    column: $table.depositApplied,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get depositAmount => $composableBuilder(
    column: $table.depositAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sellPaidPaise => $composableBuilder(
    column: $table.sellPaidPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sellDiscountPaise => $composableBuilder(
    column: $table.sellDiscountPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderStatus => $composableBuilder(
    column: $table.orderStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workflowStatus => $composableBuilder(
    column: $table.workflowStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationUnits => $composableBuilder(
    column: $table.durationUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get replacedFromRentalId => $composableBuilder(
    column: $table.replacedFromRentalId,
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

  ColumnOrderings<int> get depositApplied => $composableBuilder(
    column: $table.depositApplied,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get depositAmount => $composableBuilder(
    column: $table.depositAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sellPaidPaise => $composableBuilder(
    column: $table.sellPaidPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sellDiscountPaise => $composableBuilder(
    column: $table.sellDiscountPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderStatus => $composableBuilder(
    column: $table.orderStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workflowStatus => $composableBuilder(
    column: $table.workflowStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationUnits => $composableBuilder(
    column: $table.durationUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get replacedFromRentalId => $composableBuilder(
    column: $table.replacedFromRentalId,
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

  GeneratedColumn<int> get depositApplied => $composableBuilder(
    column: $table.depositApplied,
    builder: (column) => column,
  );

  GeneratedColumn<int> get depositAmount => $composableBuilder(
    column: $table.depositAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sellPaidPaise => $composableBuilder(
    column: $table.sellPaidPaise,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sellDiscountPaise => $composableBuilder(
    column: $table.sellDiscountPaise,
    builder: (column) => column,
  );

  GeneratedColumn<String> get orderStatus => $composableBuilder(
    column: $table.orderStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get workflowStatus => $composableBuilder(
    column: $table.workflowStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationUnits => $composableBuilder(
    column: $table.durationUnits,
    builder: (column) => column,
  );

  GeneratedColumn<String> get replacedFromRentalId => $composableBuilder(
    column: $table.replacedFromRentalId,
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
                Value<DateTime?> dueAt = const Value.absent(),
                Value<DateTime?> returnedAt = const Value.absent(),
                Value<String> qrCode = const Value.absent(),
                Value<String?> nickname = const Value.absent(),
                Value<String> billingMode = const Value.absent(),
                Value<int> rateAmount = const Value.absent(),
                Value<int> lateFeePerDay = const Value.absent(),
                Value<int> baseAmount = const Value.absent(),
                Value<int> lateAmount = const Value.absent(),
                Value<int> totalAmount = const Value.absent(),
                Value<int> depositApplied = const Value.absent(),
                Value<int> depositAmount = const Value.absent(),
                Value<int> sellPaidPaise = const Value.absent(),
                Value<int> sellDiscountPaise = const Value.absent(),
                Value<String> orderStatus = const Value.absent(),
                Value<String?> workflowStatus = const Value.absent(),
                Value<int> durationUnits = const Value.absent(),
                Value<String?> replacedFromRentalId = const Value.absent(),
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
                depositApplied: depositApplied,
                depositAmount: depositAmount,
                sellPaidPaise: sellPaidPaise,
                sellDiscountPaise: sellDiscountPaise,
                orderStatus: orderStatus,
                workflowStatus: workflowStatus,
                durationUnits: durationUnits,
                replacedFromRentalId: replacedFromRentalId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String customerId,
                required DateTime startedAt,
                Value<DateTime?> dueAt = const Value.absent(),
                Value<DateTime?> returnedAt = const Value.absent(),
                required String qrCode,
                Value<String?> nickname = const Value.absent(),
                Value<String> billingMode = const Value.absent(),
                Value<int> rateAmount = const Value.absent(),
                Value<int> lateFeePerDay = const Value.absent(),
                Value<int> baseAmount = const Value.absent(),
                Value<int> lateAmount = const Value.absent(),
                Value<int> totalAmount = const Value.absent(),
                Value<int> depositApplied = const Value.absent(),
                Value<int> depositAmount = const Value.absent(),
                Value<int> sellPaidPaise = const Value.absent(),
                Value<int> sellDiscountPaise = const Value.absent(),
                Value<String> orderStatus = const Value.absent(),
                Value<String?> workflowStatus = const Value.absent(),
                Value<int> durationUnits = const Value.absent(),
                Value<String?> replacedFromRentalId = const Value.absent(),
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
                depositApplied: depositApplied,
                depositAmount: depositAmount,
                sellPaidPaise: sellPaidPaise,
                sellDiscountPaise: sellDiscountPaise,
                orderStatus: orderStatus,
                workflowStatus: workflowStatus,
                durationUnits: durationUnits,
                replacedFromRentalId: replacedFromRentalId,
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
      required String id,
      required String rentalId,
      required String itemId,
      Value<String> instanceName,
      Value<String> shortCode,
      Value<DateTime?> returnedAt,
      Value<int> baseAmount,
      Value<int> lateAmount,
      Value<int> depositApplied,
      Value<String> billingMode,
      Value<int> rateAmount,
      Value<int> lateFeePerDay,
      Value<String> fulfillment,
      Value<String?> returnDisposition,
      Value<int> rowid,
    });
typedef $$RentalItemsTableUpdateCompanionBuilder =
    RentalItemsCompanion Function({
      Value<String> id,
      Value<String> rentalId,
      Value<String> itemId,
      Value<String> instanceName,
      Value<String> shortCode,
      Value<DateTime?> returnedAt,
      Value<int> baseAmount,
      Value<int> lateAmount,
      Value<int> depositApplied,
      Value<String> billingMode,
      Value<int> rateAmount,
      Value<int> lateFeePerDay,
      Value<String> fulfillment,
      Value<String?> returnDisposition,
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
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

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

  ColumnFilters<DateTime> get returnedAt => $composableBuilder(
    column: $table.returnedAt,
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

  ColumnFilters<int> get depositApplied => $composableBuilder(
    column: $table.depositApplied,
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

  ColumnFilters<String> get fulfillment => $composableBuilder(
    column: $table.fulfillment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get returnDisposition => $composableBuilder(
    column: $table.returnDisposition,
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
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

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

  ColumnOrderings<DateTime> get returnedAt => $composableBuilder(
    column: $table.returnedAt,
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

  ColumnOrderings<int> get depositApplied => $composableBuilder(
    column: $table.depositApplied,
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

  ColumnOrderings<String> get fulfillment => $composableBuilder(
    column: $table.fulfillment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get returnDisposition => $composableBuilder(
    column: $table.returnDisposition,
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
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

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

  GeneratedColumn<DateTime> get returnedAt => $composableBuilder(
    column: $table.returnedAt,
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

  GeneratedColumn<int> get depositApplied => $composableBuilder(
    column: $table.depositApplied,
    builder: (column) => column,
  );

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

  GeneratedColumn<String> get fulfillment => $composableBuilder(
    column: $table.fulfillment,
    builder: (column) => column,
  );

  GeneratedColumn<String> get returnDisposition => $composableBuilder(
    column: $table.returnDisposition,
    builder: (column) => column,
  );
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
                Value<String> id = const Value.absent(),
                Value<String> rentalId = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> instanceName = const Value.absent(),
                Value<String> shortCode = const Value.absent(),
                Value<DateTime?> returnedAt = const Value.absent(),
                Value<int> baseAmount = const Value.absent(),
                Value<int> lateAmount = const Value.absent(),
                Value<int> depositApplied = const Value.absent(),
                Value<String> billingMode = const Value.absent(),
                Value<int> rateAmount = const Value.absent(),
                Value<int> lateFeePerDay = const Value.absent(),
                Value<String> fulfillment = const Value.absent(),
                Value<String?> returnDisposition = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RentalItemsCompanion(
                id: id,
                rentalId: rentalId,
                itemId: itemId,
                instanceName: instanceName,
                shortCode: shortCode,
                returnedAt: returnedAt,
                baseAmount: baseAmount,
                lateAmount: lateAmount,
                depositApplied: depositApplied,
                billingMode: billingMode,
                rateAmount: rateAmount,
                lateFeePerDay: lateFeePerDay,
                fulfillment: fulfillment,
                returnDisposition: returnDisposition,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String rentalId,
                required String itemId,
                Value<String> instanceName = const Value.absent(),
                Value<String> shortCode = const Value.absent(),
                Value<DateTime?> returnedAt = const Value.absent(),
                Value<int> baseAmount = const Value.absent(),
                Value<int> lateAmount = const Value.absent(),
                Value<int> depositApplied = const Value.absent(),
                Value<String> billingMode = const Value.absent(),
                Value<int> rateAmount = const Value.absent(),
                Value<int> lateFeePerDay = const Value.absent(),
                Value<String> fulfillment = const Value.absent(),
                Value<String?> returnDisposition = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RentalItemsCompanion.insert(
                id: id,
                rentalId: rentalId,
                itemId: itemId,
                instanceName: instanceName,
                shortCode: shortCode,
                returnedAt: returnedAt,
                baseAmount: baseAmount,
                lateAmount: lateAmount,
                depositApplied: depositApplied,
                billingMode: billingMode,
                rateAmount: rateAmount,
                lateFeePerDay: lateFeePerDay,
                fulfillment: fulfillment,
                returnDisposition: returnDisposition,
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
typedef $$RentalNotesTableCreateCompanionBuilder =
    RentalNotesCompanion Function({
      required String id,
      required String rentalId,
      Value<String?> rentalItemId,
      Value<String> kind,
      required String body,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$RentalNotesTableUpdateCompanionBuilder =
    RentalNotesCompanion Function({
      Value<String> id,
      Value<String> rentalId,
      Value<String?> rentalItemId,
      Value<String> kind,
      Value<String> body,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$RentalNotesTableFilterComposer
    extends Composer<_$AppDatabase, $RentalNotesTable> {
  $$RentalNotesTableFilterComposer({
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

  ColumnFilters<String> get rentalId => $composableBuilder(
    column: $table.rentalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rentalItemId => $composableBuilder(
    column: $table.rentalItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RentalNotesTableOrderingComposer
    extends Composer<_$AppDatabase, $RentalNotesTable> {
  $$RentalNotesTableOrderingComposer({
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

  ColumnOrderings<String> get rentalId => $composableBuilder(
    column: $table.rentalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rentalItemId => $composableBuilder(
    column: $table.rentalItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RentalNotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RentalNotesTable> {
  $$RentalNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get rentalId =>
      $composableBuilder(column: $table.rentalId, builder: (column) => column);

  GeneratedColumn<String> get rentalItemId => $composableBuilder(
    column: $table.rentalItemId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$RentalNotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RentalNotesTable,
          RentalNoteRow,
          $$RentalNotesTableFilterComposer,
          $$RentalNotesTableOrderingComposer,
          $$RentalNotesTableAnnotationComposer,
          $$RentalNotesTableCreateCompanionBuilder,
          $$RentalNotesTableUpdateCompanionBuilder,
          (
            RentalNoteRow,
            BaseReferences<_$AppDatabase, $RentalNotesTable, RentalNoteRow>,
          ),
          RentalNoteRow,
          PrefetchHooks Function()
        > {
  $$RentalNotesTableTableManager(_$AppDatabase db, $RentalNotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RentalNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RentalNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RentalNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> rentalId = const Value.absent(),
                Value<String?> rentalItemId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RentalNotesCompanion(
                id: id,
                rentalId: rentalId,
                rentalItemId: rentalItemId,
                kind: kind,
                body: body,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String rentalId,
                Value<String?> rentalItemId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                required String body,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => RentalNotesCompanion.insert(
                id: id,
                rentalId: rentalId,
                rentalItemId: rentalItemId,
                kind: kind,
                body: body,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RentalNotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RentalNotesTable,
      RentalNoteRow,
      $$RentalNotesTableFilterComposer,
      $$RentalNotesTableOrderingComposer,
      $$RentalNotesTableAnnotationComposer,
      $$RentalNotesTableCreateCompanionBuilder,
      $$RentalNotesTableUpdateCompanionBuilder,
      (
        RentalNoteRow,
        BaseReferences<_$AppDatabase, $RentalNotesTable, RentalNoteRow>,
      ),
      RentalNoteRow,
      PrefetchHooks Function()
    >;
typedef $$DepositLedgerTableCreateCompanionBuilder =
    DepositLedgerCompanion Function({
      required String id,
      required String customerId,
      Value<String?> rentalId,
      required String type,
      required int amount,
      required int balanceAfter,
      Value<String?> note,
      required DateTime at,
      Value<int> rowid,
    });
typedef $$DepositLedgerTableUpdateCompanionBuilder =
    DepositLedgerCompanion Function({
      Value<String> id,
      Value<String> customerId,
      Value<String?> rentalId,
      Value<String> type,
      Value<int> amount,
      Value<int> balanceAfter,
      Value<String?> note,
      Value<DateTime> at,
      Value<int> rowid,
    });

class $$DepositLedgerTableFilterComposer
    extends Composer<_$AppDatabase, $DepositLedgerTable> {
  $$DepositLedgerTableFilterComposer({
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

  ColumnFilters<String> get rentalId => $composableBuilder(
    column: $table.rentalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get balanceAfter => $composableBuilder(
    column: $table.balanceAfter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DepositLedgerTableOrderingComposer
    extends Composer<_$AppDatabase, $DepositLedgerTable> {
  $$DepositLedgerTableOrderingComposer({
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

  ColumnOrderings<String> get rentalId => $composableBuilder(
    column: $table.rentalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get balanceAfter => $composableBuilder(
    column: $table.balanceAfter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DepositLedgerTableAnnotationComposer
    extends Composer<_$AppDatabase, $DepositLedgerTable> {
  $$DepositLedgerTableAnnotationComposer({
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

  GeneratedColumn<String> get rentalId =>
      $composableBuilder(column: $table.rentalId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<int> get balanceAfter => $composableBuilder(
    column: $table.balanceAfter,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);
}

class $$DepositLedgerTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DepositLedgerTable,
          DepositLedgerRow,
          $$DepositLedgerTableFilterComposer,
          $$DepositLedgerTableOrderingComposer,
          $$DepositLedgerTableAnnotationComposer,
          $$DepositLedgerTableCreateCompanionBuilder,
          $$DepositLedgerTableUpdateCompanionBuilder,
          (
            DepositLedgerRow,
            BaseReferences<
              _$AppDatabase,
              $DepositLedgerTable,
              DepositLedgerRow
            >,
          ),
          DepositLedgerRow,
          PrefetchHooks Function()
        > {
  $$DepositLedgerTableTableManager(_$AppDatabase db, $DepositLedgerTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DepositLedgerTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DepositLedgerTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DepositLedgerTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> customerId = const Value.absent(),
                Value<String?> rentalId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<int> balanceAfter = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DepositLedgerCompanion(
                id: id,
                customerId: customerId,
                rentalId: rentalId,
                type: type,
                amount: amount,
                balanceAfter: balanceAfter,
                note: note,
                at: at,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String customerId,
                Value<String?> rentalId = const Value.absent(),
                required String type,
                required int amount,
                required int balanceAfter,
                Value<String?> note = const Value.absent(),
                required DateTime at,
                Value<int> rowid = const Value.absent(),
              }) => DepositLedgerCompanion.insert(
                id: id,
                customerId: customerId,
                rentalId: rentalId,
                type: type,
                amount: amount,
                balanceAfter: balanceAfter,
                note: note,
                at: at,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DepositLedgerTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DepositLedgerTable,
      DepositLedgerRow,
      $$DepositLedgerTableFilterComposer,
      $$DepositLedgerTableOrderingComposer,
      $$DepositLedgerTableAnnotationComposer,
      $$DepositLedgerTableCreateCompanionBuilder,
      $$DepositLedgerTableUpdateCompanionBuilder,
      (
        DepositLedgerRow,
        BaseReferences<_$AppDatabase, $DepositLedgerTable, DepositLedgerRow>,
      ),
      DepositLedgerRow,
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
typedef $$MoneyLoansTableCreateCompanionBuilder =
    MoneyLoansCompanion Function({
      required String id,
      required String customerId,
      required String direction,
      required int principalPaise,
      Value<String> currencyCode,
      Value<String> interestKind,
      Value<int> rateBps,
      Value<String> ratePeriod,
      Value<String> interestAccrual,
      Value<String> capitalizationPolicy,
      Value<String> capitalizationCycle,
      required DateTime interestStartedAt,
      Value<DateTime?> interestEndedAt,
      Value<String> prepaymentAllocation,
      Value<String> status,
      Value<DateTime?> closedAt,
      Value<String?> note,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$MoneyLoansTableUpdateCompanionBuilder =
    MoneyLoansCompanion Function({
      Value<String> id,
      Value<String> customerId,
      Value<String> direction,
      Value<int> principalPaise,
      Value<String> currencyCode,
      Value<String> interestKind,
      Value<int> rateBps,
      Value<String> ratePeriod,
      Value<String> interestAccrual,
      Value<String> capitalizationPolicy,
      Value<String> capitalizationCycle,
      Value<DateTime> interestStartedAt,
      Value<DateTime?> interestEndedAt,
      Value<String> prepaymentAllocation,
      Value<String> status,
      Value<DateTime?> closedAt,
      Value<String?> note,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$MoneyLoansTableFilterComposer
    extends Composer<_$AppDatabase, $MoneyLoansTable> {
  $$MoneyLoansTableFilterComposer({
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

  ColumnFilters<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get principalPaise => $composableBuilder(
    column: $table.principalPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get interestKind => $composableBuilder(
    column: $table.interestKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rateBps => $composableBuilder(
    column: $table.rateBps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ratePeriod => $composableBuilder(
    column: $table.ratePeriod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get interestAccrual => $composableBuilder(
    column: $table.interestAccrual,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get capitalizationPolicy => $composableBuilder(
    column: $table.capitalizationPolicy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get capitalizationCycle => $composableBuilder(
    column: $table.capitalizationCycle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get interestStartedAt => $composableBuilder(
    column: $table.interestStartedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get interestEndedAt => $composableBuilder(
    column: $table.interestEndedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prepaymentAllocation => $composableBuilder(
    column: $table.prepaymentAllocation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MoneyLoansTableOrderingComposer
    extends Composer<_$AppDatabase, $MoneyLoansTable> {
  $$MoneyLoansTableOrderingComposer({
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

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get principalPaise => $composableBuilder(
    column: $table.principalPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get interestKind => $composableBuilder(
    column: $table.interestKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rateBps => $composableBuilder(
    column: $table.rateBps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ratePeriod => $composableBuilder(
    column: $table.ratePeriod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get interestAccrual => $composableBuilder(
    column: $table.interestAccrual,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get capitalizationPolicy => $composableBuilder(
    column: $table.capitalizationPolicy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get capitalizationCycle => $composableBuilder(
    column: $table.capitalizationCycle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get interestStartedAt => $composableBuilder(
    column: $table.interestStartedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get interestEndedAt => $composableBuilder(
    column: $table.interestEndedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prepaymentAllocation => $composableBuilder(
    column: $table.prepaymentAllocation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MoneyLoansTableAnnotationComposer
    extends Composer<_$AppDatabase, $MoneyLoansTable> {
  $$MoneyLoansTableAnnotationComposer({
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

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<int> get principalPaise => $composableBuilder(
    column: $table.principalPaise,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get interestKind => $composableBuilder(
    column: $table.interestKind,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rateBps =>
      $composableBuilder(column: $table.rateBps, builder: (column) => column);

  GeneratedColumn<String> get ratePeriod => $composableBuilder(
    column: $table.ratePeriod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get interestAccrual => $composableBuilder(
    column: $table.interestAccrual,
    builder: (column) => column,
  );

  GeneratedColumn<String> get capitalizationPolicy => $composableBuilder(
    column: $table.capitalizationPolicy,
    builder: (column) => column,
  );

  GeneratedColumn<String> get capitalizationCycle => $composableBuilder(
    column: $table.capitalizationCycle,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get interestStartedAt => $composableBuilder(
    column: $table.interestStartedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get interestEndedAt => $composableBuilder(
    column: $table.interestEndedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get prepaymentAllocation => $composableBuilder(
    column: $table.prepaymentAllocation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get closedAt =>
      $composableBuilder(column: $table.closedAt, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$MoneyLoansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MoneyLoansTable,
          MoneyLoanRow,
          $$MoneyLoansTableFilterComposer,
          $$MoneyLoansTableOrderingComposer,
          $$MoneyLoansTableAnnotationComposer,
          $$MoneyLoansTableCreateCompanionBuilder,
          $$MoneyLoansTableUpdateCompanionBuilder,
          (
            MoneyLoanRow,
            BaseReferences<_$AppDatabase, $MoneyLoansTable, MoneyLoanRow>,
          ),
          MoneyLoanRow,
          PrefetchHooks Function()
        > {
  $$MoneyLoansTableTableManager(_$AppDatabase db, $MoneyLoansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MoneyLoansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MoneyLoansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MoneyLoansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> customerId = const Value.absent(),
                Value<String> direction = const Value.absent(),
                Value<int> principalPaise = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<String> interestKind = const Value.absent(),
                Value<int> rateBps = const Value.absent(),
                Value<String> ratePeriod = const Value.absent(),
                Value<String> interestAccrual = const Value.absent(),
                Value<String> capitalizationPolicy = const Value.absent(),
                Value<String> capitalizationCycle = const Value.absent(),
                Value<DateTime> interestStartedAt = const Value.absent(),
                Value<DateTime?> interestEndedAt = const Value.absent(),
                Value<String> prepaymentAllocation = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> closedAt = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MoneyLoansCompanion(
                id: id,
                customerId: customerId,
                direction: direction,
                principalPaise: principalPaise,
                currencyCode: currencyCode,
                interestKind: interestKind,
                rateBps: rateBps,
                ratePeriod: ratePeriod,
                interestAccrual: interestAccrual,
                capitalizationPolicy: capitalizationPolicy,
                capitalizationCycle: capitalizationCycle,
                interestStartedAt: interestStartedAt,
                interestEndedAt: interestEndedAt,
                prepaymentAllocation: prepaymentAllocation,
                status: status,
                closedAt: closedAt,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String customerId,
                required String direction,
                required int principalPaise,
                Value<String> currencyCode = const Value.absent(),
                Value<String> interestKind = const Value.absent(),
                Value<int> rateBps = const Value.absent(),
                Value<String> ratePeriod = const Value.absent(),
                Value<String> interestAccrual = const Value.absent(),
                Value<String> capitalizationPolicy = const Value.absent(),
                Value<String> capitalizationCycle = const Value.absent(),
                required DateTime interestStartedAt,
                Value<DateTime?> interestEndedAt = const Value.absent(),
                Value<String> prepaymentAllocation = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> closedAt = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => MoneyLoansCompanion.insert(
                id: id,
                customerId: customerId,
                direction: direction,
                principalPaise: principalPaise,
                currencyCode: currencyCode,
                interestKind: interestKind,
                rateBps: rateBps,
                ratePeriod: ratePeriod,
                interestAccrual: interestAccrual,
                capitalizationPolicy: capitalizationPolicy,
                capitalizationCycle: capitalizationCycle,
                interestStartedAt: interestStartedAt,
                interestEndedAt: interestEndedAt,
                prepaymentAllocation: prepaymentAllocation,
                status: status,
                closedAt: closedAt,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MoneyLoansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MoneyLoansTable,
      MoneyLoanRow,
      $$MoneyLoansTableFilterComposer,
      $$MoneyLoansTableOrderingComposer,
      $$MoneyLoansTableAnnotationComposer,
      $$MoneyLoansTableCreateCompanionBuilder,
      $$MoneyLoansTableUpdateCompanionBuilder,
      (
        MoneyLoanRow,
        BaseReferences<_$AppDatabase, $MoneyLoansTable, MoneyLoanRow>,
      ),
      MoneyLoanRow,
      PrefetchHooks Function()
    >;
typedef $$MoneyLoanEntriesTableCreateCompanionBuilder =
    MoneyLoanEntriesCompanion Function({
      required String id,
      required String loanId,
      required DateTime entryAt,
      required int amountPaise,
      required String kind,
      Value<String?> note,
      Value<int> rowid,
    });
typedef $$MoneyLoanEntriesTableUpdateCompanionBuilder =
    MoneyLoanEntriesCompanion Function({
      Value<String> id,
      Value<String> loanId,
      Value<DateTime> entryAt,
      Value<int> amountPaise,
      Value<String> kind,
      Value<String?> note,
      Value<int> rowid,
    });

class $$MoneyLoanEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $MoneyLoanEntriesTable> {
  $$MoneyLoanEntriesTableFilterComposer({
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

  ColumnFilters<String> get loanId => $composableBuilder(
    column: $table.loanId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get entryAt => $composableBuilder(
    column: $table.entryAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MoneyLoanEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $MoneyLoanEntriesTable> {
  $$MoneyLoanEntriesTableOrderingComposer({
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

  ColumnOrderings<String> get loanId => $composableBuilder(
    column: $table.loanId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get entryAt => $composableBuilder(
    column: $table.entryAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MoneyLoanEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MoneyLoanEntriesTable> {
  $$MoneyLoanEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get loanId =>
      $composableBuilder(column: $table.loanId, builder: (column) => column);

  GeneratedColumn<DateTime> get entryAt =>
      $composableBuilder(column: $table.entryAt, builder: (column) => column);

  GeneratedColumn<int> get amountPaise => $composableBuilder(
    column: $table.amountPaise,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$MoneyLoanEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MoneyLoanEntriesTable,
          MoneyLoanEntryRow,
          $$MoneyLoanEntriesTableFilterComposer,
          $$MoneyLoanEntriesTableOrderingComposer,
          $$MoneyLoanEntriesTableAnnotationComposer,
          $$MoneyLoanEntriesTableCreateCompanionBuilder,
          $$MoneyLoanEntriesTableUpdateCompanionBuilder,
          (
            MoneyLoanEntryRow,
            BaseReferences<
              _$AppDatabase,
              $MoneyLoanEntriesTable,
              MoneyLoanEntryRow
            >,
          ),
          MoneyLoanEntryRow,
          PrefetchHooks Function()
        > {
  $$MoneyLoanEntriesTableTableManager(
    _$AppDatabase db,
    $MoneyLoanEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MoneyLoanEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MoneyLoanEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MoneyLoanEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> loanId = const Value.absent(),
                Value<DateTime> entryAt = const Value.absent(),
                Value<int> amountPaise = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MoneyLoanEntriesCompanion(
                id: id,
                loanId: loanId,
                entryAt: entryAt,
                amountPaise: amountPaise,
                kind: kind,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String loanId,
                required DateTime entryAt,
                required int amountPaise,
                required String kind,
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MoneyLoanEntriesCompanion.insert(
                id: id,
                loanId: loanId,
                entryAt: entryAt,
                amountPaise: amountPaise,
                kind: kind,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MoneyLoanEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MoneyLoanEntriesTable,
      MoneyLoanEntryRow,
      $$MoneyLoanEntriesTableFilterComposer,
      $$MoneyLoanEntriesTableOrderingComposer,
      $$MoneyLoanEntriesTableAnnotationComposer,
      $$MoneyLoanEntriesTableCreateCompanionBuilder,
      $$MoneyLoanEntriesTableUpdateCompanionBuilder,
      (
        MoneyLoanEntryRow,
        BaseReferences<
          _$AppDatabase,
          $MoneyLoanEntriesTable,
          MoneyLoanEntryRow
        >,
      ),
      MoneyLoanEntryRow,
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
  $$RentalNotesTableTableManager get rentalNotes =>
      $$RentalNotesTableTableManager(_db, _db.rentalNotes);
  $$DepositLedgerTableTableManager get depositLedger =>
      $$DepositLedgerTableTableManager(_db, _db.depositLedger);
  $$AppMetaTableTableManager get appMeta =>
      $$AppMetaTableTableManager(_db, _db.appMeta);
  $$MoneyLoansTableTableManager get moneyLoans =>
      $$MoneyLoansTableTableManager(_db, _db.moneyLoans);
  $$MoneyLoanEntriesTableTableManager get moneyLoanEntries =>
      $$MoneyLoanEntriesTableTableManager(_db, _db.moneyLoanEntries);
}
