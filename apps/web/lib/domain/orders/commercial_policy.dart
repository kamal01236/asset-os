import '../models/entities.dart';
import 'order_payment.dart';

/// How strongly a commercial checkout step applies to a line or order.
enum CommercialRequirement {
  off,
  optional,
  required;

  String get storageValue => name;

  static CommercialRequirement parse(
    String? raw, {
    CommercialRequirement fallback = CommercialRequirement.off,
  }) {
    switch (raw) {
      case 'optional':
        return CommercialRequirement.optional;
      case 'required':
        return CommercialRequirement.required;
      case 'off':
        return CommercialRequirement.off;
      default:
        return fallback;
    }
  }

  /// Union: required > optional > off.
  static CommercialRequirement union(
    CommercialRequirement a,
    CommercialRequirement b,
  ) {
    if (a == CommercialRequirement.required ||
        b == CommercialRequirement.required) {
      return CommercialRequirement.required;
    }
    if (a == CommercialRequirement.optional ||
        b == CommercialRequirement.optional) {
      return CommercialRequirement.optional;
    }
    return CommercialRequirement.off;
  }

  bool get isOff => this == CommercialRequirement.off;

  bool get isShown => this != CommercialRequirement.off;

  bool get isRequired => this == CommercialRequirement.required;
}

/// Named checkout steps that policies can show, require, or OR-group.
enum CommercialStep {
  pay,
  advance,
  security,
  subscription;

  String get storageValue => name;

  static CommercialStep? tryParse(String? raw) {
    switch (raw) {
      case 'pay':
        return CommercialStep.pay;
      case 'advance':
        return CommercialStep.advance;
      case 'security':
        return CommercialStep.security;
      case 'subscription':
        return CommercialStep.subscription;
      default:
        return null;
    }
  }
}

/// Inventory metadata key for a per-item [CommercialPolicy] overlay.
const String kCommercialMetadataKey = 'commercial';

/// Optional membership validity length (days) on catalog metadata.
const String kEntitlementDaysMetadataKey = 'entitlementDays';

/// ISO-8601 end instant on catalog / line metadata.
const String kEntitlementValidUntilMetadataKey = 'validUntil';

/// Pay / advance / security / subscription gates for one resource type or item.
class CommercialPolicy {
  const CommercialPolicy({
    this.pay = CommercialRequirement.off,
    this.advance = CommercialRequirement.off,
    this.security = CommercialRequirement.off,
    this.subscription = CommercialRequirement.off,
    this.requireAnyOf = const <CommercialStep>[],
  });

  final CommercialRequirement pay;
  final CommercialRequirement advance;
  final CommercialRequirement security;
  final CommercialRequirement subscription;

  /// When non-empty, at least one listed step must be satisfied (OR group).
  final List<CommercialStep> requireAnyOf;

  CommercialPolicy overlay(CommercialPolicy? other) {
    if (other == null) {
      return this;
    }
    return CommercialPolicy(
      pay: other.pay,
      advance: other.advance,
      security: other.security,
      subscription: other.subscription,
      requireAnyOf: other.requireAnyOf,
    );
  }

  /// Apply only fields present in [delta] (partial item/template JSON).
  CommercialPolicy applyDelta(CommercialPolicyDelta delta) {
    return CommercialPolicy(
      pay: delta.pay ?? pay,
      advance: delta.advance ?? advance,
      security: delta.security ?? security,
      subscription: delta.subscription ?? subscription,
      requireAnyOf: delta.requireAnyOf ?? requireAnyOf,
    );
  }

  Map<String, Object?> toJson() {
    final Map<String, Object?> json = <String, Object?>{
      'pay': pay.storageValue,
      'advance': advance.storageValue,
      'security': security.storageValue,
      'subscription': subscription.storageValue,
    };
    if (requireAnyOf.isNotEmpty) {
      json['requireAnyOf'] = requireAnyOf
          .map((CommercialStep s) => s.storageValue)
          .toList(growable: false);
    }
    return json;
  }

  static CommercialPolicy fromJson(Map<String, Object?> json) {
    return const CommercialPolicy().applyDelta(
      CommercialPolicyDelta.fromJson(json),
    );
  }
}

/// Sparse overlay parsed from template/item JSON (missing keys stay null).
class CommercialPolicyDelta {
  const CommercialPolicyDelta({
    this.pay,
    this.advance,
    this.security,
    this.subscription,
    this.requireAnyOf,
  });

  final CommercialRequirement? pay;
  final CommercialRequirement? advance;
  final CommercialRequirement? security;
  final CommercialRequirement? subscription;
  final List<CommercialStep>? requireAnyOf;

  static CommercialPolicyDelta fromJson(Map<String, Object?> json) {
    List<CommercialStep>? anyOf;
    final Object? rawAny = json['requireAnyOf'];
    if (rawAny is List) {
      final List<CommercialStep> parsed = <CommercialStep>[];
      for (final Object? entry in rawAny) {
        final CommercialStep? step = CommercialStep.tryParse(entry?.toString());
        if (step != null && !parsed.contains(step)) {
          parsed.add(step);
        }
      }
      anyOf = parsed;
    }
    return CommercialPolicyDelta(
      pay: json.containsKey('pay')
          ? CommercialRequirement.parse(json['pay']?.toString())
          : null,
      advance: json.containsKey('advance')
          ? CommercialRequirement.parse(json['advance']?.toString())
          : null,
      security: json.containsKey('security')
          ? CommercialRequirement.parse(json['security']?.toString())
          : null,
      subscription: json.containsKey('subscription')
          ? CommercialRequirement.parse(json['subscription']?.toString())
          : null,
      requireAnyOf: anyOf,
    );
  }
}

/// Built-in structural defaults (amount gates applied in [resolveLinePolicy]).
const Map<ResourceType, CommercialPolicy> kDefaultCommercialByType =
    <ResourceType, CommercialPolicy>{
  ResourceType.rental: CommercialPolicy(
    pay: CommercialRequirement.optional,
    advance: CommercialRequirement.optional,
    security: CommercialRequirement.optional,
    subscription: CommercialRequirement.off,
  ),
  ResourceType.loan: CommercialPolicy(
    pay: CommercialRequirement.optional,
    advance: CommercialRequirement.off,
    security: CommercialRequirement.optional,
    subscription: CommercialRequirement.off,
  ),
  ResourceType.sale: CommercialPolicy(
    pay: CommercialRequirement.required,
    advance: CommercialRequirement.off,
    security: CommercialRequirement.off,
    subscription: CommercialRequirement.off,
  ),
  ResourceType.service: CommercialPolicy(
    pay: CommercialRequirement.optional,
    advance: CommercialRequirement.optional,
    security: CommercialRequirement.off,
    subscription: CommercialRequirement.off,
  ),
  ResourceType.job: CommercialPolicy(
    pay: CommercialRequirement.optional,
    advance: CommercialRequirement.optional,
    security: CommercialRequirement.off,
    subscription: CommercialRequirement.off,
  ),
  ResourceType.membership: CommercialPolicy(
    pay: CommercialRequirement.required,
    advance: CommercialRequirement.off,
    security: CommercialRequirement.off,
    subscription: CommercialRequirement.off,
  ),
  ResourceType.subscription: CommercialPolicy(
    pay: CommercialRequirement.required,
    advance: CommercialRequirement.off,
    security: CommercialRequirement.off,
    subscription: CommercialRequirement.off,
  ),
  ResourceType.financial: CommercialPolicy(
    pay: CommercialRequirement.required,
    advance: CommercialRequirement.off,
    security: CommercialRequirement.off,
    subscription: CommercialRequirement.off,
  ),
  ResourceType.custom: CommercialPolicy(
    pay: CommercialRequirement.optional,
    advance: CommercialRequirement.optional,
    security: CommercialRequirement.optional,
    subscription: CommercialRequirement.off,
  ),
};

CommercialPolicy defaultCommercialForType(ResourceType type) {
  return kDefaultCommercialByType[type] ??
      kDefaultCommercialByType[ResourceType.custom]!;
}

/// Parse `metadata.commercial` when present.
CommercialPolicyDelta? commercialDeltaFromMetadata(
  Map<String, Object?> metadata,
) {
  final Object? raw = metadata[kCommercialMetadataKey];
  if (raw is! Map) {
    return null;
  }
  return CommercialPolicyDelta.fromJson(Map<String, Object?>.from(raw));
}

CommercialPolicy? commercialPolicyFromMetadata(
  Map<String, Object?> metadata,
) {
  final CommercialPolicyDelta? delta = commercialDeltaFromMetadata(metadata);
  if (delta == null) {
    return null;
  }
  return const CommercialPolicy().applyDelta(delta);
}

/// Resolve one cart line: built-in → template type → item overlay → amounts.
CommercialPolicy resolveLinePolicy({
  required ResourceType type,
  CommercialPolicy? itemOverride,
  CommercialPolicyDelta? itemDelta,
  CommercialPolicy? templateTypeDefault,
  CommercialPolicyDelta? templateDelta,
  int ratePaise = 0,
  int securityDepositPaise = 0,
}) {
  CommercialPolicy policy = defaultCommercialForType(type);
  if (templateTypeDefault != null) {
    policy = templateTypeDefault;
  } else if (templateDelta != null) {
    policy = policy.applyDelta(templateDelta);
  }
  if (itemOverride != null) {
    policy = itemOverride;
  } else if (itemDelta != null) {
    policy = policy.applyDelta(itemDelta);
  }
  return _applyAmountGates(
    policy,
    ratePaise: ratePaise,
    securityDepositPaise: securityDepositPaise,
  );
}

CommercialPolicy _applyAmountGates(
  CommercialPolicy policy, {
  required int ratePaise,
  required int securityDepositPaise,
}) {
  final int rate = ratePaise < 0 ? 0 : ratePaise;
  final int deposit = securityDepositPaise < 0 ? 0 : securityDepositPaise;
  CommercialRequirement pay = policy.pay;
  CommercialRequirement security = policy.security;
  if (rate <= 0 && pay.isShown) {
    pay = CommercialRequirement.off;
  }
  if (deposit <= 0) {
    security = CommercialRequirement.off;
  }
  return CommercialPolicy(
    pay: pay,
    advance: policy.advance,
    security: security,
    subscription: policy.subscription,
    requireAnyOf: policy.requireAnyOf,
  );
}

/// One resolved cart / order line plus its commercial policy.
class ResolvedLinePolicy {
  const ResolvedLinePolicy({
    required this.policy,
    required this.type,
    required this.fulfillment,
    required this.quantity,
    required this.unitRatePaise,
    required this.lineAmountPaise,
    required this.securityDepositPaise,
  });

  final CommercialPolicy policy;
  final ResourceType type;
  final LineFulfillment fulfillment;
  final int quantity;
  final int unitRatePaise;
  final int lineAmountPaise;
  final int securityDepositPaise;

  int get suggestedSecurityPaise {
    if (policy.security.isOff) {
      return 0;
    }
    final int perUnit = securityDepositPaise < 0 ? 0 : securityDepositPaise;
    final int qty = quantity < 1 ? 1 : quantity;
    return perUnit * qty;
  }
}

/// Draft or issued line inputs used to resolve + aggregate.
class CommercialLineInput {
  const CommercialLineInput({
    required this.type,
    required this.fulfillment,
    required this.lineAmountPaise,
    this.quantity = 1,
    this.unitRatePaise = 0,
    this.securityDepositPaise = 0,
    this.itemOverride,
    this.itemDelta,
    this.metadata = const <String, Object?>{},
  });

  final ResourceType type;
  final LineFulfillment fulfillment;
  final int lineAmountPaise;
  final int quantity;
  final int unitRatePaise;
  final int securityDepositPaise;
  final CommercialPolicy? itemOverride;
  final CommercialPolicyDelta? itemDelta;
  final Map<String, Object?> metadata;

  factory CommercialLineInput.fromCatalog({
    required InventoryItem item,
    required LineFulfillment fulfillment,
    required int lineAmountPaise,
    int quantity = 1,
    int? unitRatePaise,
  }) {
    return CommercialLineInput(
      type: item.defaultItemKind,
      fulfillment: fulfillment,
      lineAmountPaise: lineAmountPaise,
      quantity: quantity,
      unitRatePaise: unitRatePaise ?? item.rateAmount,
      securityDepositPaise: item.securityDepositPaise,
      itemDelta: commercialDeltaFromMetadata(item.metadata),
      metadata: item.metadata,
    );
  }
}

/// Union of line policies for New Order / Pay.
class AggregatedOrderCommercial {
  const AggregatedOrderCommercial({
    required this.pay,
    required this.advance,
    required this.security,
    required this.subscription,
    required this.requireAnyOf,
    required this.suggestedSecurityPaise,
    required this.minPayNowPaise,
    required this.lines,
  });

  final CommercialRequirement pay;
  final CommercialRequirement advance;
  final CommercialRequirement security;
  final CommercialRequirement subscription;
  final List<CommercialStep> requireAnyOf;
  final int suggestedSecurityPaise;
  final int minPayNowPaise;
  final List<ResolvedLinePolicy> lines;

  bool get showPay =>
      pay.isRequired ||
      (pay.isShown && minPayNowPaise > 0) ||
      requireAnyOf.contains(CommercialStep.pay);

  bool get showAdvance =>
      (advance.isRequired && security.isOff) ||
      requireAnyOf.contains(CommercialStep.advance);

  bool get showSecurity =>
      security.isShown || requireAnyOf.contains(CommercialStep.security);

  bool get showSubscription =>
      subscription.isRequired ||
      requireAnyOf.contains(CommercialStep.subscription);

  bool get requirePay => pay.isRequired;

  bool get requireAdvance => advance.isRequired;

  bool get requireSecurity => security.isRequired;

  bool get requireSubscription => subscription.isRequired;

  bool get hasAnyNonOffStep =>
      pay.isShown ||
      advance.isShown ||
      security.isShown ||
      subscription.isShown;

  /// Show New Order commercial step when something must be collected or OR-gated.
  /// Optional pay/advance alone stay on order-detail Pay (library/camera happy path).
  bool get shouldShowCommercialStep =>
      requirePay ||
      requireAdvance ||
      requireSecurity ||
      requireSubscription ||
      showSecurity ||
      requireAnyOf.isNotEmpty;

  bool get hasBlockingStep =>
      requirePay ||
      requireAdvance ||
      requireSecurity ||
      requireSubscription ||
      requireAnyOf.isNotEmpty;
}

ResolvedLinePolicy resolveCommercialLine(
  CommercialLineInput line, {
  CommercialPolicy? templateTypeDefault,
  CommercialPolicyDelta? templateDelta,
}) {
  final CommercialPolicyDelta? itemDelta =
      line.itemDelta ?? commercialDeltaFromMetadata(line.metadata);
  final CommercialPolicy policy = resolveLinePolicy(
    type: line.type,
    itemOverride: line.itemOverride,
    itemDelta: itemDelta,
    templateTypeDefault: templateTypeDefault,
    templateDelta: templateDelta,
    ratePaise: line.unitRatePaise > 0 ? line.unitRatePaise : line.lineAmountPaise,
    securityDepositPaise: line.securityDepositPaise,
  );
  return ResolvedLinePolicy(
    policy: policy,
    type: line.type,
    fulfillment: line.fulfillment,
    quantity: line.quantity < 1 ? 1 : line.quantity,
    unitRatePaise: line.unitRatePaise,
    lineAmountPaise: line.lineAmountPaise < 0 ? 0 : line.lineAmountPaise,
    securityDepositPaise: line.securityDepositPaise,
  );
}

AggregatedOrderCommercial aggregateOrderCommercial(
  List<ResolvedLinePolicy> lines,
) {
  CommercialRequirement pay = CommercialRequirement.off;
  CommercialRequirement advance = CommercialRequirement.off;
  CommercialRequirement security = CommercialRequirement.off;
  CommercialRequirement subscription = CommercialRequirement.off;
  final List<CommercialStep> anyOf = <CommercialStep>[];
  int suggested = 0;
  int minPay = 0;
  for (final ResolvedLinePolicy line in lines) {
    pay = CommercialRequirement.union(pay, line.policy.pay);
    advance = CommercialRequirement.union(advance, line.policy.advance);
    security = CommercialRequirement.union(security, line.policy.security);
    subscription =
        CommercialRequirement.union(subscription, line.policy.subscription);
    for (final CommercialStep step in line.policy.requireAnyOf) {
      if (!anyOf.contains(step)) {
        anyOf.add(step);
      }
    }
    suggested += line.suggestedSecurityPaise;
    if (line.policy.pay.isRequired) {
      minPay += line.lineAmountPaise;
    }
  }
  return AggregatedOrderCommercial(
    pay: pay,
    advance: advance,
    security: security,
    subscription: subscription,
    requireAnyOf: anyOf,
    suggestedSecurityPaise: suggested,
    minPayNowPaise: minPay,
    lines: lines,
  );
}

AggregatedOrderCommercial resolveOrderCommercial(
  List<CommercialLineInput> lines, {
  Map<ResourceType, CommercialPolicy>? templateByType,
}) {
  final List<ResolvedLinePolicy> resolved = <ResolvedLinePolicy>[
    for (final CommercialLineInput line in lines)
      resolveCommercialLine(
        line,
        templateTypeDefault: templateByType?[line.type],
      ),
  ];
  return aggregateOrderCommercial(resolved);
}

/// Build line inputs from an issued rental + catalog map.
List<CommercialLineInput> commercialLinesFromRental(
  Rental rental,
  Map<String, InventoryItem> inventoryById,
) {
  return <CommercialLineInput>[
    for (final RentalLine line in rental.lines)
      CommercialLineInput(
        type: inventoryById[line.itemId]?.defaultItemKind ?? ResourceType.rental,
        fulfillment: line.fulfillment,
        lineAmountPaise: line.baseAmount,
        quantity: 1,
        unitRatePaise: line.rateAmount,
        securityDepositPaise:
            inventoryById[line.itemId]?.securityDepositPaise ?? 0,
        itemDelta: commercialDeltaFromMetadata(
          inventoryById[line.itemId]?.metadata ?? const <String, Object?>{},
        ),
        metadata: inventoryById[line.itemId]?.metadata ?? const <String, Object?>{},
      ),
  ];
}

AggregatedOrderCommercial resolveRentalCommercial(
  Rental rental,
  Map<String, InventoryItem> inventoryById, {
  Map<ResourceType, CommercialPolicy>? templateByType,
}) {
  return resolveOrderCommercial(
    commercialLinesFromRental(rental, inventoryById),
    templateByType: templateByType,
  );
}

/// Suggested security using catalog deposits on rent lines (existing helper).
int suggestedSecurityPaiseForResolved(
  AggregatedOrderCommercial aggregated,
  Rental rental,
  Map<String, InventoryItem> inventoryById,
) {
  if (aggregated.security.isOff) {
    return 0;
  }
  if (aggregated.suggestedSecurityPaise > 0) {
    return aggregated.suggestedSecurityPaise;
  }
  return computeSuggestedSecurityPaise(rental, inventoryById);
}

/// True when membership/subscription sell lines are still valid for [customerOrders].
bool customerHasActiveEntitlement({
  required Iterable<Rental> customerOrders,
  required Map<String, InventoryItem> inventoryById,
  required DateTime now,
}) {
  for (final Rental rental in customerOrders) {
    if (rental.orderStatus == OrderStatus.cancelled) {
      continue;
    }
    for (final RentalLine line in rental.lines) {
      if (!line.isSell) {
        continue;
      }
      final InventoryItem? item = inventoryById[line.itemId];
      final ResourceType type =
          item?.defaultItemKind ?? ResourceType.rental;
      if (type != ResourceType.membership &&
          type != ResourceType.subscription) {
        continue;
      }
      final DateTime validUntil = entitlementValidUntil(
        startedAt: rental.startedAt,
        line: line,
        item: item,
      );
      if (!now.isAfter(validUntil)) {
        return true;
      }
    }
  }
  return false;
}

DateTime entitlementValidUntil({
  required DateTime startedAt,
  required RentalLine line,
  InventoryItem? item,
}) {
  final Map<String, Object?> metadata =
      item?.metadata ?? const <String, Object?>{};
  final Object? validUntilRaw = metadata[kEntitlementValidUntilMetadataKey];
  if (validUntilRaw is String && validUntilRaw.trim().isNotEmpty) {
    final DateTime? parsed = DateTime.tryParse(validUntilRaw.trim());
    if (parsed != null) {
      return parsed;
    }
  }
  final int? days = _readEntitlementDays(metadata);
  if (days != null && days > 0) {
    return startedAt.add(Duration(days: days));
  }
  final BillingMode mode = item?.billingMode ?? line.billingMode;
  final int units = line.rateAmount > 0 && mode == BillingMode.monthly
      ? 1
      : 1;
  switch (mode) {
    case BillingMode.monthly:
      return DateTime(
        startedAt.year,
        startedAt.month + units,
        startedAt.day,
        startedAt.hour,
        startedAt.minute,
        startedAt.second,
        startedAt.millisecond,
        startedAt.microsecond,
      );
    case BillingMode.weekly:
      return startedAt.add(Duration(days: 7 * units));
    case BillingMode.daily:
      return startedAt.add(Duration(days: units));
    case BillingMode.fixed:
    case BillingMode.custom:
      return startedAt.add(const Duration(days: 30));
  }
}

int? _readEntitlementDays(Map<String, Object?> metadata) {
  final Object? raw = metadata[kEntitlementDaysMetadataKey];
  if (raw is int) {
    return raw;
  }
  if (raw is num) {
    return raw.round();
  }
  if (raw is String) {
    return int.tryParse(raw.trim());
  }
  return null;
}

bool cartSatisfiesSubscription(Iterable<CommercialLineInput> lines) {
  for (final CommercialLineInput line in lines) {
    if (line.type == ResourceType.membership ||
        line.type == ResourceType.subscription) {
      return true;
    }
  }
  return false;
}

/// Throws [ArgumentError] when required commercial gates are unmet.
void assertCommercialSatisfied({
  required AggregatedOrderCommercial aggregated,
  required int amountReceivedPaise,
  required int securityPaise,
  int advancePaise = 0,
  bool subscriptionSatisfied = false,
}) {
  final int received = amountReceivedPaise < 0 ? 0 : amountReceivedPaise;
  final int security = securityPaise < 0 ? 0 : securityPaise;
  final int advance = advancePaise < 0 ? 0 : advancePaise;

  if (aggregated.requirePay && received < aggregated.minPayNowPaise) {
    throw ArgumentError('Payment is required before issue');
  }
  if (aggregated.requireSecurity) {
    final int needed = aggregated.suggestedSecurityPaise > 0
        ? aggregated.suggestedSecurityPaise
        : 1;
    if (security < needed) {
      throw ArgumentError('Security deposit is required before issue');
    }
  }
  if (aggregated.requireAdvance && advance <= 0 && security <= 0) {
    throw ArgumentError('Advance is required before issue');
  }
  if (aggregated.requireSubscription && !subscriptionSatisfied) {
    throw ArgumentError('Active membership is required before issue');
  }
  if (aggregated.requireAnyOf.isEmpty) {
    return;
  }
  final bool anyOk = aggregated.requireAnyOf.any((CommercialStep step) {
    switch (step) {
      case CommercialStep.pay:
        return received >= aggregated.minPayNowPaise &&
            (aggregated.minPayNowPaise > 0 || received > 0);
      case CommercialStep.advance:
        return advance > 0 || security > 0;
      case CommercialStep.security:
        final int needed = aggregated.suggestedSecurityPaise > 0
            ? aggregated.suggestedSecurityPaise
            : 1;
        return security >= needed;
      case CommercialStep.subscription:
        return subscriptionSatisfied;
    }
  });
  if (!anyOk) {
    throw ArgumentError('Membership or security is required before issue');
  }
}

/// Whether order-detail Pay should be offered for this cart policy.
bool shouldShowOrderPayCta({
  required AggregatedOrderCommercial aggregated,
  required Rental rental,
}) {
  if (rental.orderStatus == OrderStatus.cancelled) {
    return false;
  }
  if (rental.hasUnpaidSell) {
    return true;
  }
  return aggregated.showSecurity || aggregated.showAdvance || aggregated.showPay;
}
