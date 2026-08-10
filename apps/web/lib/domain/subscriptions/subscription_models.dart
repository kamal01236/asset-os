import '../models/entities.dart';
import '../pricing/rental_pricing.dart';

/// Fixed system subscription ranks. Higher includes every lower gated resource.
enum SubscriptionTier {
  none,
  basic,
  standard,
  pro,
  premium;

  String get storageValue => name;

  int get rank {
    switch (this) {
      case SubscriptionTier.none:
        return 0;
      case SubscriptionTier.basic:
        return 1;
      case SubscriptionTier.standard:
        return 2;
      case SubscriptionTier.pro:
        return 3;
      case SubscriptionTier.premium:
        return 4;
    }
  }

  static SubscriptionTier parse(
    String? raw, {
    SubscriptionTier fallback = SubscriptionTier.none,
  }) {
    switch (raw) {
      case 'basic':
        return SubscriptionTier.basic;
      case 'standard':
        return SubscriptionTier.standard;
      case 'pro':
        return SubscriptionTier.pro;
      case 'premium':
        return SubscriptionTier.premium;
      case 'none':
        return SubscriptionTier.none;
      default:
        return fallback;
    }
  }

  static SubscriptionTier fromRank(int rank) {
    if (rank >= SubscriptionTier.premium.rank) {
      return SubscriptionTier.premium;
    }
    if (rank >= SubscriptionTier.pro.rank) {
      return SubscriptionTier.pro;
    }
    if (rank >= SubscriptionTier.standard.rank) {
      return SubscriptionTier.standard;
    }
    if (rank >= SubscriptionTier.basic.rank) {
      return SubscriptionTier.basic;
    }
    return SubscriptionTier.none;
  }
}

/// Validity length for a subscription SKU. Not a rental [BillingMode].
enum SubscriptionPeriodUnit {
  day,
  week,
  month,
  year;

  String get storageValue => name;

  static SubscriptionPeriodUnit parse(
    String? raw, {
    SubscriptionPeriodUnit fallback = SubscriptionPeriodUnit.month,
  }) {
    switch (raw) {
      case 'day':
        return SubscriptionPeriodUnit.day;
      case 'week':
        return SubscriptionPeriodUnit.week;
      case 'month':
        return SubscriptionPeriodUnit.month;
      case 'year':
        return SubscriptionPeriodUnit.year;
      default:
        return fallback;
    }
  }
}

enum CustomerSubscriptionStatus {
  active,
  cancelled;

  String get storageValue => name;

  static CustomerSubscriptionStatus parse(String? raw) {
    if (raw == CustomerSubscriptionStatus.cancelled.name) {
      return CustomerSubscriptionStatus.cancelled;
    }
    return CustomerSubscriptionStatus.active;
  }
}

/// One customer-owned subscription period (source of truth for access).
class CustomerSubscription {
  const CustomerSubscription({
    required this.id,
    required this.customerId,
    required this.tier,
    required this.startsAt,
    required this.validUntil,
    this.sourceRentalId,
    this.sourceItemId,
    this.status = CustomerSubscriptionStatus.active,
  });

  final String id;
  final String customerId;
  final SubscriptionTier tier;
  final DateTime startsAt;
  final DateTime validUntil;
  final String? sourceRentalId;
  final String? sourceItemId;
  final CustomerSubscriptionStatus status;

  bool isActiveAt(DateTime now) {
    if (status != CustomerSubscriptionStatus.active) {
      return false;
    }
    return !now.isAfter(validUntil);
  }
}

/// True when [type] writes the customer subscription ledger on sell.
bool isSubscriptionCatalogType(ResourceType type) {
  return type == ResourceType.membership || type == ResourceType.subscription;
}

/// Add [count] periods of [unit] to [start] (calendar months/years).
DateTime addSubscriptionPeriod(
  DateTime start,
  SubscriptionPeriodUnit unit,
  int count,
) {
  final int n = count < 1 ? 1 : count;
  switch (unit) {
    case SubscriptionPeriodUnit.day:
      return start.add(Duration(days: n));
    case SubscriptionPeriodUnit.week:
      return start.add(Duration(days: 7 * n));
    case SubscriptionPeriodUnit.month:
      return addCalendarMonths(start, n);
    case SubscriptionPeriodUnit.year:
      return addCalendarMonths(start, 12 * n);
  }
}

/// Renewal end: period after [max(now, currentEnd)] so active rows have no gap.
DateTime renewSubscriptionValidUntil({
  required DateTime now,
  required DateTime currentEnd,
  required SubscriptionPeriodUnit unit,
  required int count,
}) {
  final DateTime base = now.isAfter(currentEnd) ? now : currentEnd;
  return addSubscriptionPeriod(base, unit, count);
}
