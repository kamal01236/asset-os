@Tags(['unit', 'orders'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:asset_os/domain/models/entities.dart';
import 'package:asset_os/domain/orders/commercial_policy.dart';
import 'package:asset_os/domain/subscriptions/subscription_coverage.dart';
import 'package:asset_os/domain/subscriptions/subscription_models.dart';

void main() {
  group('SubscriptionTier ranks', () {
    test('none < basic < standard < pro < premium and higher includes lower', () {
      expect(SubscriptionTier.none.rank, 0);
      expect(SubscriptionTier.basic.rank, 1);
      expect(SubscriptionTier.standard.rank, 2);
      expect(SubscriptionTier.pro.rank, 3);
      expect(SubscriptionTier.premium.rank, 4);
      expect(
        coversSubscriptionTier(
          minTier: SubscriptionTier.basic,
          effectiveRank: SubscriptionTier.pro.rank,
        ),
        isTrue,
      );
      expect(
        coversSubscriptionTier(
          minTier: SubscriptionTier.pro,
          effectiveRank: SubscriptionTier.basic.rank,
        ),
        isFalse,
      );
    });
  });

  group('effectiveSubscriptionRank', () {
    test('max active non-expired row; leftover basic survives after pro expires',
        () {
      final DateTime now = DateTime(2026, 6, 1);
      final List<CustomerSubscription> rows = <CustomerSubscription>[
        CustomerSubscription(
          id: 'CSUB-B',
          customerId: 'CUS-1',
          tier: SubscriptionTier.basic,
          startsAt: DateTime(2026, 1, 1),
          validUntil: DateTime(2026, 12, 1),
        ),
        CustomerSubscription(
          id: 'CSUB-P',
          customerId: 'CUS-1',
          tier: SubscriptionTier.pro,
          startsAt: DateTime(2026, 4, 1),
          validUntil: DateTime(2026, 5, 1),
        ),
      ];
      expect(
        effectiveSubscriptionRank(rows, DateTime(2026, 4, 15)),
        SubscriptionTier.pro.rank,
      );
      expect(effectiveSubscriptionRank(rows, now), SubscriptionTier.basic.rank);
    });

    test('cancelled and expired rows do not count', () {
      final DateTime now = DateTime(2026, 6, 1);
      final List<CustomerSubscription> rows = <CustomerSubscription>[
        CustomerSubscription(
          id: 'CSUB-X',
          customerId: 'CUS-1',
          tier: SubscriptionTier.premium,
          startsAt: DateTime(2026, 1, 1),
          validUntil: DateTime(2026, 5, 1),
        ),
        CustomerSubscription(
          id: 'CSUB-C',
          customerId: 'CUS-1',
          tier: SubscriptionTier.pro,
          startsAt: DateTime(2026, 1, 1),
          validUntil: DateTime(2026, 12, 1),
          status: CustomerSubscriptionStatus.cancelled,
        ),
      ];
      expect(effectiveSubscriptionRank(rows, now), 0);
    });
  });

  group('period math', () {
    test('renewal extends from current end when still active', () {
      final DateTime now = DateTime(2026, 6, 1);
      final DateTime currentEnd = DateTime(2026, 6, 15);
      expect(
        renewSubscriptionValidUntil(
          now: now,
          currentEnd: currentEnd,
          unit: SubscriptionPeriodUnit.month,
          count: 1,
        ),
        DateTime(2026, 7, 15),
      );
    });

    test('renewal starts from now when expired', () {
      final DateTime now = DateTime(2026, 6, 1);
      expect(
        renewSubscriptionValidUntil(
          now: now,
          currentEnd: DateTime(2026, 5, 1),
          unit: SubscriptionPeriodUnit.year,
          count: 1,
        ),
        DateTime(2027, 6, 1),
      );
    });

    test('day and week adders', () {
      final DateTime start = DateTime(2026, 1, 1);
      expect(
        addSubscriptionPeriod(start, SubscriptionPeriodUnit.day, 30),
        DateTime(2026, 1, 31),
      );
      expect(
        addSubscriptionPeriod(start, SubscriptionPeriodUnit.week, 1),
        DateTime(2026, 1, 8),
      );
    });
  });

  group('cart min tier and upsell', () {
    test('mixed cart uses max min-tier; required upsell is that tier', () {
      final List<({ResourceType type, Map<String, Object?> metadata})> lines =
          <({ResourceType type, Map<String, Object?> metadata})>[
        (
          type: ResourceType.loan,
          metadata: <String, Object?>{
            kMinSubscriptionTierMetadataKey: 'basic',
          },
        ),
        (
          type: ResourceType.rental,
          metadata: <String, Object?>{
            kMinSubscriptionTierMetadataKey: 'standard',
          },
        ),
        (
          type: ResourceType.membership,
          metadata: <String, Object?>{
            kSubscriptionTierMetadataKey: 'basic',
          },
        ),
      ];
      expect(cartMinSubscriptionTier(lines), SubscriptionTier.standard);
      expect(
        requiredUpsellTier(
          cartMinTier: SubscriptionTier.standard,
          customerRank: SubscriptionTier.basic.rank,
        ),
        SubscriptionTier.standard,
      );
      expect(
        requiredUpsellTier(
          cartMinTier: SubscriptionTier.standard,
          customerRank: SubscriptionTier.standard.rank,
        ),
        isNull,
      );
      expect(
        subscriptionCoverageSatisfied(
          customerRank: 0,
          lines: lines,
          customerCanHoldLedger: true,
        ),
        isFalse,
      );
      expect(
        subscriptionCoverageSatisfied(
          customerRank: 0,
          lines: <({ResourceType type, Map<String, Object?> metadata})>[
            ...lines,
            (
              type: ResourceType.membership,
              metadata: <String, Object?>{
                kSubscriptionTierMetadataKey: 'standard',
              },
            ),
          ],
          customerCanHoldLedger: true,
        ),
        isTrue,
      );
    });

    test('unknown customer cannot cover a required min-tier', () {
      final List<({ResourceType type, Map<String, Object?> metadata})> lines =
          <({ResourceType type, Map<String, Object?> metadata})>[
        (
          type: ResourceType.loan,
          metadata: <String, Object?>{
            kMinSubscriptionTierMetadataKey: 'basic',
          },
        ),
        (
          type: ResourceType.membership,
          metadata: <String, Object?>{
            kSubscriptionTierMetadataKey: 'basic',
          },
        ),
      ];
      expect(
        subscriptionCoverageSatisfied(
          customerRank: 0,
          lines: lines,
          customerCanHoldLedger: false,
        ),
        isFalse,
      );
    });
  });

  group('library OR security vs subscription coverage', () {
    test('requireAnyOf still passes on security without subscription', () {
      final AggregatedOrderCommercial agg = resolveOrderCommercial(
        const <CommercialLineInput>[
          CommercialLineInput(
            type: ResourceType.loan,
            fulfillment: LineFulfillment.rent,
            unitRatePaise: 0,
            lineAmountPaise: 0,
            metadata: <String, Object?>{
              kMinSubscriptionTierMetadataKey: 'basic',
            },
          ),
        ],
        templateByType: const <ResourceType, CommercialPolicy>{
          ResourceType.loan: CommercialPolicy(
            pay: CommercialRequirement.off,
            security: CommercialRequirement.optional,
            subscription: CommercialRequirement.optional,
            requireAnyOf: <CommercialStep>[
              CommercialStep.security,
              CommercialStep.subscription,
            ],
          ),
        },
      );
      expect(agg.cartMinTier, SubscriptionTier.basic);
      expect(agg.needsSubscriptionCoverage, isTrue);
      expect(agg.requireAnyOf, contains(CommercialStep.security));
      assertCommercialSatisfied(
        aggregated: agg,
        amountReceivedPaise: 0,
        securityPaise: 1000,
        subscriptionSatisfied: false,
      );
      assertCommercialSatisfied(
        aggregated: agg,
        amountReceivedPaise: 0,
        securityPaise: 0,
        subscriptionSatisfied: true,
      );
      expect(
        () => assertCommercialSatisfied(
          aggregated: agg,
          amountReceivedPaise: 0,
          securityPaise: 0,
          subscriptionSatisfied: false,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('gated cart without OR-group requires coverage', () {
      final AggregatedOrderCommercial agg = resolveOrderCommercial(
        const <CommercialLineInput>[
          CommercialLineInput(
            type: ResourceType.rental,
            fulfillment: LineFulfillment.rent,
            unitRatePaise: 30000,
            lineAmountPaise: 30000,
            metadata: <String, Object?>{
              kMinSubscriptionTierMetadataKey: 'standard',
            },
          ),
        ],
      );
      expect(agg.cartMinTier, SubscriptionTier.standard);
      expect(
        () => assertCommercialSatisfied(
          aggregated: agg,
          amountReceivedPaise: 0,
          securityPaise: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
      assertCommercialSatisfied(
        aggregated: agg,
        amountReceivedPaise: 0,
        securityPaise: 0,
        subscriptionSatisfied: true,
      );
    });
  });

  group('entitlementValidUntil backfill helper', () {
    test('metadata.validUntil overrides billing mode', () {
      const InventoryItem plan = InventoryItem(
        id: 'INV-Q',
        name: 'Quarterly',
        category: 'Gym',
        availableUnits: 5,
        totalUnits: 5,
        status: AssetStatus.available,
        qrCode: 'inventory:q',
        billingMode: BillingMode.fixed,
        rateAmount: 400000,
        defaultItemKind: ResourceType.membership,
        requiresUnitIdentity: false,
        metadata: <String, Object?>{
          kEntitlementValidUntilMetadataKey: '2026-04-01T00:00:00.000',
        },
      );
      final DateTime until = entitlementValidUntil(
        startedAt: DateTime(2026, 1, 1),
        line: RentalLine(
          id: 'RLI-Q',
          itemId: 'INV-Q',
          catalogName: 'Quarterly',
          instanceName: 'Quarterly',
          shortCode: 'Q-1',
          fulfillment: LineFulfillment.sell,
          baseAmount: 400000,
          returnedAt: DateTime(2026, 1, 1),
        ),
        item: plan,
      );
      expect(until, DateTime.parse('2026-04-01T00:00:00.000'));
    });
  });
}
