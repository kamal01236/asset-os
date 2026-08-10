import '../models/entities.dart';
import 'subscription_models.dart';

/// Catalog metadata: tier granted by a membership / subscription SKU.
const String kSubscriptionTierMetadataKey = 'subscriptionTier';

/// Catalog metadata: [SubscriptionPeriodUnit] for a SKU.
const String kSubscriptionPeriodUnitMetadataKey = 'subscriptionPeriodUnit';

/// Catalog metadata: positive period count for a SKU.
const String kSubscriptionPeriodCountMetadataKey = 'subscriptionPeriodCount';

/// Catalog metadata: minimum tier a non-SKU resource requires (`none` = ungated).
const String kMinSubscriptionTierMetadataKey = 'minSubscriptionTier';

int effectiveSubscriptionRank(
  Iterable<CustomerSubscription> rows,
  DateTime now,
) {
  int maxRank = SubscriptionTier.none.rank;
  for (final CustomerSubscription row in rows) {
    if (!row.isActiveAt(now)) {
      continue;
    }
    if (row.tier.rank > maxRank) {
      maxRank = row.tier.rank;
    }
  }
  return maxRank;
}

bool coversSubscriptionTier({
  required SubscriptionTier minTier,
  required int effectiveRank,
}) {
  return effectiveRank >= minTier.rank;
}

/// Cheapest system tier that closes the gap, or null when already covered.
SubscriptionTier? requiredUpsellTier({
  required SubscriptionTier cartMinTier,
  required int customerRank,
}) {
  if (coversSubscriptionTier(
    minTier: cartMinTier,
    effectiveRank: customerRank,
  )) {
    return null;
  }
  return cartMinTier;
}

SubscriptionTier minSubscriptionTierFromMetadata(
  Map<String, Object?> metadata,
) {
  return SubscriptionTier.parse(
    metadata[kMinSubscriptionTierMetadataKey]?.toString(),
  );
}

SubscriptionTier? subscriptionTierFromMetadata(
  Map<String, Object?> metadata, {
  SubscriptionTier? fallback,
}) {
  final Object? raw = metadata[kSubscriptionTierMetadataKey];
  if (raw == null) {
    return fallback;
  }
  final String text = raw.toString().trim();
  if (text.isEmpty) {
    return fallback;
  }
  return SubscriptionTier.parse(text, fallback: fallback ?? SubscriptionTier.basic);
}

SubscriptionPeriodUnit? subscriptionPeriodUnitFromMetadata(
  Map<String, Object?> metadata,
) {
  final Object? raw = metadata[kSubscriptionPeriodUnitMetadataKey];
  if (raw == null) {
    return null;
  }
  final String text = raw.toString().trim();
  if (text.isEmpty) {
    return null;
  }
  return SubscriptionPeriodUnit.parse(text);
}

int? subscriptionPeriodCountFromMetadata(Map<String, Object?> metadata) {
  final Object? raw = metadata[kSubscriptionPeriodCountMetadataKey];
  if (raw is int) {
    return raw < 1 ? null : raw;
  }
  if (raw is num) {
    final int rounded = raw.round();
    return rounded < 1 ? null : rounded;
  }
  if (raw is String) {
    final int? parsed = int.tryParse(raw.trim());
    if (parsed == null || parsed < 1) {
      return null;
    }
    return parsed;
  }
  return null;
}

/// Max min-tier among non-SKU cart lines (`none` when nothing is gated).
SubscriptionTier cartMinSubscriptionTier(
  Iterable<({ResourceType type, Map<String, Object?> metadata})> lines,
) {
  SubscriptionTier maxTier = SubscriptionTier.none;
  for (final ({ResourceType type, Map<String, Object?> metadata}) line
      in lines) {
    if (isSubscriptionCatalogType(line.type)) {
      continue;
    }
    final SubscriptionTier min = minSubscriptionTierFromMetadata(line.metadata);
    if (min.rank > maxTier.rank) {
      maxTier = min;
    }
  }
  return maxTier;
}

/// Highest SKU tier present on membership / subscription cart lines.
int cartGrantedSubscriptionRank(
  Iterable<({ResourceType type, Map<String, Object?> metadata})> lines,
) {
  int rank = SubscriptionTier.none.rank;
  for (final ({ResourceType type, Map<String, Object?> metadata}) line
      in lines) {
    if (!isSubscriptionCatalogType(line.type)) {
      continue;
    }
    final SubscriptionTier tier = subscriptionTierFromMetadata(
          line.metadata,
          fallback: SubscriptionTier.basic,
        ) ??
        SubscriptionTier.basic;
    if (tier.rank > rank) {
      rank = tier.rank;
    }
  }
  return rank;
}

/// Whether [customerRank] plus same-order SKUs cover every gated line.
///
/// Unknown / no-phone customers cannot hold a ledger and never cover a min-tier.
bool subscriptionCoverageSatisfied({
  required int customerRank,
  required Iterable<({ResourceType type, Map<String, Object?> metadata})> lines,
  required bool customerCanHoldLedger,
}) {
  final SubscriptionTier minTier = cartMinSubscriptionTier(lines);
  if (minTier == SubscriptionTier.none) {
    return true;
  }
  if (!customerCanHoldLedger) {
    return false;
  }
  final int granted = cartGrantedSubscriptionRank(lines);
  final int effective = customerRank > granted ? customerRank : granted;
  return coversSubscriptionTier(minTier: minTier, effectiveRank: effective);
}

CustomerSubscription? highestActiveSubscription(
  Iterable<CustomerSubscription> rows,
  DateTime now,
) {
  CustomerSubscription? best;
  for (final CustomerSubscription row in rows) {
    if (!row.isActiveAt(now)) {
      continue;
    }
    if (best == null ||
        row.tier.rank > best.tier.rank ||
        (row.tier.rank == best.tier.rank &&
            row.validUntil.isAfter(best.validUntil))) {
      best = row;
    }
  }
  return best;
}

/// Period for granting a SKU: metadata first, then entitlement days, then billing.
({SubscriptionPeriodUnit unit, int count}) resolveSubscriptionPeriod({
  required Map<String, Object?> metadata,
  BillingMode? billingMode,
}) {
  final SubscriptionPeriodUnit? unit = subscriptionPeriodUnitFromMetadata(
    metadata,
  );
  final int? count = subscriptionPeriodCountFromMetadata(metadata);
  if (unit != null && count != null) {
    return (unit: unit, count: count);
  }
  final int? days = _readEntitlementDays(metadata);
  if (days != null && days > 0) {
    return (unit: SubscriptionPeriodUnit.day, count: days);
  }
  switch (billingMode) {
    case BillingMode.daily:
      return (unit: SubscriptionPeriodUnit.day, count: 1);
    case BillingMode.weekly:
      return (unit: SubscriptionPeriodUnit.week, count: 1);
    case BillingMode.monthly:
      return (unit: SubscriptionPeriodUnit.month, count: 1);
    case BillingMode.fixed:
    case BillingMode.custom:
    case null:
      return (unit: SubscriptionPeriodUnit.month, count: 1);
  }
}

/// Merge SKU / min-tier keys into catalog metadata (null [skuTier] clears SKU keys).
Map<String, Object?> applySubscriptionCatalogMetadata(
  Map<String, Object?> metadata, {
  SubscriptionTier? skuTier,
  SubscriptionPeriodUnit? periodUnit,
  int? periodCount,
  SubscriptionTier? minTier,
}) {
  final Map<String, Object?> out = Map<String, Object?>.of(metadata);
  out.remove(kSubscriptionTierMetadataKey);
  out.remove(kSubscriptionPeriodUnitMetadataKey);
  out.remove(kSubscriptionPeriodCountMetadataKey);
  out.remove(kMinSubscriptionTierMetadataKey);
  if (skuTier != null && skuTier != SubscriptionTier.none) {
    out[kSubscriptionTierMetadataKey] = skuTier.storageValue;
    final SubscriptionPeriodUnit unit =
        periodUnit ?? SubscriptionPeriodUnit.month;
    final int count = (periodCount == null || periodCount < 1) ? 1 : periodCount;
    out[kSubscriptionPeriodUnitMetadataKey] = unit.storageValue;
    out[kSubscriptionPeriodCountMetadataKey] = count;
  } else if (minTier != null && minTier != SubscriptionTier.none) {
    out[kMinSubscriptionTierMetadataKey] = minTier.storageValue;
  }
  return out;
}

/// Cheapest catalog SKU whose tier covers [minTier] (prefer [preferredCategory]).
InventoryItem? cheapestCoveringSubscriptionSku({
  required Iterable<InventoryItem> catalog,
  required SubscriptionTier minTier,
  String? preferredCategory,
}) {
  final List<InventoryItem> covering = <InventoryItem>[];
  for (final InventoryItem item in catalog) {
    if (!item.catalogActive) {
      continue;
    }
    if (!isSubscriptionCatalogType(item.defaultItemKind)) {
      continue;
    }
    final SubscriptionTier tier = subscriptionTierFromMetadata(
          item.metadata,
          fallback: SubscriptionTier.basic,
        ) ??
        SubscriptionTier.basic;
    if (tier.rank >= minTier.rank) {
      covering.add(item);
    }
  }
  if (covering.isEmpty) {
    return null;
  }
  int rateOf(InventoryItem item) => item.rateAmount < 0 ? 0 : item.rateAmount;
  covering.sort((InventoryItem a, InventoryItem b) {
    final String? pref = preferredCategory?.trim().toLowerCase();
    if (pref != null && pref.isNotEmpty) {
      final bool aMatch = a.category.trim().toLowerCase() == pref;
      final bool bMatch = b.category.trim().toLowerCase() == pref;
      if (aMatch != bMatch) {
        return aMatch ? -1 : 1;
      }
    }
    final int rateCmp = rateOf(a).compareTo(rateOf(b));
    if (rateCmp != 0) {
      return rateCmp;
    }
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return covering.first;
}

int? _readEntitlementDays(Map<String, Object?> metadata) {
  final Object? raw = metadata['entitlementDays'];
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
