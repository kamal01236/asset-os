import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/models/entities.dart';
import '../../domain/subscriptions/subscription_models.dart';
import '../../infrastructure/l10n/l10n_ext.dart';

/// Add/edit catalog controls for SKU tier+period or resource min-tier.
class SubscriptionCatalogFields extends StatelessWidget {
  const SubscriptionCatalogFields({
    super.key,
    required this.kind,
    required this.skuTier,
    required this.periodUnit,
    required this.periodCountController,
    required this.minTier,
    required this.onSkuTierChanged,
    required this.onPeriodUnitChanged,
    required this.onMinTierChanged,
    this.fieldKeyPrefix = 'subscription',
  });

  final ResourceType kind;
  final SubscriptionTier skuTier;
  final SubscriptionPeriodUnit periodUnit;
  final TextEditingController periodCountController;
  final SubscriptionTier minTier;
  final ValueChanged<SubscriptionTier> onSkuTierChanged;
  final ValueChanged<SubscriptionPeriodUnit> onPeriodUnitChanged;
  final ValueChanged<SubscriptionTier> onMinTierChanged;
  final String fieldKeyPrefix;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    if (isSubscriptionCatalogType(kind)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(height: 8),
          DropdownButtonFormField<SubscriptionTier>(
            key: ValueKey<String>('$fieldKeyPrefix-sku-tier-$skuTier'),
            initialValue: skuTier == SubscriptionTier.none
                ? SubscriptionTier.basic
                : skuTier,
            decoration: InputDecoration(labelText: l10n.subscriptionSkuTierLabel),
            items: <SubscriptionTier>[
              SubscriptionTier.basic,
              SubscriptionTier.standard,
              SubscriptionTier.pro,
              SubscriptionTier.premium,
            ]
                .map(
                  (SubscriptionTier tier) => DropdownMenuItem<SubscriptionTier>(
                    value: tier,
                    child: Text(localizedSubscriptionTier(l10n, tier)),
                  ),
                )
                .toList(),
            onChanged: (SubscriptionTier? value) {
              if (value != null) {
                onSkuTierChanged(value);
              }
            },
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<SubscriptionPeriodUnit>(
            key: ValueKey<String>('$fieldKeyPrefix-period-unit-$periodUnit'),
            initialValue: periodUnit,
            decoration:
                InputDecoration(labelText: l10n.subscriptionPeriodUnitLabel),
            items: SubscriptionPeriodUnit.values
                .map(
                  (SubscriptionPeriodUnit unit) =>
                      DropdownMenuItem<SubscriptionPeriodUnit>(
                    value: unit,
                    child: Text(localizedSubscriptionPeriodUnit(l10n, unit)),
                  ),
                )
                .toList(),
            onChanged: (SubscriptionPeriodUnit? value) {
              if (value != null) {
                onPeriodUnitChanged(value);
              }
            },
          ),
          const SizedBox(height: 8),
          TextField(
            key: ValueKey<String>('$fieldKeyPrefix-period-count'),
            controller: periodCountController,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              labelText: l10n.subscriptionPeriodCountLabel,
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 8),
        DropdownButtonFormField<SubscriptionTier>(
          key: ValueKey<String>('$fieldKeyPrefix-min-tier-$minTier'),
          initialValue: minTier,
          decoration: InputDecoration(
            labelText: l10n.minSubscriptionTierLabel,
            helperText: l10n.minSubscriptionTierHelper,
          ),
          items: SubscriptionTier.values
              .map(
                (SubscriptionTier tier) => DropdownMenuItem<SubscriptionTier>(
                  value: tier,
                  child: Text(localizedSubscriptionTier(l10n, tier)),
                ),
              )
              .toList(),
          onChanged: (SubscriptionTier? value) {
            if (value != null) {
              onMinTierChanged(value);
            }
          },
        ),
      ],
    );
  }
}
