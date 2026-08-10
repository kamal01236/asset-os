import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../../domain/models/entities.dart';
import '../../domain/subscriptions/subscription_models.dart';

export '../../l10n/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

String localizedStatusLabel(AppLocalizations l10n, AssetStatus status) {
  switch (status) {
    case AssetStatus.available:
      return l10n.statusAvailable;
    case AssetStatus.rented:
      return l10n.statusRented;
    case AssetStatus.dueToday:
      return l10n.statusDueToday;
    case AssetStatus.overdue:
      return l10n.statusOverdue;
    case AssetStatus.archived:
      return l10n.statusArchived;
  }
}

String localizedOrderStatus(AppLocalizations l10n, OrderStatus status) {
  switch (status) {
    case OrderStatus.open:
      return l10n.orderStatusOpen;
    case OrderStatus.completed:
      return l10n.orderStatusCompleted;
    case OrderStatus.cancelled:
      return l10n.orderStatusCancelled;
  }
}

String localizedBillingMode(AppLocalizations l10n, BillingMode mode) {
  switch (mode) {
    case BillingMode.daily:
      return l10n.billingModeDaily;
    case BillingMode.weekly:
      return l10n.billingModeWeekly;
    case BillingMode.monthly:
      return l10n.billingModeMonthly;
    case BillingMode.fixed:
      return l10n.billingModeFixed;
    case BillingMode.custom:
      return l10n.billingModeCustom;
  }
}

String localizedRentalNoteKind(AppLocalizations l10n, RentalNoteKind kind) {
  switch (kind) {
    case RentalNoteKind.general:
      return l10n.orderNoteKindGeneral;
    case RentalNoteKind.terms:
      return l10n.orderNoteKindTerms;
    case RentalNoteKind.measurement:
      return l10n.orderNoteKindMeasurement;
  }
}

/// Full label for a [ResourceType] (More toggles, add-resource kind picker).
String localizedResourceTypeLabel(AppLocalizations l10n, ResourceType type) {
  switch (type) {
    case ResourceType.rental:
      return l10n.itemKindRentalLabel;
    case ResourceType.sale:
      return l10n.itemKindSaleLabel;
    case ResourceType.service:
      return l10n.itemKindServiceLabel;
    case ResourceType.job:
      return l10n.itemKindJobLabel;
    case ResourceType.subscription:
      return l10n.itemKindSubscriptionLabel;
    case ResourceType.membership:
      return l10n.itemKindMembershipLabel;
    case ResourceType.loan:
      return l10n.itemKindLoanLabel;
    case ResourceType.financial:
      return l10n.itemKindFinancialLabel;
    case ResourceType.custom:
      return l10n.itemKindCustomLabel;
  }
}

/// Badge label for non-rental catalog types; null for [ResourceType.rental].
String? localizedResourceTypeBadge(AppLocalizations l10n, ResourceType type) {
  switch (type) {
    case ResourceType.rental:
      return null;
    case ResourceType.sale:
      return l10n.itemKindSaleBadge;
    case ResourceType.service:
      return l10n.itemKindServiceBadge;
    case ResourceType.job:
      return l10n.itemKindJobBadge;
    case ResourceType.subscription:
      return l10n.itemKindSubscriptionBadge;
    case ResourceType.membership:
      return l10n.itemKindMembershipBadge;
    case ResourceType.loan:
      return l10n.itemKindLoanBadge;
    case ResourceType.financial:
      return l10n.itemKindFinancialBadge;
    case ResourceType.custom:
      return l10n.itemKindCustomBadge;
  }
}

/// Category line with optional resource-type badge (e.g. `Gym · Membership`).
String categoryWithResourceTypeBadge(
  AppLocalizations l10n,
  InventoryItem item,
) {
  final String? badge = localizedResourceTypeBadge(l10n, item.defaultItemKind);
  if (badge == null) {
    return item.category;
  }
  return '${item.category} · $badge';
}

String localizedSubscriptionTier(
  AppLocalizations l10n,
  SubscriptionTier tier,
) {
  switch (tier) {
    case SubscriptionTier.none:
      return l10n.subscriptionTierNone;
    case SubscriptionTier.basic:
      return l10n.subscriptionTierBasic;
    case SubscriptionTier.standard:
      return l10n.subscriptionTierStandard;
    case SubscriptionTier.pro:
      return l10n.subscriptionTierPro;
    case SubscriptionTier.premium:
      return l10n.subscriptionTierPremium;
  }
}

String localizedSubscriptionPeriodUnit(
  AppLocalizations l10n,
  SubscriptionPeriodUnit unit,
) {
  switch (unit) {
    case SubscriptionPeriodUnit.day:
      return l10n.subscriptionPeriodDay;
    case SubscriptionPeriodUnit.week:
      return l10n.subscriptionPeriodWeek;
    case SubscriptionPeriodUnit.month:
      return l10n.subscriptionPeriodMonth;
    case SubscriptionPeriodUnit.year:
      return l10n.subscriptionPeriodYear;
  }
}
